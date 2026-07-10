import { DayInfo } from '../models/DayInfo';
import { RecoveryInfo } from '../models/RecoveryInfo';
import { AppConstants } from '../constants/AppConstants';

/**
 * 连续天数状态
 */
export class ConsecutiveDaysState {
  maxConsecutiveDays: number;
  currentConsecutiveDays: number;
  currentDayStatus: boolean;
  newlyUnlockedAchievement: number | null;
  maxConsecutiveDaysBeforeCurrentDay: number;

  constructor(
    maxConsecutiveDays: number = 0,
    currentConsecutiveDays: number = 0,
    currentDayStatus: boolean = false,
    newlyUnlockedAchievement: number | null = null,
    maxConsecutiveDaysBeforeCurrentDay: number = maxConsecutiveDays
  ) {
    this.maxConsecutiveDays = maxConsecutiveDays;
    this.currentConsecutiveDays = currentConsecutiveDays;
    this.currentDayStatus = currentDayStatus;
    this.newlyUnlockedAchievement = newlyUnlockedAchievement;
    this.maxConsecutiveDaysBeforeCurrentDay = maxConsecutiveDaysBeforeCurrentDay;
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
    // 同一天重复调用：幂等不增天数，同时清掉 newlyUnlockedAchievement，
    // 保证"只消费一次"语义——调用方第一次没 pop 就再次调用也不会重复触发。
    if (state.newlyUnlockedAchievement !== null) {
      return new ConsecutiveDaysState(
        state.maxConsecutiveDays,
        state.currentConsecutiveDays,
        true,
        null,
        state.maxConsecutiveDaysBeforeCurrentDay
      );
    }
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

  return new ConsecutiveDaysState(newMax, newCurrent, true, newlyUnlocked, state.maxConsecutiveDays);
}

/**
 * 当天已被计为完成后，如果新增/启用目标导致今天不再 100%，撤销今天这一次计数。
 * max 恢复到今天完成前的基线，保证成就页不会保留一次未最终达成的解锁。
 */
export function onCurrentDayCompletionRevoked(state: ConsecutiveDaysState): ConsecutiveDaysState {
  if (!state.currentDayStatus) {
    return state;
  }

  const restoredMax = Math.max(state.maxConsecutiveDaysBeforeCurrentDay, 0);
  const restoredCurrent = Math.max(0, state.currentConsecutiveDays - 1);
  return new ConsecutiveDaysState(restoredMax, restoredCurrent, false, null, restoredMax);
}

/**
 * 新的一天初始化时，检查昨天是否全部完成。
 * 如果昨天未 100% 但有补救记录，连续天数不中断。
 *
 * @param yesterdayInfo     昨天的 DayInfo（可能为 null）
 * @param currentState      当前连续天数状态
 * @param yesterdayRecovery 昨天的补救记录（可选，无则 null）
 */
export function onNewDay(
  yesterdayInfo: DayInfo | null,
  currentState: ConsecutiveDaysState,
  yesterdayRecovery: RecoveryInfo | null = null
): ConsecutiveDaysState {
  if (yesterdayInfo !== null && !isAllTasksCompleted(yesterdayInfo)) {
    // 昨天未 100% 完成 — 检查是否有补救
    const hasRecovery = yesterdayRecovery !== null && yesterdayRecovery.used;
    if (!hasRecovery) {
      return new ConsecutiveDaysState(currentState.maxConsecutiveDays, 0, false, null, currentState.maxConsecutiveDays);
    }
  }
  return new ConsecutiveDaysState(
    currentState.maxConsecutiveDays,
    currentState.currentConsecutiveDays,
    false,
    null,
    currentState.maxConsecutiveDays
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
    currentState.newlyUnlockedAchievement,
    currentState.maxConsecutiveDaysBeforeCurrentDay
  );
}

/**
 * 判断指定天数是否已解锁成就
 */
export function isAchievementUnlocked(maxDays: number, threshold: number): boolean {
  return maxDays >= threshold;
}
