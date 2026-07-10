import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { ProfileStore } from '../main/ets/viewmodel/ProfileStore';
import {
  ProfileInfo,
  ProfileGender,
  validateProfileInput,
  formatProfileGender,
  calculateAge,
  formatProfileSummary
} from '../main/ets/domain/models/ProfileInfo';
import { FakeProfileRepo } from './fakes/FakeRepositories';

/**
 * ProfileStore 单元测试
 * 验证：默认资料加载、保存后可读取、各字段不丢失
 */

export default function profileStoreTest() {

  describe('ProfileStore_DefaultProfile', () => {
    it('getProfile_returnsDefaultsWhenEmpty', 0, async () => {
      const repo = new FakeProfileRepo();
      await repo.init({});
      const store = ProfileStore.createForTest(repo);
      await store.init({});

      expect(store.profile.nickname).assertEqual('健康达人');
      expect(store.profile.gender).assertEqual(ProfileGender.SECRET);
      expect(store.profile.avatarUri).assertEqual('');
      expect(store.profile.birthDate).assertEqual('');
      expect(store.profile.heightCm).assertEqual(0);
      expect(store.profile.weightKg).assertEqual(0);
    });
  });

  describe('ProfileStore_SaveAndLoad', () => {
    it('saveProfile_persistsAndReloads', 0, async () => {
      const repo = new FakeProfileRepo();
      await repo.init({});
      const store = ProfileStore.createForTest(repo);
      await store.init({});

      const profile = new ProfileInfo(
        'file://test/avatar.jpg',
        '测试用户',
        ProfileGender.MALE,
        '1995-03-15',
        175,
        70.5
      );
      await store.saveProfile(profile);

      // 新 Store 实例从同一 repo 读取
      const store2 = ProfileStore.createForTest(repo);
      await store2.init({});
      expect(store2.profile.avatarUri).assertEqual('file://test/avatar.jpg');
      expect(store2.profile.nickname).assertEqual('测试用户');
      expect(store2.profile.gender).assertEqual(ProfileGender.MALE);
      expect(store2.profile.birthDate).assertEqual('1995-03-15');
      expect(store2.profile.heightCm).assertEqual(175);
      expect(store2.profile.weightKg).assertEqual(70.5);
    });

    it('saveProfile_updatesInMemoryProfile', 0, async () => {
      const repo = new FakeProfileRepo();
      await repo.init({});
      const store = ProfileStore.createForTest(repo);
      await store.init({});

      const profile = new ProfileInfo(
        'file://test/avatar2.jpg',
        '新昵称',
        ProfileGender.FEMALE,
        '2000-01-01',
        165,
        55
      );
      await store.saveProfile(profile);

      expect(store.profile.avatarUri).assertEqual('file://test/avatar2.jpg');
      expect(store.profile.nickname).assertEqual('新昵称');
      expect(store.profile.gender).assertEqual(ProfileGender.FEMALE);
      expect(store.profile.birthDate).assertEqual('2000-01-01');
      expect(store.profile.heightCm).assertEqual(165);
      expect(store.profile.weightKg).assertEqual(55);
    });
  });

  describe('ProfileStore_PartialFields', () => {
    it('saveProfile_partialFields_notLost', 0, async () => {
      const repo = new FakeProfileRepo();
      await repo.init({});
      const store = ProfileStore.createForTest(repo);
      await store.init({});

      // 只修改昵称和性别，其余保持默认
      const profile = new ProfileInfo(
        '',
        '小王',
        ProfileGender.MALE,
        '',
        0,
        0
      );
      await store.saveProfile(profile);

      const store2 = ProfileStore.createForTest(repo);
      await store2.init({});
      expect(store2.profile.nickname).assertEqual('小王');
      expect(store2.profile.gender).assertEqual(ProfileGender.MALE);
      expect(store2.profile.avatarUri).assertEqual('');
      expect(store2.profile.birthDate).assertEqual('');
      expect(store2.profile.heightCm).assertEqual(0);
      expect(store2.profile.weightKg).assertEqual(0);
    });

    it('saveProfile_overwritePreviousValues', 0, async () => {
      const repo = new FakeProfileRepo();
      await repo.init({});
      const store = ProfileStore.createForTest(repo);
      await store.init({});

      await store.saveProfile(new ProfileInfo('uri1', 'A', ProfileGender.MALE, '1990-01-01', 180, 80));
      await store.saveProfile(new ProfileInfo('uri2', 'B', ProfileGender.FEMALE, '1995-06-15', 160, 50));

      const store2 = ProfileStore.createForTest(repo);
      await store2.init({});
      expect(store2.profile.avatarUri).assertEqual('uri2');
      expect(store2.profile.nickname).assertEqual('B');
      expect(store2.profile.gender).assertEqual(ProfileGender.FEMALE);
      expect(store2.profile.birthDate).assertEqual('1995-06-15');
      expect(store2.profile.heightCm).assertEqual(160);
      expect(store2.profile.weightKg).assertEqual(50);
    });
  });

  describe('ProfileStore_Reload', () => {
    it('reload_fetchesLatestFromRepo', 0, async () => {
      const repo = new FakeProfileRepo();
      await repo.init({});
      const store = ProfileStore.createForTest(repo);
      await store.init({});

      // 另一个 store 直接写入 repo
      const store2 = ProfileStore.createForTest(repo);
      await store2.init({});
      await store2.saveProfile(new ProfileInfo('uri3', 'C', ProfileGender.SECRET, '2001-12-25', 170, 60));

      // 第一个 store reload 后应拿到最新值
      await store.reload();
      expect(store.profile.nickname).assertEqual('C');
      expect(store.profile.avatarUri).assertEqual('uri3');
      expect(store.profile.birthDate).assertEqual('2001-12-25');
    });
  });

  describe('ProfileInfo_DeepClone', () => {
    it('deepClone_createsIndependentCopy', 0, () => {
      const original = new ProfileInfo('uri', 'name', ProfileGender.MALE, '2000-01-01', 170, 65);
      const cloned = original.deepClone();

      cloned.nickname = 'changed';
      cloned.heightCm = 180;

      expect(original.nickname).assertEqual('name');
      expect(original.heightCm).assertEqual(170);
    });
  });

  describe('ProfileInputValidation', () => {
    it('validateProfileInput_acceptsEmptyOptionalBodyFields', 0, () => {
      const result = validateProfileInput(' 健康达人 ', '', '');

      expect(result.isValid).assertTrue();
      expect(result.nickname).assertEqual('健康达人');
      expect(result.heightCm).assertEqual(0);
      expect(result.weightKg).assertEqual(0);
    });

    it('validateProfileInput_rejectsEmptyNickname', 0, () => {
      const result = validateProfileInput('   ', '170', '60');

      expect(result.isValid).assertFalse();
      expect(result.message).assertEqual('昵称不能为空');
    });

    it('validateProfileInput_rejectsHeightOutOfRange', 0, () => {
      const low = validateProfileInput('用户', '49', '60');
      const high = validateProfileInput('用户', '251', '60');

      expect(low.isValid).assertFalse();
      expect(high.isValid).assertFalse();
      expect(low.message).assertEqual('身高需在50-250cm之间');
    });

    it('validateProfileInput_rejectsWeightOutOfRange', 0, () => {
      const low = validateProfileInput('用户', '170', '1');
      const high = validateProfileInput('用户', '170', '301');

      expect(low.isValid).assertFalse();
      expect(high.isValid).assertFalse();
      expect(low.message).assertEqual('体重需在2-300kg之间');
    });
  });

  describe('ProfileDisplayFormatters', () => {
    it('formatProfileGender_mapsAllGenderValues', 0, () => {
      expect(formatProfileGender(ProfileGender.MALE)).assertEqual('男');
      expect(formatProfileGender(ProfileGender.FEMALE)).assertEqual('女');
      expect(formatProfileGender(ProfileGender.SECRET)).assertEqual('保密');
    });

    it('calculateAge_returnsZeroWhenBirthDateMissingOrInvalid', 0, () => {
      expect(calculateAge('')).assertEqual(0);
      expect(calculateAge('bad-date')).assertEqual(0);
    });

    it('formatProfileSummary_promptsWhenOnlyDefaultProfileExists', 0, () => {
      const profile = new ProfileInfo();

      expect(formatProfileSummary(profile)).assertEqual('资料未完善');
    });

    it('formatProfileSummary_joinsGenderAndAgeWhenAvailable', 0, () => {
      const currentYear = new Date().getFullYear();
      const profile = new ProfileInfo('', '用户', ProfileGender.FEMALE, `${currentYear - 20}-01-01`, 0, 0);

      expect(formatProfileSummary(profile)).assertEqual('女 · 20岁');
    });
  });
}
