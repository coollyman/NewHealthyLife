import { describe, it, expect } from '@ohos/hypium';
import {
  checkStableCompletion,
  checkRecoveryAchievement,
  checkPerfectWeek,
  AchievementType
} from '../main/ets/domain/rules/AchievementRules';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';
import { RecoveryInfo } from '../main/ets/domain/models/RecoveryInfo';

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

  describe('AchievementType', () => {
    it('allTypesDefined', 0, () => {
      expect(AchievementType.CONSECUTIVE).assertEqual('consecutive');
      expect(AchievementType.STABLE_COMPLETION).assertEqual('stable');
      expect(AchievementType.RECOVERY).assertEqual('recovery');
      expect(AchievementType.PERFECT_WEEK).assertEqual('perfect_week');
    });
  });
}
