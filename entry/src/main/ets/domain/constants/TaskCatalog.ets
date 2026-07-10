import { TaskInfo } from '../models/TaskInfo';

/**
 * 任务类型枚举
 */
export enum TaskType {
  TIME = 'time',       // 时间类：早起、早睡
  VALUE = 'value',     // 数值类：喝水、吃苹果
  ONCE = 'once'        // 一次性：每日微笑、刷牙
}

/**
 * 选择器类型
 */
export enum PickerType {
  NONE = 'none',
  TIME = 'time',
  TEXT = 'text'
}

/**
 * 任务目录项 - 描述每个预设任务的元数据
 */
export interface TaskCatalogItem {
  taskId: number;
  name: Resource;          // 任务名称资源
  icon: Resource;          // 任务图标（列表用）
  dialogIcon: Resource;    // 打卡弹窗图标
  cardIcon: Resource;      // 卡片图标
  type: TaskType;
  step: string;            // 步进值（数值任务）
  pickerType: PickerType;
  pickerRange: string[];   // 选择器可选值
  unit: Resource;          // 单位
  isAlertEnabled: boolean; // 是否支持提醒
  defaultTarget: string;   // 默认目标值
  iconKey: string;         // 图标 key（用于自定义图标白名单映射）
  unitText: string;        // 单位文本（非 Resource，直接字符串）
}

/**
 * 任务目录 - 7 个预设任务
 */
export const TASK_CATALOG: TaskCatalogItem[] = [
  {
    taskId: 0,
    name: $r('app.string.task_getup'),
    icon: $r('app.media.ic_task_getup'),
    dialogIcon: $r('app.media.ic_dialog_getup'),
    cardIcon: $r('app.media.ic_card_getup'),
    type: TaskType.TIME,
    step: '',
    pickerType: PickerType.TIME,
    pickerRange: [],
    unit: $r('app.string.unit_pre_day'),
    isAlertEnabled: true,
    defaultTarget: '08:00',
    iconKey: 'getup',
    unitText: '/ 天'
  },
  {
    taskId: 1,
    name: $r('app.string.task_drink'),
    icon: $r('app.media.ic_task_drink'),
    dialogIcon: $r('app.media.ic_dialog_drink'),
    cardIcon: $r('app.media.ic_card_drink'),
    type: TaskType.VALUE,
    step: '0.5',
    pickerType: PickerType.TEXT,
    pickerRange: ['0.5', '1', '1.5', '2', '2.5', '3'],
    unit: $r('app.string.unit_liter'),
    isAlertEnabled: false,
    defaultTarget: '1',
    iconKey: 'drink',
    unitText: 'L'
  },
  {
    taskId: 2,
    name: $r('app.string.task_apple'),
    icon: $r('app.media.ic_task_apple'),
    dialogIcon: $r('app.media.ic_dialog_apple'),
    cardIcon: $r('app.media.ic_card_apple'),
    type: TaskType.VALUE,
    step: '1',
    pickerType: PickerType.TEXT,
    pickerRange: ['1', '2', '3', '4', '5'],
    unit: $r('app.string.unit_number'),
    isAlertEnabled: false,
    defaultTarget: '1',
    iconKey: 'apple',
    unitText: '个'
  },
  {
    taskId: 3,
    name: $r('app.string.task_smile'),
    icon: $r('app.media.ic_task_smile'),
    dialogIcon: $r('app.media.ic_dialog_smile'),
    cardIcon: $r('app.media.ic_card_smile'),
    type: TaskType.VALUE,
    step: '1',
    pickerType: PickerType.TEXT,
    pickerRange: ['1', '2', '3'],
    unit: $r('app.string.unit_times'),
    isAlertEnabled: false,
    defaultTarget: '1',
    iconKey: 'smile',
    unitText: '次'
  },
  {
    taskId: 4,
    name: $r('app.string.task_brush'),
    icon: $r('app.media.ic_task_brush'),
    dialogIcon: $r('app.media.ic_dialog_brush'),
    cardIcon: $r('app.media.ic_card_clean'),
    type: TaskType.VALUE,
    step: '1',
    pickerType: PickerType.TEXT,
    pickerRange: ['1', '2', '3'],
    unit: $r('app.string.unit_times'),
    isAlertEnabled: false,
    defaultTarget: '1',
    iconKey: 'brush',
    unitText: '次'
  },
  {
    taskId: 5,
    name: $r('app.string.task_sleep'),
    icon: $r('app.media.ic_task_sleep'),
    dialogIcon: $r('app.media.ic_dialog_sleep'),
    cardIcon: $r('app.media.ic_card_sleep'),
    type: TaskType.TIME,
    step: '',
    pickerType: PickerType.TIME,
    pickerRange: [],
    unit: $r('app.string.unit_pre_day'),
    isAlertEnabled: true,
    defaultTarget: '23:00',
    iconKey: 'sleep',
    unitText: '/ 天'
  },
  {
    taskId: 6,
    name: $r('app.string.task_run'),
    icon: $r('app.media.ic_task_run'),
    dialogIcon: $r('app.media.ic_dialog_run'),
    cardIcon: $r('app.media.ic_card_run'),
    type: TaskType.VALUE,
    step: '1',
    pickerType: PickerType.TEXT,
    pickerRange: ['1', '2', '3', '5'],
    unit: $r('app.string.unit_km'),
    isAlertEnabled: true,
    defaultTarget: '1',
    iconKey: 'run',
    unitText: '公里'
  }
];

/**
 * 根据 taskId 获取任务目录项
 */
export function getTaskCatalogItem(taskId: number): TaskCatalogItem | undefined {
  return TASK_CATALOG.find(item => item.taskId === taskId);
}

/**
 * 生成默认任务配置列表（全部关闭，填充完整元数据）
 */
export function createDefaultTaskInfoList(): TaskInfo[] {
  return TASK_CATALOG.map(item => new TaskInfo(
    item.taskId, false, item.defaultTarget, false, '', '', '', -1,
    '', item.iconKey, item.type, item.step, item.unitText,
    item.pickerType, item.pickerRange.join(','), '',
    true, false, item.taskId, 0
  ));
}
