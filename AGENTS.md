# Repository Guidelines

## Project Structure & Module Organization

This is a HarmonyOS ArkTS application with a single `entry` module. Root-level files such as `build-profile.json5`, `oh-package.json5`, `hvigorfile.ts`, and `code-linter.json5` define project build, package, and lint behavior. Application code lives under `entry/src/main/ets`: pages are in `pages/`, reusable UI in `components/`, app state in `viewmodel/`, services in `services/`, persistence in `data/`, and domain rules/models/constants in `domain/`. Resources are under `entry/src/main/resources`. Unit tests are in `entry/src/test`; device or ability tests are in `entry/src/ohosTest`.

## Build, Test, and Development Commands

Use `devecocli` by default for HarmonyOS project commands.

- `devecocli build`: build the default debug product.
- `devecocli build --build-mode release`: build a release variant.
- `devecocli device list`: list connected devices and running emulators.
- `devecocli run --module entry`: build, install, and launch the app on a device.
- `devecocli log --level E --tail 200`: inspect recent error logs.
- `devecocli docs search <keyword>`: search local HarmonyOS documentation.

Run tests from DevEco Studio or the configured HarmonyOS test runner for `entry/src/test` and `entry/src/ohosTest`.

## Coding Style & Naming Conventions

Write ArkTS with clear module boundaries matching the existing folders. Use two-space indentation in JSON/JSON5 files and keep ArkTS formatting consistent with nearby files. Name pages and components in `PascalCase` with descriptive suffixes, such as `HomePage.ets`, `TaskList.ets`, and `ReminderService.ets`. Keep domain logic out of UI pages when it fits existing `domain/`, `data/`, or `services/` layers.

## Testing Guidelines

Place local unit tests in `entry/src/test` and device or ability tests in `entry/src/ohosTest`. Name test files with the `.test.ets` suffix, following examples such as `LocalUnit.test.ets` and `Ability.test.ets`. Add tests for rule, repository, and state changes whenever behavior changes.

## Commit & Pull Request Guidelines

The current history is short, so prefer concise imperative commit messages, for example `Implement health task reminders`. Pull requests should include a short summary, test/build evidence, linked issues when applicable, and screenshots or recordings for visible UI changes.

## Agent-Specific Instructions

For HarmonyOS scaffold, build, run, device, emulator, log, docs, or skills work, use `devecocli` rather than lower-level tools by default.
