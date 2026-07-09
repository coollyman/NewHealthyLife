import { DayInfo } from '../models/DayInfo';
import { DayTaskInfo } from '../models/DayTaskInfo';
import { TaskInfo } from '../models/TaskInfo';
import { createDayTaskFromTaskInfo } from './TaskRules';
import { countFinishedTasks } from './TaskRules';

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
 */
export function initializeDayData(
  date: string,
  activeTasks: TaskInfo[]
): DayInitResult {
  const dayTasks: DayTaskInfo[] = activeTasks
    .filter(t => t.isOpen)
    .map(t => createDayTaskFromTaskInfo(date, t));

  const dayInfo = new DayInfo(date, dayTasks.length, 0);
  return new DayInitResult(dayInfo, dayTasks);
}

/**
 * 确保启用任务都有对应的当日快照
 */
export function ensureDayTaskSnapshots(
  date: string,
  existingDayTasks: DayTaskInfo[],
  activeTasks: TaskInfo[]
): DayTaskInfo[] {
  const result: DayTaskInfo[] = [...existingDayTasks];
  const existingTaskIds = new Set<number>(existingDayTasks.map(t => t.taskId));

  for (const task of activeTasks) {
    if (task.isOpen && !existingTaskIds.has(task.taskId)) {
      result.push(createDayTaskFromTaskInfo(date, task));
    }
  }

  return result;
}

/**
 * 重新计算当日聚合进度
 */
export function recalculateDayInfo(
  dayInfo: DayInfo,
  dayTasks: DayTaskInfo[],
  activeTaskCount: number
): DayInfo {
  const targetTaskNum = dayTasks.length > 0 ? dayTasks.length : activeTaskCount;
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
