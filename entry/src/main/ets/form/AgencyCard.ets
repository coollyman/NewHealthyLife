let storageAgency = new LocalStorage();

/**
 * 1x2 任务列表卡片
 */
@Entry(storageAgency)
@Component
struct AgencyCard {
  @LocalStorageProp('taskList') taskListStr: string = '';
  @LocalStorageProp('taskCount') taskCount: number = 0;
  @LocalStorageProp('finishedCount') finishedCount: number = 0;

  build() {
    Column() {
      Text('健康生活')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .height(32)

      if (this.taskCount > 0) {
        List() {
          ForEach(this.parseTaskList(), (task: CardTaskEntry, index: number) => {
            ListItem() {
              Row() {
                Text(task.taskName)
                  .fontSize(12)
                  .fontColor(task.isDone ? '#999999' : '#333333')
                  .layoutWeight(1)
                if (task.isDone) {
                  Text('✓')
                    .fontSize(12)
                    .fontColor('#0A59F7')
                }
              }
              .width('100%')
              .height(28)
            }
          }, (task: CardTaskEntry, index: number) => index.toString())
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Column() {
          Text('暂无任务')
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }

      Text(`${this.finishedCount}/${this.taskCount}`)
        .fontSize(10)
        .fontColor('#666666')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .padding(8)
    .backgroundColor('#FFFFFF')
  }

  private parseTaskList(): CardTaskEntry[] {
    try {
      const arr: object[] = JSON.parse(this.taskListStr);
      return arr.map((item: object) => {
        const entry = new CardTaskEntry();
        const record = item as Record<string, Object>;
        entry.taskName = (record['taskName'] ?? '') as string;
        entry.isDone = Boolean(record['isDone']);
        entry.finValue = (record['finValue'] ?? '') as string;
        entry.targetValue = (record['targetValue'] ?? '') as string;
        return entry;
      });
    } catch (e) {
      return [];
    }
  }
}

class CardTaskEntry {
  taskName: string = '';
  isDone: boolean = false;
  finValue: string = '';
  targetValue: string = '';
}
