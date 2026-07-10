import { GoalSuggestion, GoalSuggestionType } from '../../domain/rules/GoalSuggestionRules';

/**
 * 目标建议卡片
 * 在编辑任务页目标设置区域下方展示，仅当建议类型不为 none 时显示。
 * 不弹强制弹窗，不打断打卡流程。
 */
@Component
export struct GoalSuggestionCard {
  suggestion: GoalSuggestion = new GoalSuggestion();
  onAccept: () => void = () => {};
  onDismiss: () => void = () => {};

  build() {
    if (this.suggestion.type !== GoalSuggestionType.NONE) {
      Column() {
        // 标题
        Row() {
          Text($r('app.string.goal_suggestion_title'))
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding({ left: 16, top: 12 })

        // 建议文案
        Text(this.suggestion.reason)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 12 })

        // 操作按钮
        Row() {
          Button($r('app.string.goal_suggestion_dismiss'))
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.bg_page'))
            .fontColor($r('app.color.text_secondary'))
            .height(36)
            .layoutWeight(1)
            .margin({ right: 8 })
            .onClick(() => {
              this.onDismiss();
            })

          if (this.suggestion.type !== GoalSuggestionType.KEEP) {
            Button($r('app.string.goal_suggestion_accept'))
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.text_font_color'))
              .fontColor('#FFFFFF')
              .height(36)
              .layoutWeight(1)
              .margin({ left: 8 })
              .onClick(() => {
                this.onAccept();
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })
      }
      .width('100%')
      .backgroundColor($r('app.color.bg_card'))
      .borderRadius(12)
      .margin({ left: 16, right: 16, bottom: 8 })
    }
  }
}
