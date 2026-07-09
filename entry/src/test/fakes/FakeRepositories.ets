import { TaskInfo } from '../../main/ets/domain/models/TaskInfo';
import { DayInfo } from '../../main/ets/domain/models/DayInfo';
import { DayTaskInfo } from '../../main/ets/domain/models/DayTaskInfo';
import { ConsecutiveDaysState } from '../../main/ets/domain/rules/ConsecutiveDaysRules';
import {
  ITaskRepository,
  IDayInfoRepository,
  IDayTaskRepository,
  IPrefRepository,
  IFormService,
  FormInfoLike
} from '../../main/ets/domain/ports/RepositoryPorts';

/**
 * 内存假仓库集合 — 模拟真实持久化语义，供 HomeStore 单元测试注入
 */

export class FakeTaskRepo implements ITaskRepository {
  private tasks: Map<number, TaskInfo> = new Map<number, TaskInfo>();
  private defaultsInserted: boolean = false;

  async ensureDefaultTasks(): Promise<void> {
    // 默认任务通过 createDefaultTaskInfoList() 注入，测试自行 setup
    this.defaultsInserted = true;
  }

  async updateTask(task: TaskInfo): Promise<void> {
    this.tasks.set(task.taskId, task.deepClone());
  }

  async getAllTasks(): Promise<TaskInfo[]> {
    const result: TaskInfo[] = [];
    const values: TaskInfo[] = Array.from(this.tasks.values());
    for (const task of values) {
      result.push(task.deepClone());
    }
    result.sort((a: TaskInfo, b: TaskInfo): number => a.taskId - b.taskId);
    return result;
  }

  async getActiveTasks(): Promise<TaskInfo[]> {
    const result: TaskInfo[] = [];
    const tasks = await this.getAllTasks();
    for (const task of tasks) {
      if (task.isOpen) {
        result.push(task);
      }
    }
    return result;
  }

  async getTaskById(taskId: number): Promise<TaskInfo | null> {
    const t = this.tasks.get(taskId);
    return t ? t.deepClone() : null;
  }

  /** 测试辅助：直接注入任务（不经 ensureDefaultTasks） */
  seed(tasks: TaskInfo[]): void {
    for (const t of tasks) {
      this.tasks.set(t.taskId, t.deepClone());
    }
  }

  /** 测试辅助：读取原始存储，验证持久化行为 */
  rawGet(taskId: number): TaskInfo | undefined {
    return this.tasks.get(taskId);
  }
}

export class FakeDayInfoRepo implements IDayInfoRepository {
  private days: Map<string, DayInfo> = new Map<string, DayInfo>();
  private upsertCount: number = 0;

  async upsertDayInfo(dayInfo: DayInfo): Promise<void> {
    this.upsertCount++;
    this.days.set(dayInfo.date, new DayInfo(dayInfo.date, dayInfo.targetTaskNum, dayInfo.finTaskNum));
  }

  async getDayInfo(date: string): Promise<DayInfo | null> {
    const d = this.days.get(date);
    return d ? new DayInfo(d.date, d.targetTaskNum, d.finTaskNum) : null;
  }

  async getDayInfoList(startDate: string, endDate: string): Promise<DayInfo[]> {
    const result: DayInfo[] = [];
    const dates: string[] = Array.from(this.days.keys());
    for (const date of dates) {
      const d = this.days.get(date);
      if (d !== undefined && date >= startDate && date <= endDate) {
        result.push(new DayInfo(d.date, d.targetTaskNum, d.finTaskNum));
      }
    }
    result.sort((a: DayInfo, b: DayInfo): number => a.date < b.date ? -1 : (a.date > b.date ? 1 : 0));
    return result;
  }

  /** 测试辅助 */
  rawHas(date: string): boolean {
    return this.days.has(date);
  }

  getUpsertCount(): number {
    return this.upsertCount;
  }
}

export class FakeDayTaskRepo implements IDayTaskRepository {
  private tasks: DayTaskInfo[] = [];
  private nextId: number = 1;

  async insertDayTask(dayTask: DayTaskInfo): Promise<number> {
    const dt = new DayTaskInfo(
      this.nextId, dayTask.date, dayTask.taskId,
      dayTask.targetValue, dayTask.finValue, dayTask.isDone
    );
    this.tasks.push(dt);
    return this.nextId++;
  }

  async upsertDayTask(dayTask: DayTaskInfo): Promise<number> {
    const existing = await this.getDayTask(dayTask.date, dayTask.taskId);
    if (existing !== null) {
      return existing.id;
    }
    return await this.insertDayTask(dayTask);
  }

  async batchInsertDayTasks(dayTasks: DayTaskInfo[]): Promise<void> {
    for (const dt of dayTasks) {
      dt.id = await this.upsertDayTask(dt);
    }
  }

  async updateDayTask(dayTask: DayTaskInfo): Promise<void> {
    let idx = -1;
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].id === dayTask.id) {
        idx = i;
        break;
      }
    }
    if (idx >= 0) {
      this.tasks[idx] = new DayTaskInfo(
        dayTask.id, dayTask.date, dayTask.taskId,
        dayTask.targetValue, dayTask.finValue, dayTask.isDone
      );
    }
  }

  async getDayTasks(date: string): Promise<DayTaskInfo[]> {
    const result: DayTaskInfo[] = [];
    for (const task of this.tasks) {
      if (task.date === date) {
        result.push(new DayTaskInfo(task.id, task.date, task.taskId, task.targetValue, task.finValue, task.isDone));
      }
    }
    result.sort((a: DayTaskInfo, b: DayTaskInfo): number => a.taskId - b.taskId);
    return result;
  }

  async getDayTask(date: string, taskId: number): Promise<DayTaskInfo | null> {
    for (const task of this.tasks) {
      if (task.date === date && task.taskId === taskId) {
        return new DayTaskInfo(task.id, task.date, task.taskId, task.targetValue, task.finValue, task.isDone);
      }
    }
    return null;
  }

  async deleteDayTask(date: string, taskId: number): Promise<void> {
    const kept: DayTaskInfo[] = [];
    for (const task of this.tasks) {
      if (!(task.date === date && task.taskId === taskId)) {
        kept.push(task);
      }
    }
    this.tasks = kept;
  }

  async getDayTasksByDateRange(startDate: string, endDate: string): Promise<DayTaskInfo[]> {
    const result: DayTaskInfo[] = [];
    for (const task of this.tasks) {
      if (task.date >= startDate && task.date <= endDate) {
        result.push(new DayTaskInfo(task.id, task.date, task.taskId, task.targetValue, task.finValue, task.isDone));
      }
    }
    result.sort((a: DayTaskInfo, b: DayTaskInfo): number => a.date < b.date ? -1 : (a.date > b.date ? 1 : a.taskId - b.taskId));
    return result;
  }

  /** 测试辅助：验证持久化条数 */
  rawCount(date: string): number {
    let count = 0;
    for (const task of this.tasks) {
      if (task.date === date) {
        count++;
      }
    }
    return count;
  }

  /** 测试辅助：读取原始行 */
  rawGet(date: string, taskId: number): DayTaskInfo | undefined {
    for (const task of this.tasks) {
      if (task.date === date && task.taskId === taskId) {
        return task;
      }
    }
    return undefined;
  }
}

export class FakePrefRepo implements IPrefRepository {
  private state: ConsecutiveDaysState = new ConsecutiveDaysState(0, 0, false, null);

  async getConsecutiveState(): Promise<ConsecutiveDaysState> {
    return new ConsecutiveDaysState(
      this.state.maxConsecutiveDays,
      this.state.currentConsecutiveDays,
      this.state.currentDayStatus,
      this.state.newlyUnlockedAchievement
    );
  }

  async saveConsecutiveState(state: ConsecutiveDaysState): Promise<void> {
    this.state = new ConsecutiveDaysState(
      state.maxConsecutiveDays,
      state.currentConsecutiveDays,
      state.currentDayStatus,
      state.newlyUnlockedAchievement
    );
  }

  /** 测试辅助 */
  rawGetState(): ConsecutiveDaysState {
    return this.state;
  }
}

export class FakeFormService implements IFormService {
  private forms: FormInfoLike[] = [];
  private updateCount: number = 0;
  lastDayInfo: DayInfo | null = null;
  lastDayTasks: DayTaskInfo[] = [];

  async saveForm(formId: string, formName: string, formDimension: number): Promise<void> {
    this.forms.push(new FormInfoLike(formId, formName, formDimension));
  }

  async removeForm(formId: string): Promise<void> {
    const kept: FormInfoLike[] = [];
    for (const form of this.forms) {
      if (form.formId !== formId) {
        kept.push(form);
      }
    }
    this.forms = kept;
  }

  async getAllForms(): Promise<FormInfoLike[]> {
    const result: FormInfoLike[] = [];
    for (const form of this.forms) {
      result.push(new FormInfoLike(form.formId, form.formName, form.formDimension));
    }
    return result;
  }

  async updateAllForms(dayInfo: DayInfo, dayTasks: DayTaskInfo[]): Promise<void> {
    this.updateCount++;
    this.lastDayInfo = new DayInfo(dayInfo.date, dayInfo.targetTaskNum, dayInfo.finTaskNum);
    const copied: DayTaskInfo[] = [];
    for (const task of dayTasks) {
      copied.push(new DayTaskInfo(task.id, task.date, task.taskId, task.targetValue, task.finValue, task.isDone));
    }
    this.lastDayTasks = copied;
  }

  getUpdateCount(): number {
    return this.updateCount;
  }
}
