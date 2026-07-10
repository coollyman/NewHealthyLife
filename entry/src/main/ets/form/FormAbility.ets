import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { CardFormData, FormService, buildCardFormData } from '../services/FormService';
import { DayInfoRepository } from '../data/db/DayInfoRepository';
import { DayTaskRepository } from '../data/db/DayTaskRepository';
import { TaskInfoRepository } from '../data/db/TaskInfoRepository';
import { getToday } from '../domain/utils/DateUtils';
import { DayInfo } from '../domain/models/DayInfo';
import { DayTaskInfo } from '../domain/models/DayTaskInfo';
import { TaskInfo } from '../domain/models/TaskInfo';

/**
 * 服务卡片 Ability
 */
export default class FormAbility extends FormExtensionAbility {
  private formService: FormService = new FormService();

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string;
    const formDimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number;

    this.formService.saveForm(formId, formName, formDimension);

    return formBindingData.createFormBindingData(new CardFormData());
  }

  async onCastToNormalForm(formId: string): Promise<void> {
    const formData = await this.buildFormData();
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
  }

  async onUpdateForm(formId: string): Promise<void> {
    const formData = await this.buildFormData();
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
  }

  async onRemoveForm(formId: string): Promise<void> {
    await this.formService.removeForm(formId);
  }

  private async buildFormData(): Promise<CardFormData> {
    const today = getToday();
    const dayRepo = new DayInfoRepository();
    const dayTaskRepo = new DayTaskRepository();
    const taskRepo = new TaskInfoRepository();

    let dayInfo: DayInfo | null = await dayRepo.getDayInfo(today);
    if (!dayInfo) {
      dayInfo = new DayInfo(today, 0, 0);
    }
    const dayTasks: DayTaskInfo[] = await dayTaskRepo.getDayTasks(today);
    const allTasks: TaskInfo[] = await taskRepo.getAllTasks();

    return buildCardFormData(dayInfo, dayTasks, allTasks);
  }
}
