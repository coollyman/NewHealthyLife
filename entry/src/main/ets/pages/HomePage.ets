import { HomeStore } from '../viewmodel/HomeStore';
import { TaskList } from '../components/home/TaskList';
import { ProgressHeader } from '../components/home/ProgressHeader';
import { MonthView } from '../components/home/MonthView';
import { router } from '@kit.ArkUI';

/**
 * 首页
 */
@Component
export struct HomePage {
  @Link homeStore: HomeStore;

  build() {
    Stack() {
      Scroll() {
        Column() {
          Text($r('app.string.healthy_life'))
            .fontSize(24)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .height(56)
            .padding({ left: '6.6%' })
            .position({ x: 0, y: 48 })
            .zIndex(1)

          ProgressHeader({ homeStore: this.homeStore })

          Text($r('app.string.task_list'))
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ top: 24, bottom: 8, left: 16 })

          TaskList({ homeStore: this.homeStore })
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.ic_home_add'))
          .borderRadius('50%')
      }
      .width(48)
      .height(48)
      .position({ x: '44%', y: '90%' })
      .zIndex(1)
      .onClick(() => {
        router.pushUrl({ url: 'pages/AddTaskPage' });
      })

      // 月视图覆盖层
      if (this.homeStore.isMonthView) {
        Column() {
          MonthView({ homeStore: this.homeStore })
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.bg_card'))
        .zIndex(2)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
