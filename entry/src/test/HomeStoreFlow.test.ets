import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { HomeStore, HomeStoreDeps } from '../main/ets/viewmodel/HomeStore';
import { createDefaultTaskInfoList } from '../main/ets/domain/constants/TaskCatalog';
import { getToday, getDateOffset } from '../main/ets/domain/utils/DateUtils';
import { ConsecutiveDaysState } from '../main/ets/domain/rules/ConsecutiveDaysRules';
import {
  FakeTaskRepo,
  FakeDayInfoRepo,
  FakeDayTaskRepo,
  FakePrefRepo,
  FakeFormService,
  FakeRecoveryRepo
} from './fakes/FakeRepositories';

/**
 * HomeStore 业务流程测试 — 用注入的内存假仓库测完整用户路径
 * 直接用 getToday() 取真实今天，与 HomeStore 内部保持一致
 */

const TODAY: string = getToday();

function makeDeps(): HomeStoreDeps {
  return new HomeStoreDeps(
    new FakeTaskRepo(),
    new FakeDayInfoRepo(),
    new FakeDayTaskRepo(),
    new FakePrefRepo(),
    new FakeFormService(),
    new FakeRecoveryRepo()
  );
}

function makeDefaultStore(deps: HomeStoreDeps): HomeStore {
  const store = HomeStore.createForTest(deps);
  (deps.taskRepo as FakeTaskRepo).seed(createDefaultTaskInfoList());
  // 注入 6 个默认任务（全部关闭）
  (deps.taskRepo as FakeTaskRepo).seed(createDefaultTaskInfoList());
  return store;
}

export default function homeStoreFlowTest() {

  describe('HomeStoreFlow_EnableTask', () => {
    let deps: HomeStoreDeps;
    let store: HomeStore;

    beforeAll(() => {
      deps = makeDeps();
      store = makeDefaultStore(deps);
    });

    it('enableTask_addsSnapshotToToday', 0, async () => {
      await store.initAppData();
      // 初始状态：无今日任务
      expect(store.dayTasks.length).assertEqual(0);

      await store.enableTask(0); // 早起
      const dayTasks = await deps.dayTaskRepo.getDayTasks(TODAY);
      expect(dayTasks.length).assertEqual(1);
      expect(dayTasks[0].taskId).assertEqual(0);
      expect(dayTasks[0].isDone).assertFalse();
    });

    it('enableTask_updatesMemoryDayTasks', 0, async () => {
      await store.enableTask(1); // 喝水
      expect(store.dayTasks.length).assertEqual(2);
      const ids = store.dayTasks.map(t => t.taskId);
      expect(ids.includes(0)).assertTrue();
      expect(ids.includes(1)).assertTrue();
    });

    it('enableTask_updatesDayInfoTarget', 0, () => {
      expect(store.dayInfo.targetTaskNum).assertEqual(2);
      expect(store.dayInfo.finTaskNum).assertEqual(0);
    });
  });

  describe('HomeStoreFlow_DisableTask', () => {
    let deps: HomeStoreDeps;
    let store: HomeStore;

    beforeAll(() => {
      deps = makeDeps();
      store = makeDefaultStore(deps);
    });

    it('disableTask_removesUnfinishedFromToday', 0, async () => {
      await store.initAppData();
      await store.enableTask(0); // 早起
      await store.enableTask(1); // 喝水
      expect(store.dayTasks.length).assertEqual(2);

      // 停用未完成的喝水任务
      await store.disableTask(1);
      const dayTasks = await deps.dayTaskRepo.getDayTasks(TODAY);
      const taskIds = dayTasks.map(t => t.taskId);
      expect(taskIds.includes(1)).assertFalse();
      expect(taskIds.includes(0)).assertTrue();
    });

    it('disableTask_keepsFinishedHistory', 0, async () => {
      // 早起任务打卡完成
      const earlyTask = store.dayTasks.find(t => t.taskId === 0);
      expect(earlyTask !== null && earlyTask !== undefined).assertTrue();
      if (earlyTask) {
        await store.checkin(earlyTask.id);
      }
      // 确认完成
      const finished = await deps.dayTaskRepo.getDayTask(TODAY, 0);
      expect(finished !== null && finished!.isDone).assertTrue();

      // 停用已完成的早起任务
      await store.disableTask(0);
      // DB 层应保留已完成记录
      const stillThere = await deps.dayTaskRepo.getDayTask(TODAY, 0);
      expect(stillThere !== null).assertTrue();
      expect(stillThere!.isDone).assertTrue();
    });
  });

  describe('HomeStoreFlow_UpdateTarget', () => {
    let deps: HomeStoreDeps;
    let store: HomeStore;

    beforeAll(() => {
      deps = makeDeps();
      store = makeDefaultStore(deps);
    });

    it('updateTarget_syncsToUnfinishedSnapshot', 0, async () => {
      await store.initAppData();
      await store.enableTask(0); // 早起, default 08:00

      await store.updateTaskTarget(0, '07:30');
      const dt = await deps.dayTaskRepo.getDayTask(TODAY, 0);
      expect(dt !== null && dt!.targetValue).assertEqual('07:30');
    });

    it('updateTarget_doesNotMutateFinishedSnapshot', 0, async () => {
      // 打卡完成早起
      const earlyTask = store.dayTasks.find(t => t.taskId === 0);
      if (earlyTask) {
        await store.checkin(earlyTask.id);
      }
      const done = await deps.dayTaskRepo.getDayTask(TODAY, 0);
      expect(done !== null && done!.isDone).assertTrue();
      expect(done!.targetValue).assertEqual('07:30');

      // 修改目标值 — 不应篡改已完成的快照
      await store.updateTaskTarget(0, '06:00');
      const afterUpdate = await deps.dayTaskRepo.getDayTask(TODAY, 0);
      expect(afterUpdate!.targetValue).assertEqual('07:30');
      expect(afterUpdate!.isDone).assertTrue();
    });

    it('updateNumericTarget_reopensTodayWhenNewTargetIsHigher', 0, async () => {
      const deps2 = makeDeps();
      const store2 = makeDefaultStore(deps2);
      await store2.initAppData();
      await store2.enableTask(2); // 苹果默认 target=1 step=1

      const apple = store2.dayTasks.find(t => t.taskId === 2);
      expect(apple !== null && apple !== undefined).assertTrue();
      if (apple) {
        await store2.checkin(apple.id);
      }
      const done = await deps2.dayTaskRepo.getDayTask(TODAY, 2);
      expect(done !== null && done!.isDone).assertTrue();

      await store2.updateTaskTarget(2, '3');
      const reopened = await deps2.dayTaskRepo.getDayTask(TODAY, 2);
      expect(reopened !== null && reopened!.targetValue).assertEqual('3');
      expect(reopened!.finValue).assertEqual('1');
      expect(reopened!.isDone).assertFalse();

      const refreshed = store2.dayTasks.find(t => t.taskId === 2);
      if (refreshed) {
        await store2.checkin(refreshed.id);
      }
      const afterSecond = await deps2.dayTaskRepo.getDayTask(TODAY, 2);
      expect(afterSecond!.finValue).assertEqual('2');
      expect(afterSecond!.isDone).assertFalse();
    });
  });

  describe('HomeStoreFlow_CheckinStreak', () => {
    let deps: HomeStoreDeps;
    let store: HomeStore;

    beforeAll(() => {
      deps = makeDeps();
      store = makeDefaultStore(deps);
    });

    it('checkin_allDone_incrementsStreakOnce', 0, async () => {
      await store.initAppData();
      await store.enableTask(3); // 每日微笑 (ONCE)
      // 连续天数初始应为 0
      expect(store.consecutiveState.currentConsecutiveDays).assertEqual(0);

      const task = store.dayTasks.find(t => t.taskId === 3);
      expect(task !== null && task !== undefined).assertTrue();
      if (task) {
        const ok = await store.checkin(task.id);
        expect(ok).assertTrue();
      }

      // 全部完成 → 连续天数 +1
      expect(store.consecutiveState.currentConsecutiveDays).assertEqual(1);
      expect(store.consecutiveState.currentDayStatus).assertTrue();

      // 再次调用 checkin 不应重复加（已是完成态，canCheckin=false）
      if (task) {
        const ok2 = await store.checkin(task.id);
        expect(ok2).assertFalse();
      }
      expect(store.consecutiveState.currentConsecutiveDays).assertEqual(1);
    });

    it('checkin_partialThenComplete_doesNotDoubleCount', 0, async () => {
      // 新的一天，重新 init
      const deps2 = makeDeps();
      const store2 = makeDefaultStore(deps2);
      await store2.initAppData();
      await store2.enableTask(1); // 喝水 step=0.5 target=1
      await store2.enableTask(3); // 微笑 ONCE

      // 先完成微笑
      const smile = store2.dayTasks.find(t => t.taskId === 3);
      if (smile) {
        await store2.checkin(smile.id);
      }
      // 此时未全完成（喝水未完）
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(0);

      // 再完成喝水（需两次打卡）
      const drink = store2.dayTasks.find(t => t.taskId === 1);
      if (drink) {
        await store2.checkin(drink.id); // 0 → 0.5
        await store2.checkin(drink.id); // 0.5 → 1.0
      }
      // 全部完成 → +1
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(1);
    });

    it('enableTask_afterAllDone_revokesTodayCompletionUntilNewTaskDone', 0, async () => {
      const deps2 = makeDeps();
      const store2 = makeDefaultStore(deps2);
      await store2.initAppData();
      await store2.enableTask(3); // 微笑 ONCE

      const smile = store2.dayTasks.find(t => t.taskId === 3);
      if (smile) {
        await store2.checkin(smile.id);
      }
      expect(store2.dayInfo.finTaskNum).assertEqual(1);
      expect(store2.dayInfo.targetTaskNum).assertEqual(1);
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(1);
      expect(store2.consecutiveState.maxConsecutiveDays).assertEqual(1);
      expect(store2.consecutiveState.currentDayStatus).assertTrue();

      await store2.enableTask(0); // 早起新增为今天目标
      expect(store2.dayInfo.finTaskNum).assertEqual(1);
      expect(store2.dayInfo.targetTaskNum).assertEqual(2);
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(0);
      expect(store2.consecutiveState.maxConsecutiveDays).assertEqual(0);
      expect(store2.consecutiveState.currentDayStatus).assertFalse();

      const early = store2.dayTasks.find(t => t.taskId === 0);
      if (early) {
        await store2.checkin(early.id);
      }
      expect(store2.dayInfo.finTaskNum).assertEqual(2);
      expect(store2.dayInfo.targetTaskNum).assertEqual(2);
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(1);
      expect(store2.consecutiveState.maxConsecutiveDays).assertEqual(1);
      expect(store2.consecutiveState.currentDayStatus).assertTrue();
    });

    it('enableTask_afterRecovery_keepsRecoveredStreak', 0, async () => {
      const deps2 = makeDeps();
      const store2 = makeDefaultStore(deps2);
      await store2.initAppData();
      await store2.enableTask(0);
      await store2.enableTask(2);
      await store2.enableTask(3);
      await store2.enableTask(4);
      await store2.enableTask(5);

      const completedTaskIds: number[] = [0, 2, 3, 4];
      for (const taskId of completedTaskIds) {
        const task = store2.dayTasks.find(t => t.taskId === taskId);
        if (task) {
          await store2.checkin(task.id);
        }
      }

      expect(store2.dayInfo.finTaskNum).assertEqual(4);
      expect(store2.dayInfo.targetTaskNum).assertEqual(5);
      expect(await store2.canUseRecoveryToday()).assertTrue();
      expect(await store2.useRecoveryToday()).assertTrue();
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(1);
      expect(store2.consecutiveState.currentDayStatus).assertTrue();

      await store2.enableTask(6);
      expect(store2.dayInfo.finTaskNum).assertEqual(4);
      expect(store2.dayInfo.targetTaskNum).assertEqual(6);
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(1);
      expect(store2.consecutiveState.currentDayStatus).assertTrue();
    });
  });

  describe('HomeStoreFlow_DateNavigation', () => {
    let deps: HomeStoreDeps;
    let store: HomeStore;

    beforeAll(() => {
      deps = makeDeps();
      store = makeDefaultStore(deps);
    });

    it('historyDate_doesNotAutoSeedTodayTasks', 0, async () => {
      await store.initAppData();
      await store.enableTask(0); // 早起

      // 切到昨天 — 不应触发今天补快照
      const yesterday = getDateOffset(TODAY, -1);
      await store.selectDate(yesterday);
      expect(store.selectedDate).assertEqual(yesterday);
      // 昨天无数据
      expect(store.dayTasks.length).assertEqual(0);

      // 今天的快照仍然只有早起
      const todayTasks = await deps.dayTaskRepo.getDayTasks(TODAY);
      expect(todayTasks.length).assertEqual(1);
      expect(todayTasks[0].taskId).assertEqual(0);
    });

    it('futureDate_previewOnly_noDbWrite', 0, async () => {
      const tomorrow = getDateOffset(TODAY, 1);
      await store.selectDate(tomorrow);
      // 预览数据应显示启用的早起任务
      expect(store.dayTasks.length).assertEqual(1);
      expect(store.dayTasks[0].taskId).assertEqual(0);

      // 但数据库不应有明天的记录
      const dbTasks = await deps.dayTaskRepo.getDayTasks(tomorrow);
      expect(dbTasks.length).assertEqual(0);
      const dbInfo = await deps.dayRepo.getDayInfo(tomorrow);
      expect(dbInfo === null).assertTrue();
    });

    it('switchBackToToday_restoresTodayData', 0, async () => {
      await store.selectDate(TODAY);
      expect(store.selectedDate).assertEqual(TODAY);
      expect(store.dayTasks.length).assertEqual(1);
      expect(store.dayTasks[0].taskId).assertEqual(0);
    });

    it('calendarStatus_keepsCompletedDayLitAfterSelectingAnotherDate', 0, async () => {
      const deps2 = makeDeps();
      const store2 = makeDefaultStore(deps2);
      await store2.initAppData();
      await store2.enableTask(3);

      const task = store2.dayTasks.find(t => t.taskId === 3);
      if (task) {
        await store2.checkin(task.id);
      }
      expect(store2.getCalendarDayStatus(TODAY)).assertEqual(3);

      await store2.selectDate(getDateOffset(TODAY, -1));
      expect(store2.getCalendarDayStatus(TODAY)).assertEqual(3);
    });
  });

  describe('HomeStoreFlow_InitAppData', () => {
    it('initAppData_loadsAllTasks', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();

      expect(store.allTasks.length).assertEqual(7);
      // 默认全部关闭
      for (const t of store.allTasks) {
        expect(t.isOpen).assertFalse();
      }
    });

    it('initAppData_todayInfoCreatedOnFirstRun', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();

      // 首次运行会为今天创建空 DayInfo
      const todayInfo = await deps.dayRepo.getDayInfo(TODAY);
      expect(todayInfo !== null).assertTrue();
      if (todayInfo) {
        expect(todayInfo.targetTaskNum).assertEqual(0);
        expect(todayInfo.finTaskNum).assertEqual(0);
      }
    });

    it('initAppData_isIdempotent_noDuplicateSeed', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      const firstCount = (await deps.dayTaskRepo.getDayTasks(TODAY)).length;

      await store.initAppData();
      const secondCount = (await deps.dayTaskRepo.getDayTasks(TODAY)).length;
      expect(secondCount).assertEqual(firstCount);
    });
  });

  describe('HomeStoreFlow_FormUpdate', () => {
    it('checkin_triggersFormUpdate', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      const formService = deps.formService as FakeFormService;

      await store.initAppData();
      await store.enableTask(3); // 微笑
      const beforeCount = formService.getUpdateCount();

      const task = store.dayTasks.find(t => t.taskId === 3);
      if (task) {
        await store.checkin(task.id);
      }
      const afterCount = formService.getUpdateCount();
      expect(afterCount > beforeCount).assertTrue();
      // 卡片收到的是完成后的数据
      expect(formService.lastDayTasks !== null).assertTrue();
      if (formService.lastDayTasks && formService.lastDayTasks.length > 0) {
        const smileCard = formService.lastDayTasks.find(t => t.taskId === 3);
        expect(smileCard !== null && smileCard !== undefined).assertTrue();
        if (smileCard) {
          expect(smileCard.isDone).assertTrue();
        }
      }
    });

    it('enableTask_triggersFormUpdate', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      const formService = deps.formService as FakeFormService;

      await store.initAppData();
      const before = formService.getUpdateCount();
      await store.enableTask(0);
      const after = formService.getUpdateCount();
      expect(after > before).assertTrue();
    });
  });

  describe('HomeStoreFlow_PrefRestore', () => {
    it('consecutiveState_persistsAcrossInit', 0, async () => {
      const deps = makeDeps();
      const store = makeDefaultStore(deps);
      await store.initAppData();
      await store.enableTask(3);

      const task = store.dayTasks.find(t => t.taskId === 3);
      if (task) {
        await store.checkin(task.id);
      }
      expect(store.consecutiveState.currentConsecutiveDays).assertEqual(1);

      // 模拟 app 重启：新 HomeStore 复用同一 prefRepo
      const store2 = HomeStore.createForTest(deps);
      await store2.initAppData();
      // 偏好里连续天数应恢复
      expect(store2.consecutiveState.currentConsecutiveDays).assertEqual(1);
      expect(store2.consecutiveState.maxConsecutiveDays).assertEqual(1);
    });

    it('initAppData_rebuildsStreakFromHistoryWhenPrefIsStale', 0, async () => {
      const deps = makeDeps();
      await deps.prefRepo.saveConsecutiveState(new ConsecutiveDaysState(3, 3, false, null, 3));

      const store = makeDefaultStore(deps);
      await store.initAppData();

      expect(store.consecutiveState.currentConsecutiveDays).assertEqual(0);
      expect(store.consecutiveState.maxConsecutiveDays).assertEqual(0);
      expect(store.consecutiveState.currentDayStatus).assertFalse();
    });
  });
}
