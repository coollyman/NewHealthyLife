import { describe, it, expect } from '@ohos/hypium';
import { suggestGoalAdjustment, GoalSuggestionType } from '../main/ets/domain/rules/GoalSuggestionRules';
import { DayTaskInfo } from '../main/ets/domain/DayTaskInfo';

/**
 * 目标建议规则单元测试
 * 覆盖边界值：increase / decrease / keep / none、样本不足、最大/最小值不越界
 */

const PICKER_RANGE: string[] = ['0.5', '1', '1.5', '2', '2.5', '3'];

function makeDayTask(date: string, taskId: number, isDone: boolean): DayTaskInfo {
  return new DayTaskInfo(0, date, taskId, '1', isDone ? '1' : '0', isDone);
}

export default function goalSuggestionTest() {

  describe('GoalSuggestion_Increase', () => {
    it('consecutive5Days_suggestsIncrease', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, true),
        makeDayTask('20260106', 1, true),
        makeDayTask('20260107', 1, true)
      ];
      const result = suggestGoalAdjustment('1', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.INCREASE);
      expect(result.suggestedValue).assertEqual('1.5');
    });

    it('exactly5Days_suggestsIncrease', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, true),
        makeDayTask('20260106', 1, false),
        makeDayTask('20260107', 1, false)
      ];
      const result = suggestGoalAdjustment('1', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.INCREASE);
    });
  });

  describe('GoalSuggestion_Decrease', () => {
    it('lessThan3Days_suggestsDecrease', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, false),
        makeDayTask('20260102', 1, false),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, false),
        makeDayTask('20260105', 1, false),
        makeDayTask('20260106', 1, true),
        makeDayTask('20260107', 1, false)
      ];
      const result = suggestGoalAdjustment('1', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.DECREASE);
      expect(result.suggestedValue).assertEqual('0.5');
    });

    it('only0Days_suggestsDecrease', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, false),
        makeDayTask('20260102', 1, false),
        makeDayTask('20260103', 1, false),
        makeDayTask('20260104', 1, false),
        makeDayTask('20260105', 1, false),
        makeDayTask('20260106', 1, false),
        makeDayTask('20260107', 1, false)
      ];
      const result = suggestGoalAdjustment('1', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.DECREASE);
    });
  });

  describe('GoalSuggestion_Keep', () => {
    it('threeToFourDays_suggestsKeep', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, false),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, false),
        makeDayTask('20260106', 1, true),
        makeDayTask('20260107', 1, false)
      ];
      const result = suggestGoalAdjustment('1', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.KEEP);
    });
  });

  describe('GoalSuggestion_None', () => {
    it('lessThan3Samples_returnsNone', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, false)
      ];
      const result = suggestGoalAdjustment('1', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.NONE);
    });

    it('atMaxValue_increaseBecomesNone', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, true),
        makeDayTask('20260106', 1, true),
        makeDayTask('20260107', 1, true)
      ];
      const result = suggestGoalAdjustment('3', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.NONE);
    });

    it('atMinValue_decreaseBecomesNone', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, false),
        makeDayTask('20260102', 1, false),
        makeDayTask('20260103', 1, false),
        makeDayTask('20260104', 1, false),
        makeDayTask('20260105', 1, false),
        makeDayTask('20260106', 1, false),
        makeDayTask('20260107', 1, false)
      ];
      const result = suggestGoalAdjustment('0.5', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.NONE);
    });

    it('emptyPickerRange_returnsNone', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, true)
      ];
      const result = suggestGoalAdjustment('1', tasks, []);
      expect(result.type).assertEqual(GoalSuggestionType.NONE);
    });

    it('singleElementPickerRange_returnsNone', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, true)
      ];
      const result = suggestGoalAdjustment('1', tasks, ['1']);
      expect(result.type).assertEqual(GoalSuggestionType.NONE);
    });

    it('targetNotInPickerRange_returnsNone', 0, () => {
      const tasks: DayTaskInfo[] = [
        makeDayTask('20260101', 1, true),
        makeDayTask('20260102', 1, true),
        makeDayTask('20260103', 1, true),
        makeDayTask('20260104', 1, true),
        makeDayTask('20260105', 1, true)
      ];
      const result = suggestGoalAdjustment('99', tasks, PICKER_RANGE);
      expect(result.type).assertEqual(GoalSuggestionType.NONE);
    });
  });
}
