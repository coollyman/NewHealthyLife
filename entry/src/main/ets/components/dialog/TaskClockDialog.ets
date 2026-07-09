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
      Image(this.getDialogIcon())
        .width(80)
        .height(80)
        .margin({ top: 24 })

      Text(this.getTaskName())
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 16 })

      Text(this.getProgressText())
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })

      Button($r('app.string.clock_in'))
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.text_font_color'))
        .fontColor('#FFFFFF')
        .width('60%')
        .height(40)
        .margin({ top: 24, bottom: 24 })
        .onClick(() => {
          this.onConfirm();
          this.controller.close();
        })
    }
    .width('80%')
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(16)
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
