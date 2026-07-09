/**
 * 应用全局常量
 */
export class AppConstants {
  // 任务数量
  static readonly TASK_NUM: number = 7;

  // 成就阈值
  static readonly ACHIEVEMENT_THRESHOLDS: number[] = [3, 7, 30, 50, 73, 99];

  // 日期格式
  static readonly DATE_FORMAT: string = 'yyyyMMdd';

  // 周
  static readonly WEEK_DAY_NUM: number = 7;
  static readonly WEEK_SHORTHAND_LIST: Resource[] = [
    $r('app.string.week_shorthand_mon'),
    $r('app.string.week_shorthand_tue'),
    $r('app.string.week_shorthand_wed'),
    $r('app.string.week_shorthand_thu'),
    $r('app.string.week_shorthand_fri'),
    $r('app.string.week_shorthand_sat'),
    $r('app.string.week_shorthand_sun')
  ];

  // Preferences 键名
  static readonly PREF_STORE: string = 'healthyLifePrefs';
  static readonly MAX_CONSECUTIVE_DAYS: string = 'maxConsecutiveDays';
  static readonly CURRENT_CONSECUTIVE_DAYS: string = 'currentConsecutiveDays';
  static readonly CURRENT_DAY_STATUS: string = 'currentDayStatus';

  // 数据库
  static readonly DATABASE_NAME: string = 'HealthyLife.db';
  static readonly DB_VERSION: number = 1;

  // 服务卡片
  static readonly FORM_NAME_AGENCY: string = 'agency';
  static readonly FORM_NAME_PROGRESS: string = 'progress';
  static readonly DIMENSION_1X2: number = 1;
  static readonly DIMENSION_2X2: number = 2;

  // 动画
  static readonly DURATION_200: number = 200;
  static readonly DURATION_800: number = 800;
  static readonly DURATION_1000: number = 1000;

  // 默认用户信息
  static readonly DEFAULT_MENU_INFO: Resource[] = [
    $r('app.string.mine_personal_data'),
    $r('app.string.mine_check_updates')
  ];
}
