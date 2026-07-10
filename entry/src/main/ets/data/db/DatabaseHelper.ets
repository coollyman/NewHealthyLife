import { relationalStore } from '@kit.ArkData';
import { DbSchema } from './DbSchema';
import { AppConstants } from '../../domain/constants/AppConstants';

/**
 * 数据库帮助类 - 管理 RDB 实例
 */
export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {}

  static getInstance(): DatabaseHelper {
    if (DatabaseHelper.instance === null) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  /**
   * 初始化数据库，创建所有表并执行 schema 迁移
   */
  async init(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DbSchema.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.rdbStore = await relationalStore.getRdbStore(context, config);

    // 创建所有表
    for (const sql of DbSchema.getAllCreateTableSqls()) {
      await this.rdbStore.executeSql(sql);
    }

    for (const sql of DbSchema.getAllIndexSqls()) {
      await this.rdbStore.executeSql(sql);
    }

    // Schema 迁移：为旧版 taskInfo 表补充缺失列
    await this.migrateTaskTable();
  }

  /**
   * 迁移 taskInfo 表：检测缺失列并 ALTER TABLE ADD COLUMN
   */
  private async migrateTaskTable(): Promise<void> {
    if (this.rdbStore === null) {
      return;
    }

    const store = this.rdbStore;
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_TASK);
    const resultSet = await store.query(predicates);

    // 获取已有列名
    const columnNames: string[] = [];
    for (let i = 0; i < resultSet.columnCount; i++) {
      columnNames.push(resultSet.getColumnName(i));
    }
    resultSet.close();

    for (const col of DbSchema.TASK_MIGRATION_COLUMNS) {
      if (!columnNames.includes(col)) {
        try {
          await store.executeSql(`ALTER TABLE ${DbSchema.TABLE_TASK} ADD COLUMN ${col} TEXT`);
          console.info('Schema migrated: added column ' + col);
        } catch (e) {
          console.error('Schema migration failed for column ' + col + ': ' + e);
        }
      }
    }

    // 回填默认值
    try {
      await store.executeSql(
        `UPDATE ${DbSchema.TABLE_TASK} SET isPreset = '1' WHERE isPreset IS NULL AND taskId < 100`
      );
      await store.executeSql(
        `UPDATE ${DbSchema.TABLE_TASK} SET isPreset = '0' WHERE isPreset IS NULL AND taskId >= 100`
      );
      await store.executeSql(
        `UPDATE ${DbSchema.TABLE_TASK} SET isArchived = '0' WHERE isArchived IS NULL`
      );
      await store.executeSql(
        `UPDATE ${DbSchema.TABLE_TASK} SET sortOrder = taskId WHERE sortOrder IS NULL`
      );
      await store.executeSql(
        `UPDATE ${DbSchema.TABLE_TASK} SET createdAt = '0' WHERE createdAt IS NULL`
      );
    } catch (e) {
      console.error('Schema migration backfill failed: ' + e);
    }
  }

  getStore(): relationalStore.RdbStore {
    if (this.rdbStore === null) {
      throw new Error('RDB store not initialized. Call init() first.');
    }
    return this.rdbStore;
  }

  /**
   * 清空所有业务表数据（保留表结构）
   */
  async clearAllTables(): Promise<void> {
    if (this.rdbStore === null) {
      throw new Error('RDB store not initialized. Call init() first.');
    }
    await this.rdbStore.executeSql(`DELETE FROM ${DbSchema.TABLE_DAY_TASK}`);
    await this.rdbStore.executeSql(`DELETE FROM ${DbSchema.TABLE_DAY}`);
    await this.rdbStore.executeSql(`DELETE FROM ${DbSchema.TABLE_RECOVERY}`);
    // 清空任务表 — ensureDefaultTasks 会重新插入 7 个预设任务（全部关闭）
    await this.rdbStore.executeSql(`DELETE FROM ${DbSchema.TABLE_TASK}`);
  }
}
