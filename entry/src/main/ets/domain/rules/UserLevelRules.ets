import { AppConstants } from '../constants/AppConstants';

/**
 * 用户等级规则 — 根据最高连续打卡天数计算等级。
 *
 * 等级阶梯与成就阈值对应：
 * - 0-2 天：LV.1（新手）
 * - 3-6 天：LV.2
 * - 7-29 天：LV.3
 * - 30-49 天：LV.4
 * - 50-72 天：LV.5
 * - 73-98 天：LV.6
 * - 99+ 天：LV.7
 */

/**
 * 根据最高连续打卡天数返回等级数字。
 */
export function getUserLevel(maxConsecutiveDays: number): number {
  if (maxConsecutiveDays >= 99) {
    return 7;
  }
  if (maxConsecutiveDays >= 73) {
    return 6;
  }
  if (maxConsecutiveDays >= 50) {
    return 5;
  }
  if (maxConsecutiveDays >= 30) {
    return 4;
  }
  if (maxConsecutiveDays >= 7) {
    return 3;
  }
  if (maxConsecutiveDays >= 3) {
    return 2;
  }
  return 1;
}

/**
 * 返回等级显示文案，如 "LV.3"。
 */
export function getUserLevelLabel(maxConsecutiveDays: number): string {
  return `LV.${getUserLevel(maxConsecutiveDays)}`;
}

/**
 * 返回到下一级所需天数，已达最高级时返回 null。
 */
export function getDaysToNextLevel(maxConsecutiveDays: number): number | null {
  const currentLevel = getUserLevel(maxConsecutiveDays);
  if (currentLevel >= 7) {
    return null;
  }
  const nextThreshold = AppConstants.ACHIEVEMENT_THRESHOLDS[currentLevel - 1];
  return nextThreshold - maxConsecutiveDays;
}
