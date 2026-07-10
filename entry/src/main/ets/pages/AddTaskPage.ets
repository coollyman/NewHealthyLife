import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HomeStore, isHomeStoreDataReady } from '../viewmodel/HomeStore';
import { TaskInfo, CustomTaskInput } from '../domain/models/TaskInfo';
import { TASK_CATALOG, getTaskCatalogItem, TaskCatalogItem, TaskType, PickerType } from '../domain/constants/TaskCatalog';
import { ICON_KEY_OPTIONS, getIconResource } from '../domain/constants/TaskDisplayMeta';

/**
 * 添加任务页
 * 顶部：创建自定义习惯入口
 * 下方：预设任务列表
 */
@Entry
@Component
struct AddTaskPage {
  @StorageLink('homeStore') homeStore: HomeStore = new HomeStore();
  @State showCustomForm: boolean = false;
  @State customName: string = '';
  @State customIconKey: string = 'exercise';
  @State customTypeIndex: number = 0;
  @State customTarget: string = '1';
  @State customUnit: string = '次';
  @State customStep: string = '1';
  @State customScheduleDays: boolean[] = [true, true, true, true, true, true, true];

  private typeOptions: SelectOption[] = [
    { value: '是否完成' },
    { value: '次数/数值' },
    { value: '时间目标' }
  ];
  private typeEnums: TaskType[] = [TaskType.ONCE, TaskType.VALUE, TaskType.TIME];
  private unitOptions: SelectOption[] = [
    { value: '次' }, { value: '个' }, { value: 'L' }, { value: '公里' }, { value: '分钟' }, { value: '页' }
  ];

  private get tasks(): TaskInfo[] {
    return this.homeStore?.allTasks ?? [];
  }

  async aboutToAppear(): Promise<void> {
    await this.ensureHomeStoreReady();
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

        Text($r('app.string.add_task'))
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
          // 创建自定义习惯入口
          if (!this.showCustomForm) {
            this.createCustomEntry()
          } else {
            this.customForm()
          }

          // 预设任务列表标题
          if (!this.showCustomForm) {
            Text('预设习惯')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .padding({ left: 16, top: 16, bottom: 8 })

            List({ space: 1 }) {
              ForEach(TASK_CATALOG, (item: TaskCatalogItem) => {
                ListItem() {
                  this.taskRow(item.taskId)
                }
              }, (item: TaskCatalogItem) => item.taskId.toString())
            }
            .width('100%')
            .scrollBar(BarState.Off)
            .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 12, endMargin: 12 })
          }
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  createCustomEntry() {
    Row() {
      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(20)
        .fontColor([$r('app.color.text_font_color')])

      Text('创建自定义习惯')
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .margin({ left: 12 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      this.showCustomForm = true;
    })
  }

  @Builder
  customForm() {
    Column() {
      // 名称
      Row() {
        Text('名称')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width(60)

        TextInput({ text: this.customName, placeholder: '如：冥想' })
          .fontSize(16)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.customName = value;
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.bg_card'))

      // 图标选择
      Text('图标')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({ left: 16, top: 12 })

      Row() {
        ForEach(ICON_KEY_OPTIONS, (key: string, index: number) => {
          Image(getIconResource(key))
            .width(36)
            .height(36)
            .border(this.customIconKey === key ? { width: 2, color: $r('app.color.text_font_color') } : { width: 0 })
            .borderRadius(18)
            .onClick(() => {
              this.customIconKey = key;
            })
        }, (key: string) => key)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })
      .justifyContent(FlexAlign.Start)

      // 类型选择
      Row() {
        Text('类型')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width(60)

        Select(this.typeOptions)
          .selected(this.customTypeIndex)
          .onSelect((index: number) => {
            this.customTypeIndex = index;
            if (this.typeEnums[index] === TaskType.TIME) {
              this.customTarget = '08:00';
              this.customUnit = '/ 天';
              this.customStep = '';
            } else {
              this.customTarget = '1';
              this.customUnit = '次';
              this.customStep = '1';
            }
          })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.bg_card'))

      // 目标值
      Row() {
        Text('目标')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width(60)

        TextInput({ text: this.customTarget })
          .fontSize(16)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.customTarget = value;
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.bg_card'))

      // 单位（非时间类）
      if (this.typeEnums[this.customTypeIndex] !== TaskType.TIME) {
        Row() {
          Text('单位')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .width(60)

          Select(this.unitOptions)
            .selected(0)
            .onSelect((index: number) => {
              const option = this.unitOptions[index];
              this.customUnit = typeof option.value === 'string' ? option.value : '';
            })
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.bg_card'))
      }

      // 步进（仅数值类）
      if (this.typeEnums[this.customTypeIndex] === TaskType.VALUE) {
        Row() {
          Text('步进')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .width(60)

          TextInput({ text: this.customStep })
            .fontSize(16)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.customStep = value;
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.bg_card'))
      }

      // 执行星期
      Text('执行星期')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({ left: 16, top: 12 })

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
              const anySelected = arr.some(v => v);
              if (!anySelected) {
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

      // 按钮
      Row() {
        Button('取消')
          .type(ButtonType.Capsule)
          .backgroundColor($r('app.color.bg_page'))
          .fontColor($r('app.color.text_secondary'))
          .height(44)
          .layoutWeight(1)
          .margin({ right: 8 })
          .onClick(() => {
            this.showCustomForm = false;
          })

        Button('创建')
          .type(ButtonType.Capsule)
          .backgroundColor($r('app.color.text_font_color'))
          .fontColor('#FFFFFF')
          .height(44)
          .layoutWeight(1)
          .margin({ left: 8 })
          .onClick(() => {
            this.onCreateCustom();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 24, bottom: 24 })
    }
    .width('100%')
  }

  @Builder
  taskRow(taskId: number) {
    Row() {
      Image(getTaskCatalogItem(taskId)!.icon)
        .width(32)
        .height(32)

      Text(getTaskCatalogItem(taskId)!.name)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .padding({ left: 12 })

      if (this.isTaskOpen(taskId)) {
        Text($r('app.string.task_opened'))
          .fontSize(12)
          .fontColor($r('app.color.text_font_color'))
      }

      Image($r('app.media.ic_right_grey'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.text_hint'))
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      router.pushUrl({
        url: 'pages/EditTaskPage',
        params: { taskId: taskId }
      });
    })
  }

  private async onCreateCustom(): Promise<void> {
    const name = this.customName.trim();
    if (name.length === 0) {
      promptAction.showToast({ message: '请输入名称' });
      return;
    }

    const taskType = this.typeEnums[this.customTypeIndex];
    const pickerType = taskType === TaskType.TIME ? PickerType.TIME : PickerType.TEXT;

    const input = new CustomTaskInput();
    input.taskName = name;
    input.iconKey = this.customIconKey;
    input.taskType = taskType;
    input.targetValue = this.customTarget;
    input.unitText = this.customUnit;
    input.step = this.customStep || '1';
    input.pickerType = pickerType;
    input.targetOptions = taskType === TaskType.TIME ? '' : this.customTarget;
    input.scheduleDays = this.scheduleDaysToString();
    input.isAlert = false;

    try {
      await this.homeStore.createCustomTask(input);
      promptAction.showToast({ message: '创建成功' });
      router.back();
    } catch (e) {
      console.error('AddTaskPage onCreateCustom error: ' + e);
      promptAction.showToast({ message: '创建失败' });
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

  private isTaskOpen(taskId: number): boolean {
    const tasks = this.homeStore?.allTasks;
    if (!tasks) {
      return false;
    }
    const task = tasks.find(t => t.taskId === taskId);
    return task ? task.isOpen : false;
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

export { AddTaskPage };
