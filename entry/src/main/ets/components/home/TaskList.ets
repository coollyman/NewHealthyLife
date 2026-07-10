import { HomeStore } from '../../viewmodel/HomeStore';
import { DayTaskInfo } from '../../domain/models/DayTaskInfo';
import { TaskType } from '../../domain/constants/TaskCatalog';
import { getTaskDisplayMeta, getIconResource, getTaskNameString } from '../../domain/constants/TaskDisplayMeta';
import { isToday } from '../../domain/utils/DateUtils';
import { TaskClockDialog } from '../dialog/TaskClockDialog';
import { AchievementUnlockDialog } from '../dialog/AchievementUnlockDialog';
import { router } from '@kit.ArkUI';

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
  private achievementDialogController: CustomDialogController | null = null;

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
    Column() {
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

        if (dayTask.isDone && !this.isNumericTask(dayTask.taskId)) {
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
      .height(44)
      .alignItems(VerticalAlign.Center)

      this.progressBar(dayTask)
    }
    .width('100%')
    .height(70)
    .padding({ left: '5%', right: '5%' })
    .justifyContent(FlexAlign.Center)
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

  @Builder
  progressBar(dayTask: DayTaskInfo) {
    Row() {
      if (this.getProgressPercent(dayTask) > 0) {
        Row()
          .width(`${this.getProgressPercent(dayTask)}%`)
          .height('100%')
          .borderRadius(4)
          .backgroundColor(this.getProgressColor(dayTask))
      }
    }
    .width('100%')
    .height(8)
    .borderRadius(4)
    .clip(true)
    .backgroundColor($r('app.color.task_progress_track'))
    .margin({ top: 8 })
  }

  private getTaskIcon(taskId: number): Resource {
    const task = this.homeStore.allTasks.find(t => t.taskId === taskId);
    if (!task) {
      return $r('app.media.ic_task_smile');
    }
    const meta = getTaskDisplayMeta(task);
    return getIconResource(meta.iconKey);
  }

  private getTaskName(taskId: number): string {
    const task = this.homeStore.allTasks.find(t => t.taskId === taskId);
    if (!task) {
      return '';
    }
    const meta = getTaskDisplayMeta(task);
    if (meta.isPreset) {
      // 预设任务：getTaskNameString 返回 string key 如 'task_drink'
      try {
        const key = getTaskNameString(task);
        const resource = $r(`app.string.${key}`);
        return getContext(this).resourceManager.getStringSync(resource);
      } catch (e) {
        return meta.taskName;
      }
    }
    // 自定义任务：直接返回 taskName 字符串
    return meta.taskName;
  }

  private getTaskProgress(dayTask: DayTaskInfo): string {
    const task = this.homeStore.allTasks.find(t => t.taskId === dayTask.taskId);
    if (!task) {
      return '';
    }
    const meta = getTaskDisplayMeta(task);

    if (dayTask.isDone) {
      return '已完成';
    }

    if (meta.taskType === TaskType.VALUE) {
      const fin = parseFloat(dayTask.finValue) || 0;
      const target = parseFloat(dayTask.targetValue) || 0;
      return `${fin > 0 ? fin : '--'} / ${target} ${meta.unitText}`;
    }
    return `${dayTask.finValue || '--'} / ${dayTask.targetValue} ${meta.unitText}`;
  }

  private isNumericTask(taskId: number): boolean {
    const task = this.homeStore.allTasks.find(t => t.taskId === taskId);
    if (!task) {
      return false;
    }
    return getTaskDisplayMeta(task).taskType === TaskType.VALUE;
  }

  private getProgressPercent(dayTask: DayTaskInfo): number {
    if (dayTask.isDone) {
      return 100;
    }

    const task = this.homeStore.allTasks.find(t => t.taskId === dayTask.taskId);
    if (!task) {
      return 0;
    }
    const meta = getTaskDisplayMeta(task);
    if (meta.taskType !== TaskType.VALUE) {
      return 0;
    }

    const fin = parseFloat(dayTask.finValue) || 0;
    const target = parseFloat(dayTask.targetValue) || 1;
    if (target <= 0) {
      return 0;
    }

    const pct = Math.round(fin / target * 100);
    return Math.max(0, Math.min(100, pct));
  }

  private getProgressColor(dayTask: DayTaskInfo): Resource {
    if (dayTask.isDone) {
      return $r('app.color.task_progress_done');
    }
    return $r('app.color.task_progress_active');
  }

  private getReadOnlyStatusText(): Resource {
    return isToday(this.homeStore.selectedDate) ? $r('app.string.clock_in') : $r('app.string.not_done');
  }

  private openDialog() {
    if (this.selectedTask) {
      this.dialogController = new CustomDialogController({
        builder: TaskClockDialog({
          dayTask: this.selectedTask!,
          homeStore: this.homeStore,
          onConfirm: () => {
            this.handleCheckin();
          },
          onUndo: () => {
            this.handleUndoCheckin();
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
      this.openAchievementDialog(unlocked);
    }
  }

  private async handleUndoCheckin(): Promise<void> {
    if (!this.selectedTask) {
      return;
    }
    const undone = await this.homeStore.undoCheckin(this.selectedTask.id);
    if (!undone) {
      return;
    }
    this.selectedTask = null;
  }

  private openAchievementDialog(threshold: number): void {
    this.achievementDialogController = new CustomDialogController({
      builder: AchievementUnlockDialog({
        threshold: threshold,
        onClose: () => {
          this.achievementDialogController?.close();
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.achievementDialogController.open();
  }
}
