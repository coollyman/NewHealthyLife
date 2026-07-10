import { relationalStore } from '@kit.ArkData';
import { DatabaseHelper } from './DatabaseHelper';
import { DbSchema } from './DbSchema';
import { TaskInfo, CUSTOM_TASK_ID_START } from '../../domain/models/TaskInfo';
import { createDefaultTaskInfoList, getTaskCatalogItem, TaskType, PickerType } from '../../domain/constants/TaskCatalog';
import { ITaskRepository } from '../../domain/ports/RepositoryPorts';

/**
 * TaskInfo 仓储 - 全局任务配置（预设 + 自定义）
 */
export class TaskInfoRepository implements ITaskRepository {
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  /**
   * 确保预设任务存在，并回填元数据
   */
  async ensureDefaultTasks(): Promise<void> {
    const defaults = createDefaultTaskInfoList();
    for (const task of defaults) {
      const existing = await this.getTaskById(task.taskId);
      if (existing === null) {
        await this.insertTask(task);
      } else {
        // 回填元数据（旧版数据库可能缺少新字段）
        await this.backfillTaskMetadata(existing, task);
      }
    }
  }

  /**
   * 回填预设任务的元数据字段（如旧数据缺少 iconKey/taskType 等）
   */
  private async backfillTaskMetadata(existing: TaskInfo, catalogTask: TaskInfo): Promise<void> {
    let needsUpdate = false;
    const updated = existing.deepClone();

    if (!existing.taskName && catalogTask.taskName) {
      updated.taskName = catalogTask.taskName;
      needsUpdate = true;
    }
    if (!existing.iconKey && catalogTask.iconKey) {
      updated.iconKey = catalogTask.iconKey;
      needsUpdate = true;
    }
    if (!existing.taskType && catalogTask.taskType) {
      updated.taskType = catalogTask.taskType;
      needsUpdate = true;
    }
    if (!existing.step && catalogTask.step) {
      updated.step = catalogTask.step;
      needsUpdate = true;
    }
    if (!existing.unitText && catalogTask.unitText) {
      updated.unitText = catalogTask.unitText;
      needsUpdate = true;
    }
    if (!existing.pickerType && catalogTask.pickerType) {
      updated.pickerType = catalogTask.pickerType;
      needsUpdate = true;
    }
    if (!existing.targetOptions && catalogTask.targetOptions) {
      updated.targetOptions = catalogTask.targetOptions;
      needsUpdate = true;
    }
    if (!existing.isPreset) {
      updated.isPreset = true;
      needsUpdate = true;
    }

    if (needsUpdate) {
      await this.updateTask(updated);
    }
  }

  private async insertTask(task: TaskInfo): Promise<void> {
    const store = this.dbHelper.getStore();
    const values: relationalStore.ValuesBucket = {
      'taskId': task.taskId,
      'isOpen': task.isOpen ? 1 : 0,
      'targetValue': task.targetValue,
      'isAlert': task.isAlert ? 1 : 0,
      'alertStartTime': task.alertStartTime,
      'alertEndTime': task.alertEndTime,
      'alertFrequency': task.alertFrequency,
      'reminderId': task.reminderId,
      'taskName': task.taskName,
      'iconKey': task.iconKey,
      'taskType': task.taskType,
      'step': task.step,
      'unitText': task.unitText,
      'pickerType': task.pickerType,
      'targetOptions': task.targetOptions,
      'scheduleDays': task.scheduleDays,
      'isPreset': task.isPreset ? 1 : 0,
      'isArchived': task.isArchived ? 1 : 0,
      'sortOrder': task.sortOrder,
      'createdAt': task.createdAt
    };
    await store.insert(DbSchema.TABLE_TASK, values);
  }

  /**
   * 创建新任务（自定义），返回 taskId
   */
  async createTask(task: TaskInfo): Promise<number> {
    await this.insertTask(task);
    return task.taskId;
  }

  /**
   * 归档任务（软删除）
   */
  async archiveTask(taskId: number): Promise<void> {
    const store = this.dbHelper.getStore();
    const values: relationalStore.ValuesBucket = {
      'isArchived': 1,
      'isOpen': 0
    };
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_TASK);
    predicates.equalTo('taskId', taskId);
    await store.update(values, predicates);
  }

  /**
   * 获取下一个可用 taskId（自定义任务 >= 100）
   */
  async getNextTaskId(): Promise<number> {
    const all = await this.getAllTasks();
    let maxId = CUSTOM_TASK_ID_START - 1;
    for (const t of all) {
      if (t.taskId >= CUSTOM_TASK_ID_START && t.taskId > maxId) {
        maxId = t.taskId;
      }
    }
    return maxId + 1;
  }

  /**
   * 获取下一个排序序号
   */
  async getNextSortOrder(): Promise<number> {
    const all = await this.getAllTasks();
    let maxOrder = 0;
    for (const t of all) {
      if (t.sortOrder > maxOrder) {
        maxOrder = t.sortOrder;
      }
    }
    return maxOrder + 1;
  }

  /**
   * 更新任务配置
   */
  async updateTask(task: TaskInfo): Promise<void> {
    const store = this.dbHelper.getStore();
    const values: relationalStore.ValuesBucket = {
      'isOpen': task.isOpen ? 1 : 0,
      'targetValue': task.targetValue,
      'isAlert': task.isAlert ? 1 : 0,
      'alertStartTime': task.alertStartTime,
      'alertEndTime': task.alertEndTime,
      'alertFrequency': task.alertFrequency,
      'reminderId': task.reminderId,
      'taskName': task.taskName,
      'iconKey': task.iconKey,
      'taskType': task.taskType,
      'step': task.step,
      'unitText': task.unitText,
      'pickerType': task.pickerType,
      'targetOptions': task.targetOptions,
      'scheduleDays': task.scheduleDays,
      'isPreset': task.isPreset ? 1 : 0,
      'isArchived': task.isArchived ? 1 : 0,
      'sortOrder': task.sortOrder,
      'createdAt': task.createdAt
    };
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_TASK);
    predicates.equalTo('taskId', task.taskId);
    await store.update(values, predicates);
  }

  /**
   * 获取所有任务（按 sortOrder 排序）
   */
  async getAllTasks(): Promise<TaskInfo[]> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_TASK);
    predicates.orderByAsc('sortOrder');
    const resultSet = await store.query(predicates);
    const tasks: TaskInfo[] = [];

    while (resultSet.goToNextRow()) {
      tasks.push(this.mapRow(resultSet));
    }
    resultSet.close();
    return tasks;
  }

  /**
   * 获取所有已启用且未归档的任务
   */
  async getActiveTasks(): Promise<TaskInfo[]> {
    const all = await this.getAllTasks();
    return all.filter(t => t.isOpen && !t.isArchived);
  }

  /**
   * 根据 taskId 获取任务
   */
  async getTaskById(taskId: number): Promise<TaskInfo | null> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_TASK);
    predicates.equalTo('taskId', taskId);
    const resultSet = await store.query(predicates);

    let task: TaskInfo | null = null;
    if (resultSet.goToNextRow()) {
      task = this.mapRow(resultSet);
    }
    resultSet.close();
    return task;
  }

  private mapRow(resultSet: relationalStore.ResultSet): TaskInfo {
    return new TaskInfo(
      resultSet.getLong(resultSet.getColumnIndex('taskId')),
      resultSet.getLong(resultSet.getColumnIndex('isOpen')) === 1,
      resultSet.getString(resultSet.getColumnIndex('targetValue')),
      resultSet.getLong(resultSet.getColumnIndex('isAlert')) === 1,
      resultSet.getString(resultSet.getColumnIndex('alertStartTime')),
      resultSet.getString(resultSet.getColumnIndex('alertEndTime')),
      resultSet.getString(resultSet.getColumnIndex('alertFrequency')),
      resultSet.getLong(resultSet.getColumnIndex('reminderId')),
      resultSet.getString(resultSet.getColumnIndex('taskName')),
      resultSet.getString(resultSet.getColumnIndex('iconKey')),
      this.parseTaskType(resultSet.getString(resultSet.getColumnIndex('taskType'))),
      resultSet.getString(resultSet.getColumnIndex('step')),
      resultSet.getString(resultSet.getColumnIndex('unitText')),
      this.parsePickerType(resultSet.getString(resultSet.getColumnIndex('pickerType'))),
      resultSet.getString(resultSet.getColumnIndex('targetOptions')),
      resultSet.getString(resultSet.getColumnIndex('scheduleDays')),
      resultSet.getLong(resultSet.getColumnIndex('isPreset')) === 1,
      resultSet.getLong(resultSet.getColumnIndex('isArchived')) === 1,
      resultSet.getLong(resultSet.getColumnIndex('sortOrder')),
      resultSet.getLong(resultSet.getColumnIndex('createdAt'))
    );
  }

  private parseTaskType(value: string): TaskType {
    switch (value) {
      case 'time': return TaskType.TIME;
      case 'value': return TaskType.VALUE;
      default: return TaskType.ONCE;
    }
  }

  private parsePickerType(value: string): PickerType {
    switch (value) {
      case 'time': return PickerType.TIME;
      case 'text': return PickerType.TEXT;
      default: return PickerType.NONE;
    }
  }
}
