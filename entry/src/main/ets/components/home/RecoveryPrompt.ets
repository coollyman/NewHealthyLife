import { HomeStore } from '../../viewmodel/HomeStore';
import { promptAction } from '@kit.ArkUI';

/**
 * 补救提示组件
 * 当天完成度达到 70%-99% 且本周未使用过补救时，在首页进度区域显示轻量提示。
 * 点击后弹出确认，使用补救后保持连续天数但不计为满分完成。
 */
@Component
export struct RecoveryPrompt {
  @Link homeStore: HomeStore;
  @State isVisible: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.checkVisibility();
  }

  private async checkVisibility(): Promise<void> {
    try {
      this.isVisible = await this.homeStore.canUseRecoveryToday();
    } catch (e) {
      console.error('RecoveryPrompt checkVisibility error: ' + e);
      this.isVisible = false;
    }
  }

  private showConfirmDialog(): void {
    AlertDialog.show({
      title: '今天还差一点',
      message: '使用本周补救后，今天会保持连续，但不会计为满分完成。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '使用补救',
        action: () => {
        this.handleRecovery();
      }
      }
    });
  }

  private async handleRecovery(): Promise<void> {
    try {
      const success = await this.homeStore.useRecoveryToday();
      if (success) {
        promptAction.showToast({ message: '已使用本周补救' });
      } else {
        promptAction.showToast({ message: '无法使用补救' });
      }
      await this.checkVisibility();
    } catch (e) {
      console.error('RecoveryPrompt handleRecovery error: ' + e);
    }
  }

  build() {
    Column() {
      if (this.isVisible) {
        Row() {
          Column() {
            Text($r('app.string.recovery_prompt_title'))
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Medium)

            Text($r('app.string.recovery_prompt_desc'))
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button($r('app.string.recovery_use'))
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.text_font_color'))
            .fontColor('#FFFFFF')
            .height(32)
            .fontSize(12)
            .onClick(() => {
              this.showConfirmDialog();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor($r('app.color.bg_card'))
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 8 })
      }
    }
  }
}
