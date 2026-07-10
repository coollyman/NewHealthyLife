import { DayInfo } from '../models/DayInfo';
import { RecoveryInfo } from '../models/RecoveryInfo';
import { getMondayOfWeek, isToday, getToday } from '../utils/DateUtils';

/**
 * 补救阈值：完成度达到此值及以上但未满 100% 时可使用补救
 */
export const RECOVERY_THRESHOLD: number = 70;

/**
 * 获取指定日期所在周的 weekKey（周一日期）
 */
export function getWeekKey(dateStr: string): string {
  return getMondayOfWeek(dateStr);
}

/**
 * 判断是否可以使用补救
 *
 * 条件：
 * - 日期是今天
 * - 当天目标数 > 0
 * - 完成度 >= 70 且 < 100
 * - 当前周未使用过补救
 *
 * @param dateStr      要判断的日期 yyyyMMdd
 * @param dayInfo      当天聚合数据
 * @param weekRecovery 本周已使用的补救记录（无则 null）
 */
export function canUseRecovery(
  dateStr: string,
  dayInfo: DayInfo,
  weekRecovery: RecoveryInfo | null
): boolean {
  if (!isToday(dateStr)) {
    return false;
  }
  if (dayInfo.targetTaskNum <= 0) {
    return false;
  }
  const percent = dayInfo.calculatePercentage();
  if (percent < RECOVERY_THRESHOLD || percent >= 100) {
    return false;
  }
  if (weekRecovery !== null && weekRecovery.used) {
    return false;
  }
  return true;
}

/**
 * 判断某天是否在连续天数计算中视为"完成"
 *
 * - DayInfo 100% 完成；或
 * - 存在有效补救记录
 */
export function isDayCompletedForStreak(
  dayInfo: DayInfo | null,
  recoveryInfo: RecoveryInfo | null
): boolean {
  if (dayInfo !== null && dayInfo.targetTaskNum > 0 && dayInfo.finTaskNum >= dayInfo.targetTaskNum) {
    return true;
  }
  if (recoveryInfo !== null && recoveryInfo.used) {
    return true;
  }
  return false;
}

/**
 * 创建补救记录
 */
export function createRecoveryRecord(dateStr: string, completionPercent: number): RecoveryInfo {
  return new RecoveryInfo(
    dateStr,
    getWeekKey(dateStr),
    true,
    completionPercent,
    Date.now()
  );
}
