import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { TaskInfo } from '../domain/models/TaskInfo';
import { TaskType } from '../domain/constants/TaskCatalog';

export class ReminderIntent {
  shouldSchedule: boolean;
  hour: number;
  minute: number;
  daysOfWeek: number[]; // 1=周一 ... 7=周日

  constructor(shouldSchedule: boolean, hour: number = 0, minute: number = 0, daysOfWeek: number[] = []) {
    this.shouldSchedule = shouldSchedule;
    this.hour = hour;
    this.minute = minute;
    this.daysOfWeek = daysOfWeek;
  }
}

/**
 * 提醒服务 - 封装后台代理提醒
 * 时间类任务（早起、早睡）：从 targetValue 读取提醒时间
 * 跑步任务：从 alertStartTime 读取提醒时间，从 alertFrequency 读取周频率
 */

/**
 * 解析 HH:mm 时间字符串
 */
function parseTimeString(timeStr: string): [number, number] | null {
  const m = timeStr.match(/^([01]\d|2[0-3]):([0-5]\d)$/);
  if (!m) return null;
  const h = parseInt(m[1], 10);
  const min = parseInt(m[2], 10);
  if (Number.isNaN(h) || Number.isNaN(min)) return null;
  return [h, min];
}

/**
 * 解析 alertFrequency 字段（逗号分隔的 1..7 数字）为 daysOfWeek 数组
 * 1=周一, 2=周二, ... 7=周日
 * 空字符串返回空数组（调用方决定是否阻止调度）
 */
export function parseAlertFrequency(freq: string): number[] {
  if (!freq || freq.trim() === '') return [];
  const parts = freq.split(',').map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n) && n >= 1 && n <= 7);
  // 去重
  return Array.from(new Set(parts));
}

export function buildReminderIntent(task: TaskInfo): ReminderIntent {
  if (!task.isAlert || !task.isOpen) {
    return new ReminderIntent(false);
  }

  let timeStr: string;
  let daysOfWeek: number[] = [];

  if (task.taskType === TaskType.TIME) {
    // 时间类任务：从 targetValue 读取
    timeStr = task.targetValue;
    // 每日重复
    daysOfWeek = [1, 2, 3, 4, 5, 6, 7];
  } else {
    // 数值/一次性任务：需要 isAlert + alertStartTime + alertFrequency
    if (!task.isAlert) {
      return new ReminderIntent(false);
    }
    timeStr = task.alertStartTime;
    daysOfWeek = parseAlertFrequency(task.alertFrequency);
    if (daysOfWeek.length === 0) {
      return new ReminderIntent(false);
    }
  }

  const parsed = parseTimeString(timeStr);
  if (!parsed) {
    return new ReminderIntent(false);
  }

  return new ReminderIntent(true, parsed[0], parsed[1], daysOfWeek);
}

/**
 * 创建或更新重复闹钟提醒
 * @returns reminderId，失败返回 -1
 */
export async function createOrUpdateReminder(task: TaskInfo): Promise<number> {
  const intent = buildReminderIntent(task);
  if (!intent.shouldSchedule) {
    return -1;
  }

  // 如果已有提醒，先取消
  if (task.reminderId !== -1) {
    try {
      await reminderAgentManager.cancelReminder(task.reminderId);
    } catch (e) {
      // 忽略取消失败
    }
  }

  const actionButton: reminderAgentManager.ActionButton = {
    title: '知道了',
    type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
  };

  const reminderRequest: reminderAgentManager.ReminderRequestAlarm = {
    reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
    hour: intent.hour,
    minute: intent.minute,
    title: '健康生活',
    content: '健康生活打卡提醒',
    actionButton: [actionButton],
    daysOfWeek: intent.daysOfWeek
  };

  try {
    const reminderId = await reminderAgentManager.publishReminder(reminderRequest);
    return reminderId;
  } catch (e) {
    console.error('Failed to create reminder: ' + e);
    return -1;
  }
}

/**
 * 取消提醒
 */
export async function cancelReminder(reminderId: number): Promise<void> {
  if (reminderId === -1) {
    return;
  }
  try {
    await reminderAgentManager.cancelReminder(reminderId);
  } catch (e) {
    console.error('Failed to cancel reminder: ' + e);
  }
}

/**
 * 请求通知权限
 */
export async function requestNotificationPermission(): Promise<boolean> {
  try {
    await notificationManager.requestEnableNotification();
    return true;
  } catch (e) {
    console.error('Failed to request notification permission: ' + e);
    return false;
  }
}

/**
 * 检查是否有通知权限
 */
export async function hasNotificationPermission(): Promise<boolean> {
  try {
    return await notificationManager.isNotificationEnabled();
  } catch (e) {
    return false;
  }
}
