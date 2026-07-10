import { DayInfo } from '../models/DayInfo';
import { DayTaskInfo } from '../models/DayTaskInfo';
import { TaskInfo } from '../models/TaskInfo';
import { createDayTaskFromTaskInfo } from './TaskRules';
import { countFinishedTasks } from './TaskRules';
import { getDayOfWeek } from '../utils/DateUtils';
import { isScheduledOnDay } from '../constants/TaskDisplayMeta';

/**
 * 日期初始化结果
 */
export class DayInitResult {
  dayInfo: DayInfo;
  dayTasks: DayTaskInfo[];

  constructor(dayInfo: DayInfo, dayTasks: DayTaskInfo[]) {
    this.dayInfo = dayInfo;
    this.dayTasks = dayTasks;
  }
}

/**
 * 日期初始化规则
 */

/**
 * 为指定日期创建初始 DayInfo 和 DayTask 列表
 * 只为 scheduleDays 包含当天星期的任务创建快照
 */
export function initializeDayData(
  date: string,
  activeTasks: TaskInfo[]
): DayInitResult {
  const dayOfWeek = getDayOfWeek(date);
  const dayTasks: DayTaskInfo[] = activeTasks
    .filter(t => t.isOpen && !t.isArchived && isScheduledOnDay(t, dayOfWeek))
    .map(t => createDayTaskFromTaskInfo(date, t));

  const dayInfo = new DayInfo(date, dayTasks.length, 0);
  return new DayInitResult(dayInfo, dayTasks);
}

/**
 * 确保启用任务都有对应的当日快照
 * 只为 scheduleDays 包含当天星期的任务补快照
 */
export function ensureDayTaskSnapshots(
  date: string,
  existingDayTasks: DayTaskInfo[],
  activeTasks: TaskInfo[]
): DayTaskInfo[] {
  const result: DayTaskInfo[] = [...existingDayTasks];
  const existingTaskIds = new Set<number>(existingDayTasks.map(t => t.taskId));
  const dayOfWeek = getDayOfWeek(date);

  for (const task of activeTasks) {
    if (task.isOpen && !task.isArchived && isScheduledOnDay(task, dayOfWeek) && !existingTaskIds.has(task.taskId)) {
      result.push(createDayTaskFromTaskInfo(date, task));
    }
  }

  return result;
}

/**
 * 重新计算当日聚合进度。
 * targetTaskNum 使用 dayTasks.length，不再回退到 activeTaskCount——
 * 如果今天没有排期任务（scheduleDays 过滤后为空），targetTaskNum 应为 0 而非总启用数。
 * activeTaskCount 仅在 dayTasks 为空且 dayInfo 已有 targetTaskNum > 0 时用于保留旧值。
 */
export function recalculateDayInfo(
  dayInfo: DayInfo,
  dayTasks: DayTaskInfo[],
  activeTaskCount: number
): DayInfo {
  const targetTaskNum = dayTasks.length > 0 ? dayTasks.length : 0;
  const finTaskNum = countFinishedTasks(dayTasks);
  return new DayInfo(dayInfo.date, targetTaskNum, finTaskNum);
}

/**
 * 停用任务时，从当日任务列表中移除该任务
 */
export function removeInactiveTaskFromDay(
  dayTasks: DayTaskInfo[],
  taskId: number
): DayTaskInfo[] {
  return dayTasks.filter(t => t.taskId !== taskId || t.isDone);
}
