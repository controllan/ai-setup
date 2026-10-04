# AI Setup

Complete AI development environment — **OpenCode + Agents + Workflow Skills + Caveman + MCP**, fully reproducible via a two-phase installation.

## What's Inside

| Component | Description | Source |
|-----------|-------------|--------|
| **OpenCode** | AI coding agent for the terminal | Homebrew |
| **Pi** | Second harness (`pi-coding-agent`) — same agents, skills, caveman; `pi/` is the shared Pi config source | Homebrew |
| **Workflow skills** | brainstorming, writing-plans, visual-companion — vendored + adapted | Local skills |
| **Caveman** | Token compression (cuts ~75% output) — trimmed base skill | Local skill |
| **Memory** | Persistent agent memory via Obsidian | Local skill |
| **Updater** | One-command refresh of the local install to the repo version ("update my ai-setup") | Local skill |
| **13 Agents** | Orchestrator + 12 specialists (architect, devs, test, writer, reviewers) | Custom |
| **MCP** | Obsidian; SonarQube opt-in (both disabled by default) | uvx mcp-obsidian; sonarsource/sonarqube-mcp |

## Agents

Specialist team for software engineering — the `orchestrator` is the default entrypoint (`default_agent` in `opencode.json`) and runs every request through the team lifecycle: brainstorm (brainstorming skill) → spec + user approval → writing-plans plan + user approval → per-logical-part loop (implement + e2e test → review → commit) → security review per finished feature/component/phase:

| Agent | When to use |
|-------|-------------|
| `orchestrator` | Default entrypoint: brainstorms, then auto-routes to the right specialist(s) and enforces the team lifecycle |
| `software-architect` | Only on greenfield / architectural decisions / design / restructure / architecture guidance: concept, architecture (mermaid), ADRs, OpenAPI contracts, handoff plan |
| `go-developer` | Go backends: go-gin REST, franz-go Kafka, JSON logging |
| `java-developer` | Java backends: Quarkus, Maven, JUnit 5, Panache, Kafka/IBM MQ/Postgres |
| `frontend-developer` | TypeScript UIs: Next.js/React/Angular, jest, playwright, pnpm supply-chain safety |
| `go-wasm-developer` | Go browser UIs with go-app |
| `github-actions-engineer` | CI/CD workflows with sonarqube + codeql gates, SemVer releases |
| `git-expert` | Conventional commits in logical components, branching, SemVer tags, .gitignore |
| `ux-ui-designer` | UI specs: dark (default)/light themes, minimal clicks, icon-first, ℹ️ tooltips |
| `test-engineer` | Unit/integration/e2e (playwright) tests — fast, deterministic, no artificial delays |
| `technical-writer` | Implementation plans from specs, living docs (README, guides, API docs) — no implementation code |
| `code-reviewer` | Reviews code AND tests (read-only): KISS, scalability, responsiveness, docs |
| `security-reviewer` | Vulns, backdoors, exploits, pnpm/maven supply-chain attacks (read-only) |

Routing is enforced three ways: `default_agent: orchestrator` in `opencode.json`, Task allowlists that deny `general`/`explore`/`build`/`plan` and allow only the 12 specialists (specialists themselves have Task denied — they are leaf workers), and `AGENTS.md` which overrides any skill text telling you to use a general-purpose subagent. All agents inherit your current session model (no per-agent pins). Copy `AGENTS.md` into any project that uses this team.

All agents share one non-negotiable rule set: KISS, never assume (ask instead), minimal-but-extensible, 2+ replica scalability, no artificial delays, living documentation, best practices. Design rationale: [docs/specs/2026-09-02-agent-team-design.md](docs/specs/2026-09-02-agent-team-design.md).

## Dual Harness (OpenCode + Pi)

OpenCode and Pi are both supported. The repo is the source of truth for shared config.

| Shared (synced from repo) | Where |
|---|---|
| Skills | `~/.pi/agent/skills` symlinks to `~/.config/opencode/skills` |
| Agents (12 specialists) | `pi/agents/*.md` → `~/.pi/agent/agents/` |
| Instructions | `pi/AGENTS.md` (caveman block + routing/lifecycle) → `~/.pi/agent/AGENTS.md` |
| Models config | `pi/models.json`: `commandcode` provider, 81 models |
| Defaults | `defaultProvider: commandcode`, `defaultModel: deepseek/deepseek-v4.1-flash` |
| Packages | pi-plan-mode, rpiv-todo, pi-permission-system, pi-subagents |
| Permission policy | `pi/extensions/pi-permission-system/config.json` |

Machine-local, never committed: local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) and local settings keys (`theme`, `lastChangelogVersion`). The updater deep-merges: repo wins, local values survive.

## Installation (Two Phases)

### Phase 1: Prerequisites (bash)

One-liner — installs brew, zsh, opencode, shell config, oh-my-zsh, plugins:

```bash
curl -fsSL https://raw.githubusercontent.com/controllan/ai-setup/main/bootstrap.sh | bash
```

Or if you already cloned the repo:

```bash
cd ~/ai-setup && bash bootstrap.sh
```

**What Phase 1 installs:**
- Homebrew + Homebrew packages
- zsh + oh-my-zsh + powerlevel10k theme
- zsh-autosuggestions + zsh-syntax-highlighting
- OpenCode (latest from Homebrew)
- Shell config (`.zshrc`, `.p10k.zsh`, `.gitconfig`)

### Phase 2: The AI Stack (OpenCode-driven)

Start OpenCode and paste this command:

```
fetch and follow instructions from https://raw.githubusercontent.com/controllan/ai-setup/main/INSTALL.md
```

OpenCode will read `INSTALL.md` and execute every step automatically, handling errors as they come:

| Step | What happens |
|------|-------------|
| 1 | Clone/update this repo |
| 2 | Copy `opencode.json`, `package.json` → `~/.config/opencode/`, run `npm install` |
| 3 | Copy 13 agent files → `~/.config/opencode/agents/` |
| 4 | Copy 8 skills (brainstorming, writing-plans, visual-companion, caveman, go-review, memory, update-ai-setup, verifying-github-actions) → `~/.config/opencode/skills/` |
| 5 | Run caveman installer, overlay trimmed base skill, prune extras + cavecrew |
| 6 | Remove legacy Superpowers artifacts |
| 7 | Verify everything is in place |
| 8 | Print remaining manual steps |

### After Phase 2

1. **Edit `~/.gitconfig`** — set your name and email
2. **Optional MCP setup (Obsidian and SonarQube ship disabled)** — enable per project via project `opencode.json`: `{"mcp":{"obsidian":{"enabled":true}}}` (API key in `~/.config/opencode/.secrets/obsidian-api-key`) or `{"mcp":{"sonarqube":{"enabled":true}}}` (token in `~/.config/opencode/.secrets/sonarqube-token`); or flip the live config. [Obsidian setup guide](mcp/obsidian-setup.md)
3. **Restart your terminal** — or run `exec zsh`
4. **Start OpenCode** — run `opencode`

## Directory Layout

```
~/.config/opencode/
├── opencode.json           # Main config (agents, MCP, plugins)
├── package.json            # Plugin deps
├── agents/                 # 13 agent definitions (orchestrator + 12 specialists)
├── skills/                 # 8 skills
│   ├── brainstorming/
│   ├── writing-plans/
│   ├── visual-companion/   # browser mockups (+ scripts/)
│   ├── caveman/
│   ├── go-review/
│   ├── memory/
│   ├── update-ai-setup/
│   └── verifying-github-actions/
└── plugins/
    └── caveman/            # caveman plugin
```

Repo Pi config (`pi/`):

```
pi/
├── models.json               # commandcode provider only (81 models)
├── settings.json             # packages + default provider/model
├── AGENTS.md                 # caveman block + Pi routing/lifecycle
├── agents/                   # 12 specialist definitions
└── extensions/
    └── pi-permission-system/
        └── config.json       # permission policy
```

Live Pi install (`~/.pi/agent/`):

```
~/.pi/agent/
├── models.json               # commandcode (81) + machine-local providers
├── settings.json             # synced keys + live-only keys
├── AGENTS.md
├── agents/                   # 12 specialists
├── skills -> ~/.config/opencode/skills
└── extensions/
    └── pi-permission-system/
        └── config.json
```

## Manual Installation

If you prefer step-by-step, follow [`INSTALL.md`](INSTALL.md) directly.

## Updating

Say "update my ai-setup" (uses the updater skill): it pulls the repo and, only
when `CHANGELOG.md` lists a newer version than
`~/.config/opencode/.ai-setup-version`, syncs config, agents, and skills. The
config sync deep-merges: repo wins; local providers survive; arrays unioned — Pi too (`pi/models.json` repo wins, local providers survive, `packages` unioned).
Every feature ships as a SemVer tag + GitHub release — see `CHANGELOG.md`.

Manual equivalent: follow the steps in `skills/update-ai-setup/SKILL.md` —
repo pull, config deep-merge, agents, skills including caveman overlay + prune,
Pi dual-harness sync, artifact removal, verify.

## Troubleshooting

### SonarQube tools missing

SonarQube MCP is disabled by default. To enable per project, add a project `opencode.json` with:

```json
{"mcp":{"sonarqube":{"enabled":true}}}
```

Token file: `~/.config/opencode/.secrets/sonarqube-token`.

### Skills not found

```bash
ls ~/.config/opencode/skills  # expect 8 dirs
```

### Caveman mode not switching

```bash
grep -q './plugins/caveman/plugin.js' ~/.config/opencode/opencode.json && echo "plugin entry: OK"
ls ~/.config/opencode/skills/caveman/SKILL.md && echo "skill: OK"
```

Then restart opencode.

### npm install failures

```bash
cd ~/.config/opencode && npm install --no-fund --no-audit
```

### Pi — `pi` not found

```bash
brew install pi-coding-agent
```

### Pi — models missing or fewer than 81

```bash
python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.pi/agent/models.json')));print(len(d.get('providers',{}).get('commandcode',{}).get('models',[])))"   # expect 81
```

Re-run the updater ("update my ai-setup"), which deep-merges `pi/models.json` into `~/.pi/agent/models.json`.

### Pi — subagents not loading

```bash
ls ~/.pi/agent/agents/*.md | wc -l   # expect 12
for pkg in @tintinweb/pi-subagents @narumitw/pi-plan-mode @juicesharp/rpiv-todo @gotgenes/pi-permission-system; do pi list | grep -q "npm:$pkg" && echo "pi pkg $pkg: OK" || echo "pi pkg $pkg: MISSING"; done
```

Restart Pi after syncing `~/.pi/agent` (Pi reads it at start).

### Pi — permission prompts

Policy lives in `~/.pi/agent/extensions/pi-permission-system/config.json`: reads anywhere allowed; writes outside cwd ask; secrets deny; destructive bash deny/ask. Re-run the updater Pi step to restore the repo policy.

### Pi — skills symlink broken

```bash
readlink ~/.pi/agent/skills   # expect ~/.config/opencode/skills
```
