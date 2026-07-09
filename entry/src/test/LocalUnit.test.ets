import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';
import { TaskInfo } from '../main/ets/domain/models/TaskInfo';
import { canCheckin, checkinTask, countFinishedTasks } from '../main/ets/domain/rules/TaskRules';
import {
  initializeDayData,
  ensureDayTaskSnapshots,
  recalculateDayInfo,
  removeInactiveTaskFromDay
} from '../main/ets/domain/rules/DayInitRules';
import {
  ConsecutiveDaysState,
  isAllTasksCompleted,
  isAchievementUnlocked,
  onAllTasksCompleted,
  onNewDay
} from '../main/ets/domain/rules/ConsecutiveDaysRules';
import {
  formatDate,
  getToday,
  getDateOffset,
  parseDate,
  compareDate,
  diffDays,
  getDayOfMonth,
  isToday,
  getMondayOfWeek,
  getDayOfWeek,
  getThreeWeekWindow
} from '../main/ets/domain/utils/DateUtils';
import { TASK_CATALOG, TaskType, PickerType, createDefaultTaskInfoList } from '../main/ets/domain/constants/TaskCatalog';
import { buildReminderIntent } from '../main/ets/services/ReminderService';
import { isHomeStoreDataReady } from '../main/ets/viewmodel/HomeStore';

export default function localUnitTest() {
  describe('DateUtils', () => {
    it('formatDate_shouldPadMonthAndDay', 0, () => {
      const d = new Date(2026, 0, 5); // 2026-01-05
      expect(formatDate(d)).assertEqual('20260105');
    });

    it('getDateOffset_positiveGoesFuture', 0, () => {
      expect(getDateOffset('20260101', 3)).assertEqual('20260104');
    });

    it('getDateOffset_negativeGoesPast', 0, () => {
      expect(getDateOffset('20260110', -5)).assertEqual('20260105');
    });

    it('getDateOffset_crossMonthBoundary', 0, () => {
      expect(getDateOffset('20260131', 1)).assertEqual('20260201');
    });

    it('getDateOffset_crossYearBoundary', 0, () => {
      expect(getDateOffset('20261231', 1)).assertEqual('20270101');
    });

    it('compareDate_correctSign', 0, () => {
      expect(compareDate('20260101', '20260102') < 0).assertTrue();
      expect(compareDate('20260102', '20260101') > 0).assertTrue();
      expect(compareDate('20260101', '20260101') === 0).assertTrue();
    });

    it('diffDays_correctDelta', 0, () => {
      expect(diffDays('20260101', '20260110')).assertEqual(9);
      expect(diffDays('20260110', '20260101')).assertEqual(-9);
    });

    it('getDayOfMonth_extractsDd', 0, () => {
      expect(getDayOfMonth('20260125')).assertEqual(25);
    });

    it('isToday_matchesGetToday', 0, () => {
      expect(isToday(getToday())).assertTrue();
    });

    it('getThreeWeekWindow_returnsTwentyOneDatesFromPreviousMonday', 0, () => {
      const dates = getThreeWeekWindow('20260709'); // Thursday
      expect(dates.length).assertEqual(21);
      expect(dates[0]).assertEqual('20260629');
      expect(dates[10]).assertEqual('20260709');
      expect(dates[20]).assertEqual('20260719');
    });
  });

  describe('TaskCatalog', () => {
    it('catalog_hasExactlySixStableTaskIds', 0, () => {
      expect(TASK_CATALOG.length).assertEqual(6);
      for (let i = 0; i < TASK_CATALOG.length; i++) {
        expect(TASK_CATALOG[i].taskId).assertEqual(i);
      }
    });

    it('catalog_numericTasksHavePositiveStepAndOptions', 0, () => {
      const numericTasks = TASK_CATALOG.filter(item => item.type === TaskType.VALUE);
      expect(numericTasks.length).assertEqual(2);
      for (const item of numericTasks) {
        expect(parseFloat(item.step) > 0).assertTrue();
        expect(item.pickerType).assertEqual(PickerType.TEXT);
        expect(item.pickerRange.includes(item.defaultTarget)).assertTrue();
      }
    });

    it('catalog_defaultTaskInfoListMatchesCatalog', 0, () => {
      const defaults = createDefaultTaskInfoList();
      expect(defaults.length).assertEqual(TASK_CATALOG.length);
      for (let i = 0; i < defaults.length; i++) {
        expect(defaults[i].taskId).assertEqual(TASK_CATALOG[i].taskId);
        expect(defaults[i].isOpen).assertFalse();
        expect(defaults[i].targetValue).assertEqual(TASK_CATALOG[i].defaultTarget);
      }
    });
  });

  describe('HomeStore readiness', () => {
    it('isHomeStoreDataReady_rejectsEmptyTaskList', 0, () => {
      expect(isHomeStoreDataReady([])).assertFalse();
    });

    it('isHomeStoreDataReady_acceptsCompleteDefaultTaskList', 0, () => {
      expect(isHomeStoreDataReady(createDefaultTaskInfoList())).assertTrue();
    });
  });

  describe('TaskRules', () => {
    it('canCheckin_falseWhenDone', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 0, '08:00', '08:00', true);
      expect(canCheckin(t)).assertFalse();
    });

    it('canCheckin_trueWhenNotDone', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 0, '08:00', '', false);
      expect(canCheckin(t)).assertTrue();
    });

    // ONCE / TIME 任务（taskId 3 = smile, taskId 0 = getup）
    it('checkinTask_onceTaskCompletesImmediately', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 3, '1', '', false);
      const r = checkinTask(t);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('1');
    });

    it('checkinTask_timeTaskCompletesImmediately', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 0, '08:00', '', false);
      const r = checkinTask(t);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('08:00');
    });

    // VALUE 任务（taskId 1 = drink, step=0.5）
    it('checkinTask_valueTaskAccumulatesStep', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 1, '1', '0', false);
      const r = checkinTask(t);
      expect(r.isDone).assertFalse();
      expect(r.finValue).assertEqual('0.5');
    });

    it('checkinTask_valueTaskReachesTarget', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 1, '1', '0.5', false);
      const r = checkinTask(t);
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('1');
    });

    it('checkinTask_valueTaskClampsFinValueToTarget', 0, () => {
      // target=1, step=0.5, already 0.5 → 1.0 done
      const t = new DayTaskInfo(1, '20260101', 1, '1', '0.5', false);
      const r = checkinTask(t);
      expect(r.finValue).assertEqual('1');
    });

    it('checkinTask_doneTaskIsIdempotent', 0, () => {
      const t = new DayTaskInfo(1, '20260101', 0, '08:00', '08:00', true);
      const r = checkinTask(t);
      // 已完成不重复打卡：返回对象状态不变
      expect(r.isDone).assertTrue();
      expect(r.finValue).assertEqual('08:00');
    });

    it('countFinishedTasks_countsOnlyDone', 0, () => {
      const list: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 0, '', '', true),
        new DayTaskInfo(2, '20260101', 1, '', '', false),
        new DayTaskInfo(3, '20260101', 2, '', '', true)
      ];
      expect(countFinishedTasks(list)).assertEqual(2);
    });
  });

  describe('ReminderService', () => {
    it('buildReminderIntent_schedulesOpenTimeTask', 0, () => {
      const task = new TaskInfo(0, true, '07:30');
      const intent = buildReminderIntent(task);
      expect(intent.shouldSchedule).assertTrue();
      expect(intent.hour).assertEqual(7);
      expect(intent.minute).assertEqual(30);
    });

    it('buildReminderIntent_skipsClosedOrNumericTask', 0, () => {
      expect(buildReminderIntent(new TaskInfo(0, false, '07:30')).shouldSchedule).assertFalse();
      expect(buildReminderIntent(new TaskInfo(1, true, '1')).shouldSchedule).assertFalse();
    });

    it('buildReminderIntent_rejectsInvalidTime', 0, () => {
      expect(buildReminderIntent(new TaskInfo(0, true, '25:00')).shouldSchedule).assertFalse();
      expect(buildReminderIntent(new TaskInfo(5, true, 'bad')).shouldSchedule).assertFalse();
    });
  });

  describe('DayInitRules', () => {
    it('initializeDayData_createsSnapshotsForActiveOnly', 0, () => {
      const tasks: TaskInfo[] = [
        new TaskInfo(0, true, '08:00'),
        new TaskInfo(1, false, '1'),   // 未启用
        new TaskInfo(2, true, '1')
      ];
      const r = initializeDayData('20260101', tasks);
      expect(r.dayTasks.length).assertEqual(2);
      expect(r.dayInfo.targetTaskNum).assertEqual(2);
      expect(r.dayInfo.finTaskNum).assertEqual(0);
    });

    it('ensureDayTaskSnapshots_doesNotDuplicateExisting', 0, () => {
      const existing: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 0, '08:00', '', false)
      ];
      const active: TaskInfo[] = [
        new TaskInfo(0, true, '08:00'),
        new TaskInfo(1, true, '1')
      ];
      const r = ensureDayTaskSnapshots('20260101', existing, active);
      // 原有 0 不重复，新增 1
      expect(r.length).assertEqual(2);
      const ids = r.map(t => t.taskId);
      expect(ids.includes(0)).assertTrue();
      expect(ids.includes(1)).assertTrue();
    });

    it('ensureDayTaskSnapshots_skipsInactive', 0, () => {
      const existing: DayTaskInfo[] = [];
      const active: TaskInfo[] = [
        new TaskInfo(0, true, '08:00'),
        new TaskInfo(1, false, '1')  // 未启用
      ];
      const r = ensureDayTaskSnapshots('20260101', existing, active);
      expect(r.length).assertEqual(1);
      expect(r[0].taskId).assertEqual(0);
    });

    it('ensureDayTaskSnapshots_emptyActiveReturnsExisting', 0, () => {
      const existing: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 0, '08:00', '08:00', true)
      ];
      const r = ensureDayTaskSnapshots('20260101', existing, []);
      expect(r.length).assertEqual(1);
    });

    it('recalculateDayInfo_usesDayTaskLengthAsTarget', 0, () => {
      const dayInfo = new DayInfo('20260101', 5, 0);
      const dayTasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 0, '', '', true),
        new DayTaskInfo(2, '20260101', 1, '', '', false)
      ];
      const r = recalculateDayInfo(dayInfo, dayTasks, 99);
      expect(r.targetTaskNum).assertEqual(2);
      expect(r.finTaskNum).assertEqual(1);
    });

    it('recalculateDayInfo_emptyTasksFallsBackToActiveCount', 0, () => {
      const dayInfo = new DayInfo('20260101', 0, 0);
      const r = recalculateDayInfo(dayInfo, [], 3);
      expect(r.targetTaskNum).assertEqual(3);
      expect(r.finTaskNum).assertEqual(0);
    });

    it('removeInactiveTaskFromDay_removesUnfinished', 0, () => {
      const list: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 0, '', '', false),
        new DayTaskInfo(2, '20260101', 1, '', '', false)
      ];
      const r = removeInactiveTaskFromDay(list, 0);
      expect(r.length).assertEqual(1);
      expect(r[0].taskId).assertEqual(1);
    });

    it('removeInactiveTaskFromDay_keepsFinished', 0, () => {
      const list: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 0, '', '08:00', true),
        new DayTaskInfo(2, '20260101', 1, '', '', false)
      ];
      const r = removeInactiveTaskFromDay(list, 0);
      expect(r.length).assertEqual(2);
    });
  });

  describe('ConsecutiveDaysRules', () => {
    it('isAllTasksCompleted_trueWhenFinGETarget', 0, () => {
      const d = new DayInfo('20260101', 3, 3);
      expect(isAllTasksCompleted(d)).assertTrue();
    });

    it('isAllTasksCompleted_falseWhenFinLTTarget', 0, () => {
      const d = new DayInfo('20260101', 3, 2);
      expect(isAllTasksCompleted(d)).assertFalse();
    });

    it('isAllTasksCompleted_falseWhenTargetZero', 0, () => {
      const d = new DayInfo('20260101', 0, 0);
      expect(isAllTasksCompleted(d)).assertFalse();
    });

    it('onAllTasksCompleted_incrementsStreakOnce', 0, () => {
      const s = new ConsecutiveDaysState(0, 0, false, null);
      const r1 = onAllTasksCompleted(s);
      expect(r1.currentConsecutiveDays).assertEqual(1);
      expect(r1.currentDayStatus).assertTrue();
      // 同一天再次完成 → 幂等，不重复加
      const r2 = onAllTasksCompleted(r1);
      expect(r2.currentConsecutiveDays).assertEqual(1);
      expect(r2.currentDayStatus).assertTrue();
    });

    it('onAllTasksCompleted_updatesMaxWhenCurrentExceeds', 0, () => {
      const s = new ConsecutiveDaysState(5, 5, false, null);
      const r = onAllTasksCompleted(s);
      expect(r.maxConsecutiveDays).assertEqual(6);
      expect(r.currentConsecutiveDays).assertEqual(6);
    });

    it('onAllTasksCompleted_unlocksAchievementAtThreshold', 0, () => {
      // 阈值 [3,7,30,50,73,99]
      const s = new ConsecutiveDaysState(2, 2, false, null);
      const r = onAllTasksCompleted(s);
      expect(r.maxConsecutiveDays).assertEqual(3);
      expect(r.newlyUnlockedAchievement).assertEqual(3);
    });

    it('onAllTasksCompleted_noUnlockBelowThreshold', 0, () => {
      // 4 不在阈值列表 [3,7,30,50,73,99]
      const s = new ConsecutiveDaysState(3, 3, false, null);
      const r = onAllTasksCompleted(s);
      expect(r.newlyUnlockedAchievement).assertNull();
    });

    it('onNewDay_resetsStreakWhenYesterdayIncomplete', 0, () => {
      const s = new ConsecutiveDaysState(5, 3, true, null);
      const yesterday = new DayInfo('20260101', 3, 2); // 未全完成
      const r = onNewDay(yesterday, s);
      expect(r.currentConsecutiveDays).assertEqual(0);
      expect(r.currentDayStatus).assertFalse();
      expect(r.maxConsecutiveDays).assertEqual(5);
    });

    it('onNewDay_preservesStreakWhenYesterdayComplete', 0, () => {
      const s = new ConsecutiveDaysState(5, 3, true, null);
      const yesterday = new DayInfo('20260101', 3, 3); // 全完成
      const r = onNewDay(yesterday, s);
      expect(r.currentConsecutiveDays).assertEqual(3);
      expect(r.currentDayStatus).assertFalse();
    });

    it('onNewDay_preservesStreakWhenYesterdayNull', 0, () => {
      const s = new ConsecutiveDaysState(5, 3, true, null);
      const r = onNewDay(null, s);
      expect(r.currentConsecutiveDays).assertEqual(3);
      expect(r.currentDayStatus).assertFalse();
    });

    it('onNewDay_clearsNewlyUnlocked', 0, () => {
      const s = new ConsecutiveDaysState(3, 3, true, 3);
      const yesterday = new DayInfo('20260101', 3, 3);
      const r = onNewDay(yesterday, s);
      expect(r.newlyUnlockedAchievement).assertNull();
    });

    it('isAchievementUnlocked_followsMaxStreak', 0, () => {
      expect(isAchievementUnlocked(7, 7)).assertTrue();
      expect(isAchievementUnlocked(6, 7)).assertFalse();
    });
  });

  describe('DayInfo', () => {
    it('calculatePercentage_zeroWhenNoTarget', 0, () => {
      const d = new DayInfo('20260101', 0, 0);
      expect(d.calculatePercentage()).assertEqual(0);
    });

    it('calculatePercentage_ceilsUp', 0, () => {
      const d = new DayInfo('20260101', 3, 1);
      // 1/3 = 33.3% → ceil = 34
      expect(d.calculatePercentage()).assertEqual(34);
    });

    it('calculatePercentage_fullWhenComplete', 0, () => {
      const d = new DayInfo('20260101', 3, 3);
      expect(d.calculatePercentage()).assertEqual(100);
    });
  });
}
