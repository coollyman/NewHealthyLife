import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HomeStore, isHomeStoreDataReady } from '../viewmodel/HomeStore';
import { TaskInfo } from '../domain/models/TaskInfo';
import { getTaskCatalogItem, PickerType, TaskType } from '../domain/constants/TaskCatalog';
import { GoalSuggestionCard } from '../components/home/GoalSuggestionCard';
import { GoalSuggestion, GoalSuggestionType } from '../domain/rules/GoalSuggestionRules';

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
  @State isRunTask: boolean = false;
  @State isAlert: boolean = false;
  @State alertStartTime: string = '08:00';
  @State alertFrequency: string = '1,2,3,4,5,6,7';
  @State selectedWeekDays: boolean[] = [true, true, true, true, true, true, true];
  @State goalSuggestion: GoalSuggestion = new GoalSuggestion();
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
      this.isAlert = found.isAlert;
      this.alertStartTime = found.alertStartTime || '08:00';
      this.alertFrequency = found.alertFrequency || '1,2,3,4,5,6,7';
      this.parseAlertFrequencyToSelected();
    }

    const catalog = getTaskCatalogItem(this.taskId);
    if (catalog) {
      this.pickerType = catalog.pickerType;
      this.pickerRange = catalog.pickerRange;
      this.isTimeTask = catalog.type === TaskType.TIME;
      this.isRunTask = this.taskId === 6;
      const idx = this.pickerRange.indexOf(this.targetValue);
      this.pickerSelected = idx >= 0 ? idx : 0;
    }

    // 加载目标建议（仅数值类任务）
    if (this.pickerType === PickerType.TEXT && this.pickerRange.length > 1) {
      try {
        this.goalSuggestion = await this.homeStore.getGoalSuggestion(this.taskId);
      } catch (e) {
        console.error('EditTaskPage getGoalSuggestion error: ' + e);
      }
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
            .margin({ left: 8 })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column() {
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

        // 目标建议卡片
        if (this.goalSuggestion.type !== GoalSuggestionType.NONE) {
          GoalSuggestionCard({
            suggestion: this.goalSuggestion,
            onAccept: () => {
              this.acceptGoalSuggestion();
            },
            onDismiss: () => {
              this.goalSuggestion = new GoalSuggestion();
            }
          })
        }

        // 跑步任务提醒设置
        if (this.isRunTask) {
          this.alertSection()
        }

        // 完成按钮
        Button($r('app.string.complete'))
          .type(ButtonType.Capsule)
          .backgroundColor($r('app.color.text_font_color'))
          .fontColor('#FFFFFF')
          .width('90%')
          .height(44)
          .margin({ top: 24, bottom: 24 })
          .onClick(() => {
            this.onComplete();
          })

        // 删除按钮（仅自定义任务）
        if (this.isCustomTask()) {
          Button('删除此习惯')
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.bg_page'))
            .fontColor('#E24B4A')
            .border({ width: 1, color: '#E24B4A' })
            .width('90%')
            .height(44)
            .margin({ bottom: 24 })
            .onClick(() => {
              this.onArchive();
            })
        }
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  alertSection() {
    Column() {
      // 提醒设置标题
      Row() {
        Text($r('app.string.reminder_setting'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.isAlert })
          .selectedColor($r('app.color.text_font_color'))
          .onChange((on: boolean) => {
            this.isAlert = on;
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      if (this.isAlert) {
        // 提醒时间
        Row() {
          Text($r('app.string.reminder_time'))
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)

          TimePicker({
            selected: this.parseTime(this.alertStartTime)
          })
            .onChange((value: TimePickerResult) => {
              this.alertStartTime = this.formatTime(value);
            })
            .width('50%')
            .height(120)
        }
        .width('100%')
        .height(160)
        .padding({ left: 16, right: 16 })

        // 提醒频率（周一到周日多选）
        Column() {
          Text($r('app.string.reminder_frequency'))
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .height(48)
            .padding({ left: 16 })

          Row() {
            ForEach(this.getWeekLabels(), (label: string, index: number) => {
              this.weekDayChip(label, index)
            }, (label: string, index: number) => `${label}-${index}`)
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('100%')
        .padding({ bottom: 8 })
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
  }

  @Builder
  weekDayChip(label: string, index: number) {
    Text(label)
      .fontSize(14)
      .fontColor(this.selectedWeekDays[index] ? '#FFFFFF' : $r('app.color.text_secondary'))
      .fontWeight(this.selectedWeekDays[index] ? FontWeight.Bold : FontWeight.Regular)
      .textAlign(TextAlign.Center)
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor(this.selectedWeekDays[index] ? $r('app.color.text_font_color') : $r('app.color.bg_page'))
      .onClick(() => {
        // 如果当前天已选中且是最后一个选中的天，拦截取消
        if (this.selectedWeekDays[index]) {
          const selectedCount = this.selectedWeekDays.filter(v => v).length;
          if (selectedCount <= 1) {
            promptAction.showToast({ message: '至少需要选择一天' });
            return;
          }
        }
        const arr = [...this.selectedWeekDays];
        arr[index] = !arr[index];
        this.selectedWeekDays = arr;
      })
  }

  private getWeekLabels(): string[] {
    return ['一', '二', '三', '四', '五', '六', '日'];
  }

  private parseAlertFrequencyToSelected(): void {
    const freq = this.alertFrequency;
    if (!freq || freq.trim() === '') {
      this.selectedWeekDays = [true, true, true, true, true, true, true];
      return;
    }
    const parts = freq.split(',').map(s => parseInt(s.trim(), 10));
    const arr = [false, false, false, false, false, false, false];
    for (const p of parts) {
      if (p >= 1 && p <= 7) {
        arr[p - 1] = true;
      }
    }
    this.selectedWeekDays = arr;
  }

  private syncSelectedToFrequency(): void {
    const parts: string[] = [];
    for (let i = 0; i < 7; i++) {
      if (this.selectedWeekDays[i]) {
        parts.push(String(i + 1));
      }
    }
    this.alertFrequency = parts.join(',');
  }

  private isCustomTask(): boolean {
    const task = (this.homeStore?.allTasks ?? []).find(t => t.taskId === this.taskId);
    return task ? !task.isPreset : false;
  }

  private async onArchive(): Promise<void> {
    try {
      await this.homeStore.archiveCustomTask(this.taskId);
      promptAction.showToast({ message: '已删除' });
    } catch (e) {
      console.error('EditTaskPage onArchive error: ' + e);
      promptAction.showToast({ message: '操作失败' });
    } finally {
      router.back();
    }
  }

  private async acceptGoalSuggestion(): Promise<void> {
    const suggested = this.goalSuggestion.suggestedValue;
    if (!suggested || suggested === this.targetValue) {
      this.goalSuggestion = new GoalSuggestion();
      return;
    }
    this.targetValue = suggested;
    const idx = this.pickerRange.indexOf(suggested);
    if (idx >= 0) {
      this.pickerSelected = idx;
    }
    this.goalSuggestion = new GoalSuggestion();
    promptAction.showToast({ message: '已采用建议，点击完成保存' });
  }

  private async onComplete() {
    try {
      // 更新目标值
      if (this.targetValue !== this.task.targetValue) {
        await this.homeStore.updateTaskTarget(this.taskId, this.targetValue);
      }
      if (this.isOpen && !this.task.isOpen) {
        await this.homeStore.enableTask(this.taskId);
      } else if (!this.isOpen && this.task.isOpen) {
        await this.homeStore.disableTask(this.taskId);
      }

      // 跑步提醒设置
      if (this.isRunTask) {
        this.syncSelectedToFrequency();
        const alertChanged = this.isAlert !== this.task.isAlert ||
          this.alertStartTime !== this.task.alertStartTime ||
          this.alertFrequency !== this.task.alertFrequency;
        if (alertChanged) {
          await this.homeStore.updateTaskAlert(this.taskId, this.isAlert, this.alertStartTime, this.alertFrequency);
        }
      }

      promptAction.showToast({ message: '保存成功' });
    } catch (e) {
      console.error('EditTaskPage onComplete error: ' + e);
      promptAction.showToast({ message: '操作失败' });
    } finally {
      router.back();
    }
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
