# Agent Team Design — ai-setup

Date: 2026-09-02
Status: Approved

## Context

The ai-setup repo provides a reproducible AI development environment (OpenCode + Superpowers + Caveman + MCP). `INSTALL.md` Step 3 copies agent definitions from `$REPO_DIR/agents/*.md` to `~/.config/opencode/agents/`, but the `agents/` directory does not exist yet. This spec defines a fresh set of specialist agents that collaborate as a software engineering team (plan → implement → test → review), created from scratch — no reuse of previous agent files.

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Add a dedicated **senior Java developer** role | Tool stack lists Java/Quarkus as a first-class backend stack; the original 10-role list had no Java role. Roster = 11 agents. |
| D2 | **No lead agent** — manual orchestration | User choice. The 11 specialists are orchestrated by the primary agent / user via @mention in lifecycle order. |
| D3 | **Tiered model assignment** | Heavy reasoning roles → `opencode-go/glm-5.3-flash`; executors → `opencode-go/mimo-v2.5`; mechanical role → `opencode-go/deepseek-v4-flash`. |
| D4 | **Self-contained agent files** | Each `.md` embeds the universal rules block inline (OpenCode agent files support no includes). Matches INSTALL.md Step 3 exactly; zero dependencies. |
| D5 | Files live at repo root `agents/` | Exactly what `INSTALL.md` Step 3 (`cp "$REPO_DIR/agents/"*.md`) already expects. |

## Roster

| # | File | Role | Model | Permissions |
|---|------|------|-------|-------------|
| 1 | `software-architect.md` | Architecture, concepts, mermaid diagrams, ADRs | glm-5.3-flash | edit: allow, bash: ask, webfetch: allow |
| 2 | `go-developer.md` | go-gin REST, franz-go Kafka | mimo-v2.5 | edit: allow, bash: allow |
| 3 | `java-developer.md` | Quarkus, Maven, JUnit 5, Panache | mimo-v2.5 | edit: allow, bash: allow |
| 4 | `frontend-developer.md` | Next.js/React/Angular, TS, jest, playwright | mimo-v2.5 | edit: allow, bash: allow |
| 5 | `go-wasm-developer.md` | go-app WASM UI | mimo-v2.5 | edit: allow, bash: allow |
| 6 | `github-actions-engineer.md` | CI/CD, sonarqube + codeql gates | mimo-v2.5 | edit: allow, bash: allow |
| 7 | `git-expert.md` | Conventional commits, branching, SemVer, gitignore | deepseek-v4-flash | edit: deny, bash: allow |
| 8 | `ux-ui-designer.md` | Themes, minimal clicks, icon-first UX | mimo-v2.5 | edit: allow, bash: ask |
| 9 | `test-engineer.md` | Unit/integration/e2e strategy + implementation | mimo-v2.5 | edit: allow, bash: allow |
| 10 | `code-reviewer.md` | Code + test quality review | glm-5.3-flash | edit: deny, bash: ask |
| 11 | `security-reviewer.md` | Vulns, backdoors, supply chain | glm-5.3-flash | edit: deny, bash: ask, webfetch: allow |

All agents: `mode: subagent`. Reviewers and git-expert get `temperature: 0.1`, architect `0.2`, builders default.

## Universal rules block (embedded in every agent)

1. KISS — simplest solution that satisfies the spec; no speculative features.
2. Never assume — unclear/incomplete/contradictory spec → stop and ask.
3. Minimal but extensible — smallest thing that works and can grow; tradeoffs → present options and ask.
4. Scalability — must run with 2+ replicas; no state lost on crash; instances ready <5s (ideally <1s).
5. Responsiveness — never add artificial delays (sleeps, fixed waits) to code, scripts, or tests.
6. Living documentation — docs updated with every change; docs are part of the deliverable.
7. Best practices — prefer common, established approaches over invention.

## Standard team workflow (manual orchestration)

Greenfield: architect (concept, architecture, ADRs, contracts) → ux-ui-designer (if UI) → developers (parallel, per stack) → test-engineer → code-reviewer + security-reviewer → fixes → git-expert (commits/tags). Feature change: architect-lite (scope + ADR if architectural) → developer → test-engineer → reviewers → git-expert.

## Documentation plan

- `README.md`: agent count corrected (20 → 11), overview table with when-to-use per agent.
- `INSTALL.md`: no change (Step 3 already correct).
- This spec: design record for the agent team.

## Out of scope

- No lead/orchestrator agent, no workflow skill (D2).
- No changes to bootstrap.sh, shell config, nvim, MCP setup.
