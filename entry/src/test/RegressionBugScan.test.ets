import { describe, it, expect } from '@ohos/hypium';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';
import { TaskInfo } from '../main/ets/domain/models/TaskInfo';
import { TaskType, PickerType } from '../main/ets/domain/constants/TaskCatalog';
import { recalculateDayInfo, removeInactiveTaskFromDay } from '../main/ets/domain/rules/DayInitRules';
import { checkinTask } from '../main/ets/domain/rules/TaskRules';
import { getDateOffset, getMondayOfWeek, getThreeWeekWindow } from '../main/ets/domain/utils/DateUtils';
import { buildReminderIntent } from '../main/ets/services/ReminderService';

export default function regressionBugScanTest() {
  describe('RegressionBugScan_TaskDisableRules', () => {
    it('removeInactive_keepsFinishedTaskHistory', 0, () => {
      const dayTasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260709', 1, '1', '1', true),
        new DayTaskInfo(2, '20260709', 3, '1', '', false)
      ];

      const result = removeInactiveTaskFromDay(dayTasks, 1);

      expect(result.length).assertEqual(2);
      expect(result.some(task => task.taskId === 1 && task.isDone)).assertTrue();
    });

    it('removeInactive_removesOnlyUnfinishedTask', 0, () => {
      const dayTasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260709', 1, '1', '0.5', false),
        new DayTaskInfo(2, '20260709', 3, '1', '0', false)
      ];

      const result = removeInactiveTaskFromDay(dayTasks, 1);

      expect(result.length).assertEqual(1);
      expect(result[0].taskId).assertEqual(3);
    });
  });

  describe('RegressionBugScan_NumericCheckinEdges', () => {
    it('checkinTask_clampsValueThatWouldOvershootTarget', 0, () => {
      const task = new DayTaskInfo(1, '20260709', 1, '1', '0.75', false);
      const taskInfo = new TaskInfo(1, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '0.5', '', PickerType.NONE, '', '', false, false, 0, 0);

      const result = checkinTask(task, taskInfo);

      expect(result.isDone).assertTrue();
      expect(result.finValue).assertEqual('1');
    });

    it('checkinTask_treatsInvalidProgressAsZero', 0, () => {
      const task = new DayTaskInfo(1, '20260709', 1, '1', 'bad', false);
      const taskInfo = new TaskInfo(1, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '0.5', '', PickerType.NONE, '', '', false, false, 0, 0);

      const result = checkinTask(task, taskInfo);

      expect(result.isDone).assertFalse();
      expect(result.finValue).assertEqual('0.5');
    });

    it('checkinTask_zeroTargetValueTaskCompletesWithoutPositiveProgress', 0, () => {
      const task = new DayTaskInfo(1, '20260709', 1, '0', '0', false);
      const taskInfo = new TaskInfo(1, false, '0', false, '', '', '', -1, '', '', TaskType.VALUE, '0.5', '', PickerType.NONE, '', '', false, false, 0, 0);

      const result = checkinTask(task, taskInfo);

      expect(result.isDone).assertTrue();
      expect(result.finValue).assertEqual('0');
    });
  });

  describe('RegressionBugScan_ReminderParsing', () => {
    it('buildReminderIntent_acceptsBoundaryTime', 0, () => {
      const intent = buildReminderIntent(new TaskInfo(5, true, '23:59'));

      expect(intent.shouldSchedule).assertTrue();
      expect(intent.hour).assertEqual(23);
      expect(intent.minute).assertEqual(59);
    });

    it('buildReminderIntent_rejectsExtraTimeSegments', 0, () => {
      const intent = buildReminderIntent(new TaskInfo(0, true, '07:30:00'));

      expect(intent.shouldSchedule).assertFalse();
    });

    it('buildReminderIntent_rejectsPartiallyNumericTime', 0, () => {
      const intent = buildReminderIntent(new TaskInfo(0, true, '07:3x'));

      expect(intent.shouldSchedule).assertFalse();
    });
  });

  describe('RegressionBugScan_DateBoundaries', () => {
    it('getDateOffset_handlesLeapDay', 0, () => {
      expect(getDateOffset('20260228', 1)).assertEqual('20260301');
      expect(getDateOffset('20240228', 1)).assertEqual('20240229');
    });

    it('getMondayOfWeek_returnsPreviousMondayForSunday', 0, () => {
      expect(getMondayOfWeek('20260712')).assertEqual('20260706');
    });

    it('getThreeWeekWindow_forSundayCentersSelectedDate', 0, () => {
      const dates = getThreeWeekWindow('20260712');

      expect(dates.length).assertEqual(21);
      expect(dates[13]).assertEqual('20260712');
      expect(dates[0]).assertEqual('20260629');
      expect(dates[20]).assertEqual('20260719');
    });
  });

  describe('RegressionBugScan_ProgressBounds', () => {
    it('calculatePercentage_doesNotExceedOneHundred', 0, () => {
      const dayInfo = new DayInfo('20260709', 3, 4);

      expect(dayInfo.calculatePercentage()).assertEqual(100);
    });

    it('recalculateDayInfo_countsOnlyProvidedDayTasks', 0, () => {
      const dayInfo = new DayInfo('20260709', 99, 99);
      const dayTasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260709', 1, '1', '1', true),
        new DayTaskInfo(2, '20260709', 3, '1', '', false)
      ];

      const result = recalculateDayInfo(dayInfo, dayTasks, 6);

      expect(result.targetTaskNum).assertEqual(2);
      expect(result.finTaskNum).assertEqual(1);
      expect(result.calculatePercentage()).assertEqual(50);
    });
  });
}
