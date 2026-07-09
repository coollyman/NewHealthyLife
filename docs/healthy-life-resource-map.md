# 健康生活资源映射表

## 结论

推荐采用“官方 Codelab 作为 UI 标准，旧项目资源作为素材池”的方式实现。官方素材用于确认页面结构、动效和视觉层级；旧项目资源用于提取图标、徽章、背景、空状态和启动图。不要复用旧业务逻辑。

## 可选方案

### 方案 A：只按官方截图重绘

优点是界面最贴近 Codelab；缺点是需要重新绘制或替换所有图标。适合追求全新视觉。

### 方案 B：官方 UI + 旧资源复用（推荐）

优点是实现最快，且能保持健康生活样例的辨识度。旧资源只复制图片、颜色、字符串，不复制 ArkTS 逻辑。

### 方案 C：完整沿用旧资源目录

优点是迁移成本最低；缺点是资源命名和模块边界会把旧项目痕迹带进新工程。不推荐。

## 官方素材用途

| 文件 | Codelab 章节 | 用途 | 实现参考 |
| --- | --- | --- | --- |
| `official_01_codelab-content.gif` | 总览/源码下载附近 | 开篇演示或文档封面 | 不进入 App，作为验收总览 |
| `official_02_codelab-content.png` | 成就预览 | 成就页深色样式参考 | 对应成就徽章布局 |
| `official_03_codelab-content.png` | 桌面卡片 | 服务卡片在桌面的展示 | 参考 1x2/2x2 卡片入口 |
| `official_04_codelab-content.png` | 首页静态图 | 首页主视觉 | 进度区、日期条、任务列表 |
| `official_05_codelab-content.png` | 任务添加 | 任务列表页 | 六个任务入口与开关状态 |
| `official_06_codelab-content.png` | 代码结构 | 项目结构截图 | 文档参考，不进 App |
| `official_07_codelab-content.gif` | 启动与入口 | 启动页、广告页、隐私弹窗、进入首页 | 首次启动流程 |
| `official_08_codelab-content.gif` | 应用入口 | 桌面启动与 Tab 切换 | 底部导航：首页/我的或成就 |
| `official_09_codelab-content.gif` | 首页空状态 | 无任务日期 | 空状态插画与添加入口 |
| `official_10_codelab-content.gif` | 首页日期切换 | 首页日期联动 | 三周日期条与任务刷新 |
| `official_11_codelab-content.gif` | 任务入口 | 首页到任务列表 | 悬浮添加按钮与跳转 |
| `official_12_codelab-content.gif` | 任务添加/编辑 | 任务开关与编辑页 | 任务配置流程 |
| `official_13_codelab-content.gif` | 打卡 | 打卡弹窗与进度更新 | 任务卡点击、弹窗、完成态 |
| `official_14_codelab-content.png` | 创建服务卡片 | DevEco 菜单截图 | 文档参考，不进 App |
| `official_15_codelab-content.png` | 卡片配置 | 卡片配置截图 | 文档参考，不进 App |

`official_16` 到 `official_34` 是官网反馈与页脚资源，仅保留归档，不导入应用。

## 旧资源候选

| 功能 | 资源候选 | 建议新命名 |
| --- | --- | --- |
| 启动页 | `ic_splash_bg.png`, `logo.png` | `bg_splash.png`, `ic_app_logo.png` |
| 广告页 | `ic_ad_bg.png` | `bg_onboarding_health.png` |
| 首页背景 | `ic_home_bg.png` | `bg_home_header.png` |
| 首页进度状态 | `ic_home_undone.png`, `ic_home_half_done.png`, `ic_home_all_done.png` | `img_progress_empty.png`, `img_progress_half.png`, `img_progress_done.png` |
| 添加按钮 | `ic_home_add.png` | `ic_action_add_task.png` |
| 空状态 | `ic_no_data.png` | `img_empty_task.png` |
| Tab 首页 | `ic_tabs_home_normal.png`, `ic_tabs_home_sel.png` | `ic_tab_home_normal.png`, `ic_tab_home_selected.png` |
| Tab 成就 | `ic_tabs_achievement_normal.png`, `ic_tabs_achievement_sel.png` | `ic_tab_achievement_normal.png`, `ic_tab_achievement_selected.png` |
| Tab 我的 | `ic_tabs_mine_normal.png`, `ic_tabs_mine_sel.png` | `ic_tab_mine_normal.png`, `ic_tab_mine_selected.png` |
| 任务图标 | `ic_task_getup.png`, `ic_task_drink.png`, `ic_task_apple.png`, `ic_task_smile.png`, `ic_task_brush.png`, `ic_task_sleep.png` | `ic_task_get_up.png`, `ic_task_drink_water.png`, `ic_task_eat_apple.png`, `ic_task_smile.png`, `ic_task_brush_teeth.png`, `ic_task_sleep_early.png` |
| 任务卡片图 | `ic_card_*` | `img_task_card_*` |
| 打卡弹窗图 | `ic_dialog_*` | `bg_clock_dialog_*` |
| 成就徽章 | `ic_badge_*_on.png`, `ic_badge_*_off.png` | `ic_badge_day_*_on.png`, `ic_badge_day_*_off.png` |
| 返回/右箭头 | `ach_back.svg`, `ic_right_grey.png` | `ic_nav_back.svg`, `ic_chevron_right.png` |

## 已导入资源

当前新工程已经把旧项目可复用静态素材导入到 `D:\HarmonyOS\NewHealthyLife\entry\src\main\resources\base\media`。已覆盖首页、Tab、任务、任务卡片、打卡弹窗、成就徽章、启动页、广告页、空状态、用户头像和服务卡片所需资源。

ArkTS 页面与组件中的 38 个 `$r('app.media.*')` 引用已核对，当前没有缺失媒体资源。官方 Codelab 抓取的 `official_01` 至 `official_15` 仍保留在 `reference-assets/official-codelab/media`，用于实现和验收时对照 UI，不直接作为 App 内资源。

## 页面落地清单

### 启动与授权

参考 `official_07_codelab-content.gif`。实现启动页、广告/引导页、隐私弹窗。可复用 `bg_splash.png`、`ic_app_logo.png`、`bg_onboarding_health.png`。

### 首页

参考 `official_04`、`official_09`、`official_10`、`official_11`。首页包含顶部进度区、三周日期条、任务列表、空状态、悬浮添加按钮和底部 Tab。

### 任务列表与编辑

参考 `official_05`、`official_12`。任务列表展示六个固定任务；编辑页包含启用开关、目标设置、提醒设置和完成按钮。

### 打卡弹窗

参考 `official_13`。点击首页任务卡打开弹窗；按任务类型展示对应背景图和按钮状态，完成后刷新首页进度。

### 成就页

参考 `official_02`。展示 3、7、30、50、73、99 天徽章，未达成用 off 图，达成用 on 图。

### 服务卡片

参考 `official_03`、`official_14`、`official_15`。实现 1x2 任务清单卡片和 2x2 进度卡片，资源保持轻量，不使用官网截图作为卡片内容。

## 导入规则

复制资源到对应模块的 `src/main/resources/base/media` 后，必须使用语义化命名。资源引用统一通过 `$r('app.media.xxx')` 或模块资源引用，不在 ArkTS 中硬编码文件名路径。
