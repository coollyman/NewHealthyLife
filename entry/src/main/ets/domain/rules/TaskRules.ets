import { TaskType } from '../constants/TaskCatalog';
import { DayTaskInfo } from '../models/DayTaskInfo';
import { TaskInfo } from '../models/TaskInfo';

/**
 * 打卡规则 - 纯函数，不依赖 HarmonyOS 运行时
 */

/**
 * 判断任务是否可以打卡
 */
export function canCheckin(task: DayTaskInfo, taskInfo?: TaskInfo): boolean {
  if (!task.isDone) {
    return true;
  }
  return taskInfo !== undefined && taskInfo.taskType === TaskType.VALUE;
}

/**
 * 执行打卡，返回更新后的 DayTaskInfo（不可变，返回新对象）
 * - 一次性/时间类任务：直接完成
 * - 数值任务：增加 step，达到目标时标记完成
 *
 * @param dayTask 当日任务快照
 * @param taskInfo 全局任务配置（用于获取 taskType 和 step）
 */
export function checkinTask(dayTask: DayTaskInfo, taskInfo: TaskInfo): DayTaskInfo {
  if (dayTask.isDone && taskInfo.taskType !== TaskType.VALUE) {
    return dayTask; // 已完成不重复打卡
  }

  const result = new DayTaskInfo(
    dayTask.id, dayTask.date, dayTask.taskId,
    dayTask.targetValue, dayTask.finValue, dayTask.isDone
  );

  switch (taskInfo.taskType) {
    case TaskType.ONCE:
    case TaskType.TIME:
      result.finValue = dayTask.targetValue;
      result.isDone = true;
      break;
    case TaskType.VALUE:
      const currentFin = parseFloat(dayTask.finValue) || 0;
      const target = parseFloat(dayTask.targetValue) || 0;
      const step = parseFloat(taskInfo.step) || 1;
      const newFin = currentFin + step;
      result.finValue = newFin.toString();
      if (newFin >= target) {
        result.isDone = true;
      }
      break;
  }

  return result;
}

/**
 * 撤销打卡，返回更新后的 DayTaskInfo（不可变，返回新对象）
 * - 一次性/时间类任务：重置为未完成
 * - 数值任务：回退一个 step，不低于 0
 */
export function undoCheckinTask(dayTask: DayTaskInfo, taskInfo: TaskInfo): DayTaskInfo {
  const result = new DayTaskInfo(
    dayTask.id, dayTask.date, dayTask.taskId,
    dayTask.targetValue, dayTask.finValue, dayTask.isDone
  );

  switch (taskInfo.taskType) {
    case TaskType.ONCE:
    case TaskType.TIME:
      result.finValue = '';
      result.isDone = false;
      break;
    case TaskType.VALUE:
      const currentFin = parseFloat(dayTask.finValue) || 0;
      const step = parseFloat(taskInfo.step) || 1;
      const newFin = Math.max(0, currentFin - step);
      result.finValue = newFin > 0 ? newFin.toString() : '';
      result.isDone = false;
      break;
  }

  return result;
}

/**
 * 从任务配置创建默认的当日任务快照
 */
export function createDayTaskFromTaskInfo(date: string, taskInfo: TaskInfo): DayTaskInfo {
  return new DayTaskInfo(0, date, taskInfo.taskId, taskInfo.targetValue, '', false);
}

/**
 * 计算当日已完成任务数
 */
export function countFinishedTasks(dayTasks: DayTaskInfo[]): number {
  return dayTasks.filter(t => t.isDone).length;
}
