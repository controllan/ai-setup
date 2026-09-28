# Minimal Context Setup — Design

**Date:** 2026-09-28 · **Status:** draft, awaiting user review
**Goal:** cut always-loaded context to minimum. Keep 13 agents + full workflow (brainstorm → spec → plan → implement → test → review → commit). No capability loss.

## Decisions

1. **SonarQube MCP** → repo config, `enabled: false` default. Enable when needed: per project via project `opencode.json` (`{"mcp":{"sonarqube":{"enabled":true}}}`) or flip live config temporarily. Saves ~8–10 KB/session. `opencode-cmd-provider` plugin → repo, stays enabled. Local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) stay machine-local — never committed.
2. **Superpowers removed**, 3 skills vendored + adapted to team workflow:
   - `brainstorming` — design → spec + user gate → plan handoff.
   - `writing-plans` — plan doc + user gate → orchestrator implementation loop.
   - `visual-companion` — own skill: browser mockups/diagrams/comparisons. Rule: design/UI question clearer shown than told → offer in its own message, user opt-in per use, hand out full session URL. Scripts vendored (branding stripped, guide trimmed to opencode/Unix). Session dir stays `.superpowers/brainstorm/`; remind user to gitignore `.superpowers/`.
   Dropped: other 12 skills + bootstrap injection (~3.9 KB/session) + plugin + symlinks + clone.
3. **Caveman: base only.** Plugin + `/caveman` switching + `/caveman` command stay. `skills/caveman/SKILL.md` 7 KB → ~2 KB — plugin re-injects this body per request. Keep intensity-table row format (plugin parses it). Remove `caveman-commit`, `caveman-review`, `caveman-compress`, `caveman-help`, `caveman-stats` skills + their commands.
4. **Cavecrew removed** — skill + 3 agents. Unreachable (not in any Task allowlist), untracked in repo.
5. **`go-review` removed** (on-demand, unreferenced; recoverable from git history). Live copy pruned by updater too. Keep `memory`, `verifying-github-actions`, `update-ai-setup`.
6. **Language pass**: compress orchestrator prompt, 12 specialist prompts, `AGENTS.md`, Task-listing agent descriptions (simplified technical English). `code-reviewer` checks diff for semantic loss.
7. **Workflow gates, every change request**: brainstorm (orchestrator + user) → technical-writer writes spec → user approves → technical-writer writes plan → user approves → implement loop. Technical-writer authors both spec and plan, always before implementation. Pure questions/direct answers skip. Gates written into orchestrator lifecycle.
8. **Compact doc style for committed specs/plans**: caveman ultra compression + STE clarity guardrails. Fragments OK; tables/lists over prose. Verbatim: paths, commands, signatures, numbers, negations, acceptance criteria. Code blocks unchanged. Clarity wins on conflict. Rules in both skills + one-liner in `AGENTS.md`. This spec retro-applied.
9. **Docs move**: `docs/superpowers/{specs,plans}` → `docs/specs`, `docs/plans`; all refs updated.
10. **Release 0.2.0** (breaking: superpowers removed, caveman extras pruned, sonarqube default-off, docs moved).

## Config sync fix

Deep-merge repo `opencode.json` into live config: repo wins; live-only `provider` keys preserved; arrays (`plugin`, `skills.paths`) unioned. `python3` stdlib, no `jq`. Fixes current clobber bug (updater would wipe local providers).

## Changes

**Repo:**
- `opencode/opencode.json` — add `mcp.sonarqube` (disabled) + plugin entries (`./plugins/caveman/plugin.js`, `opencode-cmd-provider`).
- New: `skills/brainstorming/`, `skills/writing-plans/`, `skills/visual-companion/` (+ `scripts/`), `skills/caveman/` (trimmed).
- Delete: `skills/go-review/`.
- `agents/orchestrator.md` (gates + compression), `agents/*.md` (compression, all 12), `AGENTS.md` (guardrail + style rule + compression).
- `skills/update-ai-setup/SKILL.md` — rewrite: config merge, skill install, caveman prune + overlay, superpowers artifact removal, verification.
- `INSTALL.md`, `README.md`, `CHANGELOG.md` (0.2.0 entry), tag + GitHub release.

**This machine:** run new updater steps (prune, remove superpowers artifacts, merge config, install skills), then user restarts opencode.

## Always-loaded budget (estimate)

| Item | Before | After |
|---|---|---|
| SonarQube MCP tools + instructions | ~8–10 KB | 0 (opt-in per project) |
| Caveman ruleset injection (per request) | ~6.5 KB | ~2 KB |
| Superpowers bootstrap injection | ~3.9 KB | 0 |
| Skill descriptions listed | ~4.4 KB (26 skills) | ~1.5 KB (8 skills) |
| Agent descriptions (Task listing) | ~3 KB | ~1.8 KB |
| Orchestrator prompt | 6.7 KB | ~3.5 KB |
| AGENTS.md (global + project) | ~2.3 KB | ~1.8 KB |
| `cmd_plan_summary` tool | ~0.5 KB | ~0.5 KB |

Net: ≈ **–20 KB/session, –4.5 KB/request**.

## Verification

- Repo: `opencode.json` valid JSON; zero refs to removed artifacts; fresh skill scan = expected list (7 local + built-in); specs/plans compact.
- Updater: idempotent re-run changes nothing; local providers survive merge; sonarqube ends disabled.
- Live: superpowers artifacts gone; caveman plugin loads; `/caveman full` switches; new session starts clean.
- Enable path: project-level config flips sonarqube on.

## Out of scope

- Upstream caveman sync beyond vendored base skill + plugin.
- Model/provider limit changes.
