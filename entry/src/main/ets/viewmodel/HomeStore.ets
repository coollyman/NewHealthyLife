import { TaskInfo, CustomTaskInput, CUSTOM_TASK_ID_START } from '../domain/models/TaskInfo';
import { DayInfo } from '../domain/models/DayInfo';
import { DayTaskInfo } from '../domain/models/DayTaskInfo';
import { RecoveryInfo } from '../domain/models/RecoveryInfo';
import { TaskInfoRepository } from '../data/db/TaskInfoRepository';
import { DayInfoRepository } from '../data/db/DayInfoRepository';
import { DayTaskRepository } from '../data/db/DayTaskRepository';
import { RecoveryRepository } from '../data/db/RecoveryRepository';
import { PreferencesRepository } from '../data/prefs/PreferencesRepository';
import { FormService } from '../services/FormService';
import { checkinTask, canCheckin } from '../domain/rules/TaskRules';
import {
  isAllTasksCompleted,
  onAllTasksCompleted,
  onCurrentDayCompletionRevoked,
  onNewDay,
  ConsecutiveDaysState
} from '../domain/rules/ConsecutiveDaysRules';
import { initializeDayData, ensureDayTaskSnapshots, recalculateDayInfo, removeInactiveTaskFromDay } from '../domain/rules/DayInitRules';
import { getToday, getDateOffset, compareDate, getMonthGrid, getMondayOfWeek, getMonthOffset, getYearMonth, diffDays, getDayOfWeek } from '../domain/utils/DateUtils';
import { getTaskCatalogItem } from '../domain/constants/TaskCatalog';
import { isScheduledOnDay } from '../domain/constants/TaskDisplayMeta';
import { createOrUpdateReminder, cancelReminder, hasNotificationPermission, requestNotificationPermission } from '../services/ReminderService';
import {
  ITaskRepository,
  IDayInfoRepository,
  IDayTaskRepository,
  IPrefRepository,
  IFormService,
  IRecoveryRepository
} from '../domain/ports/RepositoryPorts';
import { suggestGoalAdjustment, GoalSuggestion } from '../domain/rules/GoalSuggestionRules';
import {
  canUseRecovery,
  createRecoveryRecord,
  getWeekKey,
  isDayCompletedForStreak
} from '../domain/rules/RecoveryRules';
import { generateWeeklyReview, WeeklyReview } from '../domain/rules/WeeklyReviewRules';
import { calculateTaskAchievementSummaries, TaskAchievementSummary } from '../domain/rules/AchievementRules';

export function isHomeStoreDataReady(tasks: TaskInfo[] | undefined | null): boolean {
  return !!tasks && tasks.length > 0;
}

class LoadedDayData {
  dayInfo: DayInfo;
  dayTasks: DayTaskInfo[];

  constructor(dayInfo: DayInfo, dayTasks: DayTaskInfo[]) {
    this.dayInfo = dayInfo;
    this.dayTasks = dayTasks;
  }
}

/**
 * HomeStore 依赖注入容器 — 测试用
 */
export class HomeStoreDeps {
  taskRepo: ITaskRepository;
  dayRepo: IDayInfoRepository;
  dayTaskRepo: IDayTaskRepository;
  prefRepo: IPrefRepository;
  formService: IFormService;
  recoveryRepo: IRecoveryRepository;

  constructor(
    taskRepo: ITaskRepository,
    dayRepo: IDayInfoRepository,
    dayTaskRepo: IDayTaskRepository,
    prefRepo: IPrefRepository,
    formService: IFormService,
    recoveryRepo: IRecoveryRepository
  ) {
    this.taskRepo = taskRepo;
    this.dayRepo = dayRepo;
    this.dayTaskRepo = dayTaskRepo;
    this.prefRepo = prefRepo;
    this.formService = formService;
    this.recoveryRepo = recoveryRepo;
  }
}

/**
 * 首页 ViewModel - 管理首页状态和业务操作
 */
@Observed
export class HomeStore {
  // 选中日期
  selectedDate: string = getToday();
  // 当日聚合
  dayInfo: DayInfo = new DayInfo(getToday(), 0, 0);
  // 当日任务列表
  dayTasks: DayTaskInfo[] = [];
  // 所有任务配置
  allTasks: TaskInfo[] = [];
  // 连续天数状态
  consecutiveState: ConsecutiveDaysState = new ConsecutiveDaysState();
  // 月视图是否激活
  isMonthView: boolean = false;
  // 月视图浏览日期 — 跨月切换时更新，不影响 selectedDate
  monthViewDate: string = getToday();
  // 月视图数据：日期 -> 完成状态（0=无记录, 1=未完成, 2=部分完成, 3=全部完成）
  monthViewData: Map<string, number> = new Map<string, number>();
  // 月视图是否正在加载 — 防止快速切换时请求乱序
  isMonthLoading: boolean = false;
  calendarDayStatus: Map<string, number> = new Map<string, number>();
  // 今天是否已使用补救
  todayRecovery: RecoveryInfo | null = null;

  private taskRepo: ITaskRepository;
  private dayRepo: IDayInfoRepository;
  private dayTaskRepo: IDayTaskRepository;
  private prefRepo: IPrefRepository;
  private formService: IFormService;
  private recoveryRepo: IRecoveryRepository;

  /**
   * 生产构造 — 使用真实仓储实现
   */
  constructor() {
    this.taskRepo = new TaskInfoRepository();
    this.dayRepo = new DayInfoRepository();
    this.dayTaskRepo = new DayTaskRepository();
    this.prefRepo = PreferencesRepository.getInstance();
    this.formService = new FormService();
    this.recoveryRepo = new RecoveryRepository();
  }

  /**
   * 测试构造 — 注入内存假仓库，绕过 RDB/Preferences/FormProvider
   */
  constructorForTest(deps: HomeStoreDeps): void {
    this.selectedDate = getToday();
    this.dayInfo = new DayInfo(getToday(), 0, 0);
    this.dayTasks = [];
    this.allTasks = [];
    this.consecutiveState = new ConsecutiveDaysState();
    this.isMonthView = false;
    this.monthViewDate = getToday();
    this.monthViewData = new Map<string, number>();
    this.isMonthLoading = false;
    this.calendarDayStatus = new Map<string, number>();
    this.todayRecovery = null;
    this.taskRepo = deps.taskRepo;
    this.dayRepo = deps.dayRepo;
    this.dayTaskRepo = deps.dayTaskRepo;
    this.prefRepo = deps.prefRepo;
    this.formService = deps.formService;
    this.recoveryRepo = deps.recoveryRepo;
  }

  /**
   * 测试工厂 — 创建注入假仓库的 HomeStore 实例
   */
  static createForTest(deps: HomeStoreDeps): HomeStore {
    const store = new HomeStore();
    store.constructorForTest(deps);
    return store;
  }

  /**
   * 初始化应用数据
   */
  async initAppData(): Promise<void> {
    // 确保默认任务
    await this.taskRepo.ensureDefaultTasks();
    // 加载连续天数状态
    this.consecutiveState = await this.prefRepo.getConsecutiveState();

    // 新的一天检查
    const today = getToday();
    const yesterday = getDateOffset(today, -1);
    const yesterdayInfo = await this.dayRepo.getDayInfo(yesterday);
    const yesterdayRecovery = await this.recoveryRepo.getRecoveryByDate(yesterday);
    this.consecutiveState = onNewDay(yesterdayInfo, this.consecutiveState, yesterdayRecovery);
    await this.prefRepo.saveConsecutiveState(this.consecutiveState);

    // 初始化今天的数据
    await this.initDayData(today);

    // 加载今天的补救记录
    this.todayRecovery = await this.recoveryRepo.getRecoveryByDate(today);

    // 用真实历史记录校准连续天数，避免 Preferences 残留导致成就页显示错误。
    this.consecutiveState = await this.rebuildConsecutiveStateFromHistory(today);
    await this.prefRepo.saveConsecutiveState(this.consecutiveState);

    // 加载所有任务
    this.allTasks = await this.taskRepo.getAllTasks();
  }

  /**
   * 初始化指定日期的数据
   */
  async initDayData(date: string): Promise<void> {
    const loaded = await this.loadDayData(date);
    this.dayInfo = loaded.dayInfo;
    this.dayTasks = loaded.dayTasks;
    this.selectedDate = date;
    await this.loadWeekStatusData(date);
  }

  private async loadDayData(date: string): Promise<LoadedDayData> {
    let dayInfo = await this.dayRepo.getDayInfo(date);
    const activeTasks = await this.taskRepo.getActiveTasks();
    const today = getToday();
    const isTodayDate = date === today;
    const isFutureDate = compareDate(date, today) > 0;
    let dayTasks: DayTaskInfo[] = [];

    if (dayInfo === null) {
      if (!isTodayDate) {
        if (isFutureDate) {
          const preview = initializeDayData(date, activeTasks);
          return new LoadedDayData(preview.dayInfo, preview.dayTasks);
        }
        return new LoadedDayData(new DayInfo(date, 0, 0), []);
      }

      // 创建初始数据
      const initResult = initializeDayData(date, activeTasks);
      await this.dayRepo.upsertDayInfo(initResult.dayInfo);
      await this.dayTaskRepo.batchInsertDayTasks(initResult.dayTasks);
      dayInfo = initResult.dayInfo;
      dayTasks = initResult.dayTasks;
    } else {
      let existingTasks = await this.dayTaskRepo.getDayTasks(date);
      if (isTodayDate) {
        // 只有今天会根据当前启用任务补快照；历史日期只展示已保存记录。
        existingTasks = ensureDayTaskSnapshots(date, existingTasks, activeTasks);
        for (const dt of existingTasks) {
          if (dt.id === 0) {
            dt.id = await this.dayTaskRepo.upsertDayTask(dt);
          }
        }
      }
      dayTasks = existingTasks;
    }

    dayInfo = recalculateDayInfo(dayInfo, dayTasks, activeTasks.length);
    if (isTodayDate) {
      await this.dayRepo.upsertDayInfo(dayInfo);
    }
    return new LoadedDayData(dayInfo, dayTasks);
  }

  /**
   * 切换选中日期
   */
  async selectDate(date: string): Promise<void> {
    await this.initDayData(date);
  }

  /**
   * 打卡
   */
  async checkin(dayTaskId: number): Promise<boolean> {
    const dayTask = this.dayTasks.find(t => t.id === dayTaskId);
    if (!dayTask) {
      return false;
    }

    // 获取任务配置（用于 taskType 和 step）
    const taskInfo = this.allTasks.find(t => t.taskId === dayTask.taskId);
    if (!taskInfo) {
      return false;
    }
    if (!canCheckin(dayTask, taskInfo)) {
      return false;
    }

    // 执行打卡
    const updated = checkinTask(dayTask, taskInfo);
    await this.dayTaskRepo.updateDayTask(updated);

    // 更新内存
    const idx = this.dayTasks.findIndex(t => t.id === dayTaskId);
    this.dayTasks[idx] = updated;
    this.dayTasks = [...this.dayTasks]; // 触发 UI 更新

    // 重新计算当日聚合
    const activeCount = this.allTasks.filter(t => t.isOpen).length;
    this.dayInfo = recalculateDayInfo(this.dayInfo, this.dayTasks, activeCount);
    await this.dayRepo.upsertDayInfo(this.dayInfo);

    await this.syncTodayCompletionState(this.dayInfo);

    this.updateCalendarDayStatus(this.dayInfo);
    this.updateMonthViewData(this.dayInfo);

    // 更新服务卡片
    await this.formService.updateAllForms(this.dayInfo, this.dayTasks, this.allTasks);

    return true;
  }

  /**
   * 获取新解锁的成就（调用后清除）
   */
  popNewlyUnlockedAchievement(): number | null {
    const result = this.consecutiveState.newlyUnlockedAchievement;
    this.consecutiveState.newlyUnlockedAchievement = null;
    return result;
  }

  /**
   * 启用任务
   */
  async enableTask(taskId: number): Promise<void> {
    const task = this.allTasks.find(t => t.taskId === taskId);
    if (!task) return;

    task.isOpen = true;
    await this.taskRepo.updateTask(task);

    // 为当天创建任务快照（检查 scheduleDays）
    const today = getToday();
    const dayOfWeek = getDayOfWeek(today);
    if (isScheduledOnDay(task, dayOfWeek)) {
      const newDayTask = new DayTaskInfo(0, today, taskId, task.targetValue, '', false);
      newDayTask.id = await this.dayTaskRepo.upsertDayTask(newDayTask);
    }

    const todayData = await this.loadDayData(today);
    await this.syncTodayCompletionState(todayData.dayInfo);
    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = todayData.dayTasks;
    } else if (compareDate(this.selectedDate, today) > 0) {
      const selectedData = await this.loadDayData(this.selectedDate);
      this.dayInfo = selectedData.dayInfo;
      this.dayTasks = selectedData.dayTasks;
    }

    this.updateCalendarDayStatus(todayData.dayInfo);
    this.updateMonthViewData(todayData.dayInfo);

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks, this.allTasks);

    // 如果任务启用了提醒，创建提醒 — 非阻塞
    if (task.isAlert) {
      this.setupReminder(taskId).catch((e: Object) => {
        console.error('Failed to setup reminder: ' + e);
      });
    }
  }

  /**
   * 设置提醒（权限请求 + 创建闹钟）— 可独立异步执行，不阻塞调用方
   */
  private async setupReminder(taskId: number): Promise<void> {
    const task = this.allTasks.find(t => t.taskId === taskId);
    if (!task) return;
    if (!task.isAlert || !task.isOpen) {
      return;
    }

    try {
      const hasPerm = await hasNotificationPermission();
      if (!hasPerm) {
        await requestNotificationPermission();
      }
    } catch (e) {
      console.error('Failed to request notification permission: ' + e);
    }

    try {
      task.reminderId = await createOrUpdateReminder(task);
      await this.taskRepo.updateTask(task);
    } catch (e) {
      console.error('Failed to create reminder: ' + e);
    }
  }

  /**
   * 停用任务
   */
  async disableTask(taskId: number): Promise<void> {
    const task = this.allTasks.find(t => t.taskId === taskId);
    if (!task) return;

    task.isOpen = false;
    await this.taskRepo.updateTask(task);

    // 从今天任务列表移除该任务；历史日期的完成记录保留。
    const today = getToday();
    const todayTask = await this.dayTaskRepo.getDayTask(today, taskId);
    if (todayTask && !todayTask.isDone) {
      await this.dayTaskRepo.deleteDayTask(today, taskId);
    }
    const todayData = await this.loadDayData(today);
    await this.syncTodayCompletionState(todayData.dayInfo);

    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = removeInactiveTaskFromDay(todayData.dayTasks, taskId);
    } else if (compareDate(this.selectedDate, today) > 0) {
      const selectedData = await this.loadDayData(this.selectedDate);
      this.dayInfo = selectedData.dayInfo;
      this.dayTasks = selectedData.dayTasks;
    }

    this.updateCalendarDayStatus(todayData.dayInfo);
    this.updateMonthViewData(todayData.dayInfo);

    // 取消提醒
    if (task.reminderId !== -1) {
      await cancelReminder(task.reminderId);
      task.reminderId = -1;
      await this.taskRepo.updateTask(task);
    }

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks, this.allTasks);
  }

  /**
   * 更新任务目标
   */
  async updateTaskTarget(taskId: number, targetValue: string): Promise<void> {
    const task = this.allTasks.find(t => t.taskId === taskId);
    if (!task) return;

    task.targetValue = targetValue;
    await this.taskRepo.updateTask(task);

    // 更新今天的未完成任务快照目标
    const today = getToday();
    const dayTask = await this.dayTaskRepo.getDayTask(today, taskId);
    if (dayTask && !dayTask.isDone) {
      dayTask.targetValue = targetValue;
      await this.dayTaskRepo.updateDayTask(dayTask);
    }

    const todayData = await this.loadDayData(today);
    await this.syncTodayCompletionState(todayData.dayInfo);
    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = todayData.dayTasks;
    } else if (compareDate(this.selectedDate, today) > 0) {
      const selectedData = await this.loadDayData(this.selectedDate);
      this.dayInfo = selectedData.dayInfo;
      this.dayTasks = selectedData.dayTasks;
    }

    this.updateCalendarDayStatus(todayData.dayInfo);
    this.updateMonthViewData(todayData.dayInfo);

    // 如果任务启用了提醒，更新提醒
    if (task.isAlert && task.isOpen) {
      task.reminderId = await createOrUpdateReminder(task);
      await this.taskRepo.updateTask(task);
    }

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks, this.allTasks);
  }

  /**
   * 更新任务的提醒设置（alertStartTime, alertFrequency, isAlert）
   */
  async updateTaskAlert(taskId: number, isAlert: boolean, alertStartTime: string, alertFrequency: string): Promise<void> {
    const task = this.allTasks.find(t => t.taskId === taskId);
    if (!task) return;

    task.isAlert = isAlert;
    task.alertStartTime = alertStartTime;
    task.alertFrequency = alertFrequency;

    // 如果关闭提醒或任务未启用，取消已有提醒
    if (!isAlert || !task.isOpen) {
      if (task.reminderId !== -1) {
        await cancelReminder(task.reminderId);
        task.reminderId = -1;
      }
    } else {
      // 开启提醒：创建/更新提醒
      task.reminderId = await createOrUpdateReminder(task);
    }

    await this.taskRepo.updateTask(task);
  }

  /**
   * 获取进度百分比
   */
  getPercentage(): number {
    return this.dayInfo.calculatePercentage();
  }

  getCalendarDayStatus(date: string): number {
    if (date === this.selectedDate) {
      return this.getDayStatus(this.dayInfo);
    }
    return this.calendarDayStatus.get(date) ?? 0;
  }

  private getDayStatus(dayInfo: DayInfo | null): number {
    if (!dayInfo || dayInfo.targetTaskNum === 0) {
      return 0;
    }
    if (dayInfo.finTaskNum >= dayInfo.targetTaskNum) {
      return 3;
    }
    // 补救状态：完成度 >= 70% 且有补救记录 → 状态 4
    if (dayInfo.calculatePercentage() >= 70) {
      if (this.todayRecovery !== null && this.todayRecovery.date === dayInfo.date && this.todayRecovery.used) {
        return 4;
      }
    }
    if (dayInfo.finTaskNum > 0) {
      return 2;
    }
    return 1;
  }

  private updateCalendarDayStatus(dayInfo: DayInfo): void {
    const next = new Map<string, number>(this.calendarDayStatus);
    next.set(dayInfo.date, this.getDayStatus(dayInfo));
    this.calendarDayStatus = next;
  }

  /**
   * 如果月视图处于打开状态，且日期属于当前浏览月份，同步更新对应格的状态。
   */
  private updateMonthViewData(dayInfo: DayInfo): void {
    if (!this.isMonthView) {
      return;
    }
    if (getYearMonth(dayInfo.date) !== getYearMonth(this.monthViewDate)) {
      return;
    }
    const next = new Map<string, number>(this.monthViewData);
    next.set(dayInfo.date, this.getDayStatus(dayInfo));
    this.monthViewData = next;
  }

  private async syncTodayCompletionState(dayInfo: DayInfo): Promise<void> {
    if (dayInfo.date !== getToday()) {
      return;
    }

    const before = this.consecutiveState;
    if (isDayCompletedForStreak(dayInfo, this.todayRecovery)) {
      this.consecutiveState = onAllTasksCompleted(this.consecutiveState);
    } else {
      this.consecutiveState = onCurrentDayCompletionRevoked(this.consecutiveState);
    }

    if (this.consecutiveState !== before) {
      await this.prefRepo.saveConsecutiveState(this.consecutiveState);
    }
  }

  private async rebuildConsecutiveStateFromHistory(today: string): Promise<ConsecutiveDaysState> {
    const startDate = '19700101';
    const dayInfoList = await this.dayRepo.getDayInfoList(startDate, today);
    const recoveryList = await this.recoveryRepo.getRecoveryListByDateRange(startDate, today);
    const dayInfoMap = new Map<string, DayInfo>();
    const recoveryMap = new Map<string, RecoveryInfo>();
    const dateSet = new Set<string>();

    for (const info of dayInfoList) {
      dayInfoMap.set(info.date, info);
      dateSet.add(info.date);
    }
    for (const recovery of recoveryList) {
      recoveryMap.set(recovery.date, recovery);
      dateSet.add(recovery.date);
    }

    const dates = Array.from(dateSet).sort();
    let maxStreak = 0;
    let runningStreak = 0;
    let previousCompletedDate = '';

    for (const date of dates) {
      const completed = isDayCompletedForStreak(dayInfoMap.get(date) ?? null, recoveryMap.get(date) ?? null);
      if (!completed) {
        runningStreak = 0;
        previousCompletedDate = '';
        continue;
      }

      if (previousCompletedDate !== '' && diffDays(previousCompletedDate, date) === 1) {
        runningStreak++;
      } else {
        runningStreak = 1;
      }
      previousCompletedDate = date;
      maxStreak = Math.max(maxStreak, runningStreak);
    }

    const todayCompleted = isDayCompletedForStreak(dayInfoMap.get(today) ?? this.dayInfo, recoveryMap.get(today) ?? this.todayRecovery);
    const currentEndDate = todayCompleted ? today : getDateOffset(today, -1);
    let currentStreak = 0;
    let cursor = currentEndDate;
    while (compareDate(cursor, startDate) >= 0) {
      const completed = isDayCompletedForStreak(dayInfoMap.get(cursor) ?? null, recoveryMap.get(cursor) ?? null);
      if (!completed) {
        break;
      }
      currentStreak++;
      cursor = getDateOffset(cursor, -1);
    }

    const maxBeforeToday = this.calculateMaxStreakBeforeDate(dates, dayInfoMap, recoveryMap, today);
    return new ConsecutiveDaysState(
      maxStreak,
      currentStreak,
      todayCompleted,
      null,
      todayCompleted ? maxBeforeToday : maxStreak
    );
  }

  private calculateMaxStreakBeforeDate(
    dates: string[],
    dayInfoMap: Map<string, DayInfo>,
    recoveryMap: Map<string, RecoveryInfo>,
    endExclusive: string
  ): number {
    let maxStreak = 0;
    let runningStreak = 0;
    let previousCompletedDate = '';

    for (const date of dates) {
      if (compareDate(date, endExclusive) >= 0) {
        break;
      }
      const completed = isDayCompletedForStreak(dayInfoMap.get(date) ?? null, recoveryMap.get(date) ?? null);
      if (!completed) {
        runningStreak = 0;
        previousCompletedDate = '';
        continue;
      }
      if (previousCompletedDate !== '' && diffDays(previousCompletedDate, date) === 1) {
        runningStreak++;
      } else {
        runningStreak = 1;
      }
      previousCompletedDate = date;
      maxStreak = Math.max(maxStreak, runningStreak);
    }
    return maxStreak;
  }

  private async loadWeekStatusData(centerDate: string): Promise<void> {
    const monday = getMondayOfWeek(centerDate);
    const sunday = getDateOffset(monday, 6);
    const dayInfoList = await this.dayRepo.getDayInfoList(monday, sunday);
    const next = new Map<string, number>();

    for (let i = 0; i < 7; i++) {
      const date = getDateOffset(monday, i);
      const dayInfo = dayInfoList.find(di => di.date === date);
      next.set(date, this.getDayStatus(dayInfo ?? null));
    }

    next.set(this.dayInfo.date, this.getDayStatus(this.dayInfo));
    this.calendarDayStatus = next;
  }

  /**
   * 打开月视图，以当前选中日期所在月份为初始浏览月份
   */
  async openMonthView(): Promise<void> {
    this.isMonthView = true;
    this.monthViewDate = this.selectedDate;
    await this.loadMonthData(this.monthViewDate);
  }

  /**
   * 关闭月视图
   */
  closeMonthView(): void {
    this.isMonthView = false;
  }

  /**
   * 切换到上一个浏览月份（带防抖，上一次加载完成前忽略新请求）
   */
  async loadPreviousMonth(): Promise<void> {
    if (this.isMonthLoading) {
      return;
    }
    this.isMonthLoading = true;
    this.monthViewDate = getMonthOffset(this.monthViewDate, -1);
    try {
      await this.loadMonthData(this.monthViewDate);
    } finally {
      this.isMonthLoading = false;
    }
  }

  /**
   * 切换到下一个浏览月份（带防抖，上一次加载完成前忽略新请求）
   */
  async loadNextMonth(): Promise<void> {
    if (this.isMonthLoading) {
      return;
    }
    this.isMonthLoading = true;
    this.monthViewDate = getMonthOffset(this.monthViewDate, 1);
    try {
      await this.loadMonthData(this.monthViewDate);
    } finally {
      this.isMonthLoading = false;
    }
  }

  /**
   * 加载指定月份的完成状态数据（基于 DayInfo 聚合，无需任务明细）
   */
  private async loadMonthData(centerDate: string): Promise<void> {
    const days = getMonthGrid(centerDate);
    const startDate = days[0];
    const endDate = days[days.length - 1];
    const dayInfoList = await this.dayRepo.getDayInfoList(startDate, endDate);
    const recoveryList = await this.recoveryRepo.getRecoveryListByDateRange(startDate, endDate);

    const dayInfoMap = new Map<string, DayInfo>();
    for (const di of dayInfoList) {
      dayInfoMap.set(di.date, di);
    }

    const recoveryMap = new Map<string, RecoveryInfo>();
    for (const ri of recoveryList) {
      recoveryMap.set(ri.date, ri);
    }

    this.monthViewData = new Map<string, number>();
    for (const date of days) {
      const di = dayInfoMap.get(date);
      if (!di || di.targetTaskNum === 0) {
        this.monthViewData.set(date, 0); // 无记录
      } else if (di.finTaskNum >= di.targetTaskNum) {
        this.monthViewData.set(date, 3); // 全部完成
      } else {
        const ri = recoveryMap.get(date);
        if (ri && ri.used && di.calculatePercentage() >= 70) {
          this.monthViewData.set(date, 4); // 补救完成
        } else if (di.finTaskNum > 0) {
          this.monthViewData.set(date, 2); // 部分完成
        } else {
          this.monthViewData.set(date, 1); // 未完成
        }
      }
    }
  }

  /**
   * 在月视图中点击日期：选中该日并返回主界面
   */
  async selectDateFromMonthView(date: string): Promise<void> {
    this.isMonthView = false;
    await this.selectDate(date);
  }

  /**
   * 获取指定任务的目标建议。
   * 查询最近 7 天的 DayTaskInfo，调用纯函数规则生成建议。
   */
  async getGoalSuggestion(taskId: number): Promise<GoalSuggestion> {
    const today = getToday();
    const startDate = getDateOffset(today, -6); // 含今天共 7 天
    const recentTasks = await this.dayTaskRepo.getDayTasksByDateRange(startDate, today);
    const taskRecent = recentTasks.filter(t => t.taskId === taskId);

    const task = this.allTasks.find(t => t.taskId === taskId);
    if (!task) {
      return new GoalSuggestion();
    }

    const catalog = getTaskCatalogItem(taskId);
    const pickerRange = catalog ? catalog.pickerRange : [];

    return suggestGoalAdjustment(task.targetValue, taskRecent, pickerRange);
  }

  /**
   * 判断今天是否可以使用补救。
   * 条件：今天 + 完成度 >= 70% 且 < 100% + 本周未使用过补救。
   */
  async canUseRecoveryToday(): Promise<boolean> {
    const today = getToday();
    const weekKey = getWeekKey(today);
    const weekRecovery = await this.recoveryRepo.getRecoveryByWeek(weekKey);
    return canUseRecovery(today, this.dayInfo, weekRecovery);
  }

  /**
   * 使用本周补救。
   * 写入补救记录，更新连续天数（保持连续不中断）。
   */
  async useRecoveryToday(): Promise<boolean> {
    const today = getToday();
    const canUse = await this.canUseRecoveryToday();
    if (!canUse) {
      return false;
    }

    const percent = this.dayInfo.calculatePercentage();
    const record = createRecoveryRecord(today, percent);
    await this.recoveryRepo.upsertRecovery(record);
    this.todayRecovery = record;

    // 使用补救后，如果今天尚未被计为完成，增加一次连续天数
    if (!this.consecutiveState.currentDayStatus) {
      this.consecutiveState = onAllTasksCompleted(this.consecutiveState);
      await this.prefRepo.saveConsecutiveState(this.consecutiveState);
    }

    // 更新月视图和日历状态
    this.updateCalendarDayStatus(this.dayInfo);
    this.updateMonthViewData(this.dayInfo);

    // 服务卡片仍显示真实完成度，不把补救显示成满分
    await this.formService.updateAllForms(this.dayInfo, this.dayTasks, this.allTasks);

    return true;
  }

  /**
   * 生成本周复盘。
   * 查询最近 7 天的 DayInfo 和 DayTaskInfo，调用纯函数规则生成复盘。
   */
  async getWeeklyReview(): Promise<WeeklyReview> {
    const today = getToday();
    const startDate = getDateOffset(today, -6); // 含今天共 7 天
    const weekDayInfos = await this.dayRepo.getDayInfoList(startDate, today);
    const weekDayTasks = await this.dayTaskRepo.getDayTasksByDateRange(startDate, today);
    return generateWeeklyReview(weekDayInfos, weekDayTasks);
  }

  async getTaskAchievementSummaries(): Promise<TaskAchievementSummary[]> {
    const today = getToday();
    const allDayTasks = await this.dayTaskRepo.getDayTasksByDateRange('19700101', today);
    return calculateTaskAchievementSummaries(allDayTasks, this.allTasks);
  }

  /**
   * 创建自定义任务。
   * 生成新 taskId，写入仓储，如启用则为今天创建快照。
   */
  async createCustomTask(input: CustomTaskInput): Promise<number> {
    const taskId = await this.taskRepo.getNextTaskId();
    const sortOrder = await this.taskRepo.getNextSortOrder();

    const task = new TaskInfo(
      taskId, true, input.targetValue, input.isAlert,
      input.isAlert ? input.alertStartTime : '', '',
      input.isAlert ? input.alertFrequency : '', -1,
      input.taskName, input.iconKey, input.taskType, input.step,
      input.unitText, input.pickerType, input.targetOptions,
      input.scheduleDays, false, false, sortOrder, Date.now()
    );

    await this.taskRepo.createTask(task);

    // 刷新 allTasks
    this.allTasks = await this.taskRepo.getAllTasks();

    // 为今天创建快照（如果 scheduleDays 包含今天）
    const today = getToday();
    const dayOfWeek = getDayOfWeek(today);
    if (isScheduledOnDay(task, dayOfWeek)) {
      const newDayTask = new DayTaskInfo(0, today, taskId, task.targetValue, '', false);
      newDayTask.id = await this.dayTaskRepo.upsertDayTask(newDayTask);
    }

    // 刷新今日数据
    const todayData = await this.loadDayData(today);
    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = todayData.dayTasks;
    }

    // 如果启用了提醒，创建提醒
    if (task.isAlert) {
      this.setupReminder(taskId).catch((e: Object) => {
        console.error('Failed to setup reminder for custom task: ' + e);
      });
    }

    return taskId;
  }

  /**
   * 更新任务配置（主要用于自定义任务完整配置更新）。
   */
  async updateTaskConfig(task: TaskInfo): Promise<void> {
    await this.taskRepo.updateTask(task);
    this.allTasks = await this.taskRepo.getAllTasks();

    // 更新今日未完成任务快照的目标值
    const today = getToday();
    const dayTask = await this.dayTaskRepo.getDayTask(today, task.taskId);
    if (dayTask && !dayTask.isDone) {
      dayTask.targetValue = task.targetValue;
      await this.dayTaskRepo.updateDayTask(dayTask);
    }

    // 刷新今日数据
    const todayData = await this.loadDayData(today);
    await this.syncTodayCompletionState(todayData.dayInfo);
    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = todayData.dayTasks;
    }

    this.updateCalendarDayStatus(todayData.dayInfo);
    this.updateMonthViewData(todayData.dayInfo);

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks, this.allTasks);
  }

  /**
   * 归档（软删除）自定义任务。
   * 取消提醒、从未完成的今日快照移除、刷新首页。
   */
  async archiveCustomTask(taskId: number): Promise<void> {
    const task = this.allTasks.find(t => t.taskId === taskId);
    if (!task || task.isPreset) {
      return; // 预设任务不可归档
    }

    // 取消提醒
    if (task.reminderId !== -1) {
      await cancelReminder(task.reminderId);
      task.reminderId = -1;
    }

    // 归档
    await this.taskRepo.archiveTask(taskId);

    // 从未完成的今日快照移除
    const today = getToday();
    const todayTask = await this.dayTaskRepo.getDayTask(today, taskId);
    if (todayTask && !todayTask.isDone) {
      await this.dayTaskRepo.deleteDayTask(today, taskId);
    }

    // 刷新 allTasks
    this.allTasks = await this.taskRepo.getAllTasks();

    // 刷新今日数据
    const todayData = await this.loadDayData(today);
    await this.syncTodayCompletionState(todayData.dayInfo);
    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = removeInactiveTaskFromDay(todayData.dayTasks, taskId);
    }

    this.updateCalendarDayStatus(todayData.dayInfo);
    this.updateMonthViewData(todayData.dayInfo);

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks, this.allTasks);
  }
}
