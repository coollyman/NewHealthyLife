[Created with Pixso.](javascript:void(0);)

简体中文

*   简体中文
*   English

[下载 App](https://developer.huawei.com/consumer/cn/huawei-app/)

[Created with Pixso.](https://developer.huawei.com/consumer/cn/)

*   探索
*   设计
*   开发
*   分发
*   推广与变现
*   生态合作
*   支持

*   更多

*   [探索](https://developer.huawei.com/consumer/cn/discover/)
    
*   [设计](https://developer.huawei.com/consumer/cn/design/)
    
*   [开发](https://developer.huawei.com/consumer/cn/develop/)
    
*   [分发](https://developer.huawei.com/consumer/cn/distribute/)
    
*   [推广与变现](https://developer.huawei.com/consumer/cn/promote/)
    
*   [生态合作](https://developer.huawei.com/consumer/cn/cooperate/)
    
*   [支持](https://developer.huawei.com/consumer/cn/support/)
    

输入关键字搜索

开发者能力认证

鸿蒙高校创新赛

HarmonyOS 7

animation

HarmonyOS行业解决方案

layoutWeight

HarmonyOS模板&组件

bindPopup

bindsheet

RelativeContainer

CustomDialogController

animateTo

CTRL+K

[文档](https://developer.huawei.com/consumer/cn/doc/)
[管理中心](https://developer.huawei.com/consumer/cn/console)

我的

Hello，

欢迎来到开发者联盟

[*   管理中心](https://developer.huawei.com/consumer/cn/console)
[*   个人中心](https://developer.huawei.com/consumer/cn/personalcenter/overview)

[*   我的学堂](https://developer.huawei.com/consumer/cn/training/mine/)
[*   我的收藏](https://developer.huawei.com/consumer/cn/personalcenter/myInfo/myCollection)
[*   我的活动](https://developer.huawei.com/consumer/cn/personalcenter/myActivity/activityList)
[*   我的工单](https://developer.huawei.com/consumer/cn/personalcenter/myCustom/ticketlist)

立即登录

Codelabs HarmonyOS 5及以上

健康生活服务应用（ArkTS）

1 介绍

健康生活服务应用（ArkTS）

Created with Pixso. 更新时间2026-02-04

Created with Pixso. 预计学习时长45分钟

关系型数据库

源码下载

1 介绍

本篇Codelab基于ArkTS实现了一个健康生活的应用，主要用于帮助开发者更好的了解和学习关系型数据库的操作。

主要功能
----

*   用户可以创建最多6个健康生活任务（早起，喝水，吃苹果，每日微笑，刷牙，早睡），并设置任务目标。
    
*   用户可以在主页面对设置的健康生活任务进行打卡，其中早起、每日微笑、刷牙和早睡只需打卡一次即可完成任务，喝水、吃苹果需要根据任务目标量多次打卡完成。
    
*   主页可显示当天的健康生活任务完成进度，当天所有任务都打卡完成后，进度为100%，并且用户的连续打卡天数加一。
    
*   当用户连续打卡天数达到3、7、30、50、73、99天时，可以获得相应的成就。成就在获得时会以动画形式弹出，并可以在“成就”页面查看。
    
*   用户可以查看以前的健康生活任务完成情况。
    
*   打开应用，显示主页面，点击加号添加任务，添加完任务后，任务列表显示所有添加的任务。
    
*   应用退出到后台，长按应用，点击服务卡片，选择1x2卡片，添加到桌面，显示已添加任务。
    
*   应用退出到后台，长按应用，点击服务卡片，选择2x2卡片，添加到桌面，显示任务完成进度。
    
*   点击2x2或1x2元服务卡片，拉起主页面，看到任务列表。
    
*   在卡片配置文件中，设置卡片更新时间，更新时间到后，桌面上2x2或1x2卡片会重置第二天任务，需要重新添加。
    
*   用户可以设置通知提醒，仅限早起、早睡。
    

相关概念
----

*   [AppStorage](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-appstorage)
    ：应用程序中的单例对象，为应用程序范围内的可变状态属性提供中央存储。
*   [@Observed和@ObjectLink](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-observed-and-objectlink)
    ：@Observed适用于类，表示类中的数据变化由UI页面管理；@ObjectLink应用于被@Observed装饰类的对象。
*   [@Provide和@Consume](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-provide-and-consume)
    ：@Provide作为数据提供者，可以更新子节点的数据，触发页面渲染。@Consume检测到@Provide数据更新后，会发起当前视图的重新渲染。
*   [Flex](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-flex)
    ：以弹性方式布局子组件的容器组件。
*   [List](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-list)
    ：List是很常用的滚动类容器组件之一，它按照水平或者竖直方向线性排列子组件， List的子组件必须是ListItem，它的宽度默认充满List的宽度。
*   [TimePicker](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-timepicker)
    ：TimePicker是选择时间的滑动选择器组件，默认以00:00至23:59的时间区创建滑动选择器。
*   [Toggle](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-common-components-switch)
    ：组件提供勾选框样式状态按钮样式及开关样式。
*   [openCustomDialog](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-uicontext-custom-dialog)
    ：不依赖UI组件的全局自定义弹出框。
*   [关系型数据库（Relational Database，RDB）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-rdb-store)
    ：一种基于关系模型来管理数据的数据库。
*   [首选项](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-preferences)
    ：首选项为应用提供Key-Value键值型的数据处理能力，支持应用持久化轻量级数据，并对其修改和查询。
*   [后台代理提醒](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/agent-powered-reminder)
    ：后台代理提醒功能主要提供后台提醒通知发布接口，开发者可调用这些接口创建定时提醒，包括倒计时、日历、闹钟三种提醒类型。
*   [ArkTS卡片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview)
    ：卡片框架的运作机制分三大模块：卡片使用方、卡片管理服务和卡片提供方。
    *   卡片使用方：负责卡片的创建、删除、请求更新以及卡片服务通信。
    *   卡片管理服务：负责卡片的周期性刷新、卡片缓存管理、卡片生命周期管理以及卡片使用对象管理。
    *   卡片提供方：提供卡片显示内容的应用，控制卡片的显示内容、控件布局以及控件点击事件。

相关权限
----

本篇Codelab使用了代理提醒，需要在配置文件module.json5里添加允许应用使用后台代理权限:ohos.permission.PUBLISH\_AGENT\_REMINDER。权限申请请参考：[代理提醒开放能力申请](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/agent-powered-reminder#%E4%BB%A3%E7%90%86%E6%8F%90%E9%86%92%E5%BC%80%E6%94%BE%E8%83%BD%E5%8A%9B%E7%94%B3%E8%AF%B7)
。

完整示例
----

[gitcode源码地址](https://gitcode.com/harmonyos_codelabs/HealthyLife)

源码下载

源码下载

[HealthyLife.zip](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20260114181056.50326410928153464405578079614968:50001231000000:2800:D9D1542940DF05BD11F45AE694B5D30BDA6D0D57ADD669E5C27B693055F147CF.zip?needInitFileName=true "HealthyLife.zip")

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251030171755.14698105026306064103545168905062:50001231000000:2800:6F024D17BB7FC55B3A48598ECF857D0B8ED61578865884526F460EA59CA81771.png?needInitFileName=true)

2 环境搭建

首先需要完成HarmonyOS开发环境搭建，可参照如下步骤进行。

软件要求
----

*   DevEco Studio版本：DevEco Studio 6.0.2 Release及以上。
*   HarmonyOS SDK版本：HarmonyOS 6.0.2 Release SDK及以上。

硬件要求
----

*   设备类型：华为手机、模拟器。
*   HarmonyOS系统：HarmonyOS 6.0.0 Release及以上。

环境搭建
----

*   安装DevEco Studio，详情请参考[下载和安装软件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-software-install)
    。
*   设置DevEco Studio开发环境，DevEco Studio开发环境需要依赖于网络环境，需要连接上网络才能确保工具的正常使用，详情请参考[配置开发环境](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-environment-config)
    。
*   开发者可以参考以下链接，完成设备调试的相关配置：
    *   [使用真机进行调试](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-debug-device)
        

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20260106094016.36033552770218539639857129532022:50001231000000:2800:0DE837FF7FB457711F4E4E9C8A1E4D60A928174C3785768D3668DCE97BE56B87.png?needInitFileName=true)

3 代码结构解读

本篇Codelab只对核心代码进行讲解，完整代码会在源码下载中提供。

针对当前程序功能设计，在此处使用MVVM模型划分整体结构。

首先是Model层，包含默认任务信息（TaskBaseModel）、默认Tab信息（NavItemModel）、库表行信息（ColumnModel）等。主要用于存储程序基本的数据信息。

其次是View层，包含首页界面（HomeComponent）、成就界面（AchievementComponent）、个人信息界面（MineComponent）等。主要用于展示程序的界面。

最后是ViewModel层，包含界面所需数据信息（HomeStore等）和弹窗参数（TaskInfoDialogParams等）。主要用于驱动界面和数据之间的交互。

No Preview

    ├───common/src/main/ets │  ├──constants │  │  ├──CommonConstants.ets                      // 通用常量 │  │  └──RdbConstant.ets                          // RDB常量-数据库相关 │  ├──database │  │  ├──tables  │  │  │  ├──DayInfoApi.ets                        // 日期信息-数据库操作API │  │  │  ├──DayTaskInfoApi.ets                    // 当日任务信息-数据库操作API │  │  │  ├──FormInfoApi.ets                       // 服务卡片信息-数据库操作API │  │  │  ├──TableApi.ets                          // 数据库操作API接口 │  │  │  └──TaskInfoApi.ets                       // 任务信息-数据库操作API │  │  └──RdbUtils.ets                             // 数据库操作通用工具类 │  ├──model │  │  ├──database │  │  │  ├──DayInfo.ets                           // 日期信息 │  │  │  ├──DayTaskInfo.ets                       // 当日任务信息 │  │  │  ├──FormInfo.ets                          // 服务卡片信息 │  │  │  └──TaskInfo.ets                          // 任务信息 │  │  ├──ColumnModel.ets                          // 数据库表字段信息 │  │  ├──FormStorageModel.ets                     // 服务卡片数据共享实体 │  │  └──TaskBaseModel.ets                        // 单个任务基础信息 │  └──utils │     ├──agent │     │  ├──AgentUtils.ets                        // 代理提醒工具栏 │     │  └──RequestAuthorization.ets              // 配置权限工具类 │     ├──FormUtils.ets                            // 服务卡片工具类 │     ├──PreferencesUtils.ets                     // 用户首选项工具类 │     ├──PromptActionClass.ets                    // 自定义弹窗工具类 │     └──Utils.ets ├───common/src/main/resource  │├───healthylife/src/main/ets │  ├──healthyfileability │  │  └──HealthylifeAbility.ets                   // 模块入口类 │  ├──model │  │  ├──AchievementModel.ets                     // 成就信息实体 │  │  └──NavItemModel.ets                         // 应用tab实体 │  ├──pages │  │  └──HealthyLifePage.ets                      // 应用入口界面 │  ├──viewmodel │  │  ├──dialog                                   // 自定义弹窗 │  │  │  ├──AchievementDialogParams.ets           // 成就 │  │  │  ├──TargetSettingDialogParams.ets         // 目标任务 │  │  │  └──TaskInfoDialogParams.ets              // 任务信息 │  │  ├──AchievementStore.ets                     // 用户首选项存储用于成就同步 │  │  └──HomeStore.ets                            // 数据库存储用于界面显示 │  └──view │     ├──dialog                                   // 自定义弹窗 │     │  ├──AchievementDialog.ets                 // 成就 │     │  ├──TargetSettingDialog.ets               // 目标设置 │     │  └──TaskClockCustomDialog.ets             // 打卡界面 │     ├──home │     │  ├──HomeTopComponent.ets                  // 目标进度组件 │     │  ├──TaskListComponent.ets                 // 任务列表组件 │     │  └──WeekCalendarComponent.ets             // 周视图组件 │     ├──mine │     │  └──UserInfoComponent.ets                 // 用户信息组件 │     ├──task │     │  ├──AddTaskComponent.ets                  // 添加任务组件 │     │  └──EditTaskComponent.ets                 // 编辑任务组件 │     ├──AchievementComponent.ets                 // 成就页面 │     ├──HomeComponent.ets                        // 首页页面 │     └──MineComponent.ets                        // 我的页面 ├──healthylife/src/main/resource  │├───default/src/main/ets │  ├──agency │  │  └──pages │  │     └──AgencyCard.ets                        // 任务列表-服务卡片 │  ├──defaultformability │  │  └──DefaultFormAbility.ets                   // 服务卡片入口 │  ├──entryability │  │  └──EntryAbility.ets                         // 主程序入口 │  ├──pages │  │  ├──AdvertisingPage.ets                      // 广告界面 │  │  ├──Index.ets                                // 主界面 │  │  └──SplashPage.ets                           // 开始屏幕界面 │  ├──progress │  │  └──pages │  │     └──ProgressCard.ets                      // 任务进度-服务卡片       │  └──view │     └──UserPrivacyDialog.ets                    // 用户隐私协议弹窗 └──default/src/main/resource

4.1 启动页

给应用添加一个启动页，启动页里需要用到定时器来实现启动页展示固定时间后跳转应用主页的功能。

打开应用时会进入此页面，具体实现逻辑是：

通过修改entryability里的loadContent路径可以改变应用的入口文件，此处改为SplashPage。

应用启动时加载 SplashPage，显示启动页并跳转到广告页。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251103142056.93998325510655426411536836583709:50001231000000:2800:DA38C9D9BFF2D8B456ED8A9087F1BE23E897578D8D882628DA97CA6127AAFAF8.gif?needInitFileName=true)

4.2 应用入口

需要给APP添加底部菜单栏，用于切换不同的应用模块，由于各个模块之间属于完全独立的情况，并且不需要每次切换都进行界面的刷新，所以用到了Tabs，TabContent组件。

本应用一共有首页（HomeComponent）和我的（MineComponent）两个模块，分别对应Tabs组件的两个子组件TabContent。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251103142118.90591729075832125384619206759218:50001231000000:2800:DC837855E1ADD173722F43F7C79ACD7AC989232071403B9D2DC8C6C7076A44EF.gif?needInitFileName=true)

4.3 首页

首页包含了任务信息的所有入口，包含任务列表的展示，任务的编辑和新增，日期的切换以及随着日期切换界面任务列表跟着同步的功能。

导航栏
---

NavDestination 作为页面容器，使用Scroll组件实现滚动的效果。

日历组件
----

日历组件主要分为两部分：顶部日期切换栏 + 水平滚动的周历列表。

顶部日期切换栏

*   左侧箭头：点击切换到上一周（减少 7 天）。
    
*   中间文本：显示当前格式化的日期（showDateStr）。
    
*   右侧箭头：点击切换到下一周（增加 7 天）。
    
*   箭头通过symbolBuild()方法构建（复用样式和点击逻辑）。
    

周历列表（水平滚动）

*   List：水平滚动列表，展示一周的日期（数据来自homeStore.weekList）。
    
*   ForEach：遍历weekList，通过dayOfWeekBuilder为每个日期生成 UI 项。
    
*   onScrollStop：滚动停止时触发weekChange，处理周切换逻辑。
    

周视图切换，通过监听 List 滚动停止事件，根据滚动偏移量（xOffset）判断是否需要切换周：

*   向左滚动超过左阈值（WEEK\_LEFT\_LIMIT）：切换到上一周（减少 7 天）。
    
*   向右滚动超过右阈值（WEEK\_RIGHT\_LIMIT）：切换到下一周（增加 7 天）。
    
*   未超过阈值：通过动画滚回中间位置（默认选中的日期位置）。
    

homeStore主要是请求数据库的数据并对数据进行处理进而渲染到界面上。

同时还需要对数据进行刷新

添加任务悬浮按钮
--------

首页整体用了一个Stack组件，将悬浮按钮放在滚动组件层的上边。

界面跳转
----

跳转页面使用的是NavPathStack.pushPathByName()，可参考[NavPathStack](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navigation#navpathstack10)
。

点击悬浮按钮时会跳转到任务列表页面

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251103142026.89650590658863696743498955096276:50001231000000:2800:4431D5655E04CDE9AF397CE174E2B46489CDC1872EA59CFFD1ED197CF5B602C4.gif?needInitFileName=true)

5.1 任务概述

用户点击悬浮按钮进入任务列表页，点击任务列表可进入对应任务编辑的页面中，对任务进行详细的设置，之后点击完成按钮编辑任务后将返回首页。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251103142152.57978167102923256093894555303191:50001231000000:2800:6E490E38C81741FF4C5D9EB6C15166FF40D887A5F6D78335B7F6F67FA9E9B064.gif?needInitFileName=true)

5.2 任务添加

添加任务页由包括上部分的标题、返回按钮以及正中间的任务列表组成。

在aboutToAppear()周期中，通过TaskInfoApi.queryAllTaskInfo()异步获取所有任务数据，赋值给taskList，然后将flag设为true（表示数据加载完成），当数据加载完成时，渲染一个Column容器，通过ForEach遍历taskList生成任务列表。

列表右侧有一个判断是否开启的文字标识，点击某个列表需要跳转到对应的任务编辑页里。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251030174333.62038494652355165297073062573582:50001231000000:2800:C2DCB00B72B81324BF31FF9FDD943A61B47FCC5DCC84A04901DCDC6FA15B2092.png?needInitFileName=true)

5.3 任务编辑

任务编辑页由上方的“编辑任务”标题以及返回按钮，主体内容的List配置项和下方的完成按钮组成。

任务名称与开关行，采用水平布局，左侧显示任务名称，右侧开关控制 taskInfo.isOpen（任务是否开启）。

目标设置行，采用水平布局，显示 “目标设置” 标题、当前目标值及单位，点击后可打开对话框编辑目标值（条件：任务开启且有选择器）。

设置完成之后，点击完成按钮，会调用 finishTaskEdit()方法，提交编辑结果。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251103143838.66531674994405328074165555360651:50001231000000:2800:9754BB7056ED87E843B138372FCABED92B58E305BAD21B01EDBBE03EAF5F1784.gif?needInitFileName=true)

6.1 任务列表

使用Column容器组件，通过ForEach遍历homeStore.taskList展示用户当前已经开启的任务，每条任务对应一个taskCardBuilder()组件。

当点击卡片且当前日期有效时，打开任务打卡对话框（如记录任务完成情况）。

长按卡片时，若为当天任务，查询任务详情并跳转到编辑页面，使用了长按手势（LongPressGesture）。

No Preview

    // TaskListComponent.etsif (this.homeStore.taskList.length > 0) {  Column() {    ForEach(      this.homeStore.taskList,       (item: DayTaskInfo, index: number) => { this.taskCardBuilder(item, index) },      (item: DayTaskInfo, index: number) => index + JSON.stringify(item)    )  }  // ...}

6.2 打卡弹窗组件

打卡弹窗组件根据当前任务的ID获取任务名称以及弹窗背景图片资源。

openTaskClockCustomDialog()打开任务打卡对话框的入口函数，负责初始化对话框的上下文、内容，并触发显示。

taskClockDialogBuilder()包含三个核心元素（任务名称、操作按钮、关闭按钮），整体用Column垂直布局，背景设置为任务对应的图片；按钮点击分别触发打卡逻辑（taskClock()函数）和关闭对话框（PromptActionClass.closeDialog()）；根据任务是否已完成（params.dayTaskInfo.isDone），动态显示按钮文本（"打卡" 或 "已完成"）。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251103142236.03115403760492159012431987129314:50001231000000:2800:AC98125A74428FD59258110971883A31A93190841DD5C7D57C977BBCE108EF49.gif?needInitFileName=true)

6.3 打卡接口调用

打卡完成后，会调用updateTaskList()接口更新数据库任务列表信息，并且确认当天所有任务是否已完成，调用updateAchievementStore()接口更新成就信息。

No Preview

    // TaskClockCustomDialog.etsasync function taskClock(params: TaskInfoDialogParams) {  if (!params.dayTaskInfo.isDone) {    await TaskInfoApi.clockTask(params.dayTaskInfo.date, params.dayTaskInfo.taskId);    await updateTaskList(params.homeStore);  }  PromptActionClass.closeDialog();
      if (!params.dayTaskInfo.isDone) {    await updateAchievementStore(params);  }}

7.1 功能概述

成就页面展示用户可以获取的所有勋章，当用户满足一定的条件时，将点亮本页面对应的勋章，没有得到的成就勋章处于熄灭状态。共有六种勋章，当用户连续完成任务打卡3天、7天、30天、50天、73天、99天时，可以获得对应的“连续xx天达成”勋章。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251030170243.46594003424505463988897525075769:50001231000000:2800:45C5504C0FCA77E23BDE9A06034613994B84DECE0D6B90A13A71FBB55D9C4A53.png?needInitFileName=true)

7.2 页面实现

标题部分是由一个横向容器Row里包含一个Image组件和Text组件，并且给Image添加了点击事件。

每个勋章卡片是由一个纵向容器Column组件、图片Image组件和文字Text组件组成。

整体的勋章面板使用Flex一个组件即可以实现均分和换行的功能。

No Preview

    // AchievementComponent.etsRow() {  Image($r('app.media.ach_back'))    // ...    .onClick(() => {      this.pageStack.pop();    })  Text($r('app.string.my_achievement'))    // ...}.margin({  left: $r('app.float.default_12'),  right: $r('app.float.default_12')})

7.3 获取数据

进入界面第一次获取数据在aboutToAppear()声明周期中初始化全局成就信息，通过@Provide和@Consume实现双向绑定。

No Preview

    // HealthyLifePage.ets@Componentexport struct HealthyLifePage {  @Provide achievementStore: AchievementStore = new AchievementStore(0, 0, false);  // ...
      async aboutToAppear(): Promise<void> {    // ...    this.achievementStore = await initAchievementStore();  }}
    // AchievementComponent.ets@Componentexport struct AchievementComponent {  @Consume achievementStore: AchievementStore;  // ...}

8 后台代理提醒

在编辑任务点击完成时，会弹出对话框提醒用户是否开启提醒，允许就会开启提醒。

发布代理提醒，成功后会有一个任务id。

开启一个类型为闹钟的代理提醒。

Preview

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251105152342.91916497316448688250252686728834:50001231000000:2800:80C013D002E8B17F9BBB9D3FF58214D50788712985353903793E2CABB1E04A7F.gif?needInitFileName=true)

    // EditTaskComponent.etsif (this.taskBaseInfo.unit === '') {  let oldTaskInfo = await TaskInfoApi.queryByKey(this.taskInfo.taskId);  if (oldTaskInfo) {    let isRequestSuccess = await RequestAuthorization.requestNotification(this.getUIContext());    if (isRequestSuccess) {      let reminderId = await AgentUtils.creatAgent(this.taskInfo, this.taskBaseInfo, this.getUIContext());      // update reminderId      oldTaskInfo.reminderId = reminderId;      await TaskInfoApi.update(oldTaskInfo.taskId, oldTaskInfo);      hilog.info(0x0000, TAG, `create reminderId successed, reminderId is ${reminderId}`);    }  }}

9.1 创建服务卡片

**步骤1：**在main目录下，点击鼠标右键 > New > Service Widget > Static Widget。

**步骤2：**选择Hello World卡片模板，点击Next。

**步骤3：**填写卡片名字（Service widget name）、卡片介绍（Description）、是否开启低代码开发（Enable Super Visual）、开发语言（ArkTS和JS）、支持卡片规格（Support dimension）、关联表单（Ability name）点击Finish完成创建。如需创建多个卡片目录重新按照步骤1执行。

**步骤4：**创建完卡片后，在ets文件目录下显示卡片目录，然后开发者使用ArkTS开发卡片页面。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251127204507.09757810346527813206904398773581:50001231000000:2800:D115EDAC0C01DCD62973E34890482D450113A7C12D358531C929EC5FB2D6B862.png?needInitFileName=true)

9.2 初始化服务卡片

当应用添加卡片到桌面后，在DefaultFormAbility的onAddForm()方法中进行卡片初始化操作。

初始化卡片代码。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251030171005.54385638157181984747375109903955:50001231000000:2800:94EE939F6F3CD1037D14F6413C6399F52C2E4E75D2FB25C6D8A292E780F427CF.png?needInitFileName=true)

9.3 更新服务卡片

在src/main/resources/base/profile/form\_config.json配置文件中，通过scheduledUpdateTime字段配置刷新时间。当系统运行至配置好的指定时间时，系统调用onUpdateForm()方法进行更新卡片。

No Preview

    // form_config.json{  // card class name.  "name": "progress",  "displayName": "$string:progress_display_name",  // card description.  "description": "$string:progress_desc",  // card corresponds to the complete path.   "src": "./ets/progress/pages/ProgressCard.ets",  // card development language.  "uiSyntax": "arkts",  // define and display window-related configurations.  "window": {    "designWidth": 720,    "autoDesignWidth": true  },  // theme style of the card.  "colorMode": "auto",  // Indicates whether the card is the default card.  "isDefault": false,  // Does the card support periodic refresh.  "updateEnabled": true,  // Using a 24-hour format, precise to the minute, updated at midnight.  "scheduledUpdateTime": "00:00",  // Default card appearance specifications.  "defaultDimension": "2*2",  // card appearance specifications supported.  "supportDimensions": [    "2*2"  ]}
    // DefaultFormAbility.etsonUpdateForm(formId: string) {  FormUtils.updateForms();}
    // FormUtils.etspublic updateForms(): void {  FormInfoApi.queryAll().then((formInfos: FormInfo[]) => {    formInfos.forEach((item: FormInfo) => {      this.updateByFormName(item);    })  })}
    public updateByFormName(formInfo: FormInfo): void {  const date = convertDate2Str(new Date());  let updateDate: FormStorageModel = {};  if (formInfo.formName === Const.FORM_NAME_AGENCY &&    Number(formInfo.formDimension) === Const.DEFAULT_DIMENSION_2X4) {    DayTaskInfoApi.queryDayTaskInfo(date).then((dayTaskInfos: DayTaskInfo[]) => {      updateDate.dayTaskInfos = dayTaskInfos;      this.updateFormByDate(updateDate, formInfo);    })  } else if (formInfo.formName === Const.FORM_NAME_PROGRESS &&    Number(formInfo.formDimension) === Const.DEFAULT_DIMENSION_2X2) {    DayInfoApi.queryByKey(date).then((dayInfo: DayInfo | null) => {      if (!dayInfo) {        dayInfo = new DayInfo(date, 0, 0);      }      updateDate.targetTaskNum = dayInfo.targetTaskNum;      updateDate.finTaskNum = dayInfo.finTaskNum;      updateDate.percentage = dayInfo.calculatePercentage();      this.updateFormByDate(updateDate, formInfo);    })  }}

9.4 删除服务卡片

当需要删除ArkTS卡片时，在DefaultFormAbility的onRemoveForm()方法中，通过FormUtils.deleteFormData()方法删除数据库中对应的卡片信息。

No Preview

    // DefaultFormAbility.etsonRemoveForm(formId: string) {  FormUtils.deleteFormData(this.context, formId);}
    // FormUtils.etspublic deleteForm(context: Context, formId: string): void {  RdbUtils.createRdb(context).then(() => {    FormInfoApi.delete(formId).then(() => {      hilog.info(0x0000, TAG, `Delete formInfo successed, formId is ${formId}`);    }).catch((err: BusinessError) => {      hilog.error(0x0000, TAG,        `Delete formInfo failed, formId is ${formId}, code is ${err.code}, message is ${err.message}`);    });  })}

10.1 创建数据库

要使用关系型数据库存储用户数据，首先要进行数据库的创建，并提供基本的增、删、查、改接口。

导入关系型数据库模块：

关系型数据库提供两个基本功能。

获取一个RdbStore来操作关系型数据库。

关系型数据库接口提供的增、删、改、查操作均有callback和Promise两种异步回调方式，本Codelab使用了Promise异步回调，以任务信息表为例。

No Preview

    // RdbUtils.etsimport { relationalStore } from '@kit.ArkData';

10.2 数据表定义

一共定义四个数据库表来记录和同步任务信息，分别为 dayInfo 、 taskInfo 、 dayTaskInfo 、formInfo。

taskInfo表
---------

taskInfo - 任务信息 ，用于存储应用默认任务信息，控制当日及后续的任务目标和消息提醒信息，其增删改需要关联dayTaskInfo下的当日信息，且为一对一关系。

dayInfo表
--------

dayInfo - 当日信息，用于存储日期信息和当日任务数量信息，可以快速判断当日完成情况并在周视图中展示。该信息记录与dayTaskInfo的信息记录呈一对多关系。

dayTaskInfo表
------------

dayTaskInfo - 当日任务信息，用于存储日期及任务关联的任务信息，便于后续快速查找某天任务详细信息。

formInfo表
---------

formInfo-服务卡片信息。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251031173739.49544495594504886228267230517232:50001231000000:2800:9EB99F6284C714E7E3B683A42722C1DAB7F09FD30779F90F6B7364ECBB40D7F1.png?needInitFileName=true)

10.3 创建数据表

应用首次打开时，数据库中没有数据，要做数据库的初始化，并执行相应的SQL语句创建数据表。

No Preview

    // EntryAbility.etsasync onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {  // ...  // Init RDB connect and create tables  await RdbUtils.createRdb(this.context).then(() => {    for (let tableName of RdbConstants.TABLE_NAME_LIST) {      RdbUtils.createTable(tableName);    }  });  await TaskInfoApi.checkDefaultTask();  // Init preferences and get store  await PreferencesUtils.getPreferencesFromStorage(this.context);  await DayInfoApi.initAchievementStoreByDayInfo(convertDate2Str(new Date()));
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');}
    // RdbUtils.etscreateTable(tableName: string): void {  if (!this.rdbStore) {    hilog.error(0x0000, TAG, 'RdbStore is undefined');    return;  }  let createSql = this.generateTableSql(tableName);  this.rdbStore.execute(createSql)    .then(() => {      hilog.info(0x0000, TAG, `Execute create ${tableName} table sql success`);    })    .catch((err: BusinessError) => {      hilog.error(0x0000, TAG,        `Execute create ${tableName} table sql failed, code is ${err.code},message is ${err.message}`);    });}
    private generateTableSql(tableName: string): string {  let columns = RdbConstants.TABLE_COLUMNS_MAPPING[tableName];  let sql = `create table if not exists ${tableName}(`;  for (let column of columns) {    sql = sql.concat(`${column.name} ${column.type}`);    sql = sql.concat(`${column.length && column.length > 0 ? `(${column.length})` : ''}`);    sql = sql.concat(`${column.primary ? ' primary key' : ''}`);    sql = sql.concat(`${column.autoincrement ? ' autoincrement' : ''}`);    sql = sql.concat(`${column.nullable ? '' : ' not null'}`);    sql = sql.concat(', ');  }  sql = `${sql.substring(0, sql.length - 2)})`;  hilog.info(0x0000, TAG, `The SQL statement generated based on the ${tableName} is '${sql}'`);  return sql;}
    async executeSql(executeSql: string): Promise<boolean> {  let result = true;  await this.rdbStore?.executeSql(executeSql).then(() => {    hilog.info(0x0000, TAG, `Execute Sql is successful, sql is ${executeSql}`);  }).catch((err: BusinessError) => {    hilog.error(0x0000, TAG,      `Execute Sql is failed, sql is ${executeSql}, code is ${err.code}, message is ${err.message}`);    result = false;  });  return result;}

11 总结

您已经完成了本次Codelab的学习，并了解到以下知识点：

*   ArkUI基础组件、容器组件的使用。
*   使用页面路由跳转到指定页面并传递所需参数。
*   基于基础组件封装自定义组件，如日历、弹窗等。
*   数据驱动UI组件刷新。
*   使用首选项接口实现应用权限管理。
*   使用关系型数据库读写关系型数据。
*   使用ArkTS卡片能力实现1x2和2x2规格的卡片。

![](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyManage/011/111/111/0000000000011111111.20251016104859.17906322914514658589700467781540:50001231000000:2800:E6B41FB5A492EFFB1107DC087299B24C577DD30F6A335266B6968ECC10057D96.gif?needInitFileName=true)

意见反馈

您对该Codelabs的整体评价？

![赞](https://developer.huawei.com/consumer/cn/codelabsPortal/assets/images/praise.png)

![踩](https://developer.huawei.com/consumer/cn/codelabsPortal/assets/images/trample.png)

如果您有其他疑问，您也可以通过HarmonyOS开发者社区问答频道来和我们联系探讨。

[社区提问](https://developer.huawei.com/consumer/cn/forum/)
[智能客服提问](https://developer.huawei.com/consumer/cn/customerService/#/bot-dev-top/faq-top/faq-talk-top)

[HarmonyOS Developer](https://developer.huawei.com/consumer/cn)

工具

*   [ArkTS](https://developer.huawei.com/consumer/cn/arkts/)
    
*   [ArkUI](https://developer.huawei.com/consumer/cn/arkui/)
    
*   [ArkCompiler](https://developer.huawei.com/consumer/cn/arkcompiler/)
    
*   [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)
    
*   [DevEco Testing](https://developer.huawei.com/consumer/cn/deveco-testing/)
    
*   [DevEco Device Tool](https://device.harmonyos.com/cn/develop/ide)
    
*   [DevEco Service](https://developer.huawei.com/consumer/cn/deveco-service)
    
*   [仓颉](https://developer.huawei.com/consumer/cn/cangjie)
    
*   [HarmonyOS Symbol](https://developer.huawei.com/consumer/cn/design/harmonyos-symbol)
    

开放能力

*   [Account Kit](https://developer.huawei.com/consumer/cn/sdk/account-kit)
    
*   [Ads Kit](https://developer.huawei.com/consumer/cn/sdk/ads-kit)
    
*   [Core Speech Kit](https://developer.huawei.com/consumer/cn/sdk/core-speech-kit)
    
*   [Core Vision Kit](https://developer.huawei.com/consumer/cn/sdk/core-vision-kit)
    
*   [IAP Kit](https://developer.huawei.com/consumer/cn/sdk/iap-kit)
    
*   [Intents Kit](https://developer.huawei.com/consumer/cn/sdk/intents-kit)
    
*   [Location Kit](https://developer.huawei.com/consumer/cn/sdk/location-kit)
    
*   [Live View Kit](https://developer.huawei.com/consumer/cn/sdk/live-view-kit)
    
*   [Payment Kit](https://developer.huawei.com/consumer/cn/sdk/payment-kit)
    
*   [Push Kit](https://developer.huawei.com/consumer/cn/sdk/push-kit)
    
*   [Scan Kit](https://developer.huawei.com/consumer/cn/sdk/scan-kit)
    

资源

*   [文档](https://developer.huawei.com/consumer/cn/doc/)
    
*   [示例代码](https://developer.huawei.com/consumer/cn/samples/)
    
*   [最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-best-practices-overview)
    
*   [下载中心](https://developer.huawei.com/consumer/cn/download/)
    
*   [视频课程](https://developer.huawei.com/consumer/cn/training/result?type1=101718934267126043&orderBy=1)
    
*   [Codelabs](https://developer.huawei.com/consumer/cn/codelabsPortal/serviceTypes/43)
    
*   [考试认证](https://developer.huawei.com/consumer/cn/training/dev-certification/a617e0d3bc144624864a04edb951f6c4?ha_source=GWxfk&ha_sourceId=89000474)
    
*   [行业解决方案](https://developer.huawei.com/consumer/cn/solution/harmonyos/?ha_source=gwyj&ha_sourceId=89000071)
    
*   [开发者月刊](https://developer.huawei.com/consumer/cn/monthly/)
    

支持

*   [服务公告](https://developer.huawei.com/consumer/cn/notice)
    
*   [支持文档](https://developer.huawei.com/consumer/cn/doc/start/introduction-0000001053446472)
    
*   [智能客服](https://developer.huawei.com/consumer/cn/customerService/#/bot-dev-top/faq-top/faq-talk-top)
    
*   [社区问答](https://developer.huawei.com/consumer/cn/forum/)
    
*   [在线提单](https://developer.huawei.com/consumer/cn/support/feedback/#/)
    
*   [快速入门](https://developer.huawei.com/consumer/cn/develop-novice-guide/)
    
*   [联系我们](https://developer.huawei.com/consumer/cn/support/contactUs)
    
*   [协议与准则](https://developer.huawei.com/consumer/cn/agreement/)
    
*   [举报中心](https://developer.huawei.com/consumer/cn/report)
    
*   [联盟APP](https://developer.huawei.com/consumer/cn/huawei-app/)
    

Programs

*   [HUAWEI Developer Groups](https://developer.huawei.com/consumer/cn/programs/hdg/)
    
*   [HUAWEI Developer Experts](https://developer.huawei.com/consumer/cn/programs/hde)
    
*   [HUAWEI Student Developers](https://developer.huawei.com/consumer/cn/programs/hsd)
    
*   [HUAWEI Women Developers](https://developer.huawei.com/consumer/cn/programs/hwd)
    
*   [耀星计划](https://developer.huawei.com/consumer/cn/activity/yaoxingActivity/detail/617)
    

活动

*   [活动概览](https://developer.huawei.com/consumer/cn/activity/)
    
*   [HUAWEI Developer Day](https://developer.huawei.com/consumer/cn/activity/hdd/)
    
*   [HarmonyOS Tech Talk](https://developer.huawei.com/consumer/cn/training/landings/m0dkkmgd)
    
*   [2026 HarmonyOS 创新赛·极客赛道](https://developer.huawei.com/consumer/cn/activity/digixActivity/digixcmsdetail/101773710117484023)
    
*   [华为开发者大会（HDC）](https://developer.huawei.com/consumer/cn/hdc/2026/)
    
*   [鸿蒙应用开发者激励计划 2026](https://developer.huawei.com/consumer/cn/activity/harmonyos-incentive/2026?ha_source=yejiao&ha_sourceId=70000006)
    
*   [鸿蒙高校创新赛](https://developer.huawei.com/consumer/cn/activity/incentive/C4)
    

友情链接

[华为官网](https://www.huawei.com/cn/)

[消费者业务网站](https://consumer.huawei.com/cn/)

[华为商城](https://www.vmall.com/)

[HarmonyOS](https://consumer.huawei.com/cn/harmonyos-6/)

[华为终端云空间](https://cloud.huawei.com/)

[华为云](https://www.huaweicloud.com/)

简体中文

[![](https://developer.huawei.com/images/foot/1xinlang.png)![](https://developer.huawei.com/images/foot/1-1xinlang.png)](https://weibo.com/p/1006063211647923)

[![](https://developer.huawei.com/images/foot/2bz.png)![](https://developer.huawei.com/images/foot/2-2bz.png)](https://space.bilibili.com/645278427)

[![](https://developer.huawei.com/images/foot/3wx.png)![](https://developer.huawei.com/images/foot/3-1wx.png)](unsafe:javascript:void(0))

[![](https://developer.huawei.com/images/foot/4app.png)![](https://developer.huawei.com/images/foot/4-1app.png)](unsafe:javascript:void(0))

[![](https://developer.huawei.com/images/foot/5luntan.png)![](https://developer.huawei.com/images/foot/5-1luntan.png)](https://developer.huawei.com/consumer/cn/forum/)

[![](https://developer.huawei.com/images/foot/6youxiang.png)![](https://developer.huawei.com/images/foot/6-1youxiang.png)](https://developer.huawei.com/consumer/cn/blog/recommended)

华为开发者联盟 版权所有 ©2026

[使用条款](https://developer.huawei.com/consumer/cn/devservice/use)
|

[华为开发者联盟用户协议](https://developer.huawei.com/consumer/cn/doc/start/useragreement-0000001494912825)
|

[关于华为开发者联盟与隐私的声明](https://developer.huawei.com/consumer/cn/devservice/term)
|

[cookies](https://consumer.huawei.com/cn/legal/cookie-policy/)
|

[开源软件声明](https://developer.huawei.com/consumer/cn/opensource/)

您对本篇文章是否满意？

![score1](https://developer.huawei.com/consumer/cn/codelabsPortal/assets/images/Smileys/Angry2.png)

![score2](https://developer.huawei.com/consumer/cn/codelabsPortal/assets/images/Smileys/Blush2.png)

![score3](https://developer.huawei.com/consumer/cn/codelabsPortal/assets/images/Smileys/Smile2.png)

![score4](https://developer.huawei.com/consumer/cn/codelabsPortal/assets/images/Smileys/Playful2.png)

![score5](https://developer.huawei.com/consumer/cn/codelabsPortal/assets/images/Smileys/StarEyes2.png)

感谢您的反馈! 我们将在数据处理过程中匿名化您的反馈。您的反馈将有助于我们提升codelabs的质量。您提交的数据将被传输至位于中国境内的华为子公司。您的IP地址可能会被用于确定您提交反馈时所在的国家或地区，但是我们不会保存任何与此有关的信息，也不会收集任何可用于识别您与反馈的关系的信息。您提交所述反馈，则视为您同意我们可以将您的数据传输至位于中国的【华为软件技术有限公司】。请注意，如果您位于欧盟/欧洲经济区，则中国的法律可能不会为您的数据提供与欧盟/欧洲经济区法律规定的同等程度的保护。如需更多信息，请阅读《关于华为开发者联盟与隐私的声明》。

取消 提交

*   智能客服
    
    你问我答，随时在线为你解决问题
    

*   合作咨询
    
    我们的专家服务团队将竭诚为您提供专业的合作咨询服务
    

*   解决方案
    
    精准高效的一站式服务支持，助力开发者商业成功
