/**
 * 成就信息
 */
export class AchievementInfo {
  days: number;
  isUnlocked: boolean;
  badgeOn: Resource;
  badgeOff: Resource;

  constructor(days: number, isUnlocked: boolean, badgeOn: Resource, badgeOff: Resource) {
    this.days = days;
    this.isUnlocked = isUnlocked;
    this.badgeOn = badgeOn;
    this.badgeOff = badgeOff;
  }
}
