/**
 * DayTaskInfo - 某一天的单个任务快照（承载每日完成状态）
 */
export class DayTaskInfo {
  id: number;
  date: string;       // yyyyMMdd
  taskId: number;
  targetValue: string;
  finValue: string;
  isDone: boolean;

  constructor(
    id: number = 0,
    date: string = '',
    taskId: number = 0,
    targetValue: string = '',
    finValue: string = '',
    isDone: boolean = false
  ) {
    this.id = id;
    this.date = date;
    this.taskId = taskId;
    this.targetValue = targetValue;
    this.finValue = finValue;
    this.isDone = isDone;
  }
}
