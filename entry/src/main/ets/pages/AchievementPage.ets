import { HomeStore } from '../viewmodel/HomeStore';
import { AppConstants } from '../domain/constants/AppConstants';
import { isAchievementUnlocked } from '../domain/rules/ConsecutiveDaysRules';

/**
 * 成就页
 */
@Component
export struct AchievementPage {
  @Link homeStore: HomeStore;

  build() {
    Column() {
      // 标题
      Row() {
        Text($r('app.string.my_achievement'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)

      // 连续天数
      Row() {
        Column() {
          Text($r('app.string.consecutive_days'))
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text(`${this.homeStore.consecutiveState.currentConsecutiveDays}`)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_font_color'))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text($r('app.string.max_consecutive_days'))
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text(`${this.homeStore.consecutiveState.maxConsecutiveDays}`)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding(24)
      .backgroundColor($r('app.color.bg_card'))
      .margin({ bottom: 8 })

      // 徽章列表
      Grid() {
        ForEach(AppConstants.ACHIEVEMENT_THRESHOLDS, (threshold: number) => {
          GridItem() {
            this.badgeItem(threshold)
          }
        }, (threshold: number) => threshold.toString())
      }
      .columnsTemplate('1fr 1fr 2fr')
      .rowsGap(16)
      .columnsGap(8)
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  badgeItem(threshold: number) {
    Column() {
      Image(this.getBadgeIcon(threshold))
        .width(80)
        .height(80)

      Text(`连续${threshold}天`)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private getBadgeIcon(threshold: number): Resource {
    const unlocked = isAchievementUnlocked(
      this.homeStore.consecutiveState.maxConsecutiveDays, threshold
    );
    switch (threshold) {
      case 3: return unlocked ? $r('app.media.ic_badge_3_on') : $r('app.media.ic_badge_3_off');
      case 7: return unlocked ? $r('app.media.ic_badge_7_on') : $r('app.media.ic_badge_7_off');
      case 30: return unlocked ? $r('app.media.ic_badge_30_on') : $r('app.media.ic_badge_30_off');
      case 50: return unlocked ? $r('app.media.ic_badge_50_on') : $r('app.media.ic_badge_50_off');
      case 73: return unlocked ? $r('app.media.ic_badge_73_on') : $r('app.media.ic_badge_73_off');
      case 99: return unlocked ? $r('app.media.ic_badge_99_on') : $r('app.media.ic_badge_99_off');
      default: return $r('app.media.ic_badge_3_off');
    }
  }
}
