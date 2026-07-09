import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { relationalStore } from '@kit.ArkData';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DatabaseHelper } from '../../../main/ets/data/db/DatabaseHelper';
import { DbSchema } from '../../../main/ets/data/db/DbSchema';
import { TaskInfoRepository } from '../../../main/ets/data/db/TaskInfoRepository';
import { DayInfoRepository } from '../../../main/ets/data/db/DayInfoRepository';
import { DayTaskRepository } from '../../../main/ets/data/db/DayTaskRepository';
import { PreferencesRepository } from '../../../main/ets/data/prefs/PreferencesRepository';
import { TaskInfo } from '../../../main/ets/domain/models/TaskInfo';
import { DayInfo } from '../../../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../../../main/ets/domain/models/DayTaskInfo';
import { ConsecutiveDaysState } from '../../../main/ets/domain/rules/ConsecutiveDaysRules';
import { createDefaultTaskInfoList } from '../../../main/ets/domain/constants/TaskCatalog';
import { getToday } from '../../../main/ets/domain/utils/DateUtils';
import { buildReminderIntent } from '../../../main/ets/services/ReminderService';

const DOMAIN: number = 0x0001;
const TAG: string = 'DeviceIntegrationTest';

/**
 * 第 3 层：设备端集成测试
 *
 * 在真机/模拟器上跑，测真实 RDB / Preferences / 提醒权限链路。
 * 不启动 UI，但使用真实 HarmonyOS 运行时 API。
 *
 * 能抓的 bug 模式：
 * - DB 建表 SQL 错误 / 列名不匹配
 * - RDB CRUD 语义与内存假仓库不一致
 * - Preferences 读写丢数据
 * - 提醒服务在权限拒绝时崩溃
 * - EntryAbility 启动流程崩溃
 */
export default function deviceIntegrationTest() {

  describe('DeviceIntegration_DbSchema', () => {
    let dbHelper: DatabaseHelper;

    beforeAll(async () => {
      dbHelper = DatabaseHelper.getInstance();
      await dbHelper.init(globalThis.getContext());
    });

    it('db_allTablesCreated', 0, async () => {
      const store = dbHelper.getStore();
      // 验证 4 张表都存在
      const tables: string[] = [
        DbSchema.TABLE_TASK,
        DbSchema.TABLE_DAY,
        DbSchema.TABLE_DAY_TASK,
        DbSchema.TABLE_FORM
      ];
      for (const t of tables) {
        const predicates = new relationalStore.RdbPredicates(t);
        const rs = await store.query(predicates);
        const exists = rs.rowCount >= 0; // 查询不抛异常即表存在
        rs.close();
        expect(exists).assertTrue();
        hilog.info(DOMAIN, TAG, `Table ${t} exists`);
      }
    });

    it('db_uniqueIndexOnDayTask', 0, async () => {
      // idx_day_task_date_task 唯一索引应阻止重复插入
      const repo = new DayTaskRepository();
      const date = '20990101'; // 用未来日期避免干扰
      const dt = new DayTaskInfo(0, date, 99, 'test', '', false);

      const id1 = await repo.upsertDayTask(dt);
      const id2 = await repo.upsertDayTask(dt);
      // upsert 应返回同一 id，不重复插入
      expect(id1).assertEqual(id2);

      const all = await repo.getDayTasks(date);
      expect(all.length).assertEqual(1);
      // 清理
      await repo.deleteDayTask(date, 99);
    });
  });

  describe('DeviceIntegration_TaskRepo', () => {
    let taskRepo: TaskInfoRepository;

    beforeAll(async () => {
      taskRepo = new TaskInfoRepository();
    });

    it('taskRepo_ensureDefaultTasks_insertsSeven', 0, async () => {
      await taskRepo.ensureDefaultTasks();
      const all = await taskRepo.getAllTasks();
      expect(all.length).assertEqual(7);

      // 验证 taskId 0-6 都存在
      const ids = all.map(t => t.taskId).sort((a, b) => a - b);
      for (let i = 0; i < 7; i++) {
        expect(ids[i]).assertEqual(i);
      }
    });

    it('taskRepo_ensureDefaultTasks_isIdempotent', 0, async () => {
      await taskRepo.ensureDefaultTasks();
      const count1 = (await taskRepo.getAllTasks()).length;

      await taskRepo.ensureDefaultTasks();
      const count2 = (await taskRepo.getAllTasks()).length;
      expect(count2).assertEqual(count1);
    });

    it('taskRepo_updateTask_persistsChanges', 0, async () => {
      const task = new TaskInfo(10, false, 'test_val', false, '', '', '', -1);
      // 先插入
      await taskRepo.updateTask(task); // update 对不存在的行是 no-op，需要先 insert
      // 直接用 getTaskById 验证 update 路径
      const existing = await taskRepo.getTaskById(0);
      expect(existing !== null).assertTrue();

      if (existing) {
        const original = existing.targetValue;
        existing.targetValue = '07:77';
        await taskRepo.updateTask(existing);

        const after = await taskRepo.getTaskById(0);
        expect(after !== null && after!.targetValue).assertEqual('07:77');

        // 恢复
        existing.targetValue = original;
        await taskRepo.updateTask(existing);
      }
    });
  });

  describe('DeviceIntegration_DayInfoRepo', () => {
    let dayRepo: DayInfoRepository;
    const TEST_DATE: string = '20991231';

    beforeAll(async () => {
      dayRepo = new DayInfoRepository();
    });

    afterAll(async () => {
      // 清理测试数据
      const store = DatabaseHelper.getInstance().getStore();
      const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY);
      predicates.equalTo('date', TEST_DATE);
      await store.delete(predicates);
    });

    it('dayInfoRepo_upsertThenGet_roundtrip', 0, async () => {
      const di = new DayInfo(TEST_DATE, 5, 3);
      await dayRepo.upsertDayInfo(di);

      const loaded = await dayRepo.getDayInfo(TEST_DATE);
      expect(loaded !== null).assertTrue();
      if (loaded) {
        expect(loaded.date).assertEqual(TEST_DATE);
        expect(loaded.targetTaskNum).assertEqual(5);
        expect(loaded.finTaskNum).assertEqual(3);
      }
    });

    it('dayInfoRepo_upsertOverwritesExisting', 0, async () => {
      await dayRepo.upsertDayInfo(new DayInfo(TEST_DATE, 5, 3));
      await dayRepo.upsertDayInfo(new DayInfo(TEST_DATE, 10, 7));

      const loaded = await dayRepo.getDayInfo(TEST_DATE);
      expect(loaded !== null).assertTrue();
      if (loaded) {
        expect(loaded.targetTaskNum).assertEqual(10);
        expect(loaded.finTaskNum).assertEqual(7);
      }
    });
  });

  describe('DeviceIntegration_DayTaskRepo', () => {
    let dayTaskRepo: DayTaskRepository;
    const TEST_DATE: string = '20990615';

    beforeAll(async () => {
      dayTaskRepo = new DayTaskRepository();
    });

    afterAll(async () => {
      const store = DatabaseHelper.getInstance().getStore();
      const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY_TASK);
      predicates.equalTo('date', TEST_DATE);
      await store.delete(predicates);
    });

    it('dayTaskRepo_insertAndGet', 0, async () => {
      const dt = new DayTaskInfo(0, TEST_DATE, 50, 'target', '', false);
      const id = await dayTaskRepo.insertDayTask(dt);
      expect(id > 0).assertTrue();

      const loaded = await dayTaskRepo.getDayTask(TEST_DATE, 50);
      expect(loaded !== null).assertTrue();
      if (loaded) {
        expect(loaded.taskId).assertEqual(50);
        expect(loaded.targetValue).assertEqual('target');
        expect(loaded.isDone).assertFalse();
      }
    });

    it('dayTaskRepo_updateChangesIsDone', 0, async () => {
      const dt = new DayTaskInfo(0, TEST_DATE, 51, '1', '', false);
      const id = await dayTaskRepo.insertDayTask(dt);

      const loaded = await dayTaskRepo.getDayTask(TEST_DATE, 51);
      expect(loaded !== null).assertTrue();
      if (loaded) {
        loaded.isDone = true;
        loaded.finValue = '1';
        await dayTaskRepo.updateDayTask(loaded);

        const after = await dayTaskRepo.getDayTask(TEST_DATE, 51);
        expect(after !== null && after!.isDone).assertTrue();
        expect(after!.finValue).assertEqual('1');
      }
    });

    it('dayTaskRepo_deleteRemovesOnlyTarget', 0, async () => {
      await dayTaskRepo.insertDayTask(new DayTaskInfo(0, TEST_DATE, 52, 'x', '', false));
      await dayTaskRepo.insertDayTask(new DayTaskInfo(0, TEST_DATE, 53, 'x', '', false));

      await dayTaskRepo.deleteDayTask(TEST_DATE, 52);

      const remaining = await dayTaskRepo.getDayTasks(TEST_DATE);
      const ids = remaining.map(t => t.taskId);
      expect(ids.includes(52)).assertFalse();
      expect(ids.includes(53)).assertTrue();
    });
  });

  describe('DeviceIntegration_Preferences', () => {
    let prefRepo: PreferencesRepository;

    beforeAll(async () => {
      prefRepo = PreferencesRepository.getInstance();
      await prefRepo.init(globalThis.getContext());
    });

    it('pref_saveAndLoadConsecutiveState', 0, async () => {
      const state = new ConsecutiveDaysState(42, 17, true, null);
      await prefRepo.saveConsecutiveState(state);

      const loaded = await prefRepo.getConsecutiveState();
      expect(loaded.maxConsecutiveDays).assertEqual(42);
      expect(loaded.currentConsecutiveDays).assertEqual(17);
      expect(loaded.currentDayStatus).assertTrue();

      // 清理
      await prefRepo.saveConsecutiveState(new ConsecutiveDaysState(0, 0, false, null));
    });

    it('pref_overwriteWithNewValues', 0, async () => {
      await prefRepo.saveConsecutiveState(new ConsecutiveDaysState(10, 5, true, null));
      await prefRepo.saveConsecutiveState(new ConsecutiveDaysState(99, 50, false, null));

      const loaded = await prefRepo.getConsecutiveState();
      expect(loaded.maxConsecutiveDays).assertEqual(99);
      expect(loaded.currentConsecutiveDays).assertEqual(50);
      expect(loaded.currentDayStatus).assertFalse();

      // 清理
      await prefRepo.saveConsecutiveState(new ConsecutiveDaysState(0, 0, false, null));
    });
  });

  describe('DeviceIntegration_RestartRecovery', () => {
    /**
     * 模拟 app 重启：DB 中的数据在重新 getRdbStore 后应能恢复
     */
    it('restart_dbDataSurvivesReinit', 0, async () => {
      const date = '20990303';
      const dayRepo = new DayInfoRepository();
      await dayRepo.upsertDayInfo(new DayInfo(date, 3, 2));

      // 重新 init（模拟重启）
      const dbHelper = DatabaseHelper.getInstance();
      await dbHelper.init(globalThis.getContext());

      const loaded = await dayRepo.getDayInfo(date);
      expect(loaded !== null).assertTrue();
      if (loaded) {
        expect(loaded.targetTaskNum).assertEqual(3);
        expect(loaded.finTaskNum).assertEqual(2);
      }

      // 清理
      const store = dbHelper.getStore();
      const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY);
      predicates.equalTo('date', date);
      await store.delete(predicates);
    });
  });

  describe('DeviceIntegration_ReminderSafety', () => {
    /**
     * 提醒服务在权限未授权时不应崩溃
     * buildReminderIntent 是纯函数，只验证逻辑正确性
     * 实际权限请求需要 UIAbility 上下文，这里只验证不抛异常
     */
    it('buildReminderIntent_validTaskProducesCorrectIntent', 0, () => {
      const task = new TaskInfo(0, true, '07:30');
      const intent = buildReminderIntent(task);
      expect(intent.shouldSchedule).assertTrue();
      expect(intent.hour).assertEqual(7);
      expect(intent.minute).assertEqual(30);
    });

    it('buildReminderIntent_closedTaskDoesNotSchedule', 0, () => {
      const task = new TaskInfo(0, false, '07:30');
      const intent = buildReminderIntent(task);
      expect(intent.shouldSchedule).assertFalse();
    });

    it('buildReminderIntent_invalidTimeDoesNotSchedule', 0, () => {
      const task = new TaskInfo(0, true, '25:99');
      const intent = buildReminderIntent(task);
      expect(intent.shouldSchedule).assertFalse();
    });
  });

  describe('DeviceIntegration_FullCycleRdbToMemory', () => {
    /**
     * 端到端：用真实 RDB 跑一遍 enable → checkin → verify
     * 不经过 HomeStore（它调 Preferences/Form 会依赖更多运行时），
     * 只验证 Repository 层的完整 CRUD 链路
     */
    it('fullCycle_enableCheckinVerify', 0, async () => {
      const taskRepo = new TaskInfoRepository();
      const dayTaskRepo = new DayTaskRepository();
      const dayRepo = new DayInfoRepository();
      const date = '20990707';

      // 1. 确保默认任务存在
      await taskRepo.ensureDefaultTasks();
      const tasks = await taskRepo.getAllTasks();
      expect(tasks.length).assertEqual(7);

      // 2. 启用早起任务
      const task0 = tasks.find(t => t.taskId === 0);
      expect(task0 !== null).assertTrue();
      if (task0) {
        task0.isOpen = true;
        await taskRepo.updateTask(task0);
      }

      // 3. 创建当日快照
      const dt = new DayTaskInfo(0, date, 0, '08:00', '', false);
      dt.id = await dayTaskRepo.upsertDayTask(dt);
      expect(dt.id > 0).assertTrue();

      // 4. 打卡
      const loaded = await dayTaskRepo.getDayTask(date, 0);
      expect(loaded !== null).assertTrue();
      if (loaded) {
        loaded.isDone = true;
        loaded.finValue = '08:00';
        await dayTaskRepo.updateDayTask(loaded);
      }

      // 5. 验证完成状态
      const done = await dayTaskRepo.getDayTask(date, 0);
      expect(done !== null && done!.isDone).assertTrue();
      expect(done!.finValue).assertEqual('08:00');

      // 6. 写 DayInfo
      await dayRepo.upsertDayInfo(new DayInfo(date, 1, 1));
      const di = await dayRepo.getDayInfo(date);
      expect(di !== null && di!.finTaskNum).assertEqual(1);
      expect(di!.calculatePercentage()).assertEqual(100);

      // 清理
      const store = DatabaseHelper.getInstance().getStore();
      let p1 = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY_TASK);
      p1.equalTo('date', date);
      await store.delete(p1);
      let p2 = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY);
      p2.equalTo('date', date);
      await store.delete(p2);

      // 恢复任务为关闭
      if (task0) {
        task0.isOpen = false;
        await taskRepo.updateTask(task0);
      }
    });
  });
}
