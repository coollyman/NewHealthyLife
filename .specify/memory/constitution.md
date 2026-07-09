<!--
Sync Impact Report
Version change: template -> 1.0.0
Modified principles:
- Template principle 1 -> I. Product Fidelity First
- Template principle 2 -> II. Clean Domain Model
- Template principle 3 -> III. Testable Core Rules
- Template principle 4 -> IV. Local-First Reliability
- Template principle 5 -> V. Incremental Feature Slices
Added sections:
- HarmonyOS Implementation Constraints
- Development Workflow
Removed sections:
- None
Templates requiring updates:
- ✅ .specify/templates/plan-template.md reviewed; Constitution Check can reference these gates.
- ✅ .specify/templates/spec-template.md reviewed; no structural change required.
- ✅ .specify/templates/tasks-template.md reviewed; story-sliced task organization aligns.
Follow-up TODOs:
- None
-->

# NewHealthyLife Constitution

## Core Principles

### I. Product Fidelity First
The app MUST reproduce the user-visible behavior and main UI flow of the Huawei
Healthy Life Codelab unless a later product decision explicitly overrides it.
Official Codelab behavior and screenshots are the primary reference; existing
legacy source code is only a resource pool for assets and terminology. Copying
old architecture, lifecycle assumptions, persistence coupling, or known defects
is not allowed.

### II. Clean Domain Model
Habit rules MUST live outside UI components. Task catalog data, daily task
snapshots, daily progress, consecutive-day rules, achievement thresholds, date
formatting, reminder intent, and form-card update intent MUST be expressible as
small domain or service operations. UI pages and cards may orchestrate these
operations but MUST NOT become the source of business truth.

### III. Testable Core Rules
Core rule changes MUST be covered by focused tests or by an explicit manual
validation checklist when platform APIs make automation impractical. At minimum,
tests or validation steps MUST cover task enable/disable, incremental check-in,
daily progress recomputation, consecutive-day updates, achievement thresholds,
and cross-day initialization. New behavior is not complete until its verification
path is documented and run.

### IV. Local-First Reliability
The application MUST remain useful without accounts, cloud sync, or network
access. RDB records and preferences MUST be treated as the durable source for
user progress. Date changes, app restarts, reminder updates, and form-card
updates MUST be idempotent: repeating initialization or sync operations must not
duplicate daily tasks, double-count streaks, or corrupt card state.

### V. Incremental Feature Slices
Implementation MUST proceed in independently verifiable slices: core habit
tracking first, then history and achievements, then reminders and service cards,
then visual polish. Each slice MUST leave the app buildable and demonstrable.
Large rewrites that mix unrelated UI, persistence, and platform integrations in
one step are not acceptable without documented justification.

## HarmonyOS Implementation Constraints

- Target implementation is a HarmonyOS ArkTS application in the existing
  `entry` module.
- The visible product scope is fixed to six preset health tasks: wake up, drink
  water, eat apples, smile, brush teeth, and sleep early.
- User-defined task types, cloud sync, social sharing, and account systems are
  out of scope for the first implementation.
- Local RDB stores task configuration, daily aggregate progress, daily task
  snapshots, and form-card metadata. Preferences store lightweight streak and
  achievement state.
- Reminder and form-card platform APIs MUST be wrapped behind small services so
  core habit rules can be reasoned about independently.
- Reused assets MUST be renamed or organized by purpose in the new project
  structure; old source code MUST NOT be copied wholesale.

## Development Workflow

- Start each feature from a specification that states user value, acceptance
  scenarios, requirements, measurable outcomes, and assumptions.
- Planning MUST document the selected project structure, platform constraints,
  and constitution gates before implementation tasks are generated.
- Tasks MUST be ordered by user story and include exact file paths so each slice
  can be implemented and verified independently.
- Before claiming completion, run the most relevant available verification:
  unit tests, Hvigor build/check commands, or a documented manual validation
  checklist for simulator/device-only behavior.
- Destructive file operations, git resets, or workspace cleanup require explicit
  user confirmation.

## Governance

This constitution supersedes ad-hoc project habits for NewHealthyLife. Any plan
or task list that violates a principle MUST document the violation, why it is
necessary, and why a simpler compliant option was rejected.

Amendments require updating this file, bumping the semantic version, and
reviewing Spec Kit templates or generated plans that reference these principles.
MAJOR changes redefine or remove principles, MINOR changes add or materially
expand principles or required workflow, and PATCH changes clarify wording
without changing meaning.

Compliance is checked during planning, task generation, implementation review,
and final verification. If a later user instruction conflicts with this
constitution, the user instruction wins for that task and the exception must be
recorded in the relevant plan or final summary.

**Version**: 1.0.0 | **Ratified**: 2026-07-09 | **Last Amended**: 2026-07-09
