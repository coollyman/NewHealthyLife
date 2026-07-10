import { preferences } from '@kit.ArkData';
import { AppConstants } from '../../domain/constants/AppConstants';
import { ConsecutiveDaysState, createInitialConsecutiveState } from '../../domain/rules/ConsecutiveDaysRules';
import { IPrefRepository } from '../../domain/ports/RepositoryPorts';

/**
 * Preferences 仓储 - 存储连续天数和成就状态
 */
export class PreferencesRepository implements IPrefRepository {
  private static instance: PreferencesRepository | null = null;
  private pref: preferences.Preferences | null = null;

  private constructor() {}

  static getInstance(): PreferencesRepository {
    if (PreferencesRepository.instance === null) {
      PreferencesRepository.instance = new PreferencesRepository();
    }
    return PreferencesRepository.instance;
  }

  async init(context: Context): Promise<void> {
    this.pref = await preferences.getPreferences(context, AppConstants.PREF_STORE);
  }

  private getPref(): preferences.Preferences {
    if (this.pref === null) {
      throw new Error('Preferences not initialized. Call init() first.');
    }
    return this.pref;
  }

  /**
   * 获取连续天数状态
   */
  async getConsecutiveState(): Promise<ConsecutiveDaysState> {
    const p = this.getPref();
    const maxDays = await p.get(AppConstants.MAX_CONSECUTIVE_DAYS, 0) as number;
    const currentDays = await p.get(AppConstants.CURRENT_CONSECUTIVE_DAYS, 0) as number;
    const dayStatus = await p.get(AppConstants.CURRENT_DAY_STATUS, false) as boolean;
    const baselineMax = await p.get(AppConstants.MAX_CONSECUTIVE_DAYS_BEFORE_CURRENT_DAY, maxDays) as number;

    return new ConsecutiveDaysState(maxDays, currentDays, dayStatus, null, baselineMax);
  }

  /**
   * 保存连续天数状态
   */
  async saveConsecutiveState(state: ConsecutiveDaysState): Promise<void> {
    const p = this.getPref();
    await p.put(AppConstants.MAX_CONSECUTIVE_DAYS, state.maxConsecutiveDays);
    await p.put(AppConstants.CURRENT_CONSECUTIVE_DAYS, state.currentConsecutiveDays);
    await p.put(AppConstants.CURRENT_DAY_STATUS, state.currentDayStatus);
    await p.put(AppConstants.MAX_CONSECUTIVE_DAYS_BEFORE_CURRENT_DAY, state.maxConsecutiveDaysBeforeCurrentDay);
    await p.flush();
  }
}
