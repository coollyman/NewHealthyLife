import { describe, it, expect } from '@ohos/hypium';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';
import { checkinTask, canCheckin } from '../main/ets/domain/rules/TaskRules';
import {
  ensureDayTaskSnapshots,
  recalculateDayInfo,
  removeInactiveTaskFromDay
} from '../main/ets/domain/rules/DayInitRules';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { TaskInfo } from '../main/ets/domain/models/TaskInfo';
import { TaskType, PickerType } from '../main/ets/domain/constants/TaskCatalog';
import {
  ConsecutiveDaysState,
  onAllTasksCompleted,
  onNewDay,
  reconcileCurrentDayCompletion
} from '../main/ets/domain/rules/ConsecutiveDaysRules';

/**
 * T020: 数值任务打卡规则 + 一次性任务打卡规则 + 快照幂等
 */
export default function numericCheckinTest() {
  describe('NumericCheckin_Value', () => {
    // taskId=1 drink: step=0.5, default target=1
    it('value_fromZero_reachesHalfNotDone', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 1, '1', '0', false);
      const taskInfo = new TaskInfo(1, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '0.5', '', PickerType.NONE, '', '', false, false, 0, 0);
      const r = checkinTask(t, taskInfo);
      expect(r.isDone).assertFalse();
      expect(r.finValue).assertEqual('0.5');
    });

    it('value_fromHalf_reachesTargetDone', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 1, '1', '0.5', false);
      const taskInfo = new TaskInfo(1, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '0.5', '', PickerType.NONE, '', '', false, false, 0, 0);
      const r = checkinTask(t, taskInfo);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('1');
    });

    it('value_doesNotExceedTarget', 0, () => {
      // 0.5 + 0.5 = 1 → clamp to target
      const t = new DayTaskInfo(1, '20260101', 1, '1', '0.5', false);
      const taskInfo = new TaskInfo(1, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '0.5', '', PickerType.NONE, '', '', false, false, 0, 0);
      const r = checkinTask(t, taskInfo);
      expect(r.finValue).assertEqual('1');
    });

    // taskId=2 apple: step=1, default target=1
    it('apple_singleCheckinCompletes', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 2, '1', '0', false);
      const taskInfo = new TaskInfo(2, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '1', '', PickerType.NONE, '', '', false, false, 0, 0);
      const r = checkinTask(t, taskInfo);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('1');
    });

    it('apple_target2_requiresTwoCheckins', 0, () => {
      const taskInfo = new TaskInfo(2, false, '2', false, '', '', '', -1, '', '', TaskType.VALUE, '1', '', PickerType.NONE, '', '', false, false, 0, 0);
      const t1 = new DayTaskInfo(1, '20260101', 2, '2', '0', false);
      const r1 = checkinTask(t1, taskInfo);
      expect(r1.isDone).assertFalse();
      expect(r1.finValue).assertEqual('1');
      const r2 = checkinTask(r1, taskInfo);
      expect(r2.isDone).assertTrue();
      expect(r2.finValue).assertEqual('2');
    });

    it('value_doneTaskCheckinIsIdempotent', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 1, '1', '1', true);
      const taskInfo = new TaskInfo(1, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '0.5', '', PickerType.NONE, '', '', false, false, 0, 0);
      const r = checkinTask(t, taskInfo);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('1');
    });
  });

  describe('NumericCheckin_Once', () => {
    // taskId=3 smile: now VALUE with step=1, target=1
    it('once_completesInOneCheckin', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 3, '1', '0', false);
      const taskInfo = new TaskInfo(3, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '1', '', PickerType.NONE, '', '', false, false, 0, 0);
      const r = checkinTask(t, taskInfo);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('1');
    });

    // taskId=4 brush: now VALUE with step=1, target=1
    it('once_brushCompletesInOneCheckin', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 4, '1', '0', false);
      const taskInfo = new TaskInfo(4, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '1', '', PickerType.NONE, '', '', false, false, 0, 0);
      const r = checkinTask(t, taskInfo);
      expect(r.isDone).assertTrue();
    });

    it('once_doneTaskCheckinIsIdempotent', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 3, '1', '1', true);
      const taskInfo = new TaskInfo(3, false, '1', false, '', '', '', -1, '', '', TaskType.VALUE, '1', '', PickerType.NONE, '', '', false, false, 0, 0);
      const r = checkinTask(t, taskInfo);
      expect(r.isDone).assertTrue();
      expect(canCheckin(r)).assertFalse();
    });
  });

  describe('NumericCheckin_SnapshotIdempotency', () => {
    it('ensureSnapshot_noDupWhenAlreadyExists', 0, () => {
      const existing: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 1, '1', '0', false)
      ];
      const active: TaskInfo[] = [
        new TaskInfo(1, true, '1')
      ];
      const r = ensureDayTaskSnapshots('20260101', existing, active);
      expect(r.length).assertEqual(1);
    });

    it('ensureSnapshot_addsOnlyMissing', 0, () => {
      const existing: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 1, '1', '0', false)
      ];
      const active: TaskInfo[] = [
        new TaskInfo(1, true, '1'),
        new TaskInfo(2, true, '1')
      ];
      const r = ensureDayTaskSnapshots('20260101', existing, active);
      expect(r.length).assertEqual(2);
    });

    it('recalculate_afterCheckinReflectsProgress', 0, () => {
      const dayInfo = new DayInfo('20260101', 2, 0);
      const tasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 1, '1', '1', true),
        new DayTaskInfo(2, '20260101', 2, '1', '0', false)
      ];
      const r = recalculateDayInfo(dayInfo, tasks, 2);
      expect(r.targetTaskNum).assertEqual(2);
      expect(r.finTaskNum).assertEqual(1);
    });

    it('removeInactive_keepsCompletedTaskHistory', 0, () => {
      const tasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 1, '1', '1', true),
        new DayTaskInfo(2, '20260101', 3, '1', '1', true)
      ];
      const r = removeInactiveTaskFromDay(tasks, 1);
      expect(r.length).assertEqual(2);
      expect(r.some(task => task.taskId === 1 && task.isDone)).assertTrue();
    });
  });

  describe('NumericCheckin_StreakOnce', () => {
    it('streak_incrementsOncePerDay', 0, () => {
      const s = new ConsecutiveDaysState(0, 0, false, null);
      const r1 = onAllTasksCompleted(s);
      expect(r1.currentConsecutiveDays).assertEqual(1);
      // 再次触发不重复
      const r2 = onAllTasksCompleted(r1);
      expect(r2.currentConsecutiveDays).assertEqual(1);
    });

    it('streak_resetsOnNewDayIfYesterdayIncomplete', 0, () => {
      const s = new ConsecutiveDaysState(3, 3, true, null);
      const yesterday = new DayInfo('20260101', 2, 1);
      const r = onNewDay(yesterday, s);
      expect(r.currentConsecutiveDays).assertEqual(0);
    });

    it('streak_continuesOnNewDayIfYesterdayComplete', 0, () => {
      const s = new ConsecutiveDaysState(3, 3, true, null);
      const yesterday = new DayInfo('20260101', 2, 2);
      const r = onNewDay(yesterday, s);
      expect(r.currentConsecutiveDays).assertEqual(3);
    });

    it('streak_restoresCurrentDayStatusWhenTodayAlreadyComplete', 0, () => {
      const s = new ConsecutiveDaysState(1, 1, false, null);
      const today = new DayInfo('20260102', 2, 2);
      const restored = reconcileCurrentDayCompletion(today, s);
      expect(restored.currentConsecutiveDays).assertEqual(1);
      expect(restored.currentDayStatus).assertTrue();

      const afterAddingTask = new DayInfo('20260102', 3, 2);
      const pending = reconcileCurrentDayCompletion(afterAddingTask, restored);
      expect(pending.currentConsecutiveDays).assertEqual(1);
      expect(pending.currentDayStatus).assertTrue();

      const completeAgain = new DayInfo('20260102', 3, 3);
      const countedAgain = onAllTasksCompleted(reconcileCurrentDayCompletion(completeAgain, pending));
      expect(countedAgain.currentConsecutiveDays).assertEqual(1);
    });
  });
}
