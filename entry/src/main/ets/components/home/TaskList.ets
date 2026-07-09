import { HomeStore } from '../../viewmodel/HomeStore';
import { DayTaskInfo } from '../../domain/models/DayTaskInfo';
import { getTaskCatalogItem, TaskType } from '../../domain/constants/TaskCatalog';
import { isToday } from '../../domain/utils/DateUtils';
import { TaskClockDialog } from '../dialog/TaskClockDialog';
import { resourceManager } from '@kit.LocalizationKit';
import { promptAction } from '@kit.ArkUI';

/**
 * 任务列表组件
 */
@Component
export struct TaskList {
  @Link homeStore: HomeStore;
  @State selectedTask: DayTaskInfo | null = null;
  private dialogController: CustomDialogController | null = null;

  build() {
    if (this.homeStore.dayTasks.length === 0) {
      Column() {
        Image($r('app.media.ic_no_data'))
          .width(120)
          .height(120)
        Text($r('app.string.no_task'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 12 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List({ space: 8 }) {
        ForEach(this.homeStore.dayTasks, (dayTask: DayTaskInfo) => {
          ListItem() {
            this.taskItem(dayTask)
          }
        }, (dayTask: DayTaskInfo) => `${dayTask.date}-${dayTask.taskId}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12 })
      .scrollBar(BarState.Off)
    }
  }

  @Builder
  taskItem(dayTask: DayTaskInfo) {
    Row() {
      Image(this.getTaskIcon(dayTask.taskId))
        .width(40)
        .height(40)

      Column() {
        Text(this.getTaskName(dayTask.taskId))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)

        Text(this.getTaskProgress(dayTask))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })

      if (dayTask.isDone) {
        Text($r('app.string.was_done'))
          .fontSize(12)
          .fontColor($r('app.color.text_hint'))
      } else if (!isToday(this.homeStore.selectedDate)) {
        Text(this.getReadOnlyStatusText())
          .fontSize(12)
          .fontColor($r('app.color.text_hint'))
      } else {
        Text($r('app.string.clock_in'))
          .fontSize(12)
          .fontColor($r('app.color.text_font_color'))
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor($r('app.color.user_level_bg_color'))
      }
    }
    .width('100%')
    .height(64)
    .padding(12)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(12)
    .onClick(() => {
      if (!dayTask.isDone && isToday(this.homeStore.selectedDate)) {
        this.selectedTask = dayTask;
        this.openDialog();
      }
    })
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

  private getTaskProgress(dayTask: DayTaskInfo): string {
    const item = getTaskCatalogItem(dayTask.taskId);
    if (!item) return '';

    if (dayTask.isDone) {
      return '已完成';
    }

    if (item.type === TaskType.VALUE) {
      const fin = parseFloat(dayTask.finValue) || 0;
      const target = parseFloat(dayTask.targetValue) || 0;
      return `${fin}/${target}`;
    }
    return dayTask.targetValue;
  }

  private getReadOnlyStatusText(): Resource {
    return isToday(this.homeStore.selectedDate) ? $r('app.string.clock_in') : $r('app.string.not_done');
  }

  private openDialog() {
    if (this.selectedTask) {
      this.dialogController = new CustomDialogController({
        builder: TaskClockDialog({
          dayTask: this.selectedTask!,
          onConfirm: () => {
            this.handleCheckin();
          }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center
      });
      this.dialogController.open();
    }
  }

  private async handleCheckin(): Promise<void> {
    if (!this.selectedTask) {
      return;
    }
    const checked = await this.homeStore.checkin(this.selectedTask.id);
    if (!checked) {
      return;
    }
    const unlocked = this.homeStore.popNewlyUnlockedAchievement();
    if (unlocked !== null) {
      promptAction.showToast({ message: `连续打卡${unlocked}天成就已解锁` });
    }
  }
}
