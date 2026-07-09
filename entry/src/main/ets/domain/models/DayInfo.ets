/**
 * DayInfo - 某一天的聚合进度
 */
export class DayInfo {
  date: string;       // yyyyMMdd
  targetTaskNum: number;
  finTaskNum: number;

  constructor(date: string = '', targetTaskNum: number = 0, finTaskNum: number = 0) {
    this.date = date;
    this.targetTaskNum = targetTaskNum;
    this.finTaskNum = finTaskNum;
  }

  calculatePercentage(): number {
    if (this.targetTaskNum === 0) {
      return 0;
    }
    return Math.ceil(this.finTaskNum / this.targetTaskNum * 100);
  }
}
