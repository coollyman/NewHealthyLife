/**
 * 数据库表定义
 */

export interface ColumnDef {
  name: string;
  type: string;
  notNull: boolean;
  primaryKey: boolean;
  autoIncrement: boolean;
}

export class DbSchema {
  static readonly DB_NAME: string = 'HealthyLife.db';

  // 表名
  static readonly TABLE_TASK: string = 'taskInfo';
  static readonly TABLE_DAY: string = 'dayInfo';
  static readonly TABLE_DAY_TASK: string = 'dayTaskInfo';
  static readonly TABLE_FORM: string = 'formInfo';
  static readonly TABLE_RECOVERY: string = 'recoveryInfo';

  // TaskInfo 表列
  static readonly TASK_COLUMNS: ColumnDef[] = [
    { name: 'taskId', type: 'INTEGER', notNull: true, primaryKey: true, autoIncrement: false },
    { name: 'isOpen', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'targetValue', type: 'TEXT', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'isAlert', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'alertStartTime', type: 'TEXT', notNull: false, primaryKey: false, autoIncrement: false },
    { name: 'alertEndTime', type: 'TEXT', notNull: false, primaryKey: false, autoIncrement: false },
    { name: 'alertFrequency', type: 'TEXT', notNull: false, primaryKey: false, autoIncrement: false },
    { name: 'reminderId', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false }
  ];

  // DayInfo 表列
  static readonly DAY_COLUMNS: ColumnDef[] = [
    { name: 'date', type: 'TEXT', notNull: true, primaryKey: true, autoIncrement: false },
    { name: 'targetTaskNum', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'finTaskNum', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false }
  ];

  // DayTaskInfo 表列
  static readonly DAY_TASK_COLUMNS: ColumnDef[] = [
    { name: 'id', type: 'INTEGER', notNull: true, primaryKey: true, autoIncrement: true },
    { name: 'date', type: 'TEXT', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'taskId', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'targetValue', type: 'TEXT', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'finValue', type: 'TEXT', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'isDone', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false }
  ];

  // FormInfo 表列
  static readonly FORM_COLUMNS: ColumnDef[] = [
    { name: 'formId', type: 'TEXT', notNull: true, primaryKey: true, autoIncrement: false },
    { name: 'formName', type: 'TEXT', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'formDimension', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false }
  ];

  // RecoveryInfo 表列
  static readonly RECOVERY_COLUMNS: ColumnDef[] = [
    { name: 'date', type: 'TEXT', notNull: true, primaryKey: true, autoIncrement: false },
    { name: 'weekKey', type: 'TEXT', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'used', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'completionPercentAtUse', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false },
    { name: 'createdAt', type: 'INTEGER', notNull: true, primaryKey: false, autoIncrement: false }
  ];

  /**
   * 生成建表 SQL
   */
  static getCreateTableSql(tableName: string, columns: ColumnDef[]): string {
    const colDefs = columns.map(c => {
      let def = `${c.name} ${c.type}`;
      if (c.notNull) def += ' NOT NULL';
      if (c.primaryKey) def += ' PRIMARY KEY';
      if (c.autoIncrement) def += ' AUTOINCREMENT';
      return def;
    });
    return `CREATE TABLE IF NOT EXISTS ${tableName} (${colDefs.join(', ')})`;
  }

  static getAllCreateTableSqls(): string[] {
    return [
      DbSchema.getCreateTableSql(DbSchema.TABLE_TASK, DbSchema.TASK_COLUMNS),
      DbSchema.getCreateTableSql(DbSchema.TABLE_DAY, DbSchema.DAY_COLUMNS),
      DbSchema.getCreateTableSql(DbSchema.TABLE_DAY_TASK, DbSchema.DAY_TASK_COLUMNS),
      DbSchema.getCreateTableSql(DbSchema.TABLE_FORM, DbSchema.FORM_COLUMNS),
      DbSchema.getCreateTableSql(DbSchema.TABLE_RECOVERY, DbSchema.RECOVERY_COLUMNS)
    ];
  }

  static getAllIndexSqls(): string[] {
    return [
      `CREATE UNIQUE INDEX IF NOT EXISTS idx_day_task_date_task ON ${DbSchema.TABLE_DAY_TASK} (date, taskId)`
    ];
  }
}
