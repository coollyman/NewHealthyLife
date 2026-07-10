import { TaskType, PickerType } from '../constants/TaskCatalog';

/**
 * TaskInfo - 全局任务配置（不包含当天完成状态）
 * 每日完成状态由 DayTaskInfo 承载
 * 预设任务 (taskId 0-6) 由 TASK_CATALOG 初始化
 * 自定义任务 (taskId >= 100) 由用户创建
 */
export class TaskInfo {
  taskId: number;
  isOpen: boolean;
  targetValue: string;
  isAlert: boolean;
  alertStartTime: string;
  alertEndTime: string;
  alertFrequency: string;
  reminderId: number;

  // 自定义任务元数据（预设任务也从 TASK_CATALOG 回填）
  taskName: string;           // 任务名称（自定义任务直接存字符串）
  iconKey: string;            // 图标 key（预设任务存 catalog key 如 'getup'，自定义任务存白名单 key 如 'exercise'）
  taskType: TaskType;         // 任务类型: TIME / VALUE / ONCE
  step: string;               // 步进值（数值任务）
  unitText: string;           // 单位文本（如 'L' '个' '次' '公里'）
  pickerType: PickerType;    // 选择器类型: NONE / TIME / TEXT
  targetOptions: string;      // 可选目标值，逗号分隔（如 '1,2,3,5'），空表示无选择器
  scheduleDays: string;       // 执行星期，逗号分隔 1-7（如 '1,3,5'），空表示每天
  isPreset: boolean;          // 是否预设任务
  isArchived: boolean;        // 是否已归档（软删除）
  sortOrder: number;           // 排序序号
  createdAt: number;           // 创建时间戳

  constructor(
    taskId: number = 0,
    isOpen: boolean = false,
    targetValue: string = '',
    isAlert: boolean = false,
    alertStartTime: string = '',
    alertEndTime: string = '',
    alertFrequency: string = '',
    reminderId: number = -1,
    taskName: string = '',
    iconKey: string = '',
    taskType: TaskType = TaskType.ONCE,
    step: string = '',
    unitText: string = '',
    pickerType: PickerType = PickerType.NONE,
    targetOptions: string = '',
    scheduleDays: string = '',
    isPreset: boolean = false,
    isArchived: boolean = false,
    sortOrder: number = 0,
    createdAt: number = 0
  ) {
    this.taskId = taskId;
    this.isOpen = isOpen;
    this.targetValue = targetValue;
    this.isAlert = isAlert;
    this.alertStartTime = alertStartTime;
    this.alertEndTime = alertEndTime;
    this.alertFrequency = alertFrequency;
    this.reminderId = reminderId;
    this.taskName = taskName;
    this.iconKey = iconKey;
    this.taskType = taskType;
    this.step = step;
    this.unitText = unitText;
    this.pickerType = pickerType;
    this.targetOptions = targetOptions;
    this.scheduleDays = scheduleDays;
    this.isPreset = isPreset;
    this.isArchived = isArchived;
    this.sortOrder = sortOrder;
    this.createdAt = createdAt;
  }

  deepClone(): TaskInfo {
    return new TaskInfo(
      this.taskId, this.isOpen, this.targetValue, this.isAlert,
      this.alertStartTime, this.alertEndTime, this.alertFrequency, this.reminderId,
      this.taskName, this.iconKey, this.taskType, this.step, this.unitText,
      this.pickerType, this.targetOptions, this.scheduleDays,
      this.isPreset, this.isArchived, this.sortOrder, this.createdAt
    );
  }
}

/**
 * 自定义任务创建输入
 */
export class CustomTaskInput {
  taskName: string;
  iconKey: string;
  taskType: TaskType;
  targetValue: string;
  unitText: string;
  step: string;
  pickerType: PickerType;
  targetOptions: string;
  scheduleDays: string;
  isAlert: boolean;
  alertStartTime: string;
  alertFrequency: string;

  constructor() {
    this.taskName = '';
    this.iconKey = '';
    this.taskType = TaskType.ONCE;
    this.targetValue = '1';
    this.unitText = '';
    this.step = '1';
    this.pickerType = PickerType.NONE;
    this.targetOptions = '';
    this.scheduleDays = '';
    this.isAlert = false;
    this.alertStartTime = '08:00';
    this.alertFrequency = '1,2,3,4,5,6,7';
  }
}

/**
 * 自定义任务起始 ID（预设任务占 0-6）
 */
export const CUSTOM_TASK_ID_START: number = 100;
