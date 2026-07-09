# Tasks: HarmonyOS Healthy Life Codelab Reimplementation

**Input**: Design documents from `specs/001-harmonyos-ui-codelab/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Include focused Hypium tests for core domain rules and manual validation
steps for platform-only behavior.

**Organization**: Tasks are grouped by user story so the core habit loop can ship
before history/achievements and platform integrations.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on incomplete tasks.
- **[Story]**: Which user story the task supports.
- Every task includes exact repository paths.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm project baseline and align docs with Spec Kit workflow.

- [X] T001 Review current HarmonyOS entry module structure in `entry/src/main/ets/` against `specs/001-harmonyos-ui-codelab/plan.md`
- [X] T002 [P] Add Spec Kit workflow notes to `docs/superpowers/specs/2026-07-09-healthy-life-spec-design.md`
- [X] T003 [P] Confirm build/test commands for this local environment and record them in `specs/001-harmonyos-ui-codelab/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish clean rule and persistence boundaries before user stories.

**Critical**: No user story implementation should begin until these files expose
the intended boundaries and tests can target the rule layer.

- [X] T004 Normalize fixed task metadata in `entry/src/main/ets/domain/constants/TaskCatalog.ets`
- [X] T005 Update shared constants for stores, date formats, achievement thresholds, and card names in `entry/src/main/ets/domain/constants/AppConstants.ets`
- [X] T006 [P] Refine task/domain models in `entry/src/main/ets/domain/models/TaskInfo.ets`
- [X] T007 [P] Refine daily aggregate model in `entry/src/main/ets/domain/models/DayInfo.ets`
- [X] T008 [P] Refine daily snapshot model in `entry/src/main/ets/domain/models/DayTaskInfo.ets`
- [X] T009 [P] Refine achievement and form models in `entry/src/main/ets/domain/models/AchievementInfo.ets` and `entry/src/main/ets/domain/models/FormInfo.ets`
- [X] T010 Centralize date key and calendar window helpers in `entry/src/main/ets/domain/utils/DateUtils.ets`
- [X] T011 Update RDB schema for task configuration, daily progress, daily snapshots, and forms in `entry/src/main/ets/data/db/DbSchema.ets`
- [X] T012 Ensure idempotent database initialization in `entry/src/main/ets/data/db/DatabaseHelper.ets`
- [X] T013 Update task repository CRUD and default seeding in `entry/src/main/ets/data/db/TaskInfoRepository.ets`
- [X] T014 Update daily progress repository operations in `entry/src/main/ets/data/db/DayInfoRepository.ets`
- [X] T015 Update daily snapshot repository operations in `entry/src/main/ets/data/db/DayTaskRepository.ets`
- [X] T016 Update form registration repository operations in `entry/src/main/ets/data/db/FormInfoRepository.ets`
- [X] T017 Update streak and achievement preference operations in `entry/src/main/ets/data/prefs/PreferencesRepository.ets`
- [X] T018 [P] Add or update core rule tests for task catalog/date helpers in `entry/src/test/LocalUnit.test.ets`

**Checkpoint**: Domain constants, models, repositories, and date helpers are ready
for story-level behavior.

---

## Phase 3: User Story 1 - Track Today's Healthy Habits (Priority: P1) MVP

**Goal**: User can enable preset tasks, configure targets, check in today, and see
persisted progress.

**Independent Test**: Fresh install, enable drink water and smile, complete both,
restart the app, and verify today's progress remains correct.

### Tests for User Story 1

- [X] T019 [P] [US1] Add enable/disable and target validation tests in `entry/src/test/LocalUnit.test.ets`
- [X] T020 [P] [US1] Add numeric and one-time check-in rule tests in `entry/src/test/List.test.ets`

### Implementation for User Story 1

- [X] T021 [US1] Implement enable/disable and target update rules in `entry/src/main/ets/domain/rules/TaskRules.ets`
- [X] T022 [US1] Implement today's snapshot initialization rules in `entry/src/main/ets/domain/rules/DayInitRules.ets`
- [X] T023 [US1] Wire task initialization, task loading, and today's progress loading in `entry/src/main/ets/viewmodel/HomeStore.ets`
- [X] T024 [US1] Wire enable task flow from `entry/src/main/ets/pages/EditTaskPage.ets` through `entry/src/main/ets/viewmodel/HomeStore.ets`
- [X] T025 [US1] Wire disable task flow from `entry/src/main/ets/pages/EditTaskPage.ets` through `entry/src/main/ets/viewmodel/HomeStore.ets`
- [X] T026 [US1] Implement target picker behavior in `entry/src/main/ets/pages/EditTaskPage.ets`
- [X] T027 [US1] Implement add-task list states in `entry/src/main/ets/pages/AddTaskPage.ets`
- [X] T028 [US1] Render today's progress summary in `entry/src/main/ets/components/home/ProgressHeader.ets`
- [X] T029 [US1] Render today's task list and empty state in `entry/src/main/ets/components/home/TaskList.ets`
- [X] T030 [US1] Implement check-in dialog behavior in `entry/src/main/ets/components/dialog/TaskClockDialog.ets`
- [X] T031 [US1] Wire home page composition and selected-date state in `entry/src/main/ets/pages/HomePage.ets`
- [ ] T032 [US1] Run the Scenario 1 validation in `specs/001-harmonyos-ui-codelab/quickstart.md`

**Checkpoint**: User Story 1 is fully functional and can serve as the MVP.

---

## Phase 4: User Story 2 - Review History and Earn Achievements (Priority: P2)

**Goal**: User can inspect saved dates, preview future dates, and unlock streak
achievements without duplicate counting.

**Independent Test**: Complete all enabled tasks, simulate date changes, select
historical/future dates, and verify streak/achievement behavior.

### Tests for User Story 2

- [X] T033 [P] [US2] Add streak idempotency tests in `entry/src/test/LocalUnit.test.ets`
- [X] T034 [P] [US2] Add date initialization and history preview tests in `entry/src/test/List.test.ets`

### Implementation for User Story 2

- [X] T035 [US2] Implement consecutive-day update rules in `entry/src/main/ets/domain/rules/ConsecutiveDaysRules.ets`
- [X] T036 [US2] Extend day initialization for cross-day startup in `entry/src/main/ets/domain/rules/DayInitRules.ets`
- [X] T037 [US2] Add selected-date history and future preview loading in `entry/src/main/ets/viewmodel/HomeStore.ets`
- [X] T038 [US2] Implement 21-day calendar display and selection in `entry/src/main/ets/components/home/WeekCalendar.ets`
- [X] T039 [US2] Update task list behavior for historical read-only and future preview states in `entry/src/main/ets/components/home/TaskList.ets`
- [X] T040 [US2] Implement achievement state rendering in `entry/src/main/ets/pages/AchievementPage.ets`
- [X] T041 [US2] Trigger achievement unlock feedback from `entry/src/main/ets/viewmodel/HomeStore.ets`
- [X] T042 [US2] Wire bottom navigation and page routing in `entry/src/main/ets/pages/Index.ets`
- [ ] T043 [US2] Run the Scenario 2 validation in `specs/001-harmonyos-ui-codelab/quickstart.md`

**Checkpoint**: History, date transitions, streaks, and achievements work without
breaking the MVP.

---

## Phase 5: User Story 3 - Use Reminders and Home Screen Cards (Priority: P3)

**Goal**: Time-based task reminders and both service cards stay synchronized with
task configuration and today's progress.

**Independent Test**: Enable wake-up/sleep-early reminders, add both cards,
perform check-ins, and verify reminder/card state follows task state.

### Tests for User Story 3

- [X] T044 [P] [US3] Add reminder intent mapping tests in `entry/src/test/LocalUnit.test.ets`
- [X] T045 [P] [US3] Add card data mapping tests in `entry/src/test/List.test.ets`

### Implementation for User Story 3

- [X] T046 [US3] Wrap reminder create/update/cancel behavior in `entry/src/main/ets/services/ReminderService.ets`
- [X] T047 [US3] Call reminder service from task enable/disable/target update flow in `entry/src/main/ets/viewmodel/HomeStore.ets`
- [X] T048 [US3] Implement form registration lifecycle in `entry/src/main/ets/form/FormAbility.ets`
- [X] T049 [US3] Implement task-list card data mapping and updates in `entry/src/main/ets/services/FormService.ets`
- [X] T050 [US3] Implement 1x2 task-list card UI in `entry/src/main/ets/form/AgencyCard.ets`
- [X] T051 [US3] Implement 2x2 progress card UI in `entry/src/main/ets/form/ProgressCard.ets`
- [X] T052 [US3] Verify form metadata and dimensions in `entry/src/main/resources/base/profile/form_config.json`
- [X] T053 [US3] Verify reminder permission declaration in `entry/src/main/module.json5`
- [ ] T054 [US3] Run the Scenario 3 validation in `specs/001-harmonyos-ui-codelab/quickstart.md`

**Checkpoint**: Reminder and card integrations match product behavior and do not
own core habit rules.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Align visuals, resources, documentation, and final verification.

- [X] T055 [P] Align task icons, badge assets, backgrounds, and strings in `entry/src/main/resources/`
- [X] T056 [P] Polish profile/static mine page behavior in `entry/src/main/ets/pages/MinePage.ets`
- [X] T057 Review launch/entry UX alignment in `entry/src/main/ets/entryability/EntryAbility.ets`
- [X] T058 Run local unit tests for `entry/src/test/`
- [X] T059 Run HarmonyOS project sync/build for the `entry` module
- [X] T060 Update final implementation notes in `docs/superpowers/specs/2026-07-09-healthy-life-spec-design.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (Phase 1): No dependencies.
- Foundational (Phase 2): Depends on Setup and blocks all user stories.
- User Story 1 (Phase 3): Depends on Foundation and delivers MVP.
- User Story 2 (Phase 4): Depends on Foundation and should preserve US1.
- User Story 3 (Phase 5): Depends on Foundation and is easiest after US1.
- Polish (Phase 6): Depends on desired user stories.

### User Story Dependencies

- US1: No dependency on US2 or US3 after foundation.
- US2: Uses task/progress records from foundation and should be validated with
  US1 completed.
- US3: Uses task configuration and daily progress from foundation/US1.

### Within Each User Story

- Tests first where practical.
- Domain rules before repositories/viewmodel wiring.
- Viewmodel wiring before UI page polish.
- Story validation before moving to the next priority.

## Parallel Opportunities

- Setup docs tasks T002-T003 can run in parallel.
- Foundational model tasks T006-T009 can run in parallel after T004-T005.
- US1 tests T019-T020 can run in parallel.
- US2 tests T033-T034 can run in parallel.
- US3 tests T044-T045 can run in parallel.
- Card UI tasks T050-T051 can run in parallel after T049.
- Polish tasks T055-T056 can run in parallel.

## Parallel Example: User Story 1

```bash
# Parallel test work:
Task: "T019 [P] [US1] Add enable/disable and target validation tests in entry/src/test/LocalUnit.test.ets"
Task: "T020 [P] [US1] Add numeric and one-time check-in rule tests in entry/src/test/List.test.ets"

# Parallel UI/data review after domain rules:
Task: "T027 [US1] Implement add-task list states in entry/src/main/ets/pages/AddTaskPage.ets"
Task: "T028 [US1] Render today's progress summary in entry/src/main/ets/components/home/ProgressHeader.ets"
```

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 only.
3. Run Scenario 1 from `quickstart.md`.
4. Stop and demo the core habit loop before expanding scope.

### Incremental Delivery

1. Foundation -> US1: usable local habit tracker.
2. US2: history, streaks, achievements.
3. US3: reminders and cards.
4. Polish: visual/resource alignment and final build verification.

## Task Count Summary

- Total tasks: 60
- Setup: 3
- Foundational: 15
- US1: 14
- US2: 11
- US3: 11
- Polish: 6
