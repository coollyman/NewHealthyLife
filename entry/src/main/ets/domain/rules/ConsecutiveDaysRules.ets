import { DayInfo } from '../models/DayInfo';
import { AppConstants } from '../constants/AppConstants';

/**
 * 连续天数状态
 */
export class ConsecutiveDaysState {
  maxConsecutiveDays: number;
  currentConsecutiveDays: number;
  currentDayStatus: boolean;
  newlyUnlockedAchievement: number | null;

  constructor(
    maxConsecutiveDays: number = 0,
    currentConsecutiveDays: number = 0,
    currentDayStatus: boolean = false,
    newlyUnlockedAchievement: number | null = null
  ) {
    this.maxConsecutiveDays = maxConsecutiveDays;
    this.currentConsecutiveDays = currentConsecutiveDays;
    this.currentDayStatus = currentDayStatus;
    this.newlyUnlockedAchievement = newlyUnlockedAchievement;
  }
}

/**
 * 初始状态
 */
export function createInitialConsecutiveState(): ConsecutiveDaysState {
  return new ConsecutiveDaysState(0, 0, false, null);
}

/**
 * 判断当日是否全部完成
 */
export function isAllTasksCompleted(dayInfo: DayInfo): boolean {
  return dayInfo.targetTaskNum > 0 && dayInfo.finTaskNum >= dayInfo.targetTaskNum;
}

/**
 * 当天所有任务首次全部完成时，更新连续天数
 */
export function onAllTasksCompleted(state: ConsecutiveDaysState): ConsecutiveDaysState {
  if (state.currentDayStatus) {
    return state;
  }

  const newCurrent = state.currentConsecutiveDays + 1;
  const newMax = Math.max(state.maxConsecutiveDays, newCurrent);
  let newlyUnlocked: number | null = null;

  for (const threshold of AppConstants.ACHIEVEMENT_THRESHOLDS) {
    if (newMax === threshold && state.maxConsecutiveDays < threshold) {
      newlyUnlocked = threshold;
      break;
    }
  }

  return new ConsecutiveDaysState(newMax, newCurrent, true, newlyUnlocked);
}

/**
 * 新的一天初始化时，检查昨天是否全部完成
 */
export function onNewDay(
  yesterdayInfo: DayInfo | null,
  currentState: ConsecutiveDaysState
): ConsecutiveDaysState {
  if (yesterdayInfo !== null && !isAllTasksCompleted(yesterdayInfo)) {
    return new ConsecutiveDaysState(currentState.maxConsecutiveDays, 0, false, null);
  }
  return new ConsecutiveDaysState(
    currentState.maxConsecutiveDays,
    currentState.currentConsecutiveDays,
    false,
    null
  );
}

/**
 * 应用重新初始化或页面重建时，根据当天已保存的 100% 记录恢复“今天已计数”状态。
 * 这样当天先完成到 100%，之后再添加任务并再次完成，不会重复增加连续天数。
 */
export function reconcileCurrentDayCompletion(
  todayInfo: DayInfo,
  currentState: ConsecutiveDaysState
): ConsecutiveDaysState {
  if (!isAllTasksCompleted(todayInfo) || currentState.currentDayStatus) {
    return currentState;
  }
  if (currentState.currentConsecutiveDays <= 0) {
    return currentState;
  }
  return new ConsecutiveDaysState(
    currentState.maxConsecutiveDays,
    currentState.currentConsecutiveDays,
    true,
    currentState.newlyUnlockedAchievement
  );
}

/**
 * 判断指定天数是否已解锁成就
 */
export function isAchievementUnlocked(maxDays: number, threshold: number): boolean {
  return maxDays >= threshold;
}
