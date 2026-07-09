let storageProgress = new LocalStorage();

/**
 * 2x2 进度卡片
 */
@Entry(storageProgress)
@Component
struct ProgressCard {
  @LocalStorageProp('targetTaskNum') targetTaskNum: number = 0;
  @LocalStorageProp('finTaskNum') finTaskNum: number = 0;
  @LocalStorageProp('percentage') percentage: number = 0;

  build() {
    Column() {
      Text('今日进度')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Progress({ value: this.percentage, total: 100, type: ProgressType.Ring })
        .width(100)
        .height(100)
        .color('#0A59F7')
        .margin({ top: 16, bottom: 16 })

      Text(`${this.percentage}%`)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0A59F7')

      Text(`${this.finTaskNum}/${this.targetTaskNum}`)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}
