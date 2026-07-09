import { AppConstants } from '../domain/constants/AppConstants';

/**
 * 我的页面
 */
@Component
export struct MinePage {
  build() {
    Column() {
      // 用户信息
      Row() {
        Image($r('app.media.icon_user'))
          .width(64)
          .height(64)
          .borderRadius(32)

        Column() {
          Text($r('app.string.user_name'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))

          Text($r('app.string.user_level'))
            .fontSize(14)
            .fontColor($r('app.color.user_level_font_color'))
            .backgroundColor($r('app.color.user_level_bg_color'))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
            .margin({ top: 4 })

          Text($r('app.string.user_signature'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.bg_card'))

      // 菜单列表
      List({ space: 1 }) {
        ForEach(AppConstants.DEFAULT_MENU_INFO, (item: Resource) => {
          ListItem() {
            Row() {
              Text(item)
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)

              Image($r('app.media.ic_right_grey'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.text_hint'))
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .backgroundColor($r('app.color.bg_card'))
          }
        })
      }
      .width('100%')
      .margin({ top: 8 })
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 16, endMargin: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
