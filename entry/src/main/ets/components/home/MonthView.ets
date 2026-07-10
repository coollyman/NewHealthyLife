import { HomeStore } from '../../viewmodel/HomeStore';
import { getMonthGrid, getDayOfMonth, getYearMonth, parseDate } from '../../domain/utils/DateUtils';
import { AppConstants } from '../../domain/constants/AppConstants';

/**
 * 月视图组件
 * 支持跨月浏览：用户可切换上一月/下一月查看历史完成情况
 * 浏览月份不会改变首页 selectedDate，仅当点击日期时才选中并返回
 * 完成状态视觉区分：复用首页周历的完成状态勋章
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
        .margin({ bottom: 2 })

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
   * - 全部完成/补救完成：金色完成勋章
   * - 部分完成：半完成勋章
   * - 未完成：未完成勋章
   * - 无记录：留空
   */
  @Builder
  statusIndicator(date: string) {
    if (this.getStatus(date) === 3 || this.getStatus(date) === 4) {
      Image($r('app.media.ic_home_all_done'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    } else if (this.getStatus(date) === 2) {
      Image($r('app.media.ic_home_half_done'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    } else if (this.getStatus(date) === 1) {
      Image($r('app.media.ic_home_undone'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    } else {
      Blank()
        .width(24)
        .height(24)
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
