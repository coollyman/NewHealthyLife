import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { TaskInfo } from '../domain/models/TaskInfo';
import { getTaskCatalogItem } from '../domain/constants/TaskCatalog';

export class ReminderIntent {
  shouldSchedule: boolean;
  hour: number;
  minute: number;

  constructor(shouldSchedule: boolean, hour: number = 0, minute: number = 0) {
    this.shouldSchedule = shouldSchedule;
    this.hour = hour;
    this.minute = minute;
  }
}

/**
 * 提醒服务 - 封装后台代理提醒
 * 只有时间类任务（早起、早睡）需要提醒
 */

export function buildReminderIntent(task: TaskInfo): ReminderIntent {
  const catalogItem = getTaskCatalogItem(task.taskId);
  if (!catalogItem || !catalogItem.isAlertEnabled || !task.isOpen) {
    return new ReminderIntent(false);
  }

  const parts: string[] = task.targetValue.split(':');
  if (parts.length < 2) {
    return new ReminderIntent(false);
  }

  const hour = parseInt(parts[0], 10);
  const minute = parseInt(parts[1], 10);
  if (Number.isNaN(hour) || Number.isNaN(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return new ReminderIntent(false);
  }

  return new ReminderIntent(true, hour, minute);
}

/**
 * 创建或更新每日重复闹钟提醒
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
    actionButton: [actionButton]
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
