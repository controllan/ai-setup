# AI Setup

Complete AI development environment — **OpenCode + Superpowers + Caveman + Agents + MCP**.
Fully reproducible via a two-phase installation.

## What's Inside

| Component | Description | Source |
|-----------|-------------|--------|
| **OpenCode** | AI coding agent for the terminal | Homebrew |
| **Superpowers** | 14 composable dev workflow skills | [obra/superpowers](https://github.com/obra/superpowers) |
| **Caveman** | Token compression (cuts ~75% output) | Local skill |
| **Memory** | Persistent agent memory via Obsidian | Local skill |
| **Updater** | One-command refresh of the local install to the repo version ("update my ai-setup") | Local skill |
| **13 Agents** | Orchestrator + 12 specialists (architect, devs, test, writer, reviewers) | Custom |
| **MCP** | Obsidian integration for note/memory access | uvx mcp-obsidian |

## Agents

Specialist team for software engineering — the `orchestrator` is the default entrypoint (`default_agent` in `opencode.json`) and runs every request through the team lifecycle: brainstorm → architect/ux gates → technical-writer plan → per-logical-part loop (implement + test with e2e → review → commit) until the spec is done → security review per finished feature/component/phase:

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

All agents share one non-negotiable rule set: KISS, never assume (ask instead), minimal-but-extensible, 2+ replica scalability, no artificial delays, living documentation, best practices. Design rationale: [docs/superpowers/specs/2026-09-02-agent-team-design.md](docs/superpowers/specs/2026-09-02-agent-team-design.md).

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
- Homebrew + Homebrew packages (from `tools/Brewfile`)
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
| 4 | Copy personal skills (caveman, memory) → `~/.config/opencode/skills/` |
| 5 | Clone `obra/superpowers`, create plugin + skills symlinks |
| 6 | Verify everything is in place |
| 7 | Print remaining manual steps |

### After Phase 2

1. **Edit `~/.gitconfig`** — set your name and email
2. **Edit `~/.config/opencode/opencode.json`** — set your [Obsidian API key](mcp/obsidian-setup.md)
3. **Restart your terminal** — or run `exec zsh`
4. **Start OpenCode** — run `opencode` and ask: "do you have superpowers?"

## Directory Layout

```
~/.config/opencode/
├── opencode.json           # Main config (MCP, agents)
├── package.json            # Plugin deps
├── agents/                 # 13 agent definitions (orchestrator + 12 specialists)
├── skills/                 # Skills directory
│   ├── superpowers/        # → symlink → superpowers/skills (14 skills)
│   ├── caveman/
│   ├── caveman-commit/
│   ├── caveman-review/
│   └── memory/
├── plugins/
│   └── superpowers.js      # → symlink → superpowers/.opencode/plugins/superpowers.js
└── superpowers/            # Cloned from obra/superpowers
```

## Manual Installation

If you prefer step-by-step, follow [`INSTALL.md`](INSTALL.md) directly.

## Updating

Say "update my ai-setup" (uses the updater skill): it pulls the repo and, only
when `CHANGELOG.md` lists a newer version than
`~/.config/opencode/.ai-setup-version`, syncs config, agents, and skills. Every
feature ships as a SemVer tag + GitHub release — see `CHANGELOG.md`.

```bash
# Manual equivalent — this repo
cd ~/ai-setup && git pull && bash bootstrap.sh

# Superpowers
cd ~/.config/opencode/superpowers && git pull
```

## Troubleshooting

### "I don't have superpowers" — plugin not loading

```bash
ls -la ~/.config/opencode/plugins/superpowers.js  # Should be a symlink
ls ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js  # Must exist
```

### Skills not found

```bash
ls -la ~/.config/opencode/skills/superpowers  # Should be a symlink
# Should point to: ~/.config/opencode/superpowers/skills
```

### npm install failures

```bash
cd ~/.config/opencode && npm install --no-fund --no-audit
```
