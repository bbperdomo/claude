# Claude Code state of play — September 2026

Compiled 2026-09-19 from four research reports: official docs, skills and marketplaces, Android tooling, and orchestrators. Star counts and third-party claims are as the researchers reported them; **re-verify before installing anything.**

---

## Marketplaces worth knowing

| Marketplace | Trust level | Add with |
|---|---|---|
| `claude-plugins-official` | Anthropic-curated (310 entries). Third-party entries are pinned to a commit SHA | Added automatically. Manual: `/plugin marketplace add anthropics/claude-plugins-official` |
| `claude-community` (2,282 plugins) | Anthropic-screened mirror, automated checks only | `/plugin marketplace add anthropics/claude-plugins-community` |
| `anthropic-agent-skills` | Anthropic reference skills | `/plugin marketplace add anthropics/skills` |
| `chrisbanes-skills` | Well-known Android author; publishes evals | `/plugin marketplace add chrisbanes/skills` |
| `Kotlin` (kotlin-agent-skills) | JetBrains incubator | `/plugin marketplace add Kotlin/kotlin-agent-skills` |
| `dotnet-agent-skills` | Microsoft official | `/plugin marketplace add dotnet/skills` |
| trailofbits/skills | Security firm | `/plugin marketplace add trailofbits/skills` |
| `claude-code-workflows` (wshobson/agents) | Large community set; pick plugins individually | `/plugin marketplace add wshobson/agents` |

Browse and discover: https://claude.com/plugins (official, shows install counts) and the `/plugin` Discover tab, which shows each plugin's context cost and what it installs.

---

## Shortlist

### General — user scope (on in every project)
| Item | Notes |
|---|---|
| `kotlin-lsp@claude-plugins-official` | Real type errors and go-to-definition without running Gradle. Needs JetBrains' `kotlin-lsp` binary on PATH. Alpha: experimental Android support, no KMP; on Windows it's a manual zip install |
| `jdtls-lsp@claude-plugins-official` | Java equivalent. Needs `jdtls` |
| `code-review`, `pr-review-toolkit` | Official multi-agent review with confidence filtering |
| `security-guidance` | Official |
| `skill-creator`, `plugin-dev` | For building your own marketplace |
| `claude-md-management`, `hookify` | CLAUDE.md upkeep; writing hooks in plain language |
| `context7` | Up-to-date library docs. **Queries go to Upstash's hosted service** |
| `superpowers@claude-plugins-official` **or** `mattpocock-skills@claude-plugins-official` | A development methodology. Never install both (overlapping triggers) |

### Android — project scope (on only in Android repos)
| Item | Install / notes |
|---|---|
| **Android CLI** (Google) | `winget install -e --id Google.AndroidCLI`, then `android init`, then `android skills add --all --project=.`. Confirm the `--agent` value with `android skills add -h`. On Windows, `android emulator` is disabled; downloading via PowerShell isn't supported, but winget works. The `android studio …` bridge commands need Quail 2 Canary 1+ with Gemini enabled and signed in |
| **android/skills** (24 official) | https://github.com/android/skills — AGP 9 upgrade, Navigation 3, edge-to-edge, R8 analyzer, testing setup, profiler, Play policy, intent security… |
| Claude Code JetBrains plugin | https://plugins.jetbrains.com/plugin/27310, then `/ide`. In-IDE diffs, plus `getDiagnostics` from Studio's inspections |
| `chrisbanes-skills@chrisbanes-skills` | Compose state and performance, Flow, Kotlin API design, gradle-run |
| mobile-mcp | `claude mcp add mobile-mcp -- npx -y @mobilenext/mobile-mcp@latest` (Node 20+, adb). Screenshots, accessibility tree, taps on the emulator |
| Maestro MCP (alternative) | `claude mcp add maestro -- maestro mcp`. Use when you want reusable YAML UI tests |
| One of: aldefy/compose-skill **or** skydoves/compose-performance-skills | Deeper Compose coverage; pick one only |

### Kotlin Multiplatform — project scope
- `kotlin-agent-skills@Kotlin` (JetBrains)
- klibs.io MCP: `claude mcp add --transport http klibs https://api.klibs.io/mcp`
- Compose Hot Reload MCP: needs a desktop target and CMP 1.12+; runs the `hotMcpServer` Gradle task (`gradlew.bat` on Windows)

### Secondary stacks
- **.NET:** dotnet/skills, `csharp-lsp`, `microsoft-docs` (official)
- **React:** `frontend-design`, `chrome-devtools-mcp` (official), vercel-labs/agent-skills
- **Security review:** trailofbits `differential-review`, `sharp-edges`, `insecure-defaults`

---

## Built-in orchestration (nothing to install)
- **Desktop app parallel sessions** with the worktree checkbox. Add a `.worktreeinclude` so gitignored `local.properties` (and `google-services.json`, keystore props) get copied into worktrees, otherwise Android builds fail there. Keep it to about 2–3 concurrent Gradle builds.
- **Subagents** in `.claude/agents/` (frontmatter: `tools`, `model`, `isolation: worktree`, `background`)
- **`/goal`**: keep working until a condition holds, judged by a separate model. The supported successor to "Ralph" loops.
- `/loop`, desktop scheduled tasks, cloud **Routines**
- **Dynamic workflows** (`ultracode`, `/deep-research`, `/batch`): fan-out to many subagents, best for mechanical sweeps backed by a reliable compiler and test signal
- **Agent teams**: experimental (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), about 7x tokens; split panes don't work in Windows Terminal (in-process mode does)
- **Hooks**: about 30 events; `"shell": "powershell"` is supported on Windows
- **Status line**: `/statusline`; receives cost, context, and 5-hour/7-day rate limits
- **Sandboxing**: the built-in Bash sandbox is **not available on native Windows**. For unattended runs use WSL2, a devcontainer, or cloud sessions.

Anthropic's comparison of the parallel options: https://code.claude.com/docs/en/agents

---

## Skip
- **No native Windows:** Claude Squad, Conductor, Superset, cmux
- **Dead:** Crystal (deprecated), Vibe Kanban (company shut down Apr 2026), GSD (archived)
- **Mega-bundles / unverified claims:** Ruflo (claude-flow), oh-my-claudecode, ECC, gstack
- **Heavy ceremony for daily work:** spec-kit, BMAD. For lightweight specs, OpenSpec.
- **Capture-everything memory plugins:** claude-mem
- **Aggregators as install sources:** skillsmp, claudemarketplaces, tonsofskills. Fine for discovery only.
- **Any skill that asks you to** download an .exe, run `iwr … | iex`, or click past SmartScreen

## Security incidents worth remembering
- **Snyk ToxicSkills:** 13.4% of 3,984 scanned skills had critical issues; 76 were confirmed malicious; most of those were prompt injection in SKILL.md itself.
- **FakeGit (July 2026):** about 7,600 malicious repos, 800+ posing as skills or MCP servers, delivering Windows malware.
- **CVE-2025-59536 / CVE-2026-21852:** remote code execution and token exfiltration via repo hooks and MCP config.

## Vetting routine
1. Prefer official or SHA-pinned catalog entries.
2. Read the plugin's `hooks/`, `.mcp.json`, `bin/` and scripts before installing. `claude plugin details <plugin>` helps.
3. Optionally scan with `uvx mcp-scan@latest --skills` or cisco-ai-defense/skill-scanner.
4. Try at local or project scope first.
5. Pin what you keep in your own marketplace by `sha`.

---

## Key docs
- Skills: https://code.claude.com/docs/en/skills
- Plugins: https://code.claude.com/docs/en/plugins · reference: https://code.claude.com/docs/en/plugins-reference
- Marketplaces: https://code.claude.com/docs/en/plugin-marketplaces
- Discover/install: https://code.claude.com/docs/en/discover-plugins
- Settings: https://code.claude.com/docs/en/settings-reference
- Subagents: https://code.claude.com/docs/en/sub-agents · Agent teams: https://code.claude.com/docs/en/agent-teams · Workflows: https://code.claude.com/docs/en/workflows
- Hooks: https://code.claude.com/docs/en/hooks · JetBrains: https://code.claude.com/docs/en/jetbrains
- Android CLI: https://developer.android.com/tools/agents/android-cli
- Agent Skills open standard: https://agentskills.io
