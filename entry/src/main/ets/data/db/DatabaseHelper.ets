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
   * 初始化数据库，创建所有表
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
  }

  getStore(): relationalStore.RdbStore {
    if (this.rdbStore === null) {
      throw new Error('RDB store not initialized. Call init() first.');
    }
    return this.rdbStore;
  }
}
