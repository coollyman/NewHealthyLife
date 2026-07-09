import { DayTaskInfo } from '../../domain/models/DayTaskInfo';
import { getTaskCatalogItem, TaskType } from '../../domain/constants/TaskCatalog';

/**
 * 打卡弹窗
 */
@CustomDialog
struct TaskClockDialog {
  dayTask: DayTaskInfo = new DayTaskInfo();
  onConfirm: () => void = () => {};
  controller: CustomDialogController = new CustomDialogController({ builder: undefined });

  build() {
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

      Button(this.dayTask.isDone ? $r('app.string.was_done') : $r('app.string.clock_in'))
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.task_clock_bg_color'))
        .fontColor('#FFFFFF')
        .fontSize(20)
        .width(220)
        .height(48)
        .margin({ top: 20 })
        .onClick(() => {
          if (!this.dayTask.isDone) {
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

  private getDialogIcon(): Resource {
    const item = getTaskCatalogItem(this.dayTask.taskId);
    return item ? item.dialogIcon : $r('app.media.ic_dialog_smile');
  }

  private getTaskName(): string {
    const item = getTaskCatalogItem(this.dayTask.taskId);
    if (!item) return '';
    return getContext(this).resourceManager.getStringSync(item.name);
  }

  private getProgressText(): string {
    const item = getTaskCatalogItem(this.dayTask.taskId);
    if (!item) return '';

    if (item.type === TaskType.VALUE) {
      const fin: number = parseFloat(this.dayTask.finValue) || 0;
      const target: number = parseFloat(this.dayTask.targetValue) || 0;
      const step: number = parseFloat(item.step) || 0;
      return `当前: ${fin}/${target}，每次+${step}`;
    }
    return `目标: ${this.dayTask.targetValue}`;
  }
}

export { TaskClockDialog };
