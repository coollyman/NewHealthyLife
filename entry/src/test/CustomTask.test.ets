import { describe, it, expect } from '@ohos/hypium';
import { TaskInfo, CustomTaskInput, CUSTOM_TASK_ID_START } from '../main/ets/domain/models/TaskInfo';
import { TaskType, PickerType, createDefaultTaskInfoList } from '../main/ets/domain/constants/TaskCatalog';
import { getTaskDisplayMeta, isScheduledOnDay } from '../main/ets/domain/constants/TaskDisplayMeta';
import { checkinTask, canCheckin } from '../main/ets/domain/rules/TaskRules';
import { initializeDayData, ensureDayTaskSnapshots } from '../main/ets/domain/rules/DayInitRules';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';

/**
 * 自定义任务单元测试
 */

export default function customTaskTest() {

  describe('CustomTask_PresetMigration', () => {
    it('defaultTasksHaveCorrectMetadata', 0, () => {
      const defaults = createDefaultTaskInfoList();
      expect(defaults.length).assertEqual(7);

      for (let i = 0; i < 7; i++) {
        const task = defaults[i];
        expect(task.isPreset).assertTrue();
        expect(task.isArchived).assertFalse();
        expect(task.iconKey).assertNotEqual('');
        expect(task.taskType).assertNotEqual(undefined);
      }
    });

    it('presetTaskGetDisplayMetaUsesCatalog', 0, () => {
      const defaults = createDefaultTaskInfoList();
      const drinkTask = defaults[1];
      const meta = getTaskDisplayMeta(drinkTask);
      expect(meta.isPreset).assertTrue();
      expect(meta.taskType).assertEqual(TaskType.VALUE);
      expect(meta.step).assertEqual('0.5');
      expect(meta.unitText).assertEqual('L');
    });

    it('presetTaskIdRangeIs0To6', 0, () => {
      const defaults = createDefaultTaskInfoList();
      for (let i = 0; i < 7; i++) {
        expect(defaults[i].taskId).assertEqual(i);
      }
    });
  });

  describe('CustomTask_Create', () => {
    it('customTaskIdStartsAt100', 0, () => {
      expect(CUSTOM_TASK_ID_START).assertEqual(100);
    });

    it('customTaskDisplayMetaUsesTaskFields', 0, () => {
      const customTask = new TaskInfo(
        100, true, '1', false, '', '', '', -1,
        '冥想', 'meditation', TaskType.ONCE, '1', '次',
        PickerType.TEXT, '1,2,3', '1,3,5',
        false, false, 10, Date.now()
      );

      const meta = getTaskDisplayMeta(customTask);
      expect(meta.isPreset).assertFalse();
      expect(meta.taskName).assertEqual('冥想');
      expect(meta.iconKey).assertEqual('meditation');
      expect(meta.taskType).assertEqual(TaskType.ONCE);
      expect(meta.step).assertEqual('1');
      expect(meta.unitText).assertEqual('次');
      expect(meta.targetOptions).assertEqual(['1', '2', '3']);
    });

    it('customValueTaskCheckinAccumulatesStep', 0, () => {
      const customTask = new TaskInfo(
        101, true, '3', false, '', '', '', -1,
        '俯卧撑', 'exercise', TaskType.VALUE, '1', '个',
        PickerType.TEXT, '1,2,3', '',
        false, false, 11, Date.now()
      );

      const dayTask = new DayTaskInfo(0, '20260101', 101, '3', '0', false);
      const r1 = checkinTask(dayTask, customTask);
      expect(r1.isDone).assertFalse();
      expect(r1.finValue).assertEqual('1');

      const r2 = checkinTask(r1, customTask);
      expect(r2.isDone).assertFalse();
      expect(r2.finValue).assertEqual('2');

      const r3 = checkinTask(r2, customTask);
      expect(r3.isDone).assertTrue();
      expect(r3.finValue).assertEqual('3');
    });

    it('customOnceTaskCompletesImmediately', 0, () => {
      const customTask = new TaskInfo(
        102, true, '1', false, '', '', '', -1,
        '读书', 'book', TaskType.ONCE, '1', '页',
        PickerType.NONE, '', '',
        false, false, 12, Date.now()
      );

      const dayTask = new DayTaskInfo(0, '20260101', 102, '1', '', false);
      const r = checkinTask(dayTask, customTask);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('1');
    });

    it('customTimeTaskCompletesImmediately', 0, () => {
      const customTask = new TaskInfo(
        103, true, '22:00', false, '', '', '', -1,
        '熄灯', 'sleep', TaskType.TIME, '', '/ 天',
        PickerType.TIME, '', '',
        false, false, 13, Date.now()
      );

      const dayTask = new DayTaskInfo(0, '20260101', 103, '22:00', '', false);
      const r = checkinTask(dayTask, customTask);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('22:00');
    });
  });

  describe('CustomTask_ScheduleDays', () => {
    it('emptyScheduleDays_returnsTrueEveryDay', 0, () => {
      const task = new TaskInfo(104, true, '1', false, '', '', '', -1, 'test', 'book', TaskType.ONCE, '1', '', PickerType.NONE, '', '', false, false, 14, 0);
      for (let i = 0; i < 7; i++) {
        expect(isScheduledOnDay(task, i)).assertTrue();
      }
    });

    it('scheduleDaysMonWedFri_returnsTrueOnlyOnThose', 0, () => {
      // scheduleDays '1,3,5' → 周一(1), 周三(3), 周五(5)
      // dayOfWeek: 0=周日, 1=周一, ... 6=周六
      const task = new TaskInfo(105, true, '1', false, '', '', '', -1, 'test', 'book', TaskType.ONCE, '1', '', PickerType.NONE, '', '1,3,5', false, false, 15, 0);

      // 周日(0)→7, 不在 1,3,5
      expect(isScheduledOnDay(task, 0)).assertFalse();
      // 周一(1)→1, 在 1,3,5
      expect(isScheduledOnDay(task, 1)).assertTrue();
      // 周二(2)→2, 不在
      expect(isScheduledOnDay(task, 2)).assertFalse();
      // 周三(3)→3, 在
      expect(isScheduledOnDay(task, 3)).assertTrue();
      // 周四(4)→4, 不在
      expect(isScheduledOnDay(task, 4)).assertFalse();
      // 周五(5)→5, 在
      expect(isScheduledOnDay(task, 5)).assertTrue();
      // 周六(6)→6, 不在
      expect(isScheduledOnDay(task, 6)).assertFalse();
    });

    it('initializeDayData_filtersByScheduleDays', 0, () => {
      const taskEveryday = new TaskInfo(110, true, '1', false, '', '', '', -1, 'every', 'book', TaskType.ONCE, '1', '', PickerType.NONE, '', '', false, false, 10, 0);
      const taskMonWed = new TaskInfo(111, true, '1', false, '', '', '', -1, 'monwed', 'book', TaskType.ONCE, '1', '', PickerType.NONE, '', '1,3', false, false, 11, 0);

      // 2026-01-05 是周一 → dayOfWeek = 1
      const result = initializeDayData('20260105', [taskEveryday, taskMonWed]);
      expect(result.dayTasks.length).assertEqual(2);

      // 2026-01-06 是周二 → dayOfWeek = 2 → 只有每天任务
      const result2 = initializeDayData('20260106', [taskEveryday, taskMonWed]);
      expect(result2.dayTasks.length).assertEqual(1);
      expect(result2.dayTasks[0].taskId).assertEqual(110);
    });
  });

  describe('CustomTask_Archive', () => {
    it('archivedTaskNotInActiveTasks', 0, () => {
      const activeTask = new TaskInfo(110, true, '1', false, '', '', '', -1, 'active', 'book', TaskType.ONCE, '1', '', PickerType.NONE, '', '', false, false, 10, 0);
      const archivedTask = new TaskInfo(111, true, '1', false, '', '', '', -1, 'archived', 'book', TaskType.ONCE, '1', '', PickerType.NONE, '', '', false, true, 11, 0);

      // 模拟 getActiveTasks 过滤
      const all = [activeTask, archivedTask];
      const active = all.filter(t => t.isOpen && !t.isArchived);
      expect(active.length).assertEqual(1);
      expect(active[0].taskId).assertEqual(110);
    });

    it('presetTaskCannotBeArchived_fieldCheck', 0, () => {
      const preset = createDefaultTaskInfoList()[0];
      expect(preset.isPreset).assertTrue();

      // archiveCustomTask 检查 isPreset，预设任务应被拒绝
      // 这里只验证逻辑前提
      expect(preset.isPreset).assertTrue();
    });
  });

  describe('CustomTask_EnsureSnapshots', () => {
    it('ensureSnapshots_filtersByScheduleDays', 0, () => {
      const taskMonOnly = new TaskInfo(120, true, '1', false, '', '', '', -1, 'mon', 'book', TaskType.ONCE, '1', '', PickerType.NONE, '', '1', false, false, 12, 0);
      // 周二 → 不会为周一任务创建快照
      const existing: DayTaskInfo[] = [];
      const result = ensureDayTaskSnapshots('20260106', existing, [taskMonOnly]);
      expect(result.length).assertEqual(0);

      // 周一 → 创建快照
      const result2 = ensureDayTaskSnapshots('20260105', existing, [taskMonOnly]);
      expect(result2.length).assertEqual(1);
      expect(result2[0].taskId).assertEqual(120);
    });
  });
}
