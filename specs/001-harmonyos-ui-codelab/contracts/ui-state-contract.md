# UI and State Contract

This contract describes the observable state each user-facing surface needs. It
is intentionally technology-light so implementation can evolve while preserving
behavior.

## Home Surface

**Inputs**
- Selected date.
- Current task configurations.
- Daily snapshots for selected date.
- Daily progress for selected date.
- Achievement state.

**Outputs**
- 21 visible calendar dates centered around the current week.
- Selected date progress summary.
- Task list for selected date.
- Empty state when selected date has no tasks.
- Navigation intents for task management and achievements.

**Rules**
- Today supports check-in.
- Historical dates show saved records.
- Future dates show preview records without persisting completion.

## Task Management Surface

**Inputs**
- Six task catalog items.
- Current task configurations.

**Outputs**
- Add-task list with task name, icon, enabled status, and edit intent.
- Edit-task state with enabled switch, target display, target picker where
  applicable, and save action.

**Rules**
- One-time tasks do not expose target picker.
- Time tasks expose time picker.
- Numeric tasks expose fixed allowed target values.

## Check-In Dialog

**Inputs**
- Daily task snapshot.
- Catalog item visuals and display metadata.

**Outputs**
- Task-specific title and visual treatment.
- Check-in action when task is not complete.
- Completed state when task is done.

**Rules**
- Repeated completed check-in attempts do not change progress.
- Numeric tasks show progress toward target.

## Achievement Surface

**Inputs**
- Highest streak.
- Unlocked threshold set.

**Outputs**
- Six achievement badges in locked or unlocked state.
- Achievement unlock feedback when a threshold is first reached.

## Service Cards

### 1x2 Task List Card

**Inputs**
- Today's enabled task snapshots.

**Outputs**
- Compact task list suitable for the card dimension.

### 2x2 Progress Card

**Inputs**
- Today's daily progress.

**Outputs**
- Target task count.
- Completed task count.
- Percentage/progress visual.

**Rules**
- Both cards refresh after enable/disable/check-in/progress recomputation.
- Tapping a card launches the main app surface.
