import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AppConstants } from '../domain/constants/AppConstants';
import { ProfileStore } from '../viewmodel/ProfileStore';
import { formatProfileSummary } from '../domain/models/ProfileInfo';
import { HomeStore } from '../viewmodel/HomeStore';
import { getUserLevelLabel } from '../domain/rules/UserLevelRules';

/**
 * 我的页面
 */
@Component
export struct MinePage {
  @StorageLink('profileStore') profileStore: ProfileStore = new ProfileStore();
  @StorageLink('homeStore') homeStore: HomeStore = new HomeStore();

  async aboutToAppear(): Promise<void> {
    const stored = AppStorage.get<ProfileStore>('profileStore');
    if (stored) {
      this.profileStore = stored;
      await this.profileStore.reload();
    } else {
      await this.profileStore.init(getContext(this));
      AppStorage.setOrCreate<ProfileStore>('profileStore', this.profileStore);
    }

    // 确保 homeStore 已初始化（获取连续天数）
    const storedHome = AppStorage.get<HomeStore>('homeStore');
    if (storedHome) {
      this.homeStore = storedHome;
    }
  }

  build() {
    Column() {
      // 用户信息卡 — 点击进入个人资料编辑
      Row() {
        if (this.profileStore.profile.avatarUri !== '') {
          Image(this.profileStore.profile.avatarUri)
            .width(64)
            .height(64)
            .borderRadius(32)
        } else {
          Image($r('app.media.icon_user'))
            .width(64)
            .height(64)
            .borderRadius(32)
        }

        Column() {
          Text(this.profileStore.profile.nickname)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))

          Text(getUserLevelLabel(this.homeStore.consecutiveState.maxConsecutiveDays))
            .fontSize(14)
            .fontColor($r('app.color.user_level_font_color'))
            .backgroundColor($r('app.color.user_level_bg_color'))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(8)
            .margin({ top: 4 })

          Text(formatProfileSummary(this.profileStore.profile))
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
      .onClick(() => {
        router.pushUrl({ url: 'pages/ProfileEditPage' });
      })

      // 菜单列表
      List({ space: 1 }) {
        ForEach(AppConstants.DEFAULT_MENU_INFO, (item: Resource, index: number) => {
          ListItem() {
            Row() {
              Text(item)
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)

              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(20)
                .fontColor([$r('app.color.text_hint')])
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .backgroundColor($r('app.color.bg_card'))
            .onClick(() => {
              if (index === 0) {
                router.pushUrl({ url: 'pages/ProfileEditPage' });
              }
            })
          }
        }, (item: Resource, index: number) => `${index}`)
      }
      .width('100%')
      .margin({ top: 8 })
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 16, endMargin: 16 })

      // 清除所有数据
      Button('清除所有数据')
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.bg_card'))
        .fontColor('#FF4444')
        .fontSize(16)
        .width('90%')
        .height(48)
        .margin({ top: 24, bottom: 24 })
        .onClick(() => {
          this.confirmClearData();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  private confirmClearData(): void {
    promptAction.showDialog({
      title: '清除所有数据',
      message: '将清除所有打卡记录、连续天数、个人资料和自定义任务，恢复到首次安装状态。此操作不可撤销，确定继续？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确认清除', color: '#FF4444' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        this.doClearData();
      }
    }).catch((e: Object) => {
      console.error('confirmClearDialog error: ' + e);
    });
  }

  private async doClearData(): Promise<void> {
    try {
      await this.homeStore.resetAllData();
      await this.profileStore.reload();
      promptAction.showToast({ message: '数据已清除' });
    } catch (e) {
      console.error('clearData error: ' + e);
      promptAction.showToast({ message: '清除失败' });
    }
  }
}
