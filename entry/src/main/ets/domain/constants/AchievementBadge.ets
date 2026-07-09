/**
 * 成就徽章资源映射 - 供成就页与解锁弹窗共用，避免多处 switch 不一致。
 * 仅支持 AppConstants.ACHIEVEMENT_THRESHOLDS 中的阈值：3/7/30/50/73/99。
 */

/**
 * 根据阈值和是否已解锁返回对应徽章图片资源。
 * @param threshold 成就阈值，仅支持 3/7/30/50/73/99
 * @param unlocked 是否已解锁
 * @returns 徽章图片 Resource；非法阈值返回 null
 */
export function getAchievementBadgeIcon(threshold: number, unlocked: boolean): Resource | null {
  switch (threshold) {
    case 3:
      return unlocked ? $r('app.media.ic_badge_3_on') : $r('app.media.ic_badge_3_off');
    case 7:
      return unlocked ? $r('app.media.ic_badge_7_on') : $r('app.media.ic_badge_7_off');
    case 30:
      return unlocked ? $r('app.media.ic_badge_30_on') : $r('app.media.ic_badge_30_off');
    case 50:
      return unlocked ? $r('app.media.ic_badge_50_on') : $r('app.media.ic_badge_50_off');
    case 73:
      return unlocked ? $r('app.media.ic_badge_73_on') : $r('app.media.ic_badge_73_off');
    case 99:
      return unlocked ? $r('app.media.ic_badge_99_on') : $r('app.media.ic_badge_99_off');
    default:
      return null;
  }
}

/**
 * 判断给定阈值是否为有效成就阈值。
 */
export function isValidAchievementThreshold(threshold: number): boolean {
  switch (threshold) {
    case 3:
    case 7:
    case 30:
    case 50:
    case 73:
    case 99:
      return true;
    default:
      return false;
  }
}
