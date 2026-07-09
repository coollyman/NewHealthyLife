import { relationalStore } from '@kit.ArkData';
import { DatabaseHelper } from './DatabaseHelper';
import { DbSchema } from './DbSchema';
import { DayInfo } from '../../domain/models/DayInfo';

/**
 * DayInfo 仓储 - 每日聚合进度
 */
export class DayInfoRepository {
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  /**
   * 插入或替换 DayInfo
   */
  async upsertDayInfo(dayInfo: DayInfo): Promise<void> {
    const store = this.dbHelper.getStore();
    const values: relationalStore.ValuesBucket = {
      'date': dayInfo.date,
      'targetTaskNum': dayInfo.targetTaskNum,
      'finTaskNum': dayInfo.finTaskNum
    };
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY);
    predicates.equalTo('date', dayInfo.date);
    const rows = await store.query(predicates);
    const exists = rows.rowCount > 0;
    rows.close();

    if (exists) {
      await store.update(values, predicates);
    } else {
      await store.insert(DbSchema.TABLE_DAY, values);
    }
  }

  /**
   * 获取指定日期的 DayInfo
   */
  async getDayInfo(date: string): Promise<DayInfo | null> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_DAY);
    predicates.equalTo('date', date);
    const resultSet = await store.query(predicates);

    let dayInfo: DayInfo | null = null;
    if (resultSet.goToNextRow()) {
      dayInfo = new DayInfo(
        resultSet.getString(resultSet.getColumnIndex('date')),
        resultSet.getLong(resultSet.getColumnIndex('targetTaskNum')),
        resultSet.getLong(resultSet.getColumnIndex('finTaskNum'))
      );
    }
    resultSet.close();
    return dayInfo;
  }
}
