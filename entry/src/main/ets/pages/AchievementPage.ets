import { HomeStore } from '../viewmodel/HomeStore';
import { AppConstants } from '../domain/constants/AppConstants';
import { isAchievementUnlocked } from '../domain/rules/ConsecutiveDaysRules';
import { getAchievementBadgeIcon } from '../domain/constants/AchievementBadge';
import { WeeklyReview } from '../domain/rules/WeeklyReviewRules';

/**
 * 成就页
 * 展示连续天数徽章 + 周复盘 + 多维成就提示
 */
@Component
export struct AchievementPage {
  @Link homeStore: HomeStore;
  @State weeklyReview: WeeklyReview = new WeeklyReview();

  async aboutToAppear(): Promise<void> {
    try {
      this.weeklyReview = await this.homeStore.getWeeklyReview();
    } catch (e) {
      console.error('AchievementPage getWeeklyReview error: ' + e);
    }
  }

  build() {
    Scroll() {
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

        // 周复盘
        this.weeklyReviewSection()

        // 徽章列表
        Grid() {
          ForEach(AppConstants.ACHIEVEMENT_THRESHOLDS, (threshold: number) => {
            GridItem() {
              this.badgeItem(threshold)
            }
          }, (threshold: number) => threshold.toString())
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(18)
        .columnsGap(12)
        .padding(16)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  weeklyReviewSection() {
    Column() {
      Text($r('app.string.weekly_review_title'))
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ left: 16, top: 12 })

      if (this.weeklyReview.isAvailable) {
        Text(`本周完成率 ${this.weeklyReview.completionRate}%`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16, top: 4 })

        Text(this.weeklyReview.suggestion)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16, top: 4, bottom: 12 })
      } else {
        Text($r('app.string.weekly_review_insufficient'))
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
          .width('100%')
          .padding({ left: 16, top: 4, bottom: 12 })
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
  }

  @Builder
  badgeItem(threshold: number) {
    Column() {
      Image(this.getBadgeIcon(threshold))
        .width(76)
        .height(84)
        .objectFit(ImageFit.Contain)

      Text(`连续${threshold}天`)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private getBadgeIcon(threshold: number): Resource {
    const unlocked = isAchievementUnlocked(
      this.homeStore.consecutiveState.maxConsecutiveDays, threshold
    );
    const icon = getAchievementBadgeIcon(threshold, unlocked);
    return icon !== null ? icon : $r('app.media.ic_badge_3_off');
  }
}
