import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { TaskInfo } from '../main/ets/domain/models/TaskInfo';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';
import { ConsecutiveDaysState } from '../main/ets/domain/rules/ConsecutiveDaysRules';
import { createDefaultTaskInfoList } from '../main/ets/domain/constants/TaskCatalog';
import { getToday, getDateOffset } from '../main/ets/domain/utils/DateUtils';
import { HomeStore, HomeStoreDeps } from '../main/ets/viewmodel/HomeStore';
import {
  FakeTaskRepo,
  FakeDayInfoRepo,
  FakeDayTaskRepo,
  FakePrefRepo,
  FakeFormService
} from './fakes/FakeRepositories';

/**
 * 第 2 层测试：数据持久化语义
 *
 * 验证 FakeRepositories 的行为是否忠实模拟真实 RDB/Preferences，
 * 以及 HomeStore 在模拟"重启"场景下数据能否正确恢复。
 *
 * 这层测试能抓的 bug 模式：
 * - 重启丢数据（连续天数/任务开关/目标值）
 * - 重复插入（upsert 不去重）
 * - 历史记录被覆盖
 * - DayInfo 与 DayTask 不一致
 */

function makeDeps(): HomeStoreDeps {
  return new HomeStoreDeps(
    new FakeTaskRepo(),
    new FakeDayInfoRepo(),
    new FakeDayTaskRepo(),
    new FakePrefRepo(),
    new FakeFormService()
  );
}

function makeDefaultStore(deps: HomeStoreDeps): HomeStore {
  const store = HomeStore.createForTest(deps);
  (deps.taskRepo as FakeTaskRepo).seed(createDefaultTaskInfoList());
  return store;
}

export default function persistenceSemanticsTest() {

  describe('Persistence_UpsertNoDup', () => {
    let deps: HomeStoreDeps;

    beforeAll(() => {
      deps = makeDeps();
    });

    it('upsertDayTask_sameDateTaskReturnsSameId', 0, async () => {
      deps = makeDeps();
      const repo = deps.dayTaskRepo as FakeDayTaskRepo;
      const dt = new DayTaskInfo(0, '20260101', 0, '08:00', '', false);
      const id1 = await repo.upsertDayTask(dt);
      const id2 = await repo.upsertDayTask(dt);
      expect(id1).assertEqual(id2);
      expect(repo.rawCount('20260101')).assertEqual(1);
    });

    it('upsertDayTask_differentTaskGetsNewId', 0, async () => {
      deps = makeDeps();
      const repo = deps.dayTaskRepo as FakeDayTaskRepo;
      await repo.upsertDayTask(new DayTaskInfo(0, '20260101', 0, '08:00', '', false));
      await repo.upsertDayTask(new DayTaskInfo(0, '20260101', 1, '1', '', false));
      expect(repo.rawCount('20260101')).assertEqual(2);
    });

    it('upsertDayTask_differentDateSameTaskIdBothStored', 0, async () => {
      deps = makeDeps();
      const repo = deps.dayTaskRepo as FakeDayTaskRepo;
      await repo.upsertDayTask(new DayTaskInfo(0, '20260101', 0, '08:00', '', false));
      await repo.upsertDayTask(new DayTaskInfo(0, '20260102', 0, '08:00', '', false));
      expect(repo.rawCount('20260101')).assertEqual(1);
      expect(repo.rawCount('20260102')).assertEqual(1);
    });
  });

  describe('Persistence_BatchInsertIdempotent', () => {
    let deps: HomeStoreDeps;

    beforeAll(() => {
      deps = makeDeps();
    });

    it('batchInsert_thenBatchAgain_noDuplicates', 0, async () => {
      const repo = deps.dayTaskRepo as FakeDayTaskRepo;
      const batch: DayTaskInfo[] = [
        new DayTaskInfo(0, '20260101', 0, '08:00', '', false),
        new DayTaskInfo(0, '20260101', 1, '1', '', false)
      ];
      await repo.batchInsertDayTasks(batch);
      expect(repo.rawCount('20260101')).assertEqual(2);

      // 再插一次相同数据 — 不应产生重复
      const batch2: DayTaskInfo[] = [
        new DayTaskInfo(0, '20260101', 0, '08:00', '', false),
        new DayTaskInfo(0, '20260101', 1, '1', '', false)
      ];
      await repo.batchInsertDayTasks(batch2);
      expect(repo.rawCount('20260101')).assertEqual(2);
    });
  });

  describe('Persistence_EnsureDefaultOnce', () => {
    it('ensureDefaultTasks_thenAgain_noDuplicates', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);

      // 第一次 init
      await store.initAppData();
      expect(store.allTasks.length).assertEqual(6);
      const firstIds = store.allTasks.map(t => t.taskId).sort();

      // 第二次 init — 不应重复插入任务
      await store.initAppData();
      expect(store.allTasks.length).assertEqual(6);
      const secondIds = store.allTasks.map(t => t.taskId).sort();
      for (let i = 0; i < 6; i++) {
        expect(secondIds[i]).assertEqual(firstIds[i]);
      }
    });
  });

  describe('Persistence_DayInfoDayTaskConsistency', () => {
    let deps: HomeStoreDeps;
    let store: HomeStore;
    const DATE: string = getToday();

    beforeAll(async () => {
      deps = makeDeps();
      store = makeDefaultStore(deps);
      await store.initAppData();
      await store.enableTask(0); // 早起
      await store.enableTask(1); // 喝水
    });

    it('dayInfo_targetMatchesDayTaskCount', 0, () => {
      const dayTaskCount = store.dayTasks.length;
      expect(store.dayInfo.targetTaskNum).assertEqual(dayTaskCount);
    });

    it('dayInfo_finCountMatchesDoneCount', 0, async () => {
      // 完成早起
      const earlyTask = store.dayTasks.find(t => t.taskId === 0);
      if (earlyTask) {
        await store.checkin(earlyTask.id);
      }
      const doneCount = store.dayTasks.filter(t => t.isDone).length;
      expect(store.dayInfo.finTaskNum).assertEqual(doneCount);
      expect(store.dayInfo.finTaskNum).assertEqual(1);
    });

    it('dayInfo_persistedToDb_matchesMemory', 0, async () => {
      const dbInfo = await deps.dayRepo.getDayInfo(DATE);
      expect(dbInfo !== null).assertTrue();
      if (dbInfo) {
        expect(dbInfo.targetTaskNum).assertEqual(store.dayInfo.targetTaskNum);
        expect(dbInfo.finTaskNum).assertEqual(store.dayInfo.finTaskNum);
      }
    });
  });

  describe('Persistence_RestartRecovery', () => {
    it('restart_recoversTaskConfig', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.enableTask(0);
      await store.enableTask(5);
      await store.updateTaskTarget(0, '07:00');

      // 模拟重启
      const store2 = HomeStore.createForTest(deps);
      await store2.initAppData();

      // 任务开关应恢复
      const task0 = store2.allTasks.find(t => t.taskId === 0);
      expect(task0 !== null && task0 !== undefined).assertTrue();
      if (task0) {
        expect(task0.isOpen).assertTrue();
        expect(task0.targetValue).assertEqual('07:00');
      }
      const task5 = store2.allTasks.find(t => t.taskId === 5);
      expect(task5 !== null && task5 !== undefined).assertTrue();
      if (task5) {
        expect(task5.isOpen).assertTrue();
      }
      // 未启用的应保持关闭
      const task1 = store2.allTasks.find(t => t.taskId === 1);
      expect(task1 !== null && task1 !== undefined).assertTrue();
      if (task1) {
        expect(task1.isOpen).assertFalse();
      }
    });

    it('restart_recoversConsecutiveState', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.enableTask(3); // 微笑
      const task = store.dayTasks.find(t => t.taskId === 3);
      if (task) {
        await store.checkin(task.id);
      }
      expect(store.consecutiveState.currentConsecutiveDays).assertEqual(1);
      expect(store.consecutiveState.maxConsecutiveDays).assertEqual(1);

      // 重启
      const store2 = HomeStore.createForTest(deps);
      await store2.initAppData();
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(1);
      expect(store2.consecutiveState.maxConsecutiveDays).assertEqual(1);
      // currentDayStatus 应通过 reconcileCurrentDayCompletion 恢复为 true
      expect(store2.consecutiveState.currentDayStatus).assertTrue();
    });

    it('restart_recoversDayTaskProgress', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      const DATE: string = getToday();
      await store.initAppData();
      await store.enableTask(1); // 喝水 step=0.5 target=1

      // 打卡一次 → 进度 0.5
      const drink = store.dayTasks.find(t => t.taskId === 1);
      if (drink) {
        await store.checkin(drink.id);
      }
      const half = await deps.dayTaskRepo.getDayTask(DATE, 1);
      expect(half !== null && half!.finValue).assertEqual('0.5');
      expect(half!.isDone).assertFalse();

      // 重启
      const store2 = HomeStore.createForTest(deps);
      await store2.initAppData();
      const drink2 = store2.dayTasks.find(t => t.taskId === 1);
      expect(drink2 !== null && drink2 !== undefined).assertTrue();
      if (drink2) {
        expect(drink2.finValue).assertEqual('0.5');
        expect(drink2.isDone).assertFalse();
      }
    });

    it('restart_recoversCompletedDayTask', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      const DATE: string = getToday();
      await store.initAppData();
      await store.enableTask(0); // 早起
      const early = store.dayTasks.find(t => t.taskId === 0);
      if (early) {
        await store.checkin(early.id);
      }

      // 重启
      const store2 = HomeStore.createForTest(deps);
      await store2.initAppData();
      const early2 = store2.dayTasks.find(t => t.taskId === 0);
      expect(early2 !== null && early2 !== undefined).assertTrue();
      if (early2) {
        expect(early2.isDone).assertTrue();
        expect(early2.finValue).assertEqual(early2.targetValue);
      }
    });
  });

  describe('Persistence_HistoryNotOverwritten', () => {
    it('historyDate_completedRecordSurvivesNewDayInit', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      const YESTERDAY: string = getDateOffset(getToday(), -1);
      await store.initAppData();

      // 直接 insert 模拟昨天的完成记录
      await deps.dayRepo.upsertDayInfo(new DayInfo(YESTERDAY, 1, 1));
      await deps.dayTaskRepo.insertDayTask(
        new DayTaskInfo(0, YESTERDAY, 0, '08:00', '08:00', true)
      );

      // 切到昨天验证
      // 切到昨天验证
      await store.selectDate(YESTERDAY);
      const hist = store.dayTasks.find(t => t.taskId === 0);
      expect(hist !== null && hist !== undefined).assertTrue();
      if (hist) {
        expect(hist.isDone).assertTrue();
        expect(hist.finValue).assertEqual('08:00');
      }

      // 切回今天 — 不应影响昨天的记录
      await store.selectDate(getToday());
      const stillThere = await deps.dayTaskRepo.getDayTask(YESTERDAY, 0);
      expect(stillThere !== null).assertTrue();
      if (stillThere) {
        expect(stillThere.isDone).assertTrue();
        expect(stillThere.finValue).assertEqual('08:00');
      }
    });
  });

  describe('Persistence_DeleteSemantics', () => {
    let deps: HomeStoreDeps;

    beforeAll(() => {
      deps = makeDeps();
    });

    it('deleteDayTask_onlyRemovesMatchingDateAndTask', 0, async () => {
      const repo = deps.dayTaskRepo as FakeDayTaskRepo;
      const DATE = '20260101';
      await repo.insertDayTask(new DayTaskInfo(0, DATE, 0, '08:00', '', false));
      await repo.insertDayTask(new DayTaskInfo(0, DATE, 1, '1', '', false));
      await repo.insertDayTask(new DayTaskInfo(0, '20260102', 0, '08:00', '', false));

      await repo.deleteDayTask(DATE, 0);

      expect(repo.rawCount(DATE)).assertEqual(1);
      // 其他日期的相同 taskId 不受影响
      expect(repo.rawCount('20260102')).assertEqual(1);
    });

    it('deleteDayTask_nonExistentIsNoop', 0, async () => {
      const repo = deps.dayTaskRepo as FakeDayTaskRepo;
      const before = repo.rawCount('20261231');
      await repo.deleteDayTask('20261231', 99);
      expect(repo.rawCount('20261231')).assertEqual(before);
    });
  });

  describe('Preferences_SaveLoadRoundtrip', () => {
    it('saveThenLoad_returnsSameValues', 0, async () => {
      const pref = new FakePrefRepo();
      const state = new ConsecutiveDaysState(7, 5, true, null);
      await pref.saveConsecutiveState(state);

      const loaded = await pref.getConsecutiveState();
      expect(loaded.maxConsecutiveDays).assertEqual(7);
      expect(loaded.currentConsecutiveDays).assertEqual(5);
      expect(loaded.currentDayStatus).assertTrue();
      expect(loaded.newlyUnlockedAchievement === null).assertTrue();
    });

    it('saveWithAchievementThenLoad_preservesUnlock', 0, async () => {
      const pref = new FakePrefRepo();
      const state = new ConsecutiveDaysState(30, 30, true, 30);
      await pref.saveConsecutiveState(state);

      const loaded = await pref.getConsecutiveState();
      // newlyUnlockedAchievement 不持久化（弹窗即清除），但 max 应恢复
      expect(loaded.maxConsecutiveDays).assertEqual(30);
      expect(loaded.currentConsecutiveDays).assertEqual(30);
    });
  });
}
