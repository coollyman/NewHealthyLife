# Data Model: HarmonyOS Healthy Life Codelab Reimplementation

## Task Catalog Item

Immutable definition for one of the six preset tasks.

**Fields**
- `taskId`: integer 0-5.
- `name`: localized display name.
- `kind`: `time`, `numeric`, or `oneTime`.
- `defaultTarget`: target time or numeric value.
- `unit`: display unit, if any.
- `step`: progress increment for numeric tasks.
- `targetOptions`: allowed target values.
- `supportsReminder`: true for wake-up and sleep-early tasks only.
- `assets`: icon and check-in dialog visual references.

**Validation**
- Exactly six catalog entries exist.
- `taskId` values are stable and unique.
- Numeric tasks have positive `step` and target options.

## Task Configuration

User-editable state for a preset task.

**Fields**
- `taskId`: references Task Catalog Item.
- `isOpen`: whether the task is enabled.
- `targetValue`: configured target time or numeric value.
- `isAlert`: reminder enabled flag.
- `alertStartTime`, `alertEndTime`, `alertFrequency`: reserved reminder fields.
- `reminderId`: platform reminder id or `-1`.

**Validation**
- Target value must be one of the catalog-allowed values.
- `reminderId` must be `-1` when no valid platform reminder exists.
- Reminder fields only apply to tasks that support reminders.

**State Transitions**
- Disabled -> Enabled: persist configuration, create today's daily snapshot, and
  update reminder when supported.
- Enabled -> Disabled: persist configuration, remove unfinished snapshot from
  today, and cancel reminder when supported.
- Enabled target changed: persist configuration, update today's unfinished
  snapshot target, and update reminder when supported.

## Daily Task Snapshot

Task progress for one date.

**Fields**
- `id`: local identifier.
- `date`: `yyyyMMdd`.
- `taskId`: references Task Catalog Item.
- `targetValue`: copied target value for the date.
- `finValue`: current progress for the date.
- `isDone`: completion flag for the date.

**Validation**
- At most one snapshot per `date + taskId`.
- Disabled tasks cannot receive new check-ins.
- Completed tasks ignore repeated check-in attempts.

**State Transitions**
- Missing -> Created: generated for enabled tasks during daily initialization.
- In Progress -> Done: once one-time/time task is checked in or numeric progress
  reaches target.
- In Progress -> Removed: allowed only for today's disabled unfinished task.

## Daily Progress

Aggregate progress for one date.

**Fields**
- `date`: `yyyyMMdd`.
- `targetTaskNum`: number of enabled/snapshot tasks for the date.
- `finTaskNum`: number of completed snapshots.
- `percentage`: `ceil(finTaskNum / targetTaskNum * 100)`, or 0 when no tasks.

**Validation**
- `finTaskNum` cannot exceed `targetTaskNum`.
- `percentage` is derived, not hand-edited by UI.

## Achievement State

Lightweight preference-backed streak and unlock state.

**Fields**
- `currentConsecutiveDays`: current active streak.
- `maxConsecutiveDays`: highest historical streak.
- `currentDayStatus`: whether today has already been counted.
- `unlockedThresholds`: thresholds unlocked from `3, 7, 30, 50, 73, 99`.

**Validation**
- A single date can increment streak at most once.
- Highest streak never decreases.
- Unlocking the same threshold twice must be a no-op.

## Form Card Registration

Saved card metadata for synchronization.

**Fields**
- `formId`: platform card id.
- `formName`: `agency` for task list or `progress` for progress card.
- `formDimension`: platform card dimension.

**Validation**
- Unknown `formName` values are ignored or removed during cleanup.
- Missing/deleted cards must not block app state changes.
