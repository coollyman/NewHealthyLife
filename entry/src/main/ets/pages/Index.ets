import { HomeStore } from '../viewmodel/HomeStore';
import { HomePage } from './HomePage';
import { AchievementPage } from './AchievementPage';
import { MinePage } from './MinePage';

/**
 * 主入口 - 底部导航
 */
@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @StorageLink('homeStore') homeStore: HomeStore = new HomeStore();

  @Builder
  tabBuilder(title: Resource, normalIcon: Resource, selectedIcon: Resource, index: number) {
    Column() {
      Image(this.currentTab === index ? selectedIcon : normalIcon)
        .width(24)
        .height(24)
        .margin({ bottom: 4 })

      Text(title)
        .fontSize(10)
        .fontColor(this.currentTab === index ? $r('app.color.text_font_color') : $r('app.color.text_hint'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          HomePage({ homeStore: this.homeStore })
        }
        .tabBar(this.tabBuilder($r('app.string.tab_home'),
          $r('app.media.ic_tabs_home_normal'),
          $r('app.media.ic_tabs_home_sel'), 0))

        TabContent() {
          AchievementPage({ homeStore: this.homeStore })
        }
        .tabBar(this.tabBuilder($r('app.string.tab_achievement'),
          $r('app.media.ic_tabs_achievement_normal'),
          $r('app.media.ic_tabs_achievement_sel'), 1))

        TabContent() {
          MinePage()
        }
        .tabBar(this.tabBuilder($r('app.string.tab_mine'),
          $r('app.media.ic_tabs_mine_normal'),
          $r('app.media.ic_tabs_mine_sel'), 2))
      }
      .barHeight(56)
      .onChange((index: number) => {
        this.currentTab = index;
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
