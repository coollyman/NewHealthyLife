import { describe, it, expect } from '@ohos/hypium';
import {
  calculateTaskAchievementSummaries,
  checkStableCompletion,
  checkRecoveryAchievement,
  checkPerfectWeek,
  AchievementType,
  OVERACHIEVEMENT_THRESHOLDS
} from '../main/ets/domain/rules/AchievementRules';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';
import { RecoveryInfo } from '../main/ets/domain/models/RecoveryInfo';
import { TaskInfo } from '../main/ets/domain/models/TaskInfo';
import { TaskType, PickerType } from '../main/ets/domain/constants/TaskCatalog';

/**
 * 多维成就规则单元测试
 */

function makeDayTask(date: string, taskId: number, isDone: boolean): DayTaskInfo {
  return new DayTaskInfo(0, date, taskId, '1', isDone ? '1' : '0', isDone);
}

export default function achievementUpgradeTest() {

  describe('Achievement_StableCompletion', () => {
    it('fiveOrMoreCompletedDays_unlocks', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, true),
        makeDayTask('20260106', 1, false),
        makeDayTask('20260107', 1, true)
      ];
      const result = checkStableCompletion(tasks);
      expect(result.unlocked).assertTrue();
    });

    it('fourCompletedDays_doesNotUnlock', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, false),
        makeDayTask('20260106', 1, false),
        makeDayTask('20260107', 1, false)
      ];
      const result = checkStableCompletion(tasks);
      expect(result.unlocked).assertFalse();
    });

    it('lessThan5Days_returnsNotEnough', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true)
      ];
      const result = checkStableCompletion(tasks);
      expect(result.unlocked).assertFalse();
    });
  });

  describe('Achievement_Recovery', () => {
    it('yesterdayRecovery_today100Percent_unlocks', 0, () => {
      const recovery = new RecoveryInfo('20260101', '20260101', true, 80, 0);
      const todayInfo = new DayInfo('20260102', 3, 3);
      const result = checkRecoveryAchievement(recovery, todayInfo);
      expect(result.unlocked).assertTrue();
    });

    it('yesterdayRecovery_todayNot100_doesNotUnlock', 0, () => {
      const recovery = new RecoveryInfo('20260101', '20260101', true, 80, 0);
      const todayInfo = new DayInfo('20260102', 3, 2);
      const result = checkRecoveryAchievement(recovery, todayInfo);
      expect(result.unlocked).assertFalse();
    });

    it('noRecovery_doesNotUnlock', 0, () => {
      const todayInfo = new DayInfo('20260102', 3, 3);
      const result = checkRecoveryAchievement(null, todayInfo);
      expect(result.unlocked).assertFalse();
    });

    it('recoveryNotUsed_doesNotUnlock', 0, () => {
      const recovery = new RecoveryInfo('20260101', '20260101', false, 0, 0);
      const todayInfo = new DayInfo('20260102', 3, 3);
      const result = checkRecoveryAchievement(recovery, todayInfo);
      expect(result.unlocked).assertFalse();
    });
  });

  describe('Achievement_PerfectWeek', () => {
    it('allDaysCompletedOrRecovered_unlocks', 0, () => {
      const weekInfos: DayInfo[] = [
        new DayInfo('20260105', 3, 3),
        new DayInfo('20260106', 3, 3),
        new DayInfo('20260107', 3, 2),  // 部分完成，但有补救
        new DayInfo('20260108', 3, 3),
        new DayInfo('20260109', 3, 3),
        new DayInfo('20260110', 3, 3),
        new DayInfo('20260111', 3, 3)
      ];
      const recoveries: RecoveryInfo[] = [
        new RecoveryInfo('20260107', '20260105', true, 67, 0)
      ];
      const result = checkPerfectWeek(weekInfos, recoveries);
      expect(result.unlocked).assertTrue();
    });

    it('oneDayIncomplete_noRecovery_doesNotUnlock', 0, () => {
      const weekInfos: DayInfo[] = [
        new DayInfo('20260105', 3, 3),
        new DayInfo('20260106', 3, 3),
        new DayInfo('20260107', 3, 2),  // 部分完成，无补救
        new DayInfo('20260108', 3, 3),
        new DayInfo('20260109', 3, 3),
        new DayInfo('20260110', 3, 3),
        new DayInfo('20260111', 3, 3)
      ];
      const recoveries: RecoveryInfo[] = [];
      const result = checkPerfectWeek(weekInfos, recoveries);
      expect(result.unlocked).assertFalse();
    });

    it('allCompleted_unlocks', 0, () => {
      const weekInfos: DayInfo[] = [
        new DayInfo('20260105', 3, 3),
        new DayInfo('20260106', 3, 3),
        new DayInfo('20260107', 3, 3),
        new DayInfo('20260108', 3, 3),
        new DayInfo('20260109', 3, 3),
        new DayInfo('20260110', 3, 3),
        new DayInfo('20260111', 3, 3)
      ];
      const result = checkPerfectWeek(weekInfos, []);
      expect(result.unlocked).assertTrue();
    });

    it('lessThan7Days_doesNotUnlock', 0, () => {
      const weekInfos: DayInfo[] = [
        new DayInfo('20260105', 3, 3),
        new DayInfo('20260106', 3, 3),
        new DayInfo('20260107', 3, 3)
      ];
      const result = checkPerfectWeek(weekInfos, []);
      expect(result.unlocked).assertFalse();
    });

    it('emptyData_doesNotUnlock', 0, () => {
      const result = checkPerfectWeek([], []);
      expect(result.unlocked).assertFalse();
    });
  });

  describe('Achievement_TaskSummary', () => {
    it('completedTask_unlocksSingleTaskMedal', 0, () => {
      const tasks: TaskInfo[] = [
        new TaskInfo(1, true, '1', false, '', '', '', -1, '喝水', 'drink', TaskType.VALUE, '0.5', 'L', PickerType.TEXT, '1,2,3', '', false, false, 1, 0)
      ];
      const dayTasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 1, '1', '1', true)
      ];

      const summaries = calculateTaskAchievementSummaries(dayTasks, tasks);

      expect(summaries.length).assertEqual(1);
      expect(summaries[0].taskId).assertEqual(1);
      expect(summaries[0].iconKey).assertEqual('drink');
      expect(summaries[0].singleAchieved).assertTrue();
      expect(summaries[0].maxPercent).assertEqual(100);
    });

    it('numericTaskAtFourTimesTarget_unlocks200To400Percent', 0, () => {
      const tasks: TaskInfo[] = [
        new TaskInfo(6, true, '1', false, '', '', '', -1, '跑步', 'run', TaskType.VALUE, '1', '公里', PickerType.TEXT, '1,2,3', '', false, false, 6, 0)
      ];
      const dayTasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 6, '1', '4', true)
      ];

      const summaries = calculateTaskAchievementSummaries(dayTasks, tasks);

      expect(OVERACHIEVEMENT_THRESHOLDS.length).assertEqual(4);
      expect(summaries[0].maxPercent).assertEqual(400);
      expect(summaries[0].isMultiplierUnlocked(200)).assertTrue();
      expect(summaries[0].isMultiplierUnlocked(300)).assertTrue();
      expect(summaries[0].isMultiplierUnlocked(400)).assertTrue();
      expect(summaries[0].isMultiplierUnlocked(500)).assertFalse();
    });

    it('onceTask_doesNotUnlockOverachievement', 0, () => {
      const tasks: TaskInfo[] = [
        new TaskInfo(100, true, '1', false, '', '', '', -1, '冥想', 'meditation', TaskType.ONCE, '1', '次', PickerType.NONE, '', '', false, false, 100, 0)
      ];
      const dayTasks: DayTaskInfo[] = [
        new DayTaskInfo(1, '20260101', 100, '1', '1', true)
      ];

      const summaries = calculateTaskAchievementSummaries(dayTasks, tasks);

      expect(summaries[0].singleAchieved).assertTrue();
      expect(summaries[0].maxPercent).assertEqual(100);
      expect(summaries[0].isMultiplierUnlocked(200)).assertFalse();
    });
  });

  describe('AchievementType', () => {
    it('allTypesDefined', 0, () => {
      expect(AchievementType.CONSECUTIVE).assertEqual('consecutive');
      expect(AchievementType.STABLE_COMPLETION).assertEqual('stable');
      expect(AchievementType.RECOVERY).assertEqual('recovery');
      expect(AchievementType.PERFECT_WEEK).assertEqual('perfect_week');
    });
  });
}
