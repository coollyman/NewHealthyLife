# HealthyLife UI Resources Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the HealthyLife UI resource integration and verify the current ArkTS page skeleton builds.

**Architecture:** The app remains a single HarmonyOS `entry` module. UI pages consume resources from `entry/src/main/resources/base/media`, domain rules stay under `entry/src/main/ets/domain`, and resource provenance stays in `reference-assets` plus `docs/healthy-life-resource-map.md`.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, Hvigor/DevEco CLI, Hypium tests.

---

## File Structure

- Modify: `D:\HarmonyOS\NewHealthyLife\docs\healthy-life-resource-map.md` to reflect actual imported resource locations.
- Inspect: `D:\HarmonyOS\NewHealthyLife\entry\src\main\resources\base\media` to confirm required images exist.
- Inspect: `D:\HarmonyOS\NewHealthyLife\entry\src\main\ets\pages\*.ets` and `components/**/*.ets` for missing resource references.
- Verify: `D:\HarmonyOS\NewHealthyLife\entry\src\test\NumericCheckin.test.ets` and Hvigor build output.

### Task 1: Confirm Required Resource Coverage

**Files:**
- Inspect: `D:\HarmonyOS\NewHealthyLife\entry\src\main\resources\base\media`
- Modify: `D:\HarmonyOS\NewHealthyLife\docs\healthy-life-resource-map.md`

- [x] **Step 1: Check resource filenames**

Run:

```powershell
Get-ChildItem -File -LiteralPath 'D:\HarmonyOS\NewHealthyLife\entry\src\main\resources\base\media' |
  Select-Object Name |
  Sort-Object Name
```

Expected: task icons, dialog images, badge images, home images, tab icons, splash/ad images, and card images are present.

- [x] **Step 2: Check ArkTS resource references**

Run:

```powershell
rg "\$r\('app\.media\." D:\HarmonyOS\NewHealthyLife\entry\src\main\ets
```

Expected: all referenced media names exist under `entry/src/main/resources/base/media`.

- [x] **Step 3: Update the mapping document**

Add a short "已导入资源" section listing that resources now live in `entry/src/main/resources/base/media`.

### Task 2: Verify Existing UI Skeleton

**Files:**
- Inspect: `D:\HarmonyOS\NewHealthyLife\entry\src\main\ets\pages\Index.ets`
- Inspect: `D:\HarmonyOS\NewHealthyLife\entry\src\main\ets\pages\HomePage.ets`
- Inspect: `D:\HarmonyOS\NewHealthyLife\entry\src\main\ets\components\home\*.ets`

- [x] **Step 1: Inspect page composition**

Run:

```powershell
Get-Content -Raw -LiteralPath 'D:\HarmonyOS\NewHealthyLife\entry\src\main\ets\pages\Index.ets'
Get-Content -Raw -LiteralPath 'D:\HarmonyOS\NewHealthyLife\entry\src\main\ets\pages\HomePage.ets'
```

Expected: `Index` hosts bottom tabs, and `HomePage` composes progress header, calendar, task list, and add-task entry.

- [x] **Step 2: Fix missing imports or broken resource references**

If Hvigor reports unresolved symbols or resources, edit the smallest affected ArkTS or resource JSON file and rerun the build.

### Task 3: Run Tests And Build

**Files:**
- Verify: `D:\HarmonyOS\NewHealthyLife\entry\src\test\*.ets`
- Verify: `D:\HarmonyOS\NewHealthyLife\build-profile.json5`

- [x] **Step 1: Run local tests**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
& 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry test
```

Expected: Hypium tests pass, especially numeric check-in and consecutive-day rules.

- [x] **Step 2: Run debug build**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\software\DevEco Studio\sdk'
& 'D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

Expected: `entry` module builds a debug HAP without missing resource or ArkTS compile errors.

### Task 4: Report Implementation State

**Files:**
- Read: `D:\HarmonyOS\NewHealthyLife\docs\healthy-life-resource-map.md`
- Read: build/test output

- [x] **Step 1: Summarize resource status**

Report imported resources, verified references, and any resources intentionally kept only under `reference-assets`.

- [x] **Step 2: Summarize verification**

Report exact test/build commands run and whether they passed. If blocked, include the first actionable compiler error and the file to fix next.
