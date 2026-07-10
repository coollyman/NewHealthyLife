import { preferences } from '@kit.ArkData';
import { AppConstants } from '../../domain/constants/AppConstants';
import { ProfileInfo, ProfileGender } from '../../domain/models/ProfileInfo';
import { IProfileRepository } from '../../domain/ports/RepositoryPorts';

/**
 * 个人资料偏好仓储 — 使用 Preferences 存储用户资料
 */
export class ProfileRepository implements IProfileRepository {
  private static instance: ProfileRepository | null = null;
  private pref: preferences.Preferences | null = null;

  private constructor() {}

  static getInstance(): ProfileRepository {
    if (ProfileRepository.instance === null) {
      ProfileRepository.instance = new ProfileRepository();
    }
    return ProfileRepository.instance;
  }

  async init(context: Context): Promise<void> {
    this.pref = await preferences.getPreferences(context, AppConstants.PREF_STORE);
  }

  private getPref(): preferences.Preferences {
    if (this.pref === null) {
      throw new Error('ProfileRepository not initialized. Call init() first.');
    }
    return this.pref;
  }

  async getProfile(): Promise<ProfileInfo> {
    const p = this.getPref();
    const avatarUri = await p.get(AppConstants.PROFILE_AVATAR_URI, '') as string;
    const nickname = await p.get(AppConstants.PROFILE_NICKNAME, '健康达人') as string;
    const gender = await p.get(AppConstants.PROFILE_GENDER, ProfileGender.SECRET) as number;
    const birthDate = await p.get(AppConstants.PROFILE_BIRTH_DATE, '') as string;
    const heightCm = await p.get(AppConstants.PROFILE_HEIGHT_CM, 0) as number;
    const weightKg = await p.get(AppConstants.PROFILE_WEIGHT_KG, 0) as number;

    return new ProfileInfo(avatarUri, nickname, gender as ProfileGender, birthDate, heightCm, weightKg);
  }

  async saveProfile(profile: ProfileInfo): Promise<void> {
    const p = this.getPref();
    await p.put(AppConstants.PROFILE_AVATAR_URI, profile.avatarUri);
    await p.put(AppConstants.PROFILE_NICKNAME, profile.nickname);
    await p.put(AppConstants.PROFILE_GENDER, profile.gender);
    await p.put(AppConstants.PROFILE_BIRTH_DATE, profile.birthDate);
    await p.put(AppConstants.PROFILE_HEIGHT_CM, profile.heightCm);
    await p.put(AppConstants.PROFILE_WEIGHT_KG, profile.weightKg);
    await p.flush();
  }
}
