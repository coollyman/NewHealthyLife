import { HomeStore } from '../../viewmodel/HomeStore';
import { getThreeWeekWindow, isToday, getDayOfMonth, getDayOfWeek, compareDate, getToday } from '../../domain/utils/DateUtils';
import { AppConstants } from '../../domain/constants/AppConstants';

/**
 * 三周日历组件
 */
@Component
export struct WeekCalendar {
  @Link homeStore: HomeStore;

  build() {
    Column() {
      // 星期标题
      Row() {
        ForEach(AppConstants.WEEK_SHORTHAND_LIST, (day: Resource) => {
          Text(day)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })

      // 21天日期 - 横向滚动
      Scroll() {
        Row() {
          ForEach(getThreeWeekWindow(this.homeStore.selectedDate), (date: string) => {
            this.dateCell(date)
          }, (date: string) => date)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(56)
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(12)
    .margin({ left: 12, right: 12, bottom: 8 })
    .padding(8)
  }

  @Builder
  dateCell(date: string) {
    Column() {
      Text(`${getDayOfMonth(date)}`)
        .fontSize(16)
        .fontColor(this.getDateColor(date))
        .fontWeight(this.homeStore.selectedDate === date ? FontWeight.Bold : FontWeight.Normal)

      // 选中标记
      if (this.homeStore.selectedDate === date) {
        Circle()
          .width(4)
          .height(4)
          .fill($r('app.color.text_font_color'))
          .margin({ top: 2 })
      }
    }
    .width(40)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(8)
    .backgroundColor(this.homeStore.selectedDate === date ? $r('app.color.user_level_bg_color') : Color.Transparent)
    .onClick(() => {
      this.homeStore.selectDate(date);
    })
  }

  private getDateColor(date: string): ResourceColor {
    if (isToday(date)) {
      return $r('app.color.text_font_color');
    }
    if (compareDate(date, getToday()) > 0) {
      return $r('app.color.text_hint'); // 未来日期
    }
    return $r('app.color.text_primary');
  }
}
