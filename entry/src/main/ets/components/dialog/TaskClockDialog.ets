import { DayTaskInfo } from '../../domain/models/DayTaskInfo';
import { TaskType } from '../../domain/constants/TaskCatalog';
import { getTaskDisplayMeta, getDialogIconResource } from '../../domain/constants/TaskDisplayMeta';
import { HomeStore } from '../../viewmodel/HomeStore';

/**
 * 打卡弹窗
 */
@CustomDialog
struct TaskClockDialog {
  dayTask: DayTaskInfo = new DayTaskInfo();
  homeStore: HomeStore = new HomeStore();
  onConfirm: () => void = () => {};
  controller: CustomDialogController = new CustomDialogController({ builder: undefined });

  build() {
    if (this.usesIconLayout()) {
      this.iconDialog()
    } else {
      this.backgroundDialog()
    }
  }

  @Builder
  backgroundDialog() {
    Column() {
      Text(this.getTaskName())
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 28 })

      Text(this.getProgressText())
        .fontSize(14)
        .fontColor('#E6FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 28 })
        .margin({ top: 6 })

      Button(this.getButtonText())
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.task_clock_bg_color'))
        .fontColor('#FFFFFF')
        .fontSize(20)
        .width(220)
        .height(48)
        .margin({ top: 20 })
        .onClick(() => {
          if (this.canContinueCheckin()) {
            this.onConfirm();
          }
          this.controller.close();
        })
    }
    .width(316)
    .height(451)
    .justifyContent(FlexAlign.End)
    .padding({ bottom: 18 })
    .backgroundImage(this.getDialogIcon(), ImageRepeat.NoRepeat)
    .backgroundImageSize({
      width: '100%',
      height: '100%'
    })
  }

  @Builder
  iconDialog() {
    Column() {
      Image(this.getDialogIcon())
        .width(132)
        .height(132)
        .objectFit(ImageFit.Contain)
        .margin({ bottom: 18 })

      Text(this.getTaskName())
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .textAlign(TextAlign.Center)

      Text(this.getProgressText())
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })

      Button(this.getButtonText())
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.text_font_color'))
        .fontColor('#FFFFFF')
        .fontSize(18)
        .width(220)
        .height(48)
        .margin({ top: 28 })
        .onClick(() => {
          if (this.canContinueCheckin()) {
            this.onConfirm();
          }
          this.controller.close();
        })
    }
    .width(316)
    .padding({ left: 24, right: 24, top: 36, bottom: 24 })
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(28)
  }

  private usesIconLayout(): boolean {
    const task = this.homeStore.allTasks.find(t => t.taskId === this.dayTask.taskId);
    if (!task) {
      return true;
    }
    const meta = getTaskDisplayMeta(task);
    return true;
  }

  private getDialogIcon(): Resource {
    const task = this.homeStore.allTasks.find(t => t.taskId === this.dayTask.taskId);
    if (!task) {
      return $r('app.media.ic_dialog_smile');
    }
    const meta = getTaskDisplayMeta(task);
    return getDialogIconResource(meta.iconKey);
  }

  private getTaskName(): string {
    const task = this.homeStore.allTasks.find(t => t.taskId === this.dayTask.taskId);
    if (!task) {
      return '';
    }
    const meta = getTaskDisplayMeta(task);
    if (meta.isPreset) {
      try {
        const resource = $r(`app.string.task_${this.getPresetTaskKey(this.dayTask.taskId)}`);
        return getContext(this).resourceManager.getStringSync(resource);
      } catch (e) {
        return meta.taskName;
      }
    }
    return meta.taskName;
  }

  private getPresetTaskKey(taskId: number): string {
    switch (taskId) {
      case 0: return 'getup';
      case 1: return 'drink';
      case 2: return 'apple';
      case 3: return 'smile';
      case 4: return 'brush';
      case 5: return 'sleep';
      case 6: return 'run';
      default: return '';
    }
  }

  private getProgressText(): string {
    const task = this.homeStore.allTasks.find(t => t.taskId === this.dayTask.taskId);
    if (!task) {
      return '';
    }
    const meta = getTaskDisplayMeta(task);

    if (meta.taskType === TaskType.VALUE) {
      const fin: number = parseFloat(this.dayTask.finValue) || 0;
      const target: number = parseFloat(this.dayTask.targetValue) || 0;
      const step: number = parseFloat(meta.step) || 0;
      return `当前: ${fin}/${target}，每次+${step}`;
    }
    return `目标: ${this.dayTask.targetValue}`;
  }

  private canContinueCheckin(): boolean {
    if (!this.dayTask.isDone) {
      return true;
    }
    const task = this.homeStore.allTasks.find(t => t.taskId === this.dayTask.taskId);
    if (!task) {
      return false;
    }
    const meta = getTaskDisplayMeta(task);
    return meta.taskType === TaskType.VALUE;
  }

  private getButtonText(): Resource {
    return this.canContinueCheckin() ? $r('app.string.clock_in') : $r('app.string.was_done');
  }
}

export { TaskClockDialog };
