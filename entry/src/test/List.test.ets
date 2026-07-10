import { describe, it, expect } from '@ohos/hypium';
import localUnitTest from './LocalUnit.test';
import numericCheckinTest from './NumericCheckin.test';
import regressionBugScanTest from './RegressionBugScan.test';
import homeStoreFlowTest from './HomeStoreFlow.test';
import persistenceSemanticsTest from './PersistenceSemantics.test';
import monthViewTest from './MonthView.test';
import goalSuggestionTest from './GoalSuggestion.test';
import recoveryTest from './Recovery.test';
import achievementUpgradeTest from './AchievementUpgrade.test';
import weeklyReviewTest from './WeeklyReview.test';
import profileStoreTest from './ProfileStore.test';
import { getDateOffset, compareDate, getThreeWeekWindow } from '../main/ets/domain/utils/DateUtils';
import { DayInfo } from '../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../main/ets/domain/models/DayTaskInfo';
import { buildCardFormData } from '../main/ets/services/FormService';
import { buildDayTaskRenderKey } from '../main/ets/components/home/TaskList';

export default function testsuite() {
  localUnitTest();
  numericCheckinTest();
  regressionBugScanTest();
  homeStoreFlowTest();
  persistenceSemanticsTest();
  monthViewTest();
  goalSuggestionTest();
  recoveryTest();
  achievementUpgradeTest();
  weeklyReviewTest();
  profileStoreTest();

  describe('HistoryAndPreviewDates', () => {
    it('dateOffset_supportsHistoryAndFutureSelection', 0, () => {
      const today = '20260709';
      const past = getDateOffset(today, -1);
      const future = getDateOffset(today, 1);
      expect(compareDate(past, today) < 0).assertTrue();
      expect(compareDate(future, today) > 0).assertTrue();
    });

    it('threeWeekWindow_keepsSelectedDateVisible', 0, () => {
      const selectedDate = '20260709';
      const dates = getThreeWeekWindow(selectedDate);
      expect(dates.includes(selectedDate)).assertTrue();
      expect(dates.length).assertEqual(21);
    });
  });

  describe('FormCardDataMapping', () => {
    it('buildCardFormData_mapsProgressCountsAndPercentage', 0, () => {
      const dayInfo = new DayInfo('20260709', 2, 1);
      const formData = buildCardFormData(dayInfo, [
        new DayTaskInfo(1, '20260709', 1, '1', '1', true),
        new DayTaskInfo(2, '20260709', 3, '1', '', false)
      ]);

      expect(formData.taskCount).assertEqual(2);
      expect(formData.finishedCount).assertEqual(1);
      expect(formData.targetTaskNum).assertEqual(2);
      expect(formData.finTaskNum).assertEqual(1);
      expect(formData.percentage).assertEqual(50);
      expect(formData.taskList.includes('喝水')).assertTrue();
      expect(formData.taskList.includes('每日微笑')).assertTrue();
    });
  });

  describe('TaskListRenderKey', () => {
    it('renderKey_changesWhenProgressOrDoneStateChanges', 0, () => {
      const before = new DayTaskInfo(1, '20260709', 1, '1', '0', false);
      const half = new DayTaskInfo(1, '20260709', 1, '1', '0.5', false);
      const done = new DayTaskInfo(1, '20260709', 1, '1', '1', true);

      expect(buildDayTaskRenderKey(before) === buildDayTaskRenderKey(half)).assertFalse();
      expect(buildDayTaskRenderKey(half) === buildDayTaskRenderKey(done)).assertFalse();
    });
  });
}
