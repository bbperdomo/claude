# claude

Bryan's Claude Code home: a personal plugin marketplace, per-stack project templates, and the scripts that rebuild this dev machine.

## Layout

```
.claude-plugin/marketplace.json   the catalog ("bbperdomo" marketplace)
plugins/
  android-dev/                    my own: Android build loop skill + gradle-runner agent
  chrisbanes-compose/             vendored subset of chrisbanes/skills (see its VENDORED.md)
templates/
  android/                        AGENTS.md, CLAUDE.md, .gitattributes, .worktreeinclude
user/CLAUDE.md                    personal instructions, copied to ~/.claude/CLAUDE.md
setup/
  phase0-admin.ps1                one-time elevated Windows prep (WSL, WHPX, long paths, Defender)
  bootstrap-claude.ps1            recreate the user-scope Claude setup on a machine
  apply-android-template.ps1      add the Android bundle to an Android project
  vendor-chrisbanes.ps1           refresh the vendored Chris Banes skills at a pinned commit
research/                         notes on the skills/plugins ecosystem
```

## The layering rule

| Layer | Scope | What |
|---|---|---|
| Always on | user (`~/.claude`) | `superpowers`, `context7`, personal CLAUDE.md |
| Per stack | project (`<repo>/.claude/settings.json`) | e.g. Android: `android-dev`, `chrisbanes-compose`, Google's skills in `.claude/skills` |
| Just for this repo | project | `plugin-dev` (only useful while building plugins) |

Anything stack-specific is enabled per project, never at user scope. Every always-on skill costs context in every session.

## Common tasks

- **New Android project:** create it in Android Studio under `C:\dev\projects\`, then
  `.\setup\apply-android-template.ps1 -Project C:\dev\projects\<App>` and fill in AGENTS.md.
- **Add a skill of my own:** add it to an existing plugin under `plugins/`, or create a new plugin and list it in `marketplace.json`. Then:
  `claude plugin validate . --strict` and `claude plugin marketplace update bbperdomo`.
- **Adopt a third-party plugin:** read its hooks, MCP config and scripts first. Prefer the official marketplace. Otherwise pin or vendor it here. Never install from aggregator sites.
- **New machine:** `.\setup\bootstrap-claude.ps1`.

## Vetting checklist for third-party plugins
1. `claude plugin details <plugin>`: component inventory and token cost.
2. Read `hooks/`, `.mcp.json`, `bin/` and any scripts. Hooks and MCP servers run as me.
3. Pin to a commit (or vendor) and bump it deliberately after reading the diff.
