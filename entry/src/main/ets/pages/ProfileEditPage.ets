import { router, promptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { ProfileStore } from '../viewmodel/ProfileStore';
import {
  ProfileInfo,
  ProfileGender,
  validateProfileInput,
  formatProfileGender
} from '../domain/models/ProfileInfo';

/**
 * 个人资料编辑页
 */
@Entry
@Component
struct ProfileEditPage {
  @StorageLink('profileStore') profileStore: ProfileStore = new ProfileStore();
  @State avatarUri: string = '';
  @State nickname: string = '健康达人';
  @State gender: ProfileGender = ProfileGender.SECRET;
  @State birthDate: string = '';
  @State heightCm: string = '';
  @State weightKg: string = '';
  @State editingField: string = '';
  @State showBirthPicker: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.ensureProfileStoreReady();
    this.loadProfile();
  }

  private async ensureProfileStoreReady(): Promise<void> {
    const stored = AppStorage.get<ProfileStore>('profileStore');
    if (stored) {
      this.profileStore = stored;
      return;
    }
    await this.profileStore.init(getContext(this));
    AppStorage.setOrCreate<ProfileStore>('profileStore', this.profileStore);
  }

  private loadProfile(): void {
    const p = this.profileStore.profile;
    this.avatarUri = p.avatarUri;
    this.nickname = p.nickname;
    this.gender = p.gender;
    this.birthDate = p.birthDate;
    this.heightCm = p.heightCm > 0 ? String(p.heightCm) : '';
    this.weightKg = p.weightKg > 0 ? String(p.weightKg) : '';
  }

  build() {
    Column() {
      this.titleBar()

      Scroll() {
        Column() {
          this.avatarSection()
          this.profileRows()

          Button($r('app.string.complete'))
            .type(ButtonType.Capsule)
            .backgroundColor($r('app.color.text_font_color'))
            .fontColor('#FFFFFF')
            .width('90%')
            .height(44)
            .margin({ top: 24, bottom: 24 })
            .onClick(() => {
              this.onSave();
            })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  titleBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor([$r('app.color.text_primary')])
        .onClick(() => {
          router.back();
        })

      Text($r('app.string.mine_personal_data'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()
        .width(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  avatarSection() {
    Column() {
      if (this.avatarUri !== '') {
        Image(this.avatarUri)
          .width(80)
          .height(80)
          .borderRadius(40)
      } else {
        Image($r('app.media.icon_user'))
          .width(80)
          .height(80)
          .borderRadius(40)
      }

      Text($r('app.string.profile_avatar'))
        .fontSize(14)
        .fontColor($r('app.color.text_font_color'))
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: 8 })
    .onClick(() => {
      this.pickAvatar();
    })
  }

  @Builder
  profileRows() {
    Column() {
      this.textEditRow($r('app.string.profile_nickname'), this.nickname, '请输入昵称', 'nickname')
      this.genderRow()
      this.birthDateRow()
      this.textEditRow($r('app.string.profile_height'), this.heightCm, '未设置', 'height')
      this.textEditRow($r('app.string.profile_weight'), this.weightKg, '未设置', 'weight')
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  textEditRow(label: Resource, value: string, placeholder: string, field: string) {
    Column() {
      Row() {
        Text(label)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        if (this.editingField === field) {
          TextInput({ text: value, placeholder: placeholder })
            .width(150)
            .height(40)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .type(field === 'nickname' ? InputType.Normal : InputType.Number)
            .onChange((next: string) => {
              this.updateTextField(field, next);
            })
        } else {
          Text(this.formatFieldValue(field, value))
            .fontSize(15)
            .fontColor(value === '' ? $r('app.color.text_hint') : $r('app.color.text_secondary'))
            .margin({ right: 8 })

          Image($r('app.media.ic_right_grey'))
            .width(16)
            .height(16)
            .fillColor($r('app.color.text_hint'))
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.editingField = field;
        this.showBirthPicker = false;
      })

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.divider'))
        .margin({ left: 16 })
    }
    .width('100%')
  }

  @Builder
  genderRow() {
    Column() {
      Row() {
        Text($r('app.string.profile_gender'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        Text(formatProfileGender(this.gender))
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .margin({ right: 8 })

        Image($r('app.media.ic_right_grey'))
          .width(16)
          .height(16)
          .fillColor($r('app.color.text_hint'))
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.editingField = this.editingField === 'gender' ? '' : 'gender';
        this.showBirthPicker = false;
      })

      if (this.editingField === 'gender') {
        Row() {
          this.genderChip($r('app.string.profile_gender_male'), ProfileGender.MALE)
          this.genderChip($r('app.string.profile_gender_female'), ProfileGender.FEMALE)
          this.genderChip($r('app.string.profile_gender_secret'), ProfileGender.SECRET)
        }
        .width('100%')
        .height(52)
        .padding({ left: 12, right: 12, bottom: 8 })
        .justifyContent(FlexAlign.SpaceEvenly)
      }

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.divider'))
        .margin({ left: 16 })
    }
    .width('100%')
  }

  @Builder
  birthDateRow() {
    Column() {
      Row() {
        Text($r('app.string.profile_birth_date'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        Text(this.birthDate === '' ? '未设置' : this.birthDate)
          .fontSize(15)
          .fontColor(this.birthDate === '' ? $r('app.color.text_hint') : $r('app.color.text_secondary'))
          .margin({ right: 8 })

        Image($r('app.media.ic_right_grey'))
          .width(16)
          .height(16)
          .fillColor($r('app.color.text_hint'))
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.showBirthPicker = !this.showBirthPicker;
        this.editingField = '';
      })

      if (this.showBirthPicker) {
        Column() {
          Row() {
            Blank()
              .layoutWeight(1)

            Text($r('app.string.profile_clear'))
              .fontSize(14)
              .fontColor($r('app.color.text_font_color'))
              .padding({ right: 16 })
              .onClick(() => {
                this.birthDate = '';
              })
          }
          .width('100%')
          .height(32)

          DatePicker({
            start: new Date('1950-01-01'),
            end: new Date(),
            selected: this.parseBirthDate()
          })
            .onChange((value: DatePickerResult) => {
              this.birthDate = this.formatDate(value);
            })
            .width('90%')
            .height(150)
        }
        .width('100%')
        .padding({ bottom: 8 })
      }

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.divider'))
        .margin({ left: 16 })
    }
    .width('100%')
  }

  @Builder
  genderChip(label: Resource, value: ProfileGender) {
    Text(label)
      .fontSize(14)
      .fontColor(this.gender === value ? '#FFFFFF' : $r('app.color.text_secondary'))
      .fontWeight(this.gender === value ? FontWeight.Bold : FontWeight.Regular)
      .textAlign(TextAlign.Center)
      .width(80)
      .height(36)
      .borderRadius(18)
      .backgroundColor(this.gender === value ? $r('app.color.text_font_color') : $r('app.color.bg_page'))
      .onClick(() => {
        this.gender = value;
        this.editingField = '';
      })
  }

  private updateTextField(field: string, value: string): void {
    if (field === 'nickname') {
      this.nickname = value;
    } else if (field === 'height') {
      this.heightCm = value;
    } else if (field === 'weight') {
      this.weightKg = value;
    }
  }

  private formatFieldValue(field: string, value: string): string {
    if (value === '') {
      return '未设置';
    }
    if (field === 'height') {
      return `${value} cm`;
    }
    if (field === 'weight') {
      return `${value} kg`;
    }
    return value;
  }

  private async pickAvatar(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result.photoUris && result.photoUris.length > 0) {
        this.avatarUri = result.photoUris[0];
      }
    } catch (e) {
      console.error('ProfileEditPage pickAvatar error: ' + e);
      promptAction.showToast({ message: '头像选择失败' });
    }
  }

  private parseBirthDate(): Date {
    if (this.birthDate === '') {
      return new Date('1995-01-01');
    }
    const parts: number[] = this.birthDate.split('-').map((s: string) => parseInt(s, 10));
    return new Date(parts[0] || 1995, (parts[1] || 1) - 1, parts[2] || 1);
  }

  private formatDate(value: DatePickerResult): string {
    const y = String(value.year);
    const monthVal = value.month ?? 0;
    const dayVal = value.day ?? 1;
    const m = String(monthVal + 1).padStart(2, '0');
    const d = String(dayVal).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  private async onSave(): Promise<void> {
    try {
      const validation = validateProfileInput(this.nickname, this.heightCm, this.weightKg);
      if (!validation.isValid) {
        promptAction.showToast({ message: validation.message });
        return;
      }

      const profile = new ProfileInfo(
        this.avatarUri,
        validation.nickname,
        this.gender,
        this.birthDate,
        validation.heightCm,
        validation.weightKg
      );

      await this.profileStore.saveProfile(profile);
      promptAction.showToast({ message: '保存成功' });
    } catch (e) {
      console.error('ProfileEditPage onSave error: ' + e);
      promptAction.showToast({ message: '保存失败' });
    } finally {
      router.back();
    }
  }
}

export { ProfileEditPage };
