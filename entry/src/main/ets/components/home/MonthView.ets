import { HomeStore } from '../../viewmodel/HomeStore';
import { getMonthGrid, getDayOfMonth, getYearMonth, parseDate } from '../../domain/utils/DateUtils';
import { AppConstants } from '../../domain/constants/AppConstants';

/**
 * 月视图组件
 * 按当前选中月份展示日期网格
 * 每个日期使用完成状态语义：无记录/未完成/部分完成/全部完成
 * 点击日期选中该日并返回任务主界面
 */
@Component
export struct MonthView {
  @Link homeStore: HomeStore;

  build() {
    Column() {
      // 顶部：取消按钮 + 月份标题 + 空白
      Row() {
        Text($r('app.string.month_view_cancel'))
          .fontSize(16)
          .fontColor($r('app.color.text_font_color'))
          .onClick(() => {
            this.homeStore.closeMonthView();
          })

        Text(this.getMonthTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      // 星期标题行
      Row() {
        ForEach(AppConstants.WEEK_SHORTHAND_LIST, (label: Resource, index: number) => {
          Text(label)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width(`${100 / 7}%`)
            .textAlign(TextAlign.Center)
        }, (label: Resource, index: number) => `${index}`)
      }
      .width('100%')
      .height(32)

      // 日期网格（6 行 × 7 列）
      Grid() {
        ForEach(this.getMonthDates(), (date: string, index: number) => {
          GridItem() {
            this.dateCell(date)
          }
        }, (date: string, index: number) => `${date}-${index}`)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 8, right: 8, bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  dateCell(date: string) {
    Column() {
      Text(getDayOfMonth(date).toString())
        .fontSize(16)
        .fontColor(this.isCurrentMonth(date) ? $r('app.color.text_primary') : $r('app.color.text_hint'))
        .fontWeight(this.isSelected(date) ? FontWeight.Bold : FontWeight.Regular)
        .margin({ bottom: 4 })

      // 完成状态圆点
      Row()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(this.getStatusColor(date))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.homeStore.selectDateFromMonthView(date);
    })
  }

  private getMonthDates(): string[] {
    return getMonthGrid(this.homeStore.selectedDate);
  }

  private getMonthTitle(): string {
    const date = parseDate(this.homeStore.selectedDate);
    return `${date.getFullYear()}年${date.getMonth() + 1}月`;
  }

  private isCurrentMonth(date: string): boolean {
    return getYearMonth(date) === getYearMonth(this.homeStore.selectedDate);
  }

  private isSelected(date: string): boolean {
    return date === this.homeStore.selectedDate;
  }

  private getStatusColor(date: string): Resource {
    const status = this.homeStore.monthViewData.get(date) ?? 0;
    switch (status) {
      case 3: return $r('app.color.text_font_color'); // 全部完成 - 蓝色
      case 2: return $r('app.color.text_font_color'); // 部分完成 - 蓝色（半透明感由小圆点传达）
      case 1: return $r('app.color.button_red');      // 未完成 - 红色
      default: return $r('app.color.bg_page');        // 无记录 - 灰色
    }
  }
}
