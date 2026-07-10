import { relationalStore } from '@kit.ArkData';
import { DatabaseHelper } from './DatabaseHelper';
import { DbSchema } from './DbSchema';
import { RecoveryInfo } from '../../domain/models/RecoveryInfo';
import { IRecoveryRepository } from '../../domain/ports/RepositoryPorts';

/**
 * 补救日仓储
 */
export class RecoveryRepository implements IRecoveryRepository {
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  async upsertRecovery(info: RecoveryInfo): Promise<void> {
    const store = this.dbHelper.getStore();
    const values: relationalStore.ValuesBucket = {
      'date': info.date,
      'weekKey': info.weekKey,
      'used': info.used ? 1 : 0,
      'completionPercentAtUse': info.completionPercentAtUse,
      'createdAt': info.createdAt
    };
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_RECOVERY);
    predicates.equalTo('date', info.date);
    const rows = await store.query(predicates);
    const exists = rows.rowCount > 0;
    rows.close();

    if (exists) {
      await store.update(values, predicates);
    } else {
      await store.insert(DbSchema.TABLE_RECOVERY, values);
    }
  }

  async getRecoveryByDate(date: string): Promise<RecoveryInfo | null> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_RECOVERY);
    predicates.equalTo('date', date);
    const resultSet = await store.query(predicates);

    let info: RecoveryInfo | null = null;
    if (resultSet.goToNextRow()) {
      info = this.mapRow(resultSet);
    }
    resultSet.close();
    return info;
  }

  async getRecoveryByWeek(weekKey: string): Promise<RecoveryInfo | null> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_RECOVERY);
    predicates.equalTo('weekKey', weekKey);
    predicates.equalTo('used', 1);
    const resultSet = await store.query(predicates);

    let info: RecoveryInfo | null = null;
    if (resultSet.goToNextRow()) {
      info = this.mapRow(resultSet);
    }
    resultSet.close();
    return info;
  }

  async getRecoveryListByDateRange(startDate: string, endDate: string): Promise<RecoveryInfo[]> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_RECOVERY);
    predicates.greaterThanOrEqualTo('date', startDate);
    predicates.lessThanOrEqualTo('date', endDate);
    predicates.orderByAsc('date');
    const resultSet = await store.query(predicates);

    const result: RecoveryInfo[] = [];
    while (resultSet.goToNextRow()) {
      result.push(this.mapRow(resultSet));
    }
    resultSet.close();
    return result;
  }

  private mapRow(resultSet: relationalStore.ResultSet): RecoveryInfo {
    return new RecoveryInfo(
      resultSet.getString(resultSet.getColumnIndex('date')),
      resultSet.getString(resultSet.getColumnIndex('weekKey')),
      resultSet.getLong(resultSet.getColumnIndex('used')) === 1,
      resultSet.getLong(resultSet.getColumnIndex('completionPercentAtUse')),
      resultSet.getLong(resultSet.getColumnIndex('createdAt'))
    );
  }
}
