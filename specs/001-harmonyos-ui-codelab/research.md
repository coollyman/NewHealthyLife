# Research: HarmonyOS Healthy Life Codelab Reimplementation

## Decision: Keep a Fixed Task Catalog Separate from User Configuration

**Rationale**: The first implementation has exactly six preset tasks. A catalog
module can hold immutable metadata such as display name, default target, step,
target options, and reminder support. User configuration can then persist only
enablement, target value, and reminder state.

**Alternatives considered**:
- Store everything in one mutable task record. Rejected because daily completion
  state can accidentally leak into global configuration.
- Support custom task definitions immediately. Rejected because it expands scope
  beyond the Codelab-aligned v1.

## Decision: Use Daily Task Snapshots as Progress Source

**Rationale**: A snapshot copies the task target for a specific date and records
that date's progress. This preserves history when the user later changes or
disables a task.

**Alternatives considered**:
- Compute history from current task configuration. Rejected because changing a
  target would rewrite the meaning of past days.
- Store only aggregate daily progress. Rejected because the UI needs task-level
  history.

## Decision: Make Initialization and Sync Idempotent

**Rationale**: App start, date changes, form refresh, and repeated service calls
can occur more than once. Initialization must create missing records without
duplicating snapshots or double-counting streaks.

**Alternatives considered**:
- Trust lifecycle callbacks to run once. Rejected because mobile lifecycle and
  form extension behavior can repeat or interleave.

## Decision: Treat Reminder and Form APIs as Services

**Rationale**: Platform APIs are important for product fidelity but should not
own habit rules. Services can translate domain state into reminder/card updates
while letting tests focus on pure state transitions.

**Alternatives considered**:
- Call reminder/card APIs directly from UI components. Rejected because it hides
  business state changes in event handlers and makes testing harder.

## Decision: Use Hypium for Core Rule Tests and Manual Validation for Platform Features

**Rationale**: Core rules can be tested with local unit tests. Permission prompts,
home screen cards, and reminder delivery require emulator/device behavior and
should be validated through quickstart scenarios.

**Alternatives considered**:
- Require automated tests for all platform behavior now. Rejected as too costly
  for the first 0-to-1 implementation.
