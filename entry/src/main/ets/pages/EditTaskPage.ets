import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HomeStore, isHomeStoreDataReady } from '../viewmodel/HomeStore';
import { TaskInfo } from '../domain/models/TaskInfo';
import { PickerType, TaskType } from '../domain/constants/TaskCatalog';
import { getTaskDisplayMeta, getIconResource, ICON_KEY_OPTIONS } from '../domain/constants/TaskDisplayMeta';
import { GoalSuggestionCard } from '../components/home/GoalSuggestionCard';
import { GoalSuggestion, GoalSuggestionType } from '../domain/rules/GoalSuggestionRules';

/**
 * 编辑任务页
 * 预设任务：可编辑目标/启停/提醒（跑步）
 * 自定义任务：可编辑全部配置（名称/图标/目标/单位/步进/执行星期/启停/提醒）
 */
@Entry
@Component
struct EditTaskPage {
  @StorageLink('homeStore') homeStore: HomeStore = new HomeStore();
  @State task: TaskInfo = new TaskInfo();
  @State isCustom: boolean = false;
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
  // 自定义任务编辑字段
  @State customName: string = '';
  @State customIconKey: string = 'exercise';
  @State customUnit: string = '次';
  @State customStep: string = '1';
  @State customScheduleDays: boolean[] = [true, true, true, true, true, true, true];
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
      this.isCustom = !found.isPreset;

      // 自定义任务编辑字段
      this.customName = found.taskName;
      this.customIconKey = found.iconKey || 'exercise';
      this.customUnit = found.unitText || '次';
      this.customStep = found.step || '1';
      this.parseScheduleDays(found.scheduleDays);
    }

    // 用 getTaskDisplayMeta 初始化选择器（兼容预设和自定义）
    const meta = getTaskDisplayMeta(this.task);
    this.pickerType = meta.pickerType;
    this.pickerRange = meta.targetOptions;
    this.isTimeTask = meta.taskType === TaskType.TIME;
    this.isRunTask = this.taskId === 6;

    // 自定义任务的 targetOptions 可能为空但有 targetValue，用 TextInput 编辑
    if (!this.isCustom && this.pickerRange.length > 0) {
      const idx = this.pickerRange.indexOf(this.targetValue);
      this.pickerSelected = idx >= 0 ? idx : 0;
    }

    // 加载目标建议（仅数值类任务且有多个选项）
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
      this.titleBar()

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

          // 自定义任务：名称、图标、单位、步进、执行星期
          if (this.isCustom) {
            this.customFieldsSection()
          }

          // 目标设置
          if (this.pickerType === PickerType.TEXT && this.pickerRange.length > 0) {
            this.textPickerSection()
          } else if (this.pickerType === PickerType.TIME) {
            this.timePickerSection()
          } else if (this.isCustom) {
            // 自定义任务无选择器时，用 TextInput 编辑目标
            this.customTargetInputSection()
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

          // 提醒设置（预设跑步 + 自定义任务启用提醒）
          if (this.isRunTask || this.isCustom) {
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
          if (this.isCustom) {
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
  titleBar() {
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
  }

  @Builder
  customFieldsSection() {
    Column() {
      // 名称
      Row() {
        Text('名称')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width(60)

        TextInput({ text: this.customName, placeholder: '习惯名称' })
          .fontSize(16)
          .layoutWeight(1)
          .onChange((v: string) => { this.customName = v; })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Divider().strokeWidth(0.5).color($r('app.color.divider')).margin({ left: 16 })

      // 图标
      Row() {
        Text('图标')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width(60)

        Scroll() {
          Row() {
            ForEach(ICON_KEY_OPTIONS, (key: string, index: number) => {
              Image(getIconResource(key))
                .width(32)
                .height(32)
                .margin({ right: 8 })
                .border(this.customIconKey === key ? { width: 2, color: $r('app.color.text_font_color') } : { width: 0 })
                .borderRadius(16)
                .onClick(() => { this.customIconKey = key; })
            }, (key: string) => key)
          }
        }
        .layoutWeight(1)
        .height(40)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Divider().strokeWidth(0.5).color($r('app.color.divider')).margin({ left: 16 })

      // 单位（非时间类）
      if (!this.isTimeTask) {
        Row() {
          Text('单位')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .width(60)

          TextInput({ text: this.customUnit, placeholder: '次/个/L' })
            .fontSize(16)
            .layoutWeight(1)
            .onChange((v: string) => { this.customUnit = v; })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })

        Divider().strokeWidth(0.5).color($r('app.color.divider')).margin({ left: 16 })
      }

      // 步进（仅数值类）
      if (!this.isTimeTask && this.pickerType === PickerType.TEXT) {
        Row() {
          Text('步进')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .width(60)

          TextInput({ text: this.customStep, placeholder: '1' })
            .fontSize(16)
            .type(InputType.Number)
            .layoutWeight(1)
            .onChange((v: string) => { this.customStep = v; })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })

        Divider().strokeWidth(0.5).color($r('app.color.divider')).margin({ left: 16 })
      }

      // 执行星期
      Text('执行星期')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({ left: 16, top: 8 })

      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (label: string, index: number) => {
          Text(label)
            .fontSize(12)
            .fontColor(this.customScheduleDays[index] ? '#FFFFFF' : $r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor(this.customScheduleDays[index] ? $r('app.color.text_font_color') : $r('app.color.bg_page'))
            .onClick(() => {
              const arr = [...this.customScheduleDays];
              arr[index] = !arr[index];
              if (!arr.some(v => v)) {
                promptAction.showToast({ message: '至少选择一天' });
                return;
              }
              this.customScheduleDays = arr;
            })
        }, (label: string, index: number) => `${label}-${index}`)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })
      .justifyContent(FlexAlign.SpaceEvenly)

      Divider().strokeWidth(0.5).color($r('app.color.divider')).margin({ left: 16 })
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
  }

  @Builder
  customTargetInputSection() {
    Column() {
      Row() {
        Text($r('app.string.target_setting'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width(60)

        TextInput({ text: this.targetValue, placeholder: '目标值' })
          .fontSize(16)
          .type(this.isTimeTask ? InputType.Normal : InputType.Number)
          .layoutWeight(1)
          .onChange((v: string) => { this.targetValue = v; })

        if (!this.isTimeTask) {
          Text(this.customUnit)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
  }

  @Builder
  textPickerSection() {
    Column() {
      Row() {
        Text($r('app.string.target_setting'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(48)
      .padding({ left: 16 })

      TextPicker({ range: this.pickerRange, selected: this.pickerSelected })
        .onChange((value: string | string[], index: number | number[]) => {
          this.targetValue = Array.isArray(value) ? value[0] : value;
          this.pickerSelected = Array.isArray(index) ? index[0] : index;
        })
        .width('90%')
        .height(160)
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
  }

  @Builder
  timePickerSection() {
    Column() {
      Row() {
        Text($r('app.string.target_setting'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(48)
      .padding({ left: 16 })

      TimePicker({ selected: this.parseTime(this.targetValue) })
        .onChange((value: TimePickerResult) => {
          this.targetValue = this.formatTime(value);
        })
        .width('90%')
        .height(160)
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
  }

  @Builder
  alertSection() {
    Column() {
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
        Row() {
          Text($r('app.string.reminder_time'))
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)

          TimePicker({ selected: this.parseTime(this.alertStartTime) })
            .onChange((value: TimePickerResult) => {
              this.alertStartTime = this.formatTime(value);
            })
            .width('50%')
            .height(120)
        }
        .width('100%')
        .height(160)
        .padding({ left: 16, right: 16 })

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

  private parseScheduleDays(scheduleDays: string): void {
    if (!scheduleDays || scheduleDays.trim() === '') {
      this.customScheduleDays = [true, true, true, true, true, true, true];
      return;
    }
    const parts = scheduleDays.split(',').map(s => parseInt(s.trim(), 10));
    const arr = [false, false, false, false, false, false, false];
    for (const p of parts) {
      if (p >= 1 && p <= 7) {
        arr[p - 1] = true;
      }
    }
    // 如果全部为 false，默认每天
    if (!arr.some(v => v)) {
      this.customScheduleDays = [true, true, true, true, true, true, true];
    } else {
      this.customScheduleDays = arr;
    }
  }

  private scheduleDaysToString(): string {
    const parts: string[] = [];
    for (let i = 0; i < 7; i++) {
      if (this.customScheduleDays[i]) {
        parts.push(String(i + 1));
      }
    }
    return parts.join(',');
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
      if (this.isCustom) {
        // 自定义任务：更新完整配置
        const updated = this.task.deepClone();
        updated.taskName = this.customName.trim() || updated.taskName;
        updated.iconKey = this.customIconKey;
        updated.targetValue = this.targetValue;
        updated.unitText = this.customUnit;
        updated.step = this.customStep || '1';
        updated.scheduleDays = this.scheduleDaysToString();
        updated.isOpen = this.isOpen;
        updated.isAlert = this.isAlert;
        updated.alertStartTime = this.alertStartTime;
        updated.alertFrequency = this.alertFrequency;
        await this.homeStore.updateTaskConfig(updated);

        // 无论开关都调用 updateTaskAlert（关闭时取消已有 reminder）
        this.syncSelectedToFrequency();
        updated.alertFrequency = this.alertFrequency;
        const alertChanged = this.isAlert !== this.task.isAlert ||
          this.alertStartTime !== this.task.alertStartTime ||
          this.alertFrequency !== this.task.alertFrequency;
        if (alertChanged) {
          await this.homeStore.updateTaskAlert(this.taskId, this.isAlert, this.alertStartTime, this.alertFrequency);
        }
      } else {
        // 预设任务：保持原逻辑
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
