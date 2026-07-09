# HealthyLife 实现资源包

本目录汇总了重新实现健康生活应用所需的参考资源。实现以华为官方 Codelab 展示为主，旧项目资源仅作为可复用素材池，不建议复用旧逻辑代码。

## 目录结构

- `official-codelab/media/`: 从华为官方 Codelab 页面抓取的图片与 GIF，共 34 个文件。
- `official-codelab-media-manifest.json`: 每个官方资源的来源 URL、分类、文件名和下载状态。
- `legacy-project/`: 从旧项目复制出的本地资源，包括截图、公共资源、入口模块资源和 AppScope 资源。

页面与资源的对应关系见 `D:\HarmonyOS\NewHealthyLife\docs\healthy-life-resource-map.md`。

## 官方资源分类

`official-codelab/media/` 中的文件按来源用途命名：

- `official_01_codelab-content.*` 至 `official_15_codelab-content.*`: Codelab 正文中的核心功能、页面、交互动图和截图，优先作为 UI 复刻参考。
- `official_16_feedback-ui.*`、`official_17_feedback-smiley.*` 等: 官网反馈组件资源，通常不需要放入新应用。
- `official_*_site-footer.*`: 官网页脚与站点资源，仅保留归档，不建议用于应用实现。

## 旧项目资源

`legacy-project/` 复制了旧工程中可安全参考的静态素材：

- `screenshots/`: 旧 README 截图，可辅助确认页面效果。
- `commons-common-resources/`: 公共颜色、字符串、图片等资源。
- `products-default-resources/`: 入口模块资源。
- `appscope-resources/`: 应用级图标与配置资源。

## 使用建议

实现 `D:\HarmonyOS\NewHealthyLife` 时，优先从 `official-codelab/media/` 还原页面结构、布局节奏和交互效果；再从 `legacy-project` 选择图标、背景、插画等可复用素材。导入到 ArkTS 工程时，建议重新命名为业务语义化资源名，例如 `ic_task_drink_water.png`、`bg_home_progress.png`，并放入对应模块的 `src/main/resources/base/media`。
