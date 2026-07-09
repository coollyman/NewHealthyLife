import { getAchievementBadgeIcon } from '../../domain/constants/AchievementBadge';
import { AppConstants } from '../../domain/constants/AppConstants';

/**
 * 成就解锁弹窗 - 官方风格
 * 暗色遮罩、居中面板、已点亮徽章、标题"我的成就"、
 * "连续打卡 X 天达成"文案、底部"知道了"按钮。
 * 入场动画：面板 opacity 0→1 + scale 0.72→1，徽章 scale 0.5→1.12→1 回弹。
 */
@CustomDialog
export struct AchievementUnlockDialog {
  threshold: number = 0;
  onClose: () => void = () => {};
  controller: CustomDialogController = new CustomDialogController({ builder: undefined });

  @State panelOpacity: number = 0;
  @State panelScale: number = 0.72;
  @State badgeScale: number = 0.5;

  aboutToAppear(): void {
    // 面板入场 + 徽章放大
    animateTo({
      duration: AppConstants.DURATION_800,
      curve: Curve.EaseOut,
      onFinish: () => {
        // 徽章回弹到 1.0
        animateTo({
          duration: 200,
          curve: Curve.EaseOut
        }, () => {
          this.badgeScale = 1.0;
        });
      }
    }, () => {
      this.panelOpacity = 1;
      this.panelScale = 1;
      this.badgeScale = 1.12;
    });
  }

  build() {
    Column() {
      // 面板
      Column() {
        // 徽章
        Image(this.getBadgeIcon())
          .width(120)
          .height(120)
          .objectFit(ImageFit.Contain)
          .scale({ x: this.badgeScale, y: this.badgeScale })
          .margin({ top: 40, bottom: 16 })

        // 标题
        Text($r('app.string.my_achievement'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ bottom: 8 })

        // 文案
        Text(this.getAchievementText())
          .fontSize(16)
          .fontColor('#E6FFFFFF')
          .margin({ bottom: 32 })

        // 按钮
        Button($r('app.string.got_it'))
          .type(ButtonType.Capsule)
          .backgroundColor($r('app.color.button_red'))
          .fontColor('#FFFFFF')
          .fontSize(18)
          .width(180)
          .height(44)
          .margin({ bottom: 24 })
          .onClick(() => {
            this.onClose();
          })
      }
      .width(300)
      .height(400)
      .borderRadius(24)
      .backgroundColor($r('app.color.ach_bg_color'))
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .opacity(this.panelOpacity)
      .scale({ x: this.panelScale, y: this.panelScale })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.6)')
  }

  private getBadgeIcon(): Resource {
    const icon = getAchievementBadgeIcon(this.threshold, true);
    return icon !== null ? icon : $r('app.media.ic_badge_3_on');
  }

  private getAchievementText(): string {
    try {
      const template = getContext(this).resourceManager.getStringSync($r('app.string.achievement_level').id);
      return template.replace('%s', this.threshold.toString());
    } catch (e) {
      return `连续打卡 ${this.threshold} 天达成`;
    }
  }
}
