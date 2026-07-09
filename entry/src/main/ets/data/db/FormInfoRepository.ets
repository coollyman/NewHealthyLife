import { relationalStore } from '@kit.ArkData';
import { DatabaseHelper } from './DatabaseHelper';
import { DbSchema } from './DbSchema';
import { FormInfo } from '../../domain/models/FormInfo';

/**
 * FormInfo 仓储 - 服务卡片
 */
export class FormInfoRepository {
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  async insertForm(form: FormInfo): Promise<void> {
    const store = this.dbHelper.getStore();
    const values: relationalStore.ValuesBucket = {
      'formId': form.formId,
      'formName': form.formName,
      'formDimension': form.formDimension
    };
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_FORM);
    predicates.equalTo('formId', form.formId);
    const resultSet = await store.query(predicates);
    const exists = resultSet.rowCount > 0;
    resultSet.close();

    if (exists) {
      await store.update(values, predicates);
    } else {
      await store.insert(DbSchema.TABLE_FORM, values);
    }
  }

  async deleteForm(formId: string): Promise<void> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_FORM);
    predicates.equalTo('formId', formId);
    await store.delete(predicates);
  }

  async getAllForms(): Promise<FormInfo[]> {
    const store = this.dbHelper.getStore();
    const predicates = new relationalStore.RdbPredicates(DbSchema.TABLE_FORM);
    const resultSet = await store.query(predicates);

    const forms: FormInfo[] = [];
    while (resultSet.goToNextRow()) {
      forms.push(new FormInfo(
        resultSet.getString(resultSet.getColumnIndex('formId')),
        resultSet.getString(resultSet.getColumnIndex('formName')),
        resultSet.getLong(resultSet.getColumnIndex('formDimension'))
      ));
    }
    resultSet.close();
    return forms;
  }
}
