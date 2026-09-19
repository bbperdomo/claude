---
name: android-build-loop
description: How to compile, test, deploy and visually verify changes in an Android Gradle project. Use when building or type-checking Kotlin/Java code, running unit or instrumented tests, installing to an emulator or device, or confirming a UI change actually renders correctly.
---

# Android build loop

Work in the smallest loop that proves the change: compile, then test, then (for UI) look at the device.

## Gradle

- Always use the project wrapper: `.\gradlew.bat` from PowerShell/cmd, `./gradlew` from bash (Git Bash, WSL, macOS). Never a system `gradle`.
- Prefer targeted tasks over whole-project ones:
  - Type-check: `:app:compileDebugKotlin` (or the module you touched)
  - Unit tests: `:module:testDebugUnitTest --tests "*ClassNameTest"`
  - Debug APK: `:app:assembleDebug`
  - Lint, only when asked or before a PR: `:app:lintDebug`
- **Never run `clean`** unless the user asks. It throws away the build cache and makes every later build slow.
- Avoid the bare `build` task. It runs release variants and every check.
- For any run whose output may be long, or any failure you need to diagnose, delegate to the `gradle-runner` agent. It returns only the errors that matter and keeps Gradle logs out of the main context.

## Device loop (Android CLI)

1. Check for a device: `adb devices`. If none is listed, `android emulator list`, then `android emulator start <avd>`. That command returns only once the emulator has fully booted.
2. Build, install and launch: `android run`. It uses delta install by default, so repeat runs are fast.
3. Inspect the UI:
   - `android layout --pretty`: the UI tree as JSON. **Prefer this.** It is much cheaper in tokens than a screenshot and gives exact text, ids and bounds.
   - `android screen capture --annotate -o <file>.png`: take a screenshot when appearance matters (colors, spacing, clipping, edge-to-edge insets).
   - To tap: read an element's bounds from the layout, then `adb shell input tap <x> <y>`.

## Before using an unfamiliar API

Run `android docs search "<topic>"` and `android docs fetch kb://...` first. Android APIs change faster than your training data: AGP 9, Navigation 3, edge-to-edge enforcement on SDK 35+, predictive back.

## Definition of done

- The touched modules compile.
- The relevant tests pass. Say which ones you ran.
- For UI changes, the layout tree or a screenshot confirms the change on a running device.
- If you couldn't verify something (no device, a test you couldn't run), say so explicitly rather than implying it passed.
