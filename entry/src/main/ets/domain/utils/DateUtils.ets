/**
 * 日期工具 - 集中管理日期格式化和跨天逻辑
 * 所有日期格式化必须通过此类，避免散落在各处
 */

/**
 * 将 Date 格式化为 yyyyMMdd 字符串
 */
export function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}${month}${day}`;
}

/**
 * 获取今天的 yyyyMMdd
 */
export function getToday(): string {
  return formatDate(new Date());
}

/**
 * 将 yyyyMMdd 解析为 Date
 */
export function parseDate(dateStr: string): Date {
  const year = parseInt(dateStr.substring(0, 4), 10);
  const month = parseInt(dateStr.substring(4, 6), 10) - 1;
  const day = parseInt(dateStr.substring(6, 8), 10);
  return new Date(year, month, day);
}

/**
 * 获取指定日期偏移天数的 yyyyMMdd
 * @param dateStr 基准日期 yyyyMMdd
 * @param offset 偏移天数（正为未来，负为过去）
 */
export function getDateOffset(dateStr: string, offset: number): string {
  const date = parseDate(dateStr);
  date.setDate(date.getDate() + offset);
  return formatDate(date);
}

/**
 * 获取指定日期是星期几（0=周日, 1=周一, ... 6=周六）
 */
export function getDayOfWeek(dateStr: string): number {
  return parseDate(dateStr).getDay();
}

/**
 * 获取以指定日期所在周为中心的三周（21天）日期列表
 * 返回从上周一到下周日的21个 yyyyMMdd
 */
export function getThreeWeekWindow(centerDateStr: string): string[] {
  const date = parseDate(centerDateStr);
  const dayOfWeek = date.getDay(); // 0=Sun
  // 转换为以周一为起点的偏移：周一=0, 周二=1, ... 周日=6
  const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  // 上周一 = 当前日期 - mondayOffset - 7
  const startMonday = new Date(date);
  startMonday.setDate(date.getDate() - mondayOffset - 7);

  const result: string[] = [];
  for (let i = 0; i < 21; i++) {
    const d = new Date(startMonday);
    d.setDate(startMonday.getDate() + i);
    result.push(formatDate(d));
  }
  return result;
}

/**
 * 获取指定日期所在周的周一日期
 */
export function getMondayOfWeek(dateStr: string): string {
  const date = parseDate(dateStr);
  const dayOfWeek = date.getDay();
  const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  date.setDate(date.getDate() - mondayOffset);
  return formatDate(date);
}

/**
 * 比较两个 yyyyMMdd 日期
 * @returns 正数表示 dateStr1 > dateStr2, 负数表示 dateStr1 < dateStr2
 */
export function compareDate(dateStr1: string, dateStr2: string): number {
  return parseInt(dateStr1, 10) - parseInt(dateStr2, 10);
}

/**
 * 判断 dateStr 是否是今天
 */
export function isToday(dateStr: string): boolean {
  return dateStr === getToday();
}

/**
 * 获取 yyyyMMdd 中哪一天的部分（dd）
 */
export function getDayOfMonth(dateStr: string): number {
  return parseInt(dateStr.substring(6, 8), 10);
}

/**
 * 获取两个日期相差天数（dateStr2 - dateStr1）
 */
export function diffDays(dateStr1: string, dateStr2: string): number {
  const d1 = parseDate(dateStr1);
  const d2 = parseDate(dateStr2);
  return Math.round((d2.getTime() - d1.getTime()) / (1000 * 60 * 60 * 24));
}
