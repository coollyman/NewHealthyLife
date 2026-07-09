/**
 * FormInfo - 已安装的服务卡片记录
 */
export class FormInfo {
  formId: string;
  formName: string;
  formDimension: number;

  constructor(formId: string = '', formName: string = '', formDimension: number = 0) {
    this.formId = formId;
    this.formName = formName;
    this.formDimension = formDimension;
  }
}
