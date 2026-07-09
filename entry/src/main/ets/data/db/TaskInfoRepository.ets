import { relationalStore } from '@kit.ArkData';
import { DatabaseHelper } from './DatabaseHelper';
import { DbSchema } from './DbSchema';
import { TaskInfo } from '../../domain/models/TaskInfo';
import { createDefaultTaskInfoList } from '../../domain/constants/TaskCatalog';
import { ITaskRepository } from '../../domain/ports/RepositoryPorts';

/**
 * TaskInfo 仓储 - 全局任务配置
 */
export class TaskInfoRepository implements ITaskRepository {
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  /**
   * 确保 6 个默认任务存在
   */
  async ensureDefaultTasks(): Promise<void> {
    const defaults = createDefaultTaskInfoList();
    for (const task of defaults) {
      const existing = await this.getTaskById(task.taskId);
      if (existing === null) {
        await this.insertTask(task);
      }
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
      'reminderId': task.reminderId
    };
    await store.insert(DbSchema.TABLE_TASK, values);
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
      'reminderId': task.reminderId
    };
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_TASK);
    predicates.equalTo('taskId', task.taskId);
    await store.update(values, predicates);
  }

  /**
   * 获取所有任务
   */
  async getAllTasks(): Promise<TaskInfo[]> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_TASK);
    predicates.orderByAsc('taskId');
    const resultSet = await store.query(predicates);
    const tasks: TaskInfo[] = [];

    while (resultSet.goToNextRow()) {
      tasks.push(this.mapRow(resultSet));
    }
    resultSet.close();
    return tasks;
  }

  /**
   * 获取所有已启用的任务
   */
  async getActiveTasks(): Promise<TaskInfo[]> {
    const all = await this.getAllTasks();
    return all.filter(t => t.isOpen);
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
      resultSet.getLong(resultSet.getColumnIndex('reminderId'))
    );
  }
}
