# 健康生活项目长期记忆

## 项目概况
- 从零重实现 HarmonyOS「健康生活」习惯打卡应用
- 参考华为官方 Codelab，但全新干净实现
- 6 个预设任务：早起、喝水、吃苹果、每日微笑、刷牙、早睡

## 架构分层
- `domain/`: 模型、常量、规则、工具（纯逻辑，不依赖运行时）
- `data/`: RDB 仓储 + Preferences 仓储
- `services/`: 提醒服务 + 卡片更新服务
- `viewmodel/`: HomeStore (ViewModel)
- `pages/` + `components/`: UI 页面和组件
- `form/`: 服务卡片

## 构建环境
- DevEco Studio: D:/software/DevEco Studio
- SDK: D:/software/DevEco Studio/sdk (API 24, HarmonyOS 6.1.1)
- 构建命令: `DEVECO_SDK_HOME="D:/software/DevEco Studio/sdk" "/d/software/DevEco Studio/tools/hvigor/bin/hvigorw.bat" --mode module -p product=default -p module=entry@default assembleHap`
- local.properties: sdk.dir=D\:/software/DevEco Studio/sdk

## ArkTS 关键规则（踩过的坑）
- catch 不能有类型标注: `catch (e)` 可以，`catch (e: BusinessError)` 不行
- 静态方法不能使用 `this`，需用类名引用
- 对象字面量必须有对应 class/interface，不能裸 `{...}`
- interface 里不能有 Resource 类型字段（实际上可以但赋值时报错）
- 不支持解构声明: `const [a, b] = arr` 不行
- parseFloat 返回 number 但中间变量需显式标注
- UIAbility 的生命周期方法不能是 async，需要用 .then() 链
