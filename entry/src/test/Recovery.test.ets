import { describe, it, expect } from '@ohos/hypium';
import {
  canUseRecovery,
  isDayCompletedForStreak,
  createRecoveryRecord,
  getWeekKey,
  RECOVERY_THRESHOLD
} from '../main/ets/domain/rules/RecoveryRules';
import { onNewDay, ConsecutiveDaysState } from '../main/ets/domain/rules/ConsecutiveDaysRules';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { RecoveryInfo } from '../main/ets/domain/models/RecoveryInfo';
import { getToday } from '../main/ets/domain/utils/DateUtils';

/**
 * 补救规则与连续天数整合单元测试
 */

export default function recoveryTest() {
  const TODAY: string = getToday();

  describe('RecoveryRules_CanUseRecovery', () => {
    it('completion69Percent_cannotUse', 0, () => {
      const dayInfo = new DayInfo(TODAY, 10, 6); // 60%
      const result = canUseRecovery(TODAY, dayInfo, null);
      expect(result).assertFalse();
    });

    it('completionBelow70_cannotUse_evenIfWeekAvailable', 0, () => {
      const dayInfo = new DayInfo(TODAY, 10, 6); // 60%
      const result = canUseRecovery(TODAY, dayInfo, null);
      expect(result).assertFalse();
    });

    it('completion70Percent_canUse', 0, () => {
      const dayInfo = new DayInfo(TODAY, 10, 7); // 70%
      const result = canUseRecovery(TODAY, dayInfo, null);
      expect(result).assertTrue();
    });

    it('completion99Percent_canUse', 0, () => {
      const dayInfo = new DayInfo(TODAY, 100, 99); // 99%
      const result = canUseRecovery(TODAY, dayInfo, null);
      expect(result).assertTrue();
    });

    it('completion100Percent_cannotUse', 0, () => {
      const dayInfo = new DayInfo(TODAY, 10, 10); // 100%
      const result = canUseRecovery(TODAY, dayInfo, null);
      expect(result).assertFalse();
    });

    it('zeroTarget_cannotUse', 0, () => {
      const dayInfo = new DayInfo(TODAY, 0, 0);
      const result = canUseRecovery(TODAY, dayInfo, null);
      expect(result).assertFalse();
    });

    it('weekAlreadyUsed_cannotUse', 0, () => {
      const dayInfo = new DayInfo(TODAY, 10, 8); // 80%
      const weekRecovery = new RecoveryInfo(TODAY, getWeekKey(TODAY), true, 80, 0);
      const result = canUseRecovery(TODAY, dayInfo, weekRecovery);
      expect(result).assertFalse();
    });
  });

  describe('RecoveryRules_isDayCompletedForStreak', () => {
    it('fullyCompleted_returnsTrue', 0, () => {
      const dayInfo = new DayInfo('20260101', 3, 3);
      const result = isDayCompletedForStreak(dayInfo, null);
      expect(result).assertTrue();
    });

    it('notCompleted_noRecovery_returnsFalse', 0, () => {
      const dayInfo = new DayInfo('20260101', 3, 2);
      const result = isDayCompletedForStreak(dayInfo, null);
      expect(result).assertFalse();
    });

    it('notCompleted_withRecovery_returnsTrue', 0, () => {
      const dayInfo = new DayInfo('20260101', 3, 2);
      const recovery = new RecoveryInfo('20260101', '20260101', true, 67, 0);
      const result = isDayCompletedForStreak(dayInfo, recovery);
      expect(result).assertTrue();
    });

    it('nullDayInfo_withRecovery_returnsTrue', 0, () => {
      const recovery = new RecoveryInfo('20260101', '20260101', true, 70, 0);
      const result = isDayCompletedForStreak(null, recovery);
      expect(result).assertTrue();
    });

    it('nullDayInfo_nullRecovery_returnsFalse', 0, () => {
      const result = isDayCompletedForStreak(null, null);
      expect(result).assertFalse();
    });
  });

  describe('RecoveryRules_createRecoveryRecord', () => {
    it('createsRecordWithCorrectFields', 0, () => {
      const record = createRecoveryRecord('20260101', 75);
      expect(record.date).assertEqual('20260101');
      expect(record.used).assertTrue();
      expect(record.completionPercentAtUse).assertEqual(75);
      expect(record.createdAt > 0).assertTrue();
    });

    it('weekKeyIsMondayOfWeek', 0, () => {
      // 2026-01-07 is Wednesday → Monday is 2026-01-05
      const record = createRecoveryRecord('20260107', 80);
      expect(record.weekKey).assertEqual('20260105');
    });
  });

  describe('RecoveryRules_getWeekKey', () => {
    it('mondayReturnsItself', 0, () => {
      // 2026-01-05 is Monday
      expect(getWeekKey('20260105')).assertEqual('20260105');
    });

    it('sundayReturnsPreviousMonday', 0, () => {
      // 2026-01-11 is Sunday → Monday is 2026-01-05
      expect(getWeekKey('20260111')).assertEqual('20260105');
    });

    it('crossMonthWeekKey', 0, () => {
      // 2026-02-01 is Sunday → Monday is 2026-01-26
      expect(getWeekKey('20260201')).assertEqual('20260126');
    });
  });

  describe('Recovery_OnNewDay_withRecovery', () => {
    it('yesterdayIncomplete_withRecovery_streakNotBroken', 0, () => {
      const state = new ConsecutiveDaysState(5, 3, true, null);
      const yesterdayInfo = new DayInfo('20260101', 3, 2); // 未完成
      const yesterdayRecovery = new RecoveryInfo('20260101', '20260101', true, 67, 0);
      const result = onNewDay(yesterdayInfo, state, yesterdayRecovery);
      expect(result.currentConsecutiveDays).assertEqual(3); // 不中断
      expect(result.maxConsecutiveDays).assertEqual(5);
    });

    it('yesterdayIncomplete_noRecovery_streakBroken', 0, () => {
      const state = new ConsecutiveDaysState(5, 3, true, null);
      const yesterdayInfo = new DayInfo('20260101', 3, 2); // 未完成
      const result = onNewDay(yesterdayInfo, state, null);
      expect(result.currentConsecutiveDays).assertEqual(0); // 中断
    });

    it('yesterdayNull_streakPreserved', 0, () => {
      const state = new ConsecutiveDaysState(5, 3, true, null);
      const result = onNewDay(null, state, null);
      expect(result.currentConsecutiveDays).assertEqual(3);
    });

    it('yesterdayCompleted_streakPreserved_noRecoveryNeeded', 0, () => {
      const state = new ConsecutiveDaysState(5, 3, true, null);
      const yesterdayInfo = new DayInfo('20260101', 3, 3); // 全完成
      const result = onNewDay(yesterdayInfo, state, null);
      expect(result.currentConsecutiveDays).assertEqual(3);
    });
  });

  describe('Recovery_Threshold', () => {
    it('recoveryThresholdIs70', 0, () => {
      expect(RECOVERY_THRESHOLD).assertEqual(70);
    });
  });
}
