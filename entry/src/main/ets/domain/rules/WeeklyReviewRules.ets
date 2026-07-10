import { DayInfo } from '../models/DayInfo';
import { DayTaskInfo } from '../models/DayTaskInfo';
import { getTaskCatalogItem } from '../constants/TaskCatalog';

/**
 * 任务完成统计（内部用）
 */
class TaskCompletionStats {
  completed: number = 0;
  total: number = 0;
}

/**
 * 周复盘结果
 */
export class WeeklyReview {
  completionRate: number;       // 0-100
  mostStableTaskId: number;     // -1 表示无
  mostStableTaskName: string;
  mostMissedTaskId: number;     // -1 表示无
  mostMissedTaskName: string;
  suggestion: string;
  isAvailable: boolean;         // 数据不足时为 false

  constructor() {
    this.completionRate = 0;
    this.mostStableTaskId = -1;
    this.mostStableTaskName = '';
    this.mostMissedTaskId = -1;
    this.mostMissedTaskName = '';
    this.suggestion = '';
    this.isAvailable = false;
  }
}

/**
 * 生成本地规则周复盘。
 *
 * 输入：最近 7 天的 DayInfo 和 DayTaskInfo 聚合数据。
 * 输出：完成率、最稳定任务、最易遗漏任务、一条建议。
 * 数据不足时返回 isAvailable=false。
 */
export function generateWeeklyReview(
  weekDayInfos: DayInfo[],
  weekDayTasks: DayTaskInfo[]
): WeeklyReview {
  const review = new WeeklyReview();

  if (!weekDayInfos || weekDayInfos.length < 3) {
    review.suggestion = '继续打卡几天后生成复盘';
    return review;
  }

  // 计算完成率
  let totalTarget = 0;
  let totalFinished = 0;
  for (const di of weekDayInfos) {
    totalTarget += di.targetTaskNum;
    totalFinished += di.finTaskNum;
  }
  if (totalTarget === 0) {
    review.suggestion = '继续打卡几天后生成复盘';
    return review;
  }
  review.completionRate = Math.round(totalFinished / totalTarget * 100);
  review.isAvailable = true;

  // 按 taskId 统计完成天数
  const taskIdMap = new Map<number, TaskCompletionStats>();
  for (const dt of weekDayTasks) {
    let entry = taskIdMap.get(dt.taskId);
    if (entry === undefined) {
      entry = new TaskCompletionStats();
      taskIdMap.set(dt.taskId, entry);
    }
    entry.total++;
    if (dt.isDone) {
      entry.completed++;
    }
  }

  // 找最稳定和最易遗漏
  let bestRate = -1;
  let worstRate = 2; // >100% 永远不可能
  let bestTaskId = -1;
  let worstTaskId = -1;

  taskIdMap.forEach((entry, taskId) => {
    if (entry.total === 0) return;
    const rate = entry.completed / entry.total;
    if (rate > bestRate) {
      bestRate = rate;
      bestTaskId = taskId;
    }
    if (rate < worstRate) {
      worstRate = rate;
      worstTaskId = taskId;
    }
  });

  // 获取任务名称（domain 层无法访问 resourceManager，存 taskId 供 UI 层解析）
  if (bestTaskId >= 0) {
    review.mostStableTaskId = bestTaskId;
    review.mostStableTaskName = `任务${bestTaskId}`;
  }
  if (worstTaskId >= 0 && worstTaskId !== bestTaskId) {
    review.mostMissedTaskId = worstTaskId;
    review.mostMissedTaskName = `任务${worstTaskId}`;
  }

  // 生成建议
  if (review.completionRate >= 80) {
    review.suggestion = '本周表现不错，继续保持当前目标。';
  } else if (review.completionRate >= 50) {
    if (worstTaskId >= 0) {
      review.suggestion = '完成率一般，建议把遗漏较多的任务目标先调低一档。';
    } else {
      review.suggestion = '完成率一般，建议保持当前目标，注意坚持。';
    }
  } else {
    review.suggestion = '本周完成率较低，建议先降低目标，稳定后再逐步提高。';
  }

  return review;
}
