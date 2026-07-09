# Feature Specification: HarmonyOS Healthy Life Codelab Reimplementation

**Feature Branch**: `001-harmonyos-ui-codelab`

**Created**: 2026-07-09

**Status**: Draft

**Input**: User description: "从零重新实现 HarmonyOS 健康生活习惯打卡应用，功能和 UI 对齐华为官方 Codelab：6 个预设健康任务、启用停用、目标设置、每日打卡、进度展示、历史日期、连续打卡成就、提醒和 1x2/2x2 服务卡片；内部采用全新实现，旧项目仅作为资源参考。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Track Today's Healthy Habits (Priority: P1)

A user opens the app, enables one or more preset health tasks, sets targets where
available, and checks in against today's tasks until the daily progress reflects
completion.

**Why this priority**: This is the core product loop. Without today's task setup,
check-in, and progress feedback, the app has no usable MVP.

**Independent Test**: Start from a fresh install, enable drink water and smile,
set the water target, check in on each task, and verify that today's progress,
task completion states, and persisted state remain correct after reopening.

**Acceptance Scenarios**:

1. **Given** a fresh app with no enabled tasks, **When** the user enables a
   preset task, **Then** that task appears in today's task list and today's
   target task count increases.
2. **Given** an enabled numeric task, **When** the user checks in repeatedly,
   **Then** progress increases by the task step and the task becomes complete
   only when the configured target is reached.
3. **Given** an enabled one-time or time-based task, **When** the user checks in
   once, **Then** the task is marked complete and cannot be double-counted.
4. **Given** the user closes and reopens the app, **When** today's screen loads,
   **Then** enabled tasks and completed progress are restored accurately.

---

### User Story 2 - Review History and Earn Achievements (Priority: P2)

A user views a three-week date window, selects prior or future dates, sees the
appropriate task history or preview, and earns consecutive-day achievements when
daily completion thresholds are met.

**Why this priority**: History and achievements make the habit loop motivating
and prove that the app handles date changes instead of only the current session.

**Independent Test**: Complete all enabled tasks for one day, simulate the next
day, verify streak changes, select historical dates, and confirm achievement
states at configured thresholds.

**Acceptance Scenarios**:

1. **Given** a selected date with saved tasks, **When** the user selects that
   date in the calendar, **Then** the app shows the saved progress for that date.
2. **Given** a future date without saved records, **When** the user selects it,
   **Then** the app shows a preview based on currently enabled tasks without
   corrupting today's progress.
3. **Given** all enabled tasks are completed today for the first time, **When**
   progress reaches 100%, **Then** the current streak increases once and the
   highest streak updates if applicable.
4. **Given** the highest streak reaches 3, 7, 30, 50, 73, or 99 days for the
   first time, **When** the achievement screen is opened or the threshold is
   reached, **Then** the corresponding achievement is unlocked.

---

### User Story 3 - Use Reminders and Home Screen Cards (Priority: P3)

A user enables time-based tasks, receives reminder behavior consistent with the
task target, and adds home screen cards that show today's task list or progress.

**Why this priority**: Reminders and cards align the app with the official
Codelab experience, but they depend on the core task and progress model.

**Independent Test**: Enable wake-up and sleep-early tasks, change their target
times, add both supported card sizes, perform check-ins, and verify reminders
and cards remain synchronized with task state.

**Acceptance Scenarios**:

1. **Given** a time-based task is enabled, **When** the user saves it, **Then**
   the app requests any required permission and creates or updates the matching
   daily reminder.
2. **Given** a time-based task is disabled, **When** the change is saved,
   **Then** the matching reminder is cancelled and no stale reminder remains.
3. **Given** a 1x2 task-list card is added, **When** today's tasks change,
   **Then** the card shows the updated task list.
4. **Given** a 2x2 progress card is added, **When** today's progress changes,
   **Then** the card shows the updated target count, completed count, and
   percentage.

---

### Edge Cases

- Fresh install has no database records or preference values.
- Opening the app across midnight must initialize the new date without creating
  duplicate daily task records or double-counting streaks.
- Disabling an unfinished task today removes it from today's target count;
  disabling a completed task must not corrupt historical completion data.
- Checking in after a task is already complete must leave progress unchanged.
- Numeric task progress may exceed its target on the last step but still counts
  as exactly one completed task.
- No enabled tasks means daily percentage is 0% and streaks do not increase.
- Permission denial for reminders must leave the task usable and clearly avoid
  creating a false reminder state.
- Deleted or unavailable service cards must not block normal app progress.
- Future date preview must not persist as completed historical data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST provide exactly six preset task types for the first
  implementation: wake up, drink water, eat apples, smile, brush teeth, and
  sleep early.
- **FR-002**: Users MUST be able to enable or disable each preset task.
- **FR-003**: Users MUST be able to configure targets for wake-up time,
  sleep-early time, daily water amount, and daily apple count.
- **FR-004**: Fixed one-time tasks MUST complete with a single check-in.
- **FR-005**: Numeric tasks MUST advance by their configured step and complete
  when their progress reaches or exceeds the configured target.
- **FR-006**: Time-based tasks MUST complete with a single check-in and retain
  their configured target time for reminder behavior.
- **FR-007**: The app MUST persist task configuration separately from daily task
  completion records.
- **FR-008**: The app MUST create daily task snapshots for enabled tasks and use
  those snapshots as the source of daily progress.
- **FR-009**: The app MUST recompute daily target count, completed count, and
  percentage after task enablement, disablement, and check-in.
- **FR-010**: The app MUST show a 21-day calendar window centered around the
  current week and allow date selection.
- **FR-011**: The app MUST show saved historical progress for dates with
  records.
- **FR-012**: The app MUST show a non-destructive preview for future dates that
  do not yet have records.
- **FR-013**: The app MUST track current consecutive completion days and highest
  consecutive completion days.
- **FR-014**: The app MUST unlock achievements at highest-streak thresholds of
  3, 7, 30, 50, 73, and 99 days.
- **FR-015**: The app MUST request and manage reminders for wake-up and
  sleep-early tasks when reminder permission and platform capability allow it.
- **FR-016**: The app MUST support a 1x2 home screen card showing today's task
  list.
- **FR-017**: The app MUST support a 2x2 home screen card showing today's
  target count, completed count, and percentage.
- **FR-018**: Service cards MUST update after task configuration or daily
  progress changes.
- **FR-019**: The app MUST visually align with the official Healthy Life Codelab
  main flows: launch/home, task management, check-in dialog, achievements,
  profile, and cards.
- **FR-020**: The implementation MUST treat legacy project code only as a
  reference/resource source and MUST NOT preserve legacy bugs or hidden global
  task completion state.

### Key Entities *(include if feature involves data)*

- **Task Catalog Item**: A preset health task type, including task identity,
  display name, default target, unit, step behavior, target options, and whether
  reminders are supported.
- **Task Configuration**: The user's current enablement, target value, reminder
  state, and platform reminder identifier for one preset task.
- **Daily Task Snapshot**: A task instance for a specific date, including copied
  target value, current progress, and completion state.
- **Daily Progress**: Aggregate progress for one date, including target task
  count, completed task count, and percentage.
- **Achievement State**: Highest streak, current streak, current day counted
  status, and unlocked achievement thresholds.
- **Form Card Registration**: A saved platform card identifier, card name, and
  dimension used for synchronization.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From a fresh install, a user can enable two tasks and complete
  today's habit loop in under 2 minutes.
- **SC-002**: 100% of the six preset tasks can be enabled, disabled, and shown
  correctly in the task management flow.
- **SC-003**: Daily progress remains correct across app restart for at least 10
  consecutive manual verification runs.
- **SC-004**: Consecutive-day and achievement thresholds produce no duplicate
  unlocks when the same completed day is reopened multiple times.
- **SC-005**: The three-week calendar allows selecting all 21 visible dates
  without changing unrelated dates' saved progress.
- **SC-006**: Both supported service card sizes reflect task/progress changes
  after a normal card update cycle.
- **SC-007**: The project can be synchronized and built through the available
  HarmonyOS build tooling after each completed implementation slice.

## Assumptions

- The first implementation targets local-only usage with no account, cloud sync,
  or social sharing.
- Legacy resources may be copied or recreated, but legacy source architecture is
  not a compatibility requirement.
- Historical dates are read-only for the first implementation; users check in
  only for the current day.
- Future dates without saved records are previews and do not become persisted
  history until normal daily initialization.
- Reminder behavior follows the configured target time for wake-up and
  sleep-early tasks; advanced reminder schedules are out of scope.
- The official card reset behavior is preserved for the first implementation
  unless a later product decision changes it.
