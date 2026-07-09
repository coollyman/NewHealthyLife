import { router } from '@kit.ArkUI';
import { HomeStore, isHomeStoreDataReady } from '../viewmodel/HomeStore';
import { TaskInfo } from '../domain/models/TaskInfo';
import { TASK_CATALOG, getTaskCatalogItem, TaskCatalogItem } from '../domain/constants/TaskCatalog';

/**
 * 添加任务页
 */
@Entry
@Component
struct AddTaskPage {
  @StorageLink('homeStore') homeStore: HomeStore = new HomeStore();

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
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      // 任务列表
      List({ space: 1 }) {
        ForEach(TASK_CATALOG, (item: TaskCatalogItem) => {
          ListItem() {
            this.taskRow(item.taskId)
          }
        }, (item: TaskCatalogItem) => item.taskId.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 12, endMargin: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  taskRow(taskId: number) {
    Row() {
      // 图标
      Image(getTaskCatalogItem(taskId)!.icon)
        .width(32)
        .height(32)

      // 名称
      Text(getTaskCatalogItem(taskId)!.name)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .padding({ left: 12 })

      // 已开启状态
      if (this.isTaskOpen(taskId)) {
        Text($r('app.string.task_opened'))
          .fontSize(12)
          .fontColor($r('app.color.text_font_color'))
      }

      // 箭头
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
