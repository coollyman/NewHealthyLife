import { TaskInfo } from '../domain/models/TaskInfo';
import { DayInfo } from '../domain/models/DayInfo';
import { DayTaskInfo } from '../domain/models/DayTaskInfo';
import { TaskInfoRepository } from '../data/db/TaskInfoRepository';
import { DayInfoRepository } from '../data/db/DayInfoRepository';
import { DayTaskRepository } from '../data/db/DayTaskRepository';
import { PreferencesRepository } from '../data/prefs/PreferencesRepository';
import { FormService } from '../services/FormService';
import { checkinTask, canCheckin } from '../domain/rules/TaskRules';
import { isAllTasksCompleted, onAllTasksCompleted, onNewDay, ConsecutiveDaysState } from '../domain/rules/ConsecutiveDaysRules';
import { initializeDayData, ensureDayTaskSnapshots, recalculateDayInfo, removeInactiveTaskFromDay } from '../domain/rules/DayInitRules';
import { getToday, getDateOffset, compareDate } from '../domain/utils/DateUtils';
import { getTaskCatalogItem } from '../domain/constants/TaskCatalog';
import { createOrUpdateReminder, cancelReminder, hasNotificationPermission, requestNotificationPermission } from '../services/ReminderService';

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

  private taskRepo: TaskInfoRepository = new TaskInfoRepository();
  private dayRepo: DayInfoRepository = new DayInfoRepository();
  private dayTaskRepo: DayTaskRepository = new DayTaskRepository();
  private prefRepo: PreferencesRepository = PreferencesRepository.getInstance();
  private formService: FormService = new FormService();

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

    // 如果是时间类任务，创建提醒
    if (catalog && catalog.isAlertEnabled) {
      const hasPerm = await hasNotificationPermission();
      if (!hasPerm) {
        await requestNotificationPermission();
      }
      task.reminderId = await createOrUpdateReminder(task);
      await this.taskRepo.updateTask(task);
    }

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks);
  }

  /**
   * 停用任务
   */
  async disableTask(taskId: number): Promise<void> {
    const task = this.allTasks.find(t => t.taskId === taskId);
    if (!task) return;

    task.isOpen = false;
    await this.taskRepo.updateTask(task);

    // 从今天任务列表移除未完成的
    const today = getToday();
    await this.dayTaskRepo.deleteUnfinishedTask(today, taskId);
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

    // 如果是时间类任务且已启用，更新提醒
    const catalog = getTaskCatalogItem(taskId);
    if (catalog && catalog.isAlertEnabled && task.isOpen) {
      task.reminderId = await createOrUpdateReminder(task);
      await this.taskRepo.updateTask(task);
    }

    await this.formService.updateAllForms(todayData.dayInfo, todayData.dayTasks);
  }

  /**
   * 获取进度百分比
   */
  getPercentage(): number {
    return this.dayInfo.calculatePercentage();
  }
}
