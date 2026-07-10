import { DayTaskInfo } from '../models/DayTaskInfo';

/**
 * 目标建议类型
 */
export enum GoalSuggestionType {
  INCREASE = 'increase',
  DECREASE = 'decrease',
  KEEP = 'keep',
  NONE = 'none'
}

/**
 * 目标建议结果
 */
export class GoalSuggestion {
  type: GoalSuggestionType;
  suggestedValue: string;
  reason: string;

  constructor(
    type: GoalSuggestionType = GoalSuggestionType.NONE,
    suggestedValue: string = '',
    reason: string = ''
  ) {
    this.type = type;
    this.suggestedValue = suggestedValue;
    this.reason = reason;
  }
}

/**
 * 根据最近 7 天完成情况，给出目标调整建议。
 *
 * 规则：
 * - 连续 5 天及以上完成该任务 → 建议提高一档
 * - 最近 7 天完成少于 3 天 → 建议降低一档
 * - 最近 7 天完成 3-4 天 → 建议保持
 * - 有效记录少于 3 天 → 不给出建议（样本过少）
 * - 已是最小/最大值时不给出越界建议
 * - 只从 pickerRange 中选择建议值
 *
 * @param targetValue  当前目标值
 * @param recentTasks  最近 7 天的 DayTaskInfo 列表（按日期升序）
 * @param pickerRange  任务目录中的可选目标范围
 */
export function suggestGoalAdjustment(
  targetValue: string,
  recentTasks: DayTaskInfo[],
  pickerRange: string[]
): GoalSuggestion {
  // 样本不足
  if (!recentTasks || recentTasks.length < 3) {
    return new GoalSuggestion(GoalSuggestionType.NONE, '', '数据不足，暂不给出建议');
  }

  // pickerRange 为空或只有一档，无法调整
  if (!pickerRange || pickerRange.length <= 1) {
    return new GoalSuggestion(GoalSuggestionType.NONE, '', '');
  }

  const completedDays = recentTasks.filter(t => t.isDone).length;
  const currentIdx = pickerRange.indexOf(targetValue);

  // 当前目标不在 pickerRange 中，无法定位
  if (currentIdx < 0) {
    return new GoalSuggestion(GoalSuggestionType.NONE, '', '');
  }

  // 连续 5 天及以上完成 → 提高一档
  if (completedDays >= 5) {
    if (currentIdx >= pickerRange.length - 1) {
      // 已是最大值
      return new GoalSuggestion(GoalSuggestionType.NONE, '', '目标已达上限，保持当前');
    }
    const suggested = pickerRange[currentIdx + 1];
    return new GoalSuggestion(
      GoalSuggestionType.INCREASE,
      suggested,
      `最近 ${recentTasks.length} 天完成了 ${completedDays} 天，可以把目标从 ${targetValue} 调整到 ${suggested}。`
    );
  }

  // 最近 7 天完成少于 3 天 → 降低一档
  if (completedDays < 3) {
    if (currentIdx <= 0) {
      // 已是最小值
      return new GoalSuggestion(GoalSuggestionType.NONE, '', '目标已达下限，保持当前');
    }
    const suggested = pickerRange[currentIdx - 1];
    return new GoalSuggestion(
      GoalSuggestionType.DECREASE,
      suggested,
      `最近 ${recentTasks.length} 天只完成了 ${completedDays} 天，建议先降到 ${suggested}，稳定后再提高。`
    );
  }

  // 3-4 天 → 保持
  return new GoalSuggestion(
    GoalSuggestionType.KEEP,
    targetValue,
    `最近 ${recentTasks.length} 天完成了 ${completedDays} 天，保持当前目标即可。`
  );
}
