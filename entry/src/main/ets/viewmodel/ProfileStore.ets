import { ProfileInfo } from '../domain/models/ProfileInfo';
import { ProfileRepository } from '../data/prefs/ProfileRepository';
import { IProfileRepository } from '../domain/ports/RepositoryPorts';

/**
 * 个人资料 ViewModel — 管理用户资料状态
 */
@Observed
export class ProfileStore {
  profile: ProfileInfo = new ProfileInfo();

  private profileRepo: IProfileRepository;

  constructor() {
    this.profileRepo = ProfileRepository.getInstance();
  }

  /**
   * 测试构造 — 注入假仓储
   */
  constructorForTest(repo: IProfileRepository): void {
    this.profile = new ProfileInfo();
    this.profileRepo = repo;
  }

  static createForTest(repo: IProfileRepository): ProfileStore {
    const store = new ProfileStore();
    store.constructorForTest(repo);
    return store;
  }

  async init(context: Context): Promise<void> {
    await this.profileRepo.init(context);
    this.profile = await this.profileRepo.getProfile();
  }

  async saveProfile(profile: ProfileInfo): Promise<void> {
    await this.profileRepo.saveProfile(profile);
    this.profile = profile.deepClone();
  }

  async reload(): Promise<void> {
    this.profile = await this.profileRepo.getProfile();
  }
}
