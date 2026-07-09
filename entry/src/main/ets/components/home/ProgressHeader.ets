import { HomeStore } from '../../viewmodel/HomeStore';
import { WeekCalendar } from './WeekCalendar';

/**
 * 首页顶部进度展示
 */
@Component
export struct ProgressHeader {
  @Link homeStore: HomeStore;

  build() {
    Column() {
      Text($r('app.string.target_progress'))
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .fontWeight(FontWeight.Regular)
        .width('100%')
        .padding({ left: 24 })

      Row() {
        Text(`${this.homeStore.getPercentage()}`)
          .fontSize(72)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Bold)

        Text('%')
          .fontSize(40)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Regular)
          .width('100%')
          .margin({ top: 12, left: 8 })
      }
      .width('100%')
      .padding({ left: 24 })

      WeekCalendar({ homeStore: this.homeStore })
    }
    .width('100%')
    .height(451)
    .backgroundImage($r('app.media.ic_home_bg'))
    .backgroundImagePosition({ x: 0, y: 0 })
    .backgroundImageSize({
      width: '100%',
      height: '90%'
    })
    .justifyContent(FlexAlign.End)
  }
}
