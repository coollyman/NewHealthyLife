import { TaskInfo } from '../models/TaskInfo';
import { TaskType, PickerType, getTaskCatalogItem, TaskCatalogItem } from './TaskCatalog';

/**
 * 任务展示元数据 — 统一从 TaskInfo 解析，不再只依赖 catalog
 */
export class TaskDisplayMeta {
  taskName: string;
  iconKey: string;
  taskType: TaskType;
  step: string;
  unitText: string;
  pickerType: PickerType;
  targetOptions: string[];
  isPreset: boolean;
  isAlertEnabled: boolean;

  constructor() {
    this.taskName = '';
    this.iconKey = '';
    this.taskType = TaskType.ONCE;
    this.step = '';
    this.unitText = '';
    this.pickerType = PickerType.NONE;
    this.targetOptions = [];
    this.isPreset = false;
    this.isAlertEnabled = false;
  }
}

/**
 * 图标 key -> Resource 白名单映射
 * 预设任务沿用 catalog 资源；自定义任务从此白名单选取
 */
export function getIconResource(iconKey: string): Resource {
  switch (iconKey) {
    case 'getup': return $r('app.media.ic_task_getup');
    case 'drink': return $r('app.media.ic_task_drink');
    case 'apple': return $r('app.media.ic_task_apple');
    case 'smile': return $r('app.media.ic_task_smile');
    case 'brush': return $r('app.media.ic_task_brush');
    case 'sleep': return $r('app.media.ic_task_sleep');
    case 'run': return $r('app.media.ic_task_run');
    case 'exercise': return $r('app.media.ic_task_run');
    case 'book': return $r('app.media.ic_task_smile');
    case 'meditation': return $r('app.media.ic_task_smile');
    case 'water': return $r('app.media.ic_task_drink');
    case 'weight': return $r('app.media.ic_task_run');
    default: return $r('app.media.ic_task_smile');
  }
}

/**
 * 图标 key -> 打卡弹窗图标 Resource
 */
export function getDialogIconResource(iconKey: string): Resource {
  switch (iconKey) {
    case 'getup': return $r('app.media.ic_dialog_getup');
    case 'drink': return $r('app.media.ic_dialog_drink');
    case 'apple': return $r('app.media.ic_dialog_apple');
    case 'smile': return $r('app.media.ic_dialog_smile');
    case 'brush': return $r('app.media.ic_dialog_brush');
    case 'sleep': return $r('app.media.ic_dialog_sleep');
    case 'run': return $r('app.media.ic_dialog_run');
    case 'exercise': return $r('app.media.ic_dialog_run');
    default: return $r('app.media.ic_dialog_smile');
  }
}

/**
 * 内置图标白名单 — 供自定义任务选择
 */
export const ICON_KEY_OPTIONS: string[] = [
  'getup', 'drink', 'apple', 'smile', 'brush', 'sleep', 'run',
  'exercise', 'book', 'meditation', 'water', 'weight'
];

/**
 * 从 TaskInfo 解析展示元数据。
 * 预设任务从 catalog 取 Resource 字段；
 * 自定义任务从 TaskInfo 自身字段取。
 */
export function getTaskDisplayMeta(task: TaskInfo): TaskDisplayMeta {
  const meta = new TaskDisplayMeta();

  if (task.isPreset) {
    const catalog = getTaskCatalogItem(task.taskId);
    if (catalog) {
      meta.taskName = catalog.name.id.toString(); // Resource id，UI 用 resourceManager 解析
      meta.iconKey = catalog.iconKey;
      meta.taskType = catalog.type;
      meta.step = catalog.step;
      meta.unitText = catalog.unitText;
      meta.pickerType = catalog.pickerType;
      meta.targetOptions = catalog.pickerRange;
      meta.isPreset = true;
      meta.isAlertEnabled = catalog.isAlertEnabled;
      return meta;
    }
  }

  // 自定义任务或 catalog 缺失时，从 TaskInfo 字段取
  meta.taskName = task.taskName;
  meta.iconKey = task.iconKey;
  meta.taskType = task.taskType;
  meta.step = task.step;
  meta.unitText = task.unitText;
  meta.pickerType = task.pickerType;
  meta.targetOptions = task.targetOptions
    ? task.targetOptions.split(',').filter(s => s.length > 0)
    : [];
  meta.isPreset = task.isPreset;
  meta.isAlertEnabled = task.isAlert;
  return meta;
}

/**
 * 获取任务名称字符串（需要 Resource 解析的由 UI 层处理）
 * 预设任务返回 Resource id 字符串，UI 用 resourceManager.getStringSync；
 * 自定义任务直接返回 taskName 字符串。
 */
export function getTaskNameString(task: TaskInfo): string {
  if (task.isPreset) {
    const catalog = getTaskCatalogItem(task.taskId);
    if (catalog) {
      return catalog.name.id.toString();
    }
  }
  return task.taskName;
}

/**
 * 判断任务是否在指定星期几需要执行
 * scheduleDays 为空表示每天执行
 * dayOfWeek: 0=周日, 1=周一, ... 6=周六
 */
export function isScheduledOnDay(task: TaskInfo, dayOfWeek: number): boolean {
  if (!task.scheduleDays || task.scheduleDays.trim() === '') {
    return true; // 每天执行
  }
  // scheduleDays 用 1-7（1=周一, 7=周日）
  // dayOfWeek 是 0=周日, 需转换为 1-7
  const dayNum = dayOfWeek === 0 ? 7 : dayOfWeek;
  const parts = task.scheduleDays.split(',').map(s => parseInt(s.trim(), 10));
  return parts.includes(dayNum);
}
