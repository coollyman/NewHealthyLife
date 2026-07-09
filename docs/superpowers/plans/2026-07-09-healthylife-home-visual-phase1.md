# HealthyLife 首页视觉第一阶段计划

目标：先把 NewHealthyLife 首页与打卡弹窗拉近 HealthyLife 旧项目观感，不改业务逻辑。

改动范围：
- ProgressHeader：使用 `ic_home_bg` 做顶部大图背景，突出标题、今日进度百分比和进度状态图。
- TaskList：任务列表改为大圆角白卡，使用 `cardIcon`，状态文案按旧项目形式显示；未完成任务保留打卡入口。
- TaskClockDialog：放大任务插画和圆角弹窗，使用半透明背景色与蓝色胶囊按钮。

验证：运行 `hvigorw.bat assembleApp --no-daemon --stacktrace`，确认 ArkTS 编译通过。
