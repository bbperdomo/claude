# {{PROJECT_NAME}}

{{One paragraph: what the app does and who it's for.}}

## Stack
- Kotlin, Jetpack Compose. minSdk {{N}}, targetSdk {{N}}
- Architecture: {{MVVM / MVI}} · DI: {{Hilt / Koin / none}} · Persistence: {{Room / DataStore / none}}
- Modules: `:app` {{list feature/core modules as they're added}}

## Commands
Run from the repo root. Use `./gradlew` in bash and `.\gradlew.bat` in PowerShell.
- Type-check: `.\gradlew.bat :app:compileDebugKotlin`
- Unit tests: `.\gradlew.bat :app:testDebugUnitTest`
- Build, install and launch on a running emulator or device: `android run`
- Lint: `.\gradlew.bat :app:lintDebug`
- Never run `clean` unless asked.

## Conventions
- {{Project-specific rules: package layout, state handling, error handling, naming, anything that must not be touched.}}
