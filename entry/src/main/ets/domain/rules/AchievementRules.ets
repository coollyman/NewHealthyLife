import { DayInfo } from '../models/DayInfo';
import { DayTaskInfo } from '../models/DayTaskInfo';
import { RecoveryInfo } from '../models/RecoveryInfo';
import { getMondayOfWeek, getDateOffset } from '../utils/DateUtils';

/**
 * 成就类型枚举 — 多维成就
 */
export enum AchievementType {
  CONSECUTIVE = 'consecutive',     // 连续天数（已有）
  STABLE_COMPLETION = 'stable',    // 稳定完成：某任务最近7天完成5天
  RECOVERY = 'recovery',           // 恢复能力：使用补救后第二天完成100%
  PERFECT_WEEK = 'perfect_week'    // 全勤周：自然周内每天有效完成或补救
}

/**
 * 多维成就状态
 */
export class AchievementStatus {
  type: AchievementType;
  unlocked: boolean;
  description: string;

  constructor(type: AchievementType, unlocked: boolean, description: string) {
    this.type = type;
    this.unlocked = unlocked;
    this.description = description;
  }
}

/**
 * 检查"稳定完成"成就：某任务最近 7 天完成 5 天及以上
 */
export function checkStableCompletion(recentTasks: DayTaskInfo[]): AchievementStatus {
  if (!recentTasks || recentTasks.length < 5) {
    return new AchievementStatus(
      AchievementType.STABLE_COMPLETION, false, '数据不足'
    );
  }
  const completedDays = recentTasks.filter(t => t.isDone).length;
  const unlocked = completedDays >= 5;
  return new AchievementStatus(
    AchievementType.STABLE_COMPLETION,
    unlocked,
    unlocked ? `最近7天完成${completedDays}天` : `最近7天完成${completedDays}天，未达标`
  );
}

/**
 * 检查"恢复能力"成就：使用补救后第二天完成 100%
 * @param yesterdayRecovery 昨天的补救记录
 * @param todayDayInfo 今天的完成情况
 */
export function checkRecoveryAchievement(
  yesterdayRecovery: RecoveryInfo | null,
  todayDayInfo: DayInfo | null
): AchievementStatus {
  if (yesterdayRecovery === null || !yesterdayRecovery.used) {
    return new AchievementStatus(
      AchievementType.RECOVERY, false, '未使用过补救'
    );
  }
  if (todayDayInfo === null || todayDayInfo.targetTaskNum === 0) {
    return new AchievementStatus(
      AchievementType.RECOVERY, false, '今天无任务数据'
    );
  }
  const unlocked = todayDayInfo.finTaskNum >= todayDayInfo.targetTaskNum;
  return new AchievementStatus(
    AchievementType.RECOVERY,
    unlocked,
    unlocked ? '补救后第二天完成100%' : '补救后第二天未完成'
  );
}

/**
 * 检查"全勤周"成就：自然周内每天有效完成或补救
 * @param weekDayInfos 本周 7 天的 DayInfo 列表
 * @param weekRecoveries 本周的补救记录列表
 */
export function checkPerfectWeek(
  weekDayInfos: DayInfo[],
  weekRecoveries: RecoveryInfo[]
): AchievementStatus {
  if (!weekDayInfos || weekDayInfos.length === 0) {
    return new AchievementStatus(
      AchievementType.PERFECT_WEEK, false, '数据不足'
    );
  }
  const recoveryMap = new Map<string, boolean>();
  for (const r of weekRecoveries) {
    recoveryMap.set(r.date, r.used);
  }

  let allDaysCompleted = true;
  let validDays = 0;

  for (const di of weekDayInfos) {
    if (di.targetTaskNum === 0) {
      continue; // 无记录的日期跳过
    }
    validDays++;
    const isComplete = di.finTaskNum >= di.targetTaskNum;
    const hasRecovery = recoveryMap.get(di.date) === true;
    if (!isComplete && !hasRecovery) {
      allDaysCompleted = false;
      break;
    }
  }

  if (validDays < 7) {
    return new AchievementStatus(
      AchievementType.PERFECT_WEEK, false, '本周数据不足'
    );
  }

  return new AchievementStatus(
    AchievementType.PERFECT_WEEK,
    allDaysCompleted,
    allDaysCompleted ? '本周全勤' : '本周未全勤'
  );
}
