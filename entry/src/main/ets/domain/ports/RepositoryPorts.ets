import { TaskInfo } from '../models/TaskInfo';
import { DayInfo } from '../models/DayInfo';
import { DayTaskInfo } from '../models/DayTaskInfo';
import { RecoveryInfo } from '../models/RecoveryInfo';
import { ConsecutiveDaysState } from '../rules/ConsecutiveDaysRules';
import { ProfileInfo } from '../models/ProfileInfo';

/**
 * 任务配置仓储接口 — 可被内存假仓库替换以测 HomeStore 业务流
 */
export interface ITaskRepository {
  ensureDefaultTasks(): Promise<void>;
  updateTask(task: TaskInfo): Promise<void>;
  getAllTasks(): Promise<TaskInfo[]>;
  getActiveTasks(): Promise<TaskInfo[]>;
  getTaskById(taskId: number): Promise<TaskInfo | null>;
  createTask(task: TaskInfo): Promise<number>;
  archiveTask(taskId: number): Promise<void>;
  getNextTaskId(): Promise<number>;
  getNextSortOrder(): Promise<number>;
}

/**
 * 每日聚合仓储接口
 */
export interface IDayInfoRepository {
  upsertDayInfo(dayInfo: DayInfo): Promise<void>;
  getDayInfo(date: string): Promise<DayInfo | null>;
  getDayInfoList(startDate: string, endDate: string): Promise<DayInfo[]>;
}

/**
 * 每日任务快照仓储接口
 */
export interface IDayTaskRepository {
  insertDayTask(dayTask: DayTaskInfo): Promise<number>;
  upsertDayTask(dayTask: DayTaskInfo): Promise<number>;
  batchInsertDayTasks(dayTasks: DayTaskInfo[]): Promise<void>;
  updateDayTask(dayTask: DayTaskInfo): Promise<void>;
  getDayTasks(date: string): Promise<DayTaskInfo[]>;
  getDayTask(date: string, taskId: number): Promise<DayTaskInfo | null>;
  deleteDayTask(date: string, taskId: number): Promise<void>;
  getDayTasksByDateRange(startDate: string, endDate: string): Promise<DayTaskInfo[]>;
}

/**
 * 偏好仓储接口 — 连续天数状态
 */
export interface IPrefRepository {
  getConsecutiveState(): Promise<ConsecutiveDaysState>;
  saveConsecutiveState(state: ConsecutiveDaysState): Promise<void>;
}

/**
 * 个人资料仓储接口
 */
export interface IProfileRepository {
  init(context: Context): Promise<void>;
  getProfile(): Promise<ProfileInfo>;
  saveProfile(profile: ProfileInfo): Promise<void>;
}

/**
 * 补救日仓储接口
 */
export interface IRecoveryRepository {
  upsertRecovery(info: RecoveryInfo): Promise<void>;
  getRecoveryByDate(date: string): Promise<RecoveryInfo | null>;
  getRecoveryByWeek(weekKey: string): Promise<RecoveryInfo | null>;
  getRecoveryListByDateRange(startDate: string, endDate: string): Promise<RecoveryInfo[]>;
}

/**
 * 卡片服务接口 — 测试时用空实现
 */
export interface IFormService {
  saveForm(formId: string, formName: string, formDimension: number): Promise<void>;
  removeForm(formId: string): Promise<void>;
  getAllForms(): Promise<FormInfoLike[]>;
  updateAllForms(dayInfo: DayInfo, dayTasks: DayTaskInfo[]): Promise<void>;
}

/**
 * 卡片信息简化结构（避免引入 FormInfo 实体依赖）
 */
export class FormInfoLike {
  formId: string = '';
  formName: string = '';
  formDimension: number = 0;

  constructor(formId: string = '', formName: string = '', formDimension: number = 0) {
    this.formId = formId;
    this.formName = formName;
    this.formDimension = formDimension;
  }
}
