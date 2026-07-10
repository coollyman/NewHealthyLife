# 健康生活项目长期记忆

## 项目概况
- 从零重实现 HarmonyOS「健康生活」习惯打卡应用
- 参考华为官方 Codelab，但全新干净实现
- 7 个预设任务：早起、喝水、吃苹果、每日微笑、刷牙、早睡、跑步一公里
- 微笑/刷牙为可设次数任务(1/2/3次)，跑步为数值任务(1/2/3/5公里)，跑步支持周频率提醒

## 架构分层
- `domain/`: 模型、常量、规则、工具（纯逻辑，不依赖运行时）
- `data/`: RDB 仓储 + Preferences 仓储
- `services/`: 提醒服务 + 卡片更新服务
- `viewmodel/`: HomeStore (ViewModel)
- `pages/` + `components/`: UI 页面和组件
- `form/`: 服务卡片

## 构建环境
- DevEco Studio 实际路径: `D:\software\DevEco Studio`（D 盘，非 C 盘）
- SDK: `D:\software\DevEco Studio\sdk` (API 24, HarmonyOS 6.1.1)
- 构建命令（注意 NODE_OPTIONS 要清空，路径用双反斜杠）:
  `cd /d/HarmonyOS/NewHealthyLife && NODE_OPTIONS="" node "D:\\software\\DevEco Studio\\tools\\hvigor\\bin\\hvigorw.js" --mode module -p product=default -p module=entry@default assembleHap`
- 构建还需设置 PATH 包含 SDK 的 previewer/common/bin 和 hms/toolchains/lib
  `export PATH="/d/software/DevEco Studio/sdk/default/openharmony/previewer/common/bin:/d/software/DevEco Studio/sdk/default/hms/toolchains/lib:$PATH"`
- **重要**: 使用 `--no-daemon` 参数避免 hvigor 守护进程不继承 PATH 导致 restool DLL 找不到
- devecocli 也可用，但 hvigor sync 时常报配置错；直接调 hvigorw.js 更稳
- devecocli build 会因 ohpm install 的 NODE_OPTIONS `--use-system-ca` 报错而失败，用 hvigorw.js 绕过
- local.properties: sdk.dir=D\:/software/DevEco Studio/sdk

## ArkTS 关键规则（踩过的坑）
- catch 不能有类型标注: `catch (e)` 可以，`catch (e: BusinessError)` 不行
- 静态方法不能使用 `this`，需用类名引用
- 对象字面量必须有对应 class/interface，不能裸 `{...}`
- 对象字面量不能用作类型声明: `Map<number, {a:number}>` 不行，需先 `class Stats {a:number=0}` 再用
- `??` 空值合并运算符返回 undefined 时需手动处理: `taskIdMap.get(id)` 可能返回 undefined
- interface 里不能有 Resource 类型字段（实际上可以但赋值时报错）
- 不支持解构声明: `const [a, b] = arr` 不行
- parseFloat 返回 number 但中间变量需显式标注
- UIAbility 的生命周期方法不能是 async，需要用 .then() 链
- Row 的 alignItems 接受 VerticalAlign，Column 的 alignItems 接受 HorizontalAlign（不能混用）
- promptAction.showDialog 的 buttons[].color 必须是 string 类型（如 '#666666'），不能是 number
- promptAction.showDialog 返回类型用 `promptAction.ShowDialogSuccessResponse` 而非裸 `ShowDialogSuccessResponse`
- @Builder 中不能使用 AlertDialog（必须用 promptAction.showDialog 替代）
