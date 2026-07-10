/**
 * 性别枚举
 */
export enum ProfileGender {
  SECRET = 0,
  MALE = 1,
  FEMALE = 2
}

export const PROFILE_HEIGHT_MIN_CM: number = 50;
export const PROFILE_HEIGHT_MAX_CM: number = 250;
export const PROFILE_WEIGHT_MIN_KG: number = 2;
export const PROFILE_WEIGHT_MAX_KG: number = 300;

export class ProfileValidationResult {
  isValid: boolean;
  message: string;
  nickname: string;
  heightCm: number;
  weightKg: number;

  constructor(
    isValid: boolean,
    message: string,
    nickname: string,
    heightCm: number,
    weightKg: number
  ) {
    this.isValid = isValid;
    this.message = message;
    this.nickname = nickname;
    this.heightCm = heightCm;
    this.weightKg = weightKg;
  }
}

export function validateProfileInput(nickname: string, heightText: string, weightText: string): ProfileValidationResult {
  const trimmedName = nickname.trim();
  if (trimmedName.length === 0) {
    return new ProfileValidationResult(false, '昵称不能为空', trimmedName, 0, 0);
  }

  const height = parseOptionalNumber(heightText);
  if (height < 0 || (height > 0 && (height < PROFILE_HEIGHT_MIN_CM || height > PROFILE_HEIGHT_MAX_CM))) {
    return new ProfileValidationResult(false, '身高需在50-250cm之间', trimmedName, 0, 0);
  }

  const weight = parseOptionalNumber(weightText);
  if (weight < 0 || (weight > 0 && (weight < PROFILE_WEIGHT_MIN_KG || weight > PROFILE_WEIGHT_MAX_KG))) {
    return new ProfileValidationResult(false, '体重需在2-300kg之间', trimmedName, 0, 0);
  }

  return new ProfileValidationResult(true, '', trimmedName, height, weight);
}

function parseOptionalNumber(value: string): number {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return 0;
  }
  const parsed = Number(trimmed);
  if (!Number.isFinite(parsed)) {
    return -1;
  }
  return parsed;
}

export function formatProfileGender(gender: ProfileGender): string {
  if (gender === ProfileGender.MALE) {
    return '男';
  }
  if (gender === ProfileGender.FEMALE) {
    return '女';
  }
  return '保密';
}

export function calculateAge(birthDate: string): number {
  const parts = birthDate.split('-');
  if (parts.length !== 3) {
    return 0;
  }

  const year = Number(parts[0]);
  const month = Number(parts[1]);
  const day = Number(parts[2]);
  if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day) ||
    year <= 0 || month < 1 || month > 12 || day < 1 || day > 31) {
    return 0;
  }

  const today = new Date();
  let age = today.getFullYear() - year;
  const currentMonth = today.getMonth() + 1;
  const currentDay = today.getDate();
  if (currentMonth < month || (currentMonth === month && currentDay < day)) {
    age--;
  }
  return age > 0 ? age : 0;
}

export function formatProfileSummary(profile: ProfileInfo): string {
  const parts: string[] = [];

  if (profile.gender !== ProfileGender.SECRET) {
    parts.push(formatProfileGender(profile.gender));
  }

  const age = calculateAge(profile.birthDate);
  if (age > 0) {
    parts.push(`${age}岁`);
  }

  if (parts.length === 0) {
    return '资料未完善';
  }
  return parts.join(' · ');
}

/**
 * 个人资料模型
 */
export class ProfileInfo {
  avatarUri: string;
  nickname: string;
  gender: ProfileGender;
  birthDate: string;
  heightCm: number;
  weightKg: number;

  constructor(
    avatarUri: string = '',
    nickname: string = '健康达人',
    gender: ProfileGender = ProfileGender.SECRET,
    birthDate: string = '',
    heightCm: number = 0,
    weightKg: number = 0
  ) {
    this.avatarUri = avatarUri;
    this.nickname = nickname;
    this.gender = gender;
    this.birthDate = birthDate;
    this.heightCm = heightCm;
    this.weightKg = weightKg;
  }

  /**
   * 深拷贝
   */
  deepClone(): ProfileInfo {
    return new ProfileInfo(
      this.avatarUri,
      this.nickname,
      this.gender,
      this.birthDate,
      this.heightCm,
      this.weightKg
    );
  }

  /**
   * 是否使用默认头像
   */
  isDefaultAvatar(): boolean {
    return this.avatarUri === '';
  }
}
