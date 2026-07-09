import { TaskInfo } from '../domain/models/TaskInfo';
import { DayInfo } from '../domain/models/DayInfo';
import { DayTaskInfo } from '../domain/models/DayTaskInfo';
import { TaskInfoRepository } from '../data/db/TaskInfoRepository';
import { DayInfoRepository } from '../data/db/DayInfoRepository';
import { DayTaskRepository } from '../data/db/DayTaskRepository';
import { PreferencesRepository } from '../data/prefs/PreferencesRepository';
import { FormService } from '../services/FormService';
import { checkinTask, canCheckin } from '../domain/rules/TaskRules';
import {
  isAllTasksCompleted,
  onAllTasksCompleted,
  onNewDay,
  reconcileCurrentDayCompletion,
  ConsecutiveDaysState
} from '../domain/rules/ConsecutiveDaysRules';
import { initializeDayData, ensureDayTaskSnapshots, recalculateDayInfo, removeInactiveTaskFromDay } from '../domain/rules/DayInitRules';
import { getToday, getDateOffset, compareDate, getMonthGrid, getMondayOfWeek } from '../domain/utils/DateUtils';
import { getTaskCatalogItem } from '../domain/constants/TaskCatalog';
import { createOrUpdateReminder, cancelReminder, hasNotificationPermission, requestNotificationPermission } from '../services/ReminderService';
import {
  ITaskRepository,
  IDayInfoRepository,
  IDayTaskRepository,
  IPrefRepository,
  IFormService
} from '../domain/ports/RepositoryPorts';

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

  constructor(
    taskRepo: ITaskRepository,
    dayRepo: IDayInfoRepository,
    dayTaskRepo: IDayTaskRepository,
    prefRepo: IPrefRepository,
    formService: IFormService
  ) {
    this.taskRepo = taskRepo;
    this.dayRepo = dayRepo;
    this.dayTaskRepo = dayTaskRepo;
    this.prefRepo = prefRepo;
    this.formService = formService;
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
  // 月视图数据：日期 -> 完成状态（0=无记录, 1=未完成, 2=部分完成, 3=全部完成）
  monthViewData: Map<string, number> = new Map<string, number>();
  calendarDayStatus: Map<string, number> = new Map<string, number>();

  private taskRepo: ITaskRepository;
  private dayRepo: IDayInfoRepository;
  private dayTaskRepo: IDayTaskRepository;
  private prefRepo: IPrefRepository;
  private formService: IFormService;

  /**
   * 生产构造 — 使用真实仓储实现
   */
  constructor() {
    this.taskRepo = new TaskInfoRepository();
    this.dayRepo = new DayInfoRepository();
    this.dayTaskRepo = new DayTaskRepository();
    this.prefRepo = PreferencesRepository.getInstance();
    this.formService = new FormService();
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
    this.monthViewData = new Map<string, number>();
    this.calendarDayStatus = new Map<string, number>();
    this.taskRepo = deps.taskRepo;
    this.dayRepo = deps.dayRepo;
    this.dayTaskRepo = deps.dayTaskRepo;
    this.prefRepo = deps.prefRepo;
    this.formService = deps.formService;
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
    this.consecutiveState = onNewDay(yesterdayInfo, this.consecutiveState);
    await this.prefRepo.saveConsecutiveState(this.consecutiveState);

    // 初始化今天的数据
    await this.initDayData(today);
    this.consecutiveState = reconcileCurrentDayCompletion(this.dayInfo, this.consecutiveState);
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
    if (!dayTask || !canCheckin(dayTask)) {
      return false;
    }

    // 执行打卡
    const updated = checkinTask(dayTask);
    await this.dayTaskRepo.updateDayTask(updated);

    // 更新内存
    const idx = this.dayTasks.findIndex(t => t.id === dayTaskId);
    this.dayTasks[idx] = updated;
    this.dayTasks = [...this.dayTasks]; // 触发 UI 更新

    // 重新计算当日聚合
    const activeCount = this.allTasks.filter(t => t.isOpen).length;
    this.dayInfo = recalculateDayInfo(this.dayInfo, this.dayTasks, activeCount);
    await this.dayRepo.upsertDayInfo(this.dayInfo);

    // 检查是否全部完成
    if (isAllTasksCompleted(this.dayInfo)) {
      this.consecutiveState = onAllTasksCompleted(this.consecutiveState);
      await this.prefRepo.saveConsecutiveState(this.consecutiveState);
    }

    this.updateCalendarDayStatus(this.dayInfo);

    // 更新服务卡片
    await this.formService.updateAllForms(this.dayInfo, this.dayTasks);

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

    // 为当天创建任务快照
    const today = getToday();
    const catalog = getTaskCatalogItem(taskId);
    if (catalog) {
      const newDayTask = new DayTaskInfo(0, today, taskId, task.targetValue, '', false);
      newDayTask.id = await this.dayTaskRepo.upsertDayTask(newDayTask);
    }

    const todayData = await this.loadDayData(today);
    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = todayData.dayTasks;
    } else if (compareDate(this.selectedDate, today) > 0) {
      const selectedData = await this.loadDayData(this.selectedDate);
      this.dayInfo = selectedData.dayInfo;
      this.dayTasks = selectedData.dayTasks;
    }

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks);

    // 如果是支持提醒的任务，创建提醒 — 非阻塞，避免权限弹窗卡住页面导航
    if (catalog && catalog.isAlertEnabled) {
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
    const catalog = getTaskCatalogItem(taskId);
    if (!catalog || !catalog.isAlertEnabled || !task.isOpen) {
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

    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = removeInactiveTaskFromDay(todayData.dayTasks, taskId);
    } else if (compareDate(this.selectedDate, today) > 0) {
      const selectedData = await this.loadDayData(this.selectedDate);
      this.dayInfo = selectedData.dayInfo;
      this.dayTasks = selectedData.dayTasks;
    }

    // 取消提醒
    if (task.reminderId !== -1) {
      await cancelReminder(task.reminderId);
      task.reminderId = -1;
      await this.taskRepo.updateTask(task);
    }

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks);
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
    if (this.selectedDate === today) {
      this.dayInfo = todayData.dayInfo;
      this.dayTasks = todayData.dayTasks;
    } else if (compareDate(this.selectedDate, today) > 0) {
      const selectedData = await this.loadDayData(this.selectedDate);
      this.dayInfo = selectedData.dayInfo;
      this.dayTasks = selectedData.dayTasks;
    }

    // 如果是支持提醒的任务且已启用，更新提醒
    const catalog = getTaskCatalogItem(taskId);
    if (catalog && catalog.isAlertEnabled && task.isOpen) {
      task.reminderId = await createOrUpdateReminder(task);
      await this.taskRepo.updateTask(task);
    }

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks);
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
   * 打开月视图，加载当前选中日期所在月份的数据
   */
  async openMonthView(): Promise<void> {
    this.isMonthView = true;
    await this.loadMonthData(this.selectedDate);
  }

  /**
   * 关闭月视图
   */
  closeMonthView(): void {
    this.isMonthView = false;
  }

  /**
   * 加载指定月份的完成状态数据
   */
  private async loadMonthData(centerDate: string): Promise<void> {
    const days = getMonthGrid(centerDate);
    const startDate = days[0];
    const endDate = days[days.length - 1];
    const dayInfoList = await this.dayRepo.getDayInfoList(startDate, endDate);
    const dayTaskList = await this.dayTaskRepo.getDayTasksByDateRange(startDate, endDate);

    // 构建 date -> DayInfo 映射
    const dayInfoMap = new Map<string, DayInfo>();
    for (const di of dayInfoList) {
      dayInfoMap.set(di.date, di);
    }

    // 构建 date -> 完成任务数 映射
    const dayTaskMap = new Map<string, DayTaskInfo[]>();
    for (const dt of dayTaskList) {
      let list = dayTaskMap.get(dt.date);
      if (!list) {
        list = [];
        dayTaskMap.set(dt.date, list);
      }
      list.push(dt);
    }

    this.monthViewData = new Map<string, number>();
    for (const date of days) {
      const di = dayInfoMap.get(date);
      if (!di || di.targetTaskNum === 0) {
        this.monthViewData.set(date, 0); // 无记录
      } else if (di.finTaskNum >= di.targetTaskNum) {
        this.monthViewData.set(date, 3); // 全部完成
      } else if (di.finTaskNum > 0) {
        this.monthViewData.set(date, 2); // 部分完成
      } else {
        this.monthViewData.set(date, 1); // 未完成
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
}
