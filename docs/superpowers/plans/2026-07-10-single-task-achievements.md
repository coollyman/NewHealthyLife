# Single Task Achievements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-task completion and overachievement medals to the achievement page.

**Architecture:** Keep achievement calculations as pure rules in `AchievementRules.ets`, expose a small HomeStore query method that reads historical `DayTaskInfo`, and render the results in `AchievementPage.ets`. Numeric tasks may continue accumulating after reaching 100% so 200%/300%/400% medals can be earned.

**Tech Stack:** HarmonyOS ArkTS, Hypium tests, existing RDB repositories and resource badges.

---

### Task 1: Achievement Rules

**Files:**
- Modify: `entry/src/main/ets/domain/rules/AchievementRules.ets`
- Test: `entry/src/test/AchievementUpgrade.test.ets`

- [ ] Add tests for per-task completion, numeric max percent, and threshold unlocks.
- [ ] Add `TaskAchievementSummary`, `calculateTaskAchievementSummaries`, and `OVERACHIEVEMENT_THRESHOLDS`.
- [ ] Verify tests compile with `devecocli build`.

### Task 2: Numeric Overachievement Check-in

**Files:**
- Modify: `entry/src/main/ets/domain/rules/TaskRules.ets`
- Modify: `entry/src/main/ets/components/home/TaskList.ets`
- Test: `entry/src/test/NumericCheckin.test.ets`

- [ ] Add tests proving a completed numeric task can continue from 100% to 150%/200%.
- [ ] Change `canCheckin` and `checkinTask` so numeric tasks remain checkable after completion and keep accumulating `finValue`.
- [ ] Keep once/time tasks idempotent after completion.
- [ ] Show numeric completed rows as progress text instead of only `已完成`.

### Task 3: HomeStore + Achievement Page

**Files:**
- Modify: `entry/src/main/ets/viewmodel/HomeStore.ets`
- Modify: `entry/src/main/ets/pages/AchievementPage.ets`

- [ ] Add `getTaskAchievementSummaries()` to load all historical day tasks and current task configs.
- [ ] Render “单项达成” and “超额达成” sections below existing consecutive badges.
- [ ] Reuse existing on/off badge resources with compact labels.

### Task 4: Verification

**Files:**
- All touched files

- [ ] Run `devecocli build`.
- [ ] Confirm no new build errors.
- [ ] Report any remaining existing warnings separately.
