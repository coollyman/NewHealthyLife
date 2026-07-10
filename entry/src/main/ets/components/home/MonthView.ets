import { HomeStore } from '../../viewmodel/HomeStore';
import { getMonthGrid, getDayOfMonth, getYearMonth, parseDate } from '../../domain/utils/DateUtils';
import { AppConstants } from '../../domain/constants/AppConstants';

/**
 * 月视图组件
 * 支持跨月浏览：用户可切换上一月/下一月查看历史完成情况
 * 浏览月份不会改变首页 selectedDate，仅当点击日期时才选中并返回
 * 完成状态视觉区分：全部完成(实心蓝)、部分完成(实心橙)、未完成(实心红)、无记录(透明圆环)
 */
@Component
export struct MonthView {
  @Link homeStore: HomeStore;

  build() {
    Column() {
      // 顶部：取消按钮 + 上一月箭头 + 月份标题 + 下一月箭头
      Row() {
        Text($r('app.string.month_view_cancel'))
          .fontSize(16)
          .fontColor($r('app.color.text_font_color'))
          .onClick(() => {
            this.homeStore.closeMonthView();
          })

        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(20)
            .fontColor([$r('app.color.text_secondary')])
            .opacity(this.homeStore.isMonthLoading ? 0.4 : 1)
            .onClick(() => {
              this.homeStore.loadPreviousMonth();
            })

          Text(this.getMonthTitle())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 16, right: 16 })

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor([$r('app.color.text_secondary')])
            .opacity(this.homeStore.isMonthLoading ? 0.4 : 1)
            .onClick(() => {
              this.homeStore.loadNextMonth();
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        // 右侧占位，与取消按钮对称
        Text($r('app.string.month_view_cancel'))
          .fontSize(16)
          .fontColor($r('app.color.bg_card'))
          .visibility(Visibility.Hidden)
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

      // 完成状态标识
      this.statusIndicator(date)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.homeStore.selectDateFromMonthView(date);
    })
  }

  /**
   * 完成状态指示器：
   * - 全部完成：实心圆 + 蓝色，尺寸较大
   * - 补救完成：实心圆 + 蓝色描边
   * - 部分完成：实心圆 + 橙色
   * - 未完成：实心圆 + 红色
   * - 无记录：空心圆环 + 浅灰色
   */
  @Builder
  statusIndicator(date: string) {
    if (this.getStatus(date) === 3) {
      // 全部完成 - 实心蓝色，尺寸较大
      Row()
        .width(10)
        .height(10)
        .borderRadius(5)
        .backgroundColor($r('app.color.status_all_done'))
    } else if (this.getStatus(date) === 4) {
      // 补救完成 - 实心蓝色 + 蓝色描边（带星标感）
      Row()
        .width(10)
        .height(10)
        .borderRadius(5)
        .backgroundColor($r('app.color.status_all_done'))
        .border({ width: 2, color: $r('app.color.text_font_color') })
    } else if (this.getStatus(date) === 2) {
      // 部分完成 - 实心橙色
      Row()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor($r('app.color.status_partial_done'))
    } else if (this.getStatus(date) === 1) {
      // 未完成 - 实心红色
      Row()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor($r('app.color.status_not_done'))
    } else {
      // 无记录 - 空心圆环
      Row()
        .width(8)
        .height(8)
        .borderRadius(4)
        .border({ width: 1, color: $r('app.color.status_no_record') })
    }
  }

  private getMonthDates(): string[] {
    return getMonthGrid(this.homeStore.monthViewDate);
  }

  private getMonthTitle(): string {
    const date = parseDate(this.homeStore.monthViewDate);
    return `${date.getFullYear()}年${date.getMonth() + 1}月`;
  }

  private isCurrentMonth(date: string): boolean {
    return getYearMonth(date) === getYearMonth(this.homeStore.monthViewDate);
  }

  private isSelected(date: string): boolean {
    return date === this.homeStore.selectedDate;
  }

  private getStatus(date: string): number {
    return this.homeStore.monthViewData.get(date) ?? 0;
  }
}
