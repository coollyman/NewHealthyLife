import { HomeStore } from '../viewmodel/HomeStore';
import { AppConstants } from '../domain/constants/AppConstants';
import { isAchievementUnlocked } from '../domain/rules/ConsecutiveDaysRules';
import { getAchievementBadgeIcon } from '../domain/constants/AchievementBadge';
import { WeeklyReview } from '../domain/rules/WeeklyReviewRules';
import { OVERACHIEVEMENT_THRESHOLDS, TaskAchievementSummary } from '../domain/rules/AchievementRules';
import { TaskType } from '../domain/constants/TaskCatalog';
import { getIconResource, getTaskNameString } from '../domain/constants/TaskDisplayMeta';

/**

/**
 * 成就页
 * 展示连续天数徽章 + 周复盘 + 多维成就提示
 */
@Component
export struct AchievementPage {
  @Link homeStore: HomeStore;
  @State weeklyReview: WeeklyReview = new WeeklyReview();
  @State taskAchievements: TaskAchievementSummary[] = [];

  async aboutToAppear(): Promise<void> {
    try {
      this.weeklyReview = await this.homeStore.getWeeklyReview();
      this.taskAchievements = await this.homeStore.getTaskAchievementSummaries();
    } catch (e) {
      console.error('AchievementPage load achievements error: ' + e);
    }
  }

  build() {
    Scroll() {
      Column() {
        // 标题
        Row() {
          Text($r('app.string.my_achievement'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.Center)

        // 连续天数
        Row() {
          Column() {
            Text($r('app.string.consecutive_days'))
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.homeStore.consecutiveState.currentConsecutiveDays}`)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_font_color'))
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text($r('app.string.max_consecutive_days'))
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.homeStore.consecutiveState.maxConsecutiveDays}`)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding(24)
        .backgroundColor($r('app.color.bg_card'))
        .margin({ bottom: 8 })

        // 周复盘
        this.weeklyReviewSection()

        // 徽章列表
        Grid() {
          ForEach(AppConstants.ACHIEVEMENT_THRESHOLDS, (threshold: number) => {
            GridItem() {
              this.badgeItem(threshold)
            }
          }, (threshold: number) => threshold.toString())
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(18)
        .columnsGap(12)
        .padding(16)

        this.singleTaskAchievementSection()
        this.overAchievementSection()
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  weeklyReviewSection() {
    Column() {
      Text($r('app.string.weekly_review_title'))
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ left: 16, top: 12 })

      if (this.weeklyReview.isAvailable) {
        Text(`本周完成率 ${this.weeklyReview.completionRate}%`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16, top: 4 })

        if (this.weeklyReview.mostStableTaskId >= 0) {
          Text(`最稳定：${this.getTaskNameById(this.weeklyReview.mostStableTaskId)}`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .padding({ left: 16, top: 2 })
        }

        if (this.weeklyReview.mostMissedTaskId >= 0) {
          Text(`最易遗漏：${this.getTaskNameById(this.weeklyReview.mostMissedTaskId)}`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .padding({ left: 16, top: 2 })
        }

        Text(this.weeklyReview.suggestion)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16, top: 4, bottom: 12 })
      } else {
        Text($r('app.string.weekly_review_insufficient'))
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
          .width('100%')
          .padding({ left: 16, top: 4, bottom: 12 })
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
  }

  @Builder
  badgeItem(threshold: number) {
    Column() {
      Image(this.getBadgeIcon(threshold))
        .width(76)
        .height(84)
        .objectFit(ImageFit.Contain)

      Text(`连续${threshold}天`)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  singleTaskAchievementSection() {
    Column() {
      Text('单项达成')
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 8 })

      Grid() {
        ForEach(this.taskAchievements, (summary: TaskAchievementSummary) => {
          GridItem() {
            this.singleTaskBadge(summary)
          }
        }, (summary: TaskAchievementSummary) => `single-${summary.taskId}`)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(16)
      .columnsGap(12)
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
  }

  @Builder
  overAchievementSection() {
    Column() {
      Text('超额达成')
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 8 })

      if (this.getNumericTaskAchievements().length === 0) {
        Text('数值任务完成后继续打卡，可点亮 200% / 300% / 400% 奖章')
          .fontSize(13)
          .fontColor($r('app.color.text_hint'))
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 14 })
      } else {
        ForEach(this.getNumericTaskAchievements(), (summary: TaskAchievementSummary) => {
          this.overTaskRow(summary)
        }, (summary: TaskAchievementSummary) => `over-${summary.taskId}`)
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 16 })
  }

  @Builder
  singleTaskBadge(summary: TaskAchievementSummary) {
    Column() {
      Stack() {
        Circle()
          .width(56)
          .height(56)
          .fill(summary.singleAchieved ? '#FFF3D6' : '#F1F3F5')

        Image(getIconResource(summary.iconKey))
          .width(34)
          .height(34)
          .objectFit(ImageFit.Contain)
          .opacity(summary.singleAchieved ? 1 : 0.38)
      }
      .width(56)
      .height(56)
      .border({
        width: summary.singleAchieved ? 1 : 0,
        color: '#F3C45F'
      })
      .borderRadius(28)

      Text(this.getTaskName(summary))
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
    }
    .width('100%')
    .height(90)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  overTaskRow(summary: TaskAchievementSummary) {
    Column() {
      Row() {
        Text(this.getTaskName(summary))
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`最高${summary.maxPercent}%`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      Row() {
        ForEach(OVERACHIEVEMENT_THRESHOLDS, (threshold: number) => {
          this.overBadge(summary, threshold)
        }, (threshold: number) => `${summary.taskId}-${threshold}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ left: 8, right: 8, bottom: 14 })
    }
    .width('100%')
  }

  @Builder
  overBadge(summary: TaskAchievementSummary, threshold: number) {
    Column() {
      Image(this.getOverBadgeIcon(threshold, summary.isMultiplierUnlocked(threshold)))
        .width(44)
        .height(50)
        .objectFit(ImageFit.Contain)

      Text(`${threshold}%`)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 4 })
    }
    .width(62)
    .alignItems(HorizontalAlign.Center)
  }

  private getBadgeIcon(threshold: number): Resource {
    const unlocked = isAchievementUnlocked(
      this.homeStore.consecutiveState.maxConsecutiveDays, threshold
    );
    const icon = getAchievementBadgeIcon(threshold, unlocked);
    return icon !== null ? icon : $r('app.media.ic_badge_3_off');
  }

  private getTaskName(summary: TaskAchievementSummary): string {
    const task = this.homeStore.allTasks.find(t => t.taskId === summary.taskId);
    if (!task) {
      return summary.taskName || `任务${summary.taskId}`;
    }
    if (!task.isPreset) {
      return task.taskName || summary.taskName || `任务${summary.taskId}`;
    }
    try {
      const key = getTaskNameString(task);
      const resource = $r(`app.string.${key}`);
      return getContext(this).resourceManager.getStringSync(resource);
    } catch (e) {
      return summary.taskName || `任务${summary.taskId}`;
    }
  }

  private getTaskNameById(taskId: number): string {
    const task = this.homeStore.allTasks.find(t => t.taskId === taskId);
    if (!task) {
      return `任务${taskId}`;
    }
    if (!task.isPreset) {
      return task.taskName || `任务${taskId}`;
    }
    try {
      const key = getTaskNameString(task);
      const resource = $r(`app.string.${key}`);
      return getContext(this).resourceManager.getStringSync(resource);
    } catch (e) {
      return task.taskName || `任务${taskId}`;
    }
  }

  private getNumericTaskAchievements(): TaskAchievementSummary[] {
    return this.taskAchievements.filter((summary: TaskAchievementSummary) => summary.taskType === TaskType.VALUE);
  }

  private getOverBadgeIcon(threshold: number, unlocked: boolean): Resource {
    if (threshold === 200) {
      return unlocked ? $r('app.media.ic_badge_7_on') : $r('app.media.ic_badge_7_off');
    }
    if (threshold === 300) {
      return unlocked ? $r('app.media.ic_badge_30_on') : $r('app.media.ic_badge_30_off');
    }
    if (threshold === 400) {
      return unlocked ? $r('app.media.ic_badge_50_on') : $r('app.media.ic_badge_50_off');
    }
    return unlocked ? $r('app.media.ic_badge_99_on') : $r('app.media.ic_badge_99_off');
  }
}
