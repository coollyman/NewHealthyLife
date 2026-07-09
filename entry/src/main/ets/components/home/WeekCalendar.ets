import { HomeStore } from '../../viewmodel/HomeStore';
import { getDateOffset, getMondayOfWeek, parseDate } from '../../domain/utils/DateUtils';
import { AppConstants } from '../../domain/constants/AppConstants';

/**
 * 周视图组件，结构对齐 HealthyLife 原版 WeekCalendarComponent。
 */
@Component
export struct WeekCalendar {
  @Link homeStore: HomeStore;

  build() {
    Column() {
      Column() {
        Row() {
          this.arrowBuild($r('sys.symbol.chevron_left'), () => {
            this.homeStore.selectDate(getDateOffset(this.homeStore.selectedDate, -7));
          })

          Text(this.getDisplayDate())
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Regular)
            .padding({ left: 14, right: 14 })

          this.arrowBuild($r('sys.symbol.chevron_right'), () => {
            this.homeStore.selectDate(getDateOffset(this.homeStore.selectedDate, 7));
          })

          // 月视图入口图标
          Image($r('app.media.ic_month_view'))
            .width(20)
            .height(20)
            .margin({ left: 8 })
            .fillColor($r('app.color.text_secondary'))
            .onClick(() => {
              this.homeStore.openMonthView();
            })
        }

        Row() {
          ForEach(this.getCurrentWeekDates(), (date: string, index: number) => {
            this.dayOfWeekBuilder(date, index)
          }, (date: string) => date)
        }
        .width('100%')
        .height('50%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .borderRadius(26)
      .backgroundColor($r('app.color.bg_card'))
    }
    .width('100%')
    .height('42%')
    .padding('3.3%')
  }

  @Builder
  dayOfWeekBuilder(date: string, index: number) {
    Column() {
      Text(AppConstants.WEEK_SHORTHAND_LIST[index % 7])
        .fontSize(12)
        .fontColor(this.homeStore.selectedDate === date ? $r('app.color.text_font_color') : $r('app.color.text_secondary'))
        .fontWeight(FontWeight.Regular)

      Divider()
        .margin({ top: 2, bottom: 4 })
        .width(12)
        .color($r('app.color.text_font_color'))
        .visibility(this.homeStore.selectedDate === date ? Visibility.Visible : Visibility.Hidden)

      Image(this.getProgressImage(date))
        .height(28)
        .objectFit(ImageFit.Contain)
        .margin({ top: '8%' })
    }
    .width(`${100 / 7}%`)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (this.homeStore.selectedDate === date) {
        return;
      }
      this.homeStore.selectDate(date);
    })
  }

  @Builder
  arrowBuild(icon: Resource, click: () => void) {
    SymbolGlyph(icon)
      .fontSize(18)
      .fontColor([$r('app.color.text_secondary')])
      .onClick(() => {
        click();
      })
  }

  private getCurrentWeekDates(): string[] {
    const monday = getMondayOfWeek(this.homeStore.selectedDate);
    const dates: string[] = [];
    for (let i = 0; i < 7; i++) {
      dates.push(getDateOffset(monday, i));
    }
    return dates;
  }

  private getDisplayDate(): string {
    const date = parseDate(this.homeStore.selectedDate);
    const weekDays: string[] = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日${weekDays[date.getDay()]}`;
  }

  private getProgressImage(date: string): Resource {
    const status = this.homeStore.getCalendarDayStatus(date);
    if (status === 3) {
      return $r('app.media.ic_home_all_done');
    }
    if (status === 2) {
      return $r('app.media.ic_home_half_done');
    }
    return $r('app.media.ic_home_undone');
  }
}
