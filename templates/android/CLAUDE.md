@AGENTS.md

## Claude setup for this repo
- Project facts live in AGENTS.md, which Gemini in Android Studio reads too. Keep them there, and keep this file for Claude-only notes.
- Plugins enabled at project scope, from the `bbperdomo` marketplace:
  - `android-dev`: the build loop skill, plus the `gradle-runner` agent for long or failing builds
  - `chrisbanes-compose`: Compose and Kotlin skills
- Google's official Android skills are in `.claude/skills`. Manage them with:
  `android skills add|remove|update <skill> --agent=claude-code --project=.`
