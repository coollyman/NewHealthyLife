import { HomeStore } from '../../viewmodel/HomeStore';
import { DayTaskInfo } from '../../domain/models/DayTaskInfo';
import { getTaskCatalogItem, TaskType } from '../../domain/constants/TaskCatalog';
import { isToday } from '../../domain/utils/DateUtils';
import { TaskClockDialog } from '../dialog/TaskClockDialog';
import { promptAction, router } from '@kit.ArkUI';

export function buildDayTaskRenderKey(dayTask: DayTaskInfo): string {
  return `${dayTask.date}-${dayTask.taskId}-${dayTask.finValue}-${dayTask.isDone ? 1 : 0}`;
}

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
          .width(132)
          .height(100)
          .margin({ bottom: 8 })

        Text($r('app.string.no_task'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .margin({ top: 48 })
      .alignItems(HorizontalAlign.Center)
    } else {
      Column() {
        ForEach(this.homeStore.dayTasks, (dayTask: DayTaskInfo) => {
          this.taskItem(dayTask)
        }, (dayTask: DayTaskInfo) => buildDayTaskRenderKey(dayTask))
      }
      .width('100%')
      .padding({ top: '1.5%', left: 16, right: 16 })
    }
  }

  @Builder
  taskItem(dayTask: DayTaskInfo) {
    Row() {
      Image(this.getTaskIcon(dayTask.taskId))
        .width(36)
        .height(36)
        .objectFit(ImageFit.Contain)
        .margin({ right: 8 })

      Column() {
        Text(this.getTaskName(dayTask.taskId))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Regular)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (dayTask.isDone) {
        Text($r('app.string.was_done'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Regular)
      } else if (!isToday(this.homeStore.selectedDate)) {
        Text(this.getReadOnlyStatusText())
          .fontSize(16)
          .fontColor($r('app.color.text_hint'))
      } else {
        Text(this.getTaskProgress(dayTask))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
      }
    }
    .width('100%')
    .height(62)
    .padding({ left: '5%', right: '5%' })
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(16)
    .margin({ bottom: 12 })
    .onClick(() => {
      if (isToday(this.homeStore.selectedDate)) {
        this.selectedTask = dayTask;
        this.openDialog();
      }
    })
    .gesture(LongPressGesture().onAction(() => {
      if (isToday(this.homeStore.selectedDate)) {
        router.pushUrl({
          url: 'pages/EditTaskPage',
          params: { taskId: dayTask.taskId }
        });
      }
    }))
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
      return `${fin > 0 ? fin : '--'} / ${target} ${this.getUnitText(item.unit)}`;
    }
    return `${dayTask.finValue || '--'} / ${dayTask.targetValue} ${this.getUnitText(item.unit)}`;
  }

  private getUnitText(unit: Resource): string {
    try {
      return getContext(this).resourceManager.getStringSync(unit);
    } catch (e) {
      return '';
    }
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
    this.selectedTask = null;
    const unlocked = this.homeStore.popNewlyUnlockedAchievement();
    if (unlocked !== null) {
      promptAction.showToast({ message: `连续打卡${unlocked}天成就已解锁` });
    }
  }
}
