import { HomeStore } from '../../viewmodel/HomeStore';
import { DayTaskInfo } from '../../domain/models/DayTaskInfo';
import { getTaskCatalogItem } from '../../domain/constants/TaskCatalog';

/**
 * 选中日期的子任务进度条列表
 * 展示每个任务的 finValue / targetValue 进度
 */
@Component
export struct DailyTaskProgress {
  @Link homeStore: HomeStore;

  build() {
    if (this.homeStore.dayTasks.length === 0) {
      Column() {
        Text('暂无任务记录')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .alignItems(HorizontalAlign.Center)
    } else {
      Column() {
        ForEach(this.homeStore.dayTasks, (dayTask: DayTaskInfo) => {
          this.progressItem(dayTask)
        }, (dayTask: DayTaskInfo) => `${dayTask.date}-${dayTask.taskId}-${dayTask.finValue}-${dayTask.isDone ? 1 : 0}`)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })
    }
  }

  @Builder
  progressItem(dayTask: DayTaskInfo) {
    Row() {
      // 任务图标
      Image(this.getTaskIcon(dayTask.taskId))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .margin({ right: 8 })

      // 任务名 + 进度条
      Column() {
        Row() {
          Text(this.getTaskName(dayTask.taskId))
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)

          Text(this.getProgressText(dayTask))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ bottom: 4 })

        // 进度条
        Row() {
          // 已完成部分
          Row()
            .width(`${this.getProgressPercent(dayTask)}%`)
            .height(6)
            .backgroundColor(dayTask.isDone ? $r('app.color.text_font_color') : $r('app.color.text_font_color'))
            .borderRadius(3)

          // 剩余部分
          Row()
            .layoutWeight(1)
            .height(6)
            .backgroundColor($r('app.color.bg_page'))
            .borderRadius(3)
        }
        .width('100%')
        .height(6)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  private getTaskIcon(taskId: number): Resource {
    const item = getTaskCatalogItem(taskId);
    return item ? item.icon : $r('app.media.ic_task_smile');
  }

  private getTaskName(taskId: number): string {
    const item = getTaskCatalogItem(taskId);
    if (!item) return '';
    try {
      return getContext(this).resourceManager.getStringSync(item.name);
    } catch (e) {
      return '';
    }
  }

  private getProgressText(dayTask: DayTaskInfo): string {
    if (dayTask.isDone) return '已完成';
    return `${dayTask.finValue || '0'} / ${dayTask.targetValue}`;
  }

  private getProgressPercent(dayTask: DayTaskInfo): number {
    if (dayTask.isDone) return 100;
    const fin = parseFloat(dayTask.finValue) || 0;
    const target = parseFloat(dayTask.targetValue) || 1;
    if (target === 0) return 100;
    const pct = Math.round((fin / target) * 100);
    return pct > 100 ? 100 : pct;
  }
}
