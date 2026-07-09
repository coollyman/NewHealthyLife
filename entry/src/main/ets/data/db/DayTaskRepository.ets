import { relationalStore } from '@kit.ArkData';
import { DatabaseHelper } from './DatabaseHelper';
import { DbSchema } from './DbSchema';
import { DayTaskInfo } from '../../domain/models/DayTaskInfo';
import { IDayTaskRepository } from '../../domain/ports/RepositoryPorts';

/**
 * DayTaskInfo 仓储 - 每日任务快照
 */
export class DayTaskRepository implements IDayTaskRepository {
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  /**
   * 插入每日任务快照
   */
  async insertDayTask(dayTask: DayTaskInfo): Promise<number> {
    const store = this.dbHelper.getStore();
    const values: relationalStore.ValuesBucket = {
      'date': dayTask.date,
      'taskId': dayTask.taskId,
      'targetValue': dayTask.targetValue,
      'finValue': dayTask.finValue,
      'isDone': dayTask.isDone ? 1 : 0
    };
    return await store.insert(DbSchema.TABLE_DAY_TASK, values);
  }

  /**
   * 插入缺失的每日任务快照；若已存在则直接返回既有 id
   */
  async upsertDayTask(dayTask: DayTaskInfo): Promise<number> {
    const existing = await this.getDayTask(dayTask.date, dayTask.taskId);
    if (existing !== null) {
      return existing.id;
    }
    return await this.insertDayTask(dayTask);
  }

  /**
   * 批量插入每日任务快照
   */
  async batchInsertDayTasks(dayTasks: DayTaskInfo[]): Promise<void> {
    for (const dt of dayTasks) {
      dt.id = await this.upsertDayTask(dt);
    }
  }

  /**
   * 更新每日任务
   */
  async updateDayTask(dayTask: DayTaskInfo): Promise<void> {
    const store = this.dbHelper.getStore();
    const values: relationalStore.ValuesBucket = {
      'date': dayTask.date,
      'taskId': dayTask.taskId,
      'targetValue': dayTask.targetValue,
      'finValue': dayTask.finValue,
      'isDone': dayTask.isDone ? 1 : 0
    };
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY_TASK);
    predicates.equalTo('id', dayTask.id);
    await store.update(values, predicates);
  }

  /**
   * 获取指定日期的所有任务快照
   */
  async getDayTasks(date: string): Promise<DayTaskInfo[]> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY_TASK);
    predicates.equalTo('date', date);
    predicates.orderByAsc('taskId');
    const resultSet = await store.query(predicates);

    const tasks: DayTaskInfo[] = [];
    while (resultSet.goToNextRow()) {
      tasks.push(this.mapRow(resultSet));
    }
    resultSet.close();
    return tasks;
  }

  /**
   * 获取指定日期和任务的快照
   */
  async getDayTask(date: string, taskId: number): Promise<DayTaskInfo | null> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY_TASK);
    predicates.equalTo('date', date);
    predicates.equalTo('taskId', taskId);
    const resultSet = await store.query(predicates);

    let task: DayTaskInfo | null = null;
    if (resultSet.goToNextRow()) {
      task = this.mapRow(resultSet);
    }
    resultSet.close();
    return task;
  }

  /**
   * 删除指定日期的任务快照
   */
  async deleteDayTask(date: string, taskId: number): Promise<void> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY_TASK);
    predicates.equalTo('date', date);
    predicates.equalTo('taskId', taskId);
    await store.delete(predicates);
  }

  /**
   * 获取日期范围内的所有任务快照
   */
  async getDayTasksByDateRange(startDate: string, endDate: string): Promise<DayTaskInfo[]> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY_TASK);
    predicates.greaterThanOrEqualTo('date', startDate);
    predicates.lessThanOrEqualTo('date', endDate);
    predicates.orderByAsc('date');
    predicates.orderByAsc('taskId');
    const resultSet = await store.query(predicates);

    const tasks: DayTaskInfo[] = [];
    while (resultSet.goToNextRow()) {
      tasks.push(this.mapRow(resultSet));
    }
    resultSet.close();
    return tasks;
  }

  private mapRow(resultSet: relationalStore.ResultSet): DayTaskInfo {
    return new DayTaskInfo(
      resultSet.getLong(resultSet.getColumnIndex('id')),
      resultSet.getString(resultSet.getColumnIndex('date')),
      resultSet.getLong(resultSet.getColumnIndex('taskId')),
      resultSet.getString(resultSet.getColumnIndex('targetValue')),
      resultSet.getString(resultSet.getColumnIndex('finValue')),
      resultSet.getLong(resultSet.getColumnIndex('isDone')) === 1
    );
  }
}
