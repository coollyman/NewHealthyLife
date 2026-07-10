import { formProvider, formBindingData } from '@kit.FormKit';
import { FormInfoRepository } from '../data/db/FormInfoRepository';
import { FormInfo } from '../domain/models/FormInfo';
import { DayInfo } from '../domain/models/DayInfo';
import { DayTaskInfo } from '../domain/models/DayTaskInfo';
import { TaskInfo } from '../domain/models/TaskInfo';
import { AppConstants } from '../domain/constants/AppConstants';
import { IFormService, FormInfoLike } from '../domain/ports/RepositoryPorts';
import { getTaskDisplayMeta } from '../domain/constants/TaskDisplayMeta';

/**
 * 卡片任务条目
 */
export class CardTaskItem {
  taskId: number = 0;
  taskName: string = '';
  isDone: boolean = false;
  finValue: string = '';
  targetValue: string = '';

  constructor(taskId: number, taskName: string, isDone: boolean, finValue: string, targetValue: string) {
    this.taskId = taskId;
    this.taskName = taskName;
    this.isDone = isDone;
    this.finValue = finValue;
    this.targetValue = targetValue;
  }
}

/**
 * 服务卡片数据
 */
export class CardFormData {
  taskList: string = '';
  taskCount: number = 0;
  finishedCount: number = 0;
  targetTaskNum: number = 0;
  finTaskNum: number = 0;
  percentage: number = 0;
}

export function getCardTaskName(taskId: number, allTasks: TaskInfo[] = []): string {
  const task = allTasks.find(t => t.taskId === taskId);
  if (!task) {
    // 兜底硬编码（兼容旧数据）
    switch (taskId) {
      case 0: return '早起';
      case 1: return '喝水';
      case 2: return '吃苹果';
      case 3: return '每日微笑';
      case 4: return '刷牙';
      case 5: return '早睡';
      case 6: return '跑步';
      default: return '任务' + taskId;
    }
  }
  const meta = getTaskDisplayMeta(task);
  return meta.taskName;
}

export function buildCardFormData(dayInfo: DayInfo, dayTasks: DayTaskInfo[], allTasks: TaskInfo[] = []): CardFormData {
  const taskList: CardTaskItem[] = dayTasks.map(dt => new CardTaskItem(
    dt.taskId,
    getCardTaskName(dt.taskId, allTasks),
    dt.isDone,
    dt.finValue,
    dt.targetValue
  ));

  const formData: CardFormData = new CardFormData();
  formData.taskList = JSON.stringify(taskList);
  formData.taskCount = dayTasks.length;
  formData.finishedCount = dayTasks.filter(t => t.isDone).length;
  formData.targetTaskNum = dayInfo.targetTaskNum;
  formData.finTaskNum = dayInfo.finTaskNum;
  formData.percentage = dayInfo.calculatePercentage();
  return formData;
}

/**
 * 服务卡片更新服务
 */
export class FormService implements IFormService {
  private formRepo: FormInfoRepository = new FormInfoRepository();

  async saveForm(formId: string, formName: string, formDimension: number): Promise<void> {
    const form = new FormInfo(formId, formName, formDimension);
    await this.formRepo.insertForm(form);
  }

  async removeForm(formId: string): Promise<void> {
    await this.formRepo.deleteForm(formId);
  }

  async getAllForms(): Promise<FormInfo[]> {
    return await this.formRepo.getAllForms();
  }

  async updateAllForms(dayInfo: DayInfo, dayTasks: DayTaskInfo[]): Promise<void> {
    const forms = await this.formRepo.getAllForms();
    for (const form of forms) {
      try {
        if (form.formName === AppConstants.FORM_NAME_AGENCY) {
          await this.updateAgencyCard(form.formId, dayTasks);
        } else if (form.formName === AppConstants.FORM_NAME_PROGRESS) {
          await this.updateProgressCard(form.formId, dayInfo);
        }
      } catch (e) {
        console.error('Failed to update form ' + form.formId + ': ' + JSON.stringify(e));
      }
    }
  }

  private async updateAgencyCard(formId: string, dayTasks: DayTaskInfo[]): Promise<void> {
    const formData = buildCardFormData(new DayInfo('', dayTasks.length, dayTasks.filter(t => t.isDone).length), dayTasks);
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
  }

  private async updateProgressCard(formId: string, dayInfo: DayInfo): Promise<void> {
    const formData = buildCardFormData(dayInfo, []);
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
  }
}
