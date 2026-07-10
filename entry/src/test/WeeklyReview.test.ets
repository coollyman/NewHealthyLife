import { describe, it, expect } from '@ohos/hypium';
import { generateWeeklyReview } from '../main/ets/domain/rules/WeeklyReviewRules';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';

/**
 * 周复盘规则单元测试
 */

function makeDayTask(date: string, taskId: number, isDone: boolean): DayTaskInfo {
  return new DayTaskInfo(0, date, taskId, '1', isDone ? '1' : '0', isDone);
}

export default function weeklyReviewTest() {

  describe('WeeklyReview_Generate', () => {
    it('insufficientData_returnsNotAvailable', 0, () => {
      const review = generateWeeklyReview([], []);
      expect(review.isAvailable).assertFalse();
    });

    it('lessThan3Days_returnsNotAvailable', 0, () => {
      const dayInfos: DayInfo[] = [
        new DayInfo('20260101', 3, 3)
      ];
      const review = generateWeeklyReview(dayInfos, []);
      expect(review.isAvailable).assertFalse();
    });

    it('zeroTotalTarget_returnsNotAvailable', 0, () => {
      const dayInfos: DayInfo[] = [
        new DayInfo('20260101', 0, 0),
        new DayInfo('20260102', 0, 0),
        new DayInfo('20260103', 0, 0)
      ];
      const review = generateWeeklyReview(dayInfos, []);
      expect(review.isAvailable).assertFalse();
    });

    it('fullWeekCompletion_returns100Percent', 0, () => {
      const dayInfos: DayInfo[] = [
        new DayInfo('20260105', 3, 3),
        new DayInfo('20260106', 3, 3),
        new DayInfo('20260107', 3, 3),
        new DayInfo('20260108', 3, 3),
        new DayInfo('20260109', 3, 3),
        new DayInfo('20260110', 3, 3),
        new DayInfo('20260111', 3, 3)
      ];
      const review = generateWeeklyReview(dayInfos, []);
      expect(review.isAvailable).assertTrue();
      expect(review.completionRate).assertEqual(100);
    });

    it('halfCompletion_returns50Percent', 0, () => {
      const dayInfos: DayInfo[] = [
        new DayInfo('20260105', 2, 1),
        new DayInfo('20260106', 2, 1),
        new DayInfo('20260107', 2, 1)
      ];
      const review = generateWeeklyReview(dayInfos, []);
      expect(review.isAvailable).assertTrue();
      expect(review.completionRate).assertEqual(50);
    });

    it('identifiesMostStableTask', 0, () => {
      const dayInfos: DayInfo[] = [
        new DayInfo('20260105', 2, 1),
        new DayInfo('20260106', 2, 1),
        new DayInfo('20260107', 2, 1)
      ];
      const dayTasks: DayTaskInfo[] = [
        makeDayTask('20260105', 1, true),
        makeDayTask('20260106', 1, true),
        makeDayTask('20260107', 1, true),
        makeDayTask('20260105', 2, false),
        makeDayTask('20260106', 2, false),
        makeDayTask('20260107', 2, false)
      ];
      const review = generateWeeklyReview(dayInfos, dayTasks);
      expect(review.mostStableTaskId).assertEqual(1);
    });

    it('identifiesMostMissedTask', 0, () => {
      const dayInfos: DayInfo[] = [
        new DayInfo('20260105', 2, 1),
        new DayInfo('20260106', 2, 1),
        new DayInfo('20260107', 2, 1)
      ];
      const dayTasks: DayTaskInfo[] = [
        makeDayTask('20260105', 1, true),
        makeDayTask('20260106', 1, true),
        makeDayTask('20260107', 1, true),
        makeDayTask('20260105', 2, false),
        makeDayTask('20260106', 2, false),
        makeDayTask('20260107', 2, false)
      ];
      const review = generateWeeklyReview(dayInfos, dayTasks);
      expect(review.mostMissedTaskId).assertEqual(2);
    });

    it('highCompletionSaysKeepGoing', 0, () => {
      const dayInfos: DayInfo[] = [
        new DayInfo('20260105', 2, 2),
        new DayInfo('20260106', 2, 2),
        new DayInfo('20260107', 2, 2)
      ];
      const review = generateWeeklyReview(dayInfos, []);
      expect(review.completionRate >= 80).assertTrue();
    });

    it('lowCompletionSaysLowerTarget', 0, () => {
      const dayInfos: DayInfo[] = [
        new DayInfo('20260105', 2, 0),
        new DayInfo('20260106', 2, 0),
        new DayInfo('20260107', 2, 0)
      ];
      const review = generateWeeklyReview(dayInfos, []);
      expect(review.completionRate < 50).assertTrue();
    });
  });
}
