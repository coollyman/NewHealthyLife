# Quickstart Validation Guide

## Prerequisites

- Open the project in DevEco Studio or use the available HarmonyOS build tooling.
- Use a simulator or device for service card and reminder validation.
- Start from a clean install when validating first-run behavior.

## Build and Test

1. Sync the HarmonyOS project dependencies.
2. Run available local tests for `entry/src/test`.
3. Build the `entry` module.
4. Install and launch the app on a simulator/device.

## Scenario 1: Today's Habit MVP

1. Launch from a clean install.
2. Confirm all six preset tasks exist and are disabled by default.
3. Enable "drink water" and set target to 1L.
4. Enable "smile".
5. Return to the home surface and confirm both tasks appear for today.
6. Check in "drink water" twice and confirm it completes after reaching 1L.
7. Check in "smile" once and confirm today's progress reaches 100%.
8. Close and reopen the app; confirm task states and progress persist.

## Scenario 2: History and Achievements

1. Complete all enabled tasks for today.
2. Reopen the same date and confirm the streak does not increase twice.
3. Simulate or wait for the next day.
4. Confirm daily initialization creates new snapshots without duplicating old
   records.
5. Select a historical date and confirm saved progress is shown.
6. Select a future date and confirm preview behavior does not alter today.
7. Validate achievement unlocks at configured thresholds with seeded or repeated
   test data.

## Scenario 3: Reminders and Cards

1. Enable "wake up" and set a target time.
2. Allow reminder permission if prompted.
3. Confirm a reminder id is saved or a permission-denied state is handled.
4. Change the target time and confirm reminder state updates.
5. Disable the task and confirm reminder state is cancelled.
6. Add the 1x2 task-list card and 2x2 progress card.
7. Perform a check-in in the app.
8. Confirm both cards refresh to match today's task list and progress.

## Completion Criteria

- Core habit loop works from fresh install through restart.
- History and streak rules are idempotent.
- Reminder denial or failure does not break task usage.
- Both card dimensions can be added, launched, and refreshed.
- The app remains visually aligned with the official Codelab main flows.
