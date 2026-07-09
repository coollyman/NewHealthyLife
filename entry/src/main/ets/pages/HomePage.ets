import { HomeStore } from '../viewmodel/HomeStore';
import { WeekCalendar } from '../components/home/WeekCalendar';
import { TaskList } from '../components/home/TaskList';
import { ProgressHeader } from '../components/home/ProgressHeader';
import { getToday } from '../domain/utils/DateUtils';
import { router } from '@kit.ArkUI';

/**
 * 首页
 */
@Component
export struct HomePage {
  @Link homeStore: HomeStore;

  build() {
    Column() {
      // 顶部进度
      ProgressHeader({ homeStore: this.homeStore })

      // 三周日历
      WeekCalendar({ homeStore: this.homeStore })

      // 任务列表
      TaskList({ homeStore: this.homeStore })

      // 底部添加按钮
      Row() {
        Button() {
          Row() {
            Image($r('app.media.ic_home_add'))
              .width(20)
              .height(20)
              .fillColor('#FFFFFF')
            Text($r('app.string.add_task'))
              .fontColor('#FFFFFF')
              .fontSize(14)
              .margin({ left: 8 })
          }
        }
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.text_font_color'))
        .width('60%')
        .height(40)
        .onClick(() => {
          router.pushUrl({ url: 'pages/AddTaskPage' });
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 8, bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
