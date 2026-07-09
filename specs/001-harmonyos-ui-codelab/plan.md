# Implementation Plan: HarmonyOS Healthy Life Codelab Reimplementation

**Branch**: `001-harmonyos-ui-codelab` | **Date**: 2026-07-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-harmonyos-ui-codelab/spec.md`

## Summary

Reimplement the HarmonyOS Healthy Life habit tracker as a local-first ArkTS app
aligned with Huawei's Codelab-visible behavior: six preset tasks, daily check-in,
progress, history, achievements, reminders, and two service card sizes. The
technical approach keeps business rules in domain modules, stores durable state
in local RDB/preferences, and wraps reminders/cards behind services so the core
habit model remains testable.

## Technical Context

**Language/Version**: ArkTS in HarmonyOS Stage model project; repository config
uses `modelVersion` 6.1.1.

**Primary Dependencies**: HarmonyOS kits already referenced by the project:
ArkUI, ArkData, FormKit, BackgroundTasksKit, AbilityKit, PerformanceAnalysisKit,
LocalizationKit, and test dependencies `@ohos/hypium` / `@ohos/hamock`.

**Storage**: Local RDB for task configuration, daily task snapshots, daily
progress, and form registrations; Preferences for streak and achievement state.

**Testing**: Hypium local/unit tests where APIs are pure or mockable; manual
device/simulator validation for reminders, service cards, permissions, and
visual alignment.

**Target Platform**: HarmonyOS phone app with entry ability and form extension.

**Project Type**: Mobile app with local persistence and home screen cards.

**Performance Goals**: App start and date selection should feel immediate for
the fixed six-task scope; check-in, enable/disable, and progress recomputation
should complete within a normal tap interaction.

**Constraints**: Local-first, offline-capable, no account/cloud dependency,
fixed six preset tasks for v1, reminder/card APIs must not own core habit rules,
and daily initialization must be idempotent.

**Scale/Scope**: One entry module, six task types, 21 visible calendar dates,
six achievement thresholds, two card dimensions, and daily history stored
locally.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Product Fidelity First: PASS. Spec traces to the official Codelab-visible
  flows while treating legacy code only as reference/resource material.
- Clean Domain Model: PASS. Plan separates domain rules, repositories, app
  services, state stores, UI pages/components, and form surfaces.
- Testable Core Rules: PASS. Data model and tasks include focused rule tests and
  manual validation for platform-only behavior.
- Local-First Reliability: PASS. RDB/preferences are the durable source of user
  progress; repeated initialization and sync must be idempotent.
- Incremental Feature Slices: PASS. Tasks are organized as core tracking,
  history/achievements, reminders/cards, and polish.

## Project Structure

### Documentation (this feature)

```text
specs/001-harmonyos-ui-codelab/
├── spec.md
├── checklists/
│   └── requirements.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-state-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
entry/src/main/ets/
├── domain/
│   ├── constants/
│   │   ├── AppConstants.ets
│   │   └── TaskCatalog.ets
│   ├── models/
│   │   ├── AchievementInfo.ets
│   │   ├── DayInfo.ets
│   │   ├── DayTaskInfo.ets
│   │   ├── FormInfo.ets
│   │   └── TaskInfo.ets
│   ├── rules/
│   │   ├── ConsecutiveDaysRules.ets
│   │   ├── DayInitRules.ets
│   │   └── TaskRules.ets
│   └── utils/
│       └── DateUtils.ets
├── data/
│   ├── db/
│   │   ├── DatabaseHelper.ets
│   │   ├── DayInfoRepository.ets
│   │   ├── DayTaskRepository.ets
│   │   ├── DbSchema.ets
│   │   ├── FormInfoRepository.ets
│   │   └── TaskInfoRepository.ets
│   └── prefs/
│       └── PreferencesRepository.ets
├── services/
│   ├── FormService.ets
│   └── ReminderService.ets
├── viewmodel/
│   └── HomeStore.ets
├── pages/
│   ├── AchievementPage.ets
│   ├── AddTaskPage.ets
│   ├── EditTaskPage.ets
│   ├── HomePage.ets
│   ├── Index.ets
│   └── MinePage.ets
├── components/
│   ├── dialog/
│   └── home/
└── form/
    ├── AgencyCard.ets
    ├── FormAbility.ets
    └── ProgressCard.ets

entry/src/test/
├── LocalUnit.test.ets
└── List.test.ets
```

**Structure Decision**: Use the existing `entry` module and current layered
folders. The implementation should refine the existing domain/data/service/UI
boundaries instead of adding another module.

## Phase 0: Research

See [research.md](./research.md).

## Phase 1: Design & Contracts

- Data model: [data-model.md](./data-model.md)
- UI/state contract: [contracts/ui-state-contract.md](./contracts/ui-state-contract.md)
- Validation guide: [quickstart.md](./quickstart.md)

## Complexity Tracking

No constitution violations are currently required.
