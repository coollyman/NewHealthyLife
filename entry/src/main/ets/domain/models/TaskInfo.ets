/**
 * TaskInfo - 全局任务配置（不包含当天完成状态）
 * 每日完成状态由 DayTaskInfo 承载
 */
export class TaskInfo {
  taskId: number;
  isOpen: boolean;
  targetValue: string;
  isAlert: boolean;
  alertStartTime: string;
  alertEndTime: string;
  alertFrequency: string;
  reminderId: number;

  constructor(
    taskId: number = 0,
    isOpen: boolean = false,
    targetValue: string = '',
    isAlert: boolean = false,
    alertStartTime: string = '',
    alertEndTime: string = '',
    alertFrequency: string = '',
    reminderId: number = -1
  ) {
    this.taskId = taskId;
    this.isOpen = isOpen;
    this.targetValue = targetValue;
    this.isAlert = isAlert;
    this.alertStartTime = alertStartTime;
    this.alertEndTime = alertEndTime;
    this.alertFrequency = alertFrequency;
    this.reminderId = reminderId;
  }

  deepClone(): TaskInfo {
    return new TaskInfo(
      this.taskId, this.isOpen, this.targetValue, this.isAlert,
      this.alertStartTime, this.alertEndTime, this.alertFrequency, this.reminderId
    );
  }
}
