import { HomeStore } from '../../viewmodel/HomeStore';
import { getToday, isToday, getDayOfMonth } from '../../domain/utils/DateUtils';

/**
 * 首页顶部进度展示
 */
@Component
export struct ProgressHeader {
  @Link homeStore: HomeStore;

  build() {
    Row() {
      // 左侧进度图片
      Column() {
        Image(this.getProgressImage())
          .width(80)
          .height(80)
        Text(`${this.homeStore.dayInfo.finTaskNum}/${this.homeStore.dayInfo.targetTaskNum}`)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .margin({ top: 4 })
      }
      .width('30%')
      .justifyContent(FlexAlign.Center)

      // 右侧进度信息
      Column() {
        Text($r('app.string.today_progress'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))

        Row() {
          Text(`${this.homeStore.getPercentage()}%`)
            .fontSize(36)
            .fontColor($r('app.color.text_font_color'))
            .fontWeight(FontWeight.Bold)
        }
        .margin({ top: 4 })

        Row() {
          Text($r('app.string.consecutive_days'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(`${this.homeStore.consecutiveState.currentConsecutiveDays}`)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })
    }
    .width('100%')
    .height(120)
    .padding(16)
    .backgroundColor($r('app.color.bg_card'))
  }

  private getProgressImage(): Resource {
    const dayInfo = this.homeStore.dayInfo;
    if (dayInfo.finTaskNum === 0 || dayInfo.targetTaskNum === 0) {
      return $r('app.media.ic_home_undone');
    }
    if (dayInfo.finTaskNum < dayInfo.targetTaskNum) {
      return $r('app.media.ic_home_half_done');
    }
    return $r('app.media.ic_home_all_done');
  }
}
