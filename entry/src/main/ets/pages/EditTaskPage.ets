import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HomeStore, isHomeStoreDataReady } from '../viewmodel/HomeStore';
import { TaskInfo } from '../domain/models/TaskInfo';
import { getTaskCatalogItem, PickerType, TaskType } from '../domain/constants/TaskCatalog';

/**
 * 编辑任务页
 */
@Entry
@Component
struct EditTaskPage {
  @StorageLink('homeStore') homeStore: HomeStore = new HomeStore();
  @State task: TaskInfo = new TaskInfo();
  @State isOpen: boolean = false;
  @State targetValue: string = '';
  @State pickerRange: string[] = [];
  @State pickerSelected: number = 0;
  @State pickerType: PickerType = PickerType.NONE;
  @State isTimeTask: boolean = false;
  private taskId: number = 0;

  async aboutToAppear(): Promise<void> {
    await this.ensureHomeStoreReady();

    const params = router.getParams() as Record<string, number>;
    this.taskId = params?.taskId ?? 0;

    const found = (this.homeStore?.allTasks ?? []).find(t => t.taskId === this.taskId);
    if (found) {
      this.task = found.deepClone();
      this.isOpen = found.isOpen;
      this.targetValue = found.targetValue;
    }

    const catalog = getTaskCatalogItem(this.taskId);
    if (catalog) {
      this.pickerType = catalog.pickerType;
      this.pickerRange = catalog.pickerRange;
      this.isTimeTask = catalog.type === TaskType.TIME;
      const idx = this.pickerRange.indexOf(this.targetValue);
      this.pickerSelected = idx >= 0 ? idx : 0;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.text_primary')])
          .onClick(() => {
            router.back();
          })

        Text($r('app.string.edit_task'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      // 启用开关
      Row() {
        Text($r('app.string.task_opened'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.isOpen })
          .selectedColor($r('app.color.text_font_color'))
          .onChange((on: boolean) => {
            this.isOpen = on;
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.bg_card'))
      .margin({ bottom: 8 })

      // 目标设置
      if (this.pickerType !== PickerType.NONE) {
        Column() {
          // 标题
          Row() {
            Text($r('app.string.target_setting'))
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')
          .height(48)
          .padding({ left: 16 })

          // 选择器
          if (this.pickerType === PickerType.TEXT && this.pickerRange.length > 0) {
            TextPicker({ range: this.pickerRange, selected: this.pickerSelected })
              .onChange((value: string | string[], index: number | number[]) => {
                this.targetValue = Array.isArray(value) ? value[0] : value;
                this.pickerSelected = Array.isArray(index) ? index[0] : index;
              })
              .width('90%')
              .height(160)
          }

          if (this.pickerType === PickerType.TIME) {
            TimePicker({
              selected: this.parseTime(this.targetValue)
            })
              .onChange((value: TimePickerResult) => {
                this.targetValue = this.formatTime(value);
              })
              .width('90%')
              .height(160)
          }
        }
        .width('100%')
        .backgroundColor($r('app.color.bg_card'))
        .margin({ bottom: 8 })
      }

      // 完成按钮
      Button($r('app.string.complete'))
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.text_font_color'))
        .fontColor('#FFFFFF')
        .width('90%')
        .height(44)
        .margin({ top: 24 })
        .onClick(() => {
          this.onComplete();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  private async onComplete() {
    // 更新目标值
    if (this.targetValue !== this.task.targetValue) {
      await this.homeStore.updateTaskTarget(this.taskId, this.targetValue);
    }

    // 启用/停用
    if (this.isOpen && !this.task.isOpen) {
      await this.homeStore.enableTask(this.taskId);
    } else if (!this.isOpen && this.task.isOpen) {
      await this.homeStore.disableTask(this.taskId);
    }

    promptAction.showToast({ message: '保存成功' });
    router.back();
  }

  private parseTime(timeStr: string): Date {
    const parts: number[] = timeStr.split(':').map((s: string) => parseInt(s, 10));
    const date = new Date();
    date.setHours(parts[0] || 8, parts[1] || 0, 0, 0);
    return date;
  }

  private formatTime(value: TimePickerResult): string {
    const h = String(value.hour).padStart(2, '0');
    const m = String(value.minute).padStart(2, '0');
    return `${h}:${m}`;
  }

  private async ensureHomeStoreReady(): Promise<void> {
    if (isHomeStoreDataReady(this.homeStore?.allTasks)) {
      return;
    }
    const stored = AppStorage.get<HomeStore>('homeStore');
    if (stored && isHomeStoreDataReady(stored.allTasks)) {
      this.homeStore = stored;
      return;
    }
    await this.homeStore.initAppData();
    AppStorage.setOrCreate<HomeStore>('homeStore', this.homeStore);
  }
}

export { EditTaskPage };
