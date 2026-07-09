import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseHelper } from '../data/db/DatabaseHelper';
import { PreferencesRepository } from '../data/prefs/PreferencesRepository';
import { HomeStore } from '../viewmodel/HomeStore';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to set colorMode: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'EntryAbility', 'onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onWindowStageCreate');

    this.initAppData()
      .then(() => {
        this.loadContent(windowStage);
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN, 'EntryAbility', 'Init failed: %{public}s', JSON.stringify(err));
        this.loadContent(windowStage);
      });
  }

  private async initAppData(): Promise<void> {
    const dbHelper = DatabaseHelper.getInstance();
    await dbHelper.init(this.context);

    const prefRepo = PreferencesRepository.getInstance();
    await prefRepo.init(this.context);

    const homeStore = new HomeStore();
    await homeStore.initAppData();
    AppStorage.setOrCreate<HomeStore>('homeStore', homeStore);
  }

  private loadContent(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'EntryAbility', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'EntryAbility', 'Content loaded.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onBackground');
  }
}
