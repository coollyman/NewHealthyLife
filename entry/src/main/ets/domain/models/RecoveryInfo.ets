/**
 * RecoveryInfo - 补救日记录
 * 当天完成度达到 70% 及以上但未满 100% 时，用户可使用补救保持连续天数。
 * 每自然周最多 1 次。
 */
export class RecoveryInfo {
  date: string;       // yyyyMMdd，主键
  weekKey: string;     // 周一日期 yyyyMMdd，用于判断同周
  used: boolean;
  completionPercentAtUse: number;
  createdAt: number;   // 毫秒时间戳

  constructor(
    date: string = '',
    weekKey: string = '',
    used: boolean = false,
    completionPercentAtUse: number = 0,
    createdAt: number = 0
  ) {
    this.date = date;
    this.weekKey = weekKey;
    this.used = used;
    this.completionPercentAtUse = completionPercentAtUse;
    this.createdAt = createdAt;
  }
}
