import { DayInfo } from '../models/DayInfo';
import { DayTaskInfo } from '../models/DayTaskInfo';
import { RecoveryInfo } from '../models/RecoveryInfo';
import { TaskInfo } from '../models/TaskInfo';
import { TaskType } from '../constants/TaskCatalog';

/**
 * 成就类型枚举 — 多维成就
 */
export enum AchievementType {
  CONSECUTIVE = 'consecutive',     // 连续天数（已有）
  STABLE_COMPLETION = 'stable',    // 稳定完成：某任务最近7天完成5天
  RECOVERY = 'recovery',           // 恢复能力：使用补救后第二天完成100%
  PERFECT_WEEK = 'perfect_week'    // 全勤周：自然周内每天有效完成或补救
}

export const OVERACHIEVEMENT_THRESHOLDS: number[] = [200, 300, 400, 500];

/**
 * 多维成就状态
 */
export class AchievementStatus {
  type: AchievementType;
  unlocked: boolean;
  description: string;

  constructor(type: AchievementType, unlocked: boolean, description: string) {
    this.type = type;
    this.unlocked = unlocked;
    this.description = description;
  }
}

/**
 * 单项任务成就摘要。
 * singleAchieved: 该任务历史上至少完成过一次。
 * maxPercent: 数值任务历史最高完成百分比；非数值任务完成后为 100。
 */
export class TaskAchievementSummary {
  taskId: number;
  taskName: string;
  iconKey: string;
  taskType: TaskType;
  singleAchieved: boolean;
  maxPercent: number;

  constructor(
    taskId: number,
    taskName: string,
    iconKey: string,
    taskType: TaskType,
    singleAchieved: boolean = false,
    maxPercent: number = 0
  ) {
    this.taskId = taskId;
    this.taskName = taskName;
    this.iconKey = iconKey;
    this.taskType = taskType;
    this.singleAchieved = singleAchieved;
    this.maxPercent = maxPercent;
  }

  isMultiplierUnlocked(threshold: number): boolean {
    return this.taskType === TaskType.VALUE && this.maxPercent >= threshold;
  }
}

export function calculateTaskAchievementSummaries(
  dayTasks: DayTaskInfo[],
  tasks: TaskInfo[]
): TaskAchievementSummary[] {
  const taskMap = new Map<number, TaskInfo>();
  for (const task of tasks) {
    taskMap.set(task.taskId, task);
  }

  const summaryMap = new Map<number, TaskAchievementSummary>();
  for (const task of tasks) {
    summaryMap.set(task.taskId, new TaskAchievementSummary(
      task.taskId,
      task.taskName,
      task.iconKey,
      task.taskType,
      false,
      0
    ));
  }

  for (const dayTask of dayTasks) {
    const task = taskMap.get(dayTask.taskId);
    if (!task) {
      continue;
    }

    let summary = summaryMap.get(dayTask.taskId);
    if (!summary) {
      summary = new TaskAchievementSummary(dayTask.taskId, task.taskName, task.iconKey, task.taskType, false, 0);
      summaryMap.set(dayTask.taskId, summary);
    }

    if (dayTask.isDone) {
      summary.singleAchieved = true;
    }

    const target = parseFloat(dayTask.targetValue) || 0;
    const fin = parseFloat(dayTask.finValue) || 0;
    if (task.taskType === TaskType.VALUE && target > 0) {
      const percent = Math.floor(fin / target * 100);
      if (percent > summary.maxPercent) {
        summary.maxPercent = percent;
      }
      if (percent >= 100) {
        summary.singleAchieved = true;
      }
    } else if (dayTask.isDone && summary.maxPercent < 100) {
      summary.maxPercent = 100;
    }
  }

  return Array.from(summaryMap.values()).sort((a: TaskAchievementSummary, b: TaskAchievementSummary): number => {
    return a.taskId - b.taskId;
  });
}

/**
 * 检查"稳定完成"成就：某任务最近 7 天完成 5 天及以上
 */
export function checkStableCompletion(recentTasks: DayTaskInfo[]): AchievementStatus {
  if (!recentTasks || recentTasks.length < 5) {
    return new AchievementStatus(
      AchievementType.STABLE_COMPLETION, false, '数据不足'
    );
  }
  const completedDays = recentTasks.filter(t => t.isDone).length;
  const unlocked = completedDays >= 5;
  return new AchievementStatus(
    AchievementType.STABLE_COMPLETION,
    unlocked,
    unlocked ? `最近7天完成${completedDays}天` : `最近7天完成${completedDays}天，未达标`
  );
}

/**
 * 检查"恢复能力"成就：使用补救后第二天完成 100%
 * @param yesterdayRecovery 昨天的补救记录
 * @param todayDayInfo 今天的完成情况
 */
export function checkRecoveryAchievement(
  yesterdayRecovery: RecoveryInfo | null,
  todayDayInfo: DayInfo | null
): AchievementStatus {
  if (yesterdayRecovery === null || !yesterdayRecovery.used) {
    return new AchievementStatus(
      AchievementType.RECOVERY, false, '未使用过补救'
    );
  }
  if (todayDayInfo === null || todayDayInfo.targetTaskNum === 0) {
    return new AchievementStatus(
      AchievementType.RECOVERY, false, '今天无任务数据'
    );
  }
  const unlocked = todayDayInfo.finTaskNum >= todayDayInfo.targetTaskNum;
  return new AchievementStatus(
    AchievementType.RECOVERY,
    unlocked,
    unlocked ? '补救后第二天完成100%' : '补救后第二天未完成'
  );
}

/**
 * 检查"全勤周"成就：自然周内每天有效完成或补救
 * @param weekDayInfos 本周 7 天的 DayInfo 列表
 * @param weekRecoveries 本周的补救记录列表
 */
export function checkPerfectWeek(
  weekDayInfos: DayInfo[],
  weekRecoveries: RecoveryInfo[]
): AchievementStatus {
  if (!weekDayInfos || weekDayInfos.length === 0) {
    return new AchievementStatus(
      AchievementType.PERFECT_WEEK, false, '数据不足'
    );
  }
  const recoveryMap = new Map<string, boolean>();
  for (const r of weekRecoveries) {
    recoveryMap.set(r.date, r.used);
  }

  let allDaysCompleted = true;
  let validDays = 0;

  for (const di of weekDayInfos) {
    if (di.targetTaskNum === 0) {
      continue; // 无记录的日期跳过
    }
    validDays++;
    const isComplete = di.finTaskNum >= di.targetTaskNum;
    const hasRecovery = recoveryMap.get(di.date) === true;
    if (!isComplete && !hasRecovery) {
      allDaysCompleted = false;
      break;
    }
  }

  if (validDays < 7) {
    return new AchievementStatus(
      AchievementType.PERFECT_WEEK, false, '本周数据不足'
    );
  }

  return new AchievementStatus(
    AchievementType.PERFECT_WEEK,
    allDaysCompleted,
    allDaysCompleted ? '本周全勤' : '本周未全勤'
  );
}
