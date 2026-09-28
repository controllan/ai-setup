# Minimal Context Setup — Design

**Date:** 2026-09-28
**Status:** Draft — awaiting user review
**Goal:** Cut always-loaded context to the minimum while keeping all 13 agents and the full team workflow (brainstorm → spec → plan → implement → test → review → commit). No capability loss; only ceremony and dead weight removed.

## Decisions (approved in session 2026-09-28)

1. **SonarQube MCP + `opencode-cmd-provider` plugin** move into the repo config and stay enabled. Local model providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) stay machine-local — not committed.
2. **Superpowers is removed** with two skills vendored into the repo and adapted to the team workflow:
   - `brainstorming` — design → spec doc → user-review gate.
   - `writing-plans` — spec → implementation plan doc → user-approval gate → implementation.
   The other 12 skills (subagent-driven-development, executing-plans, dispatching-parallel-agents, receiving/requesting-code-review, using-git-worktrees, finishing-a-development-branch, systematic-debugging, test-driven-development, verification-before-completion, writing-skills, using-superpowers) are dropped. The `using-superpowers` bootstrap injection (~3.9 KB/session) and the plugin/symlinks/clone go too.
   - No visual companion (browser server + scripts) — text-only process.
   - No spec/plan reviewer prompt extras — review goes through `code-reviewer` when wanted.
3. **Caveman: base skill only.** Keep plugin + `/caveman` command + mode switching. Trim `skills/caveman/SKILL.md` (~7 KB → ~2 KB); the plugin injects the SKILL.md body into the system prompt on every turn, so this trims per-request context. The intensity table row format (`| **level** |` and `- level:` lines) is preserved because the plugin parses it. Remove `caveman-commit`, `caveman-review`, `caveman-compress`, `caveman-help`, `caveman-stats` skills and their commands.
4. **Cavecrew removed**: skill + `cavecrew-investigator/builder/reviewer` agents. They are unreachable — not in any Task allowlist — and untracked in the repo.
5. **`go-review` removed** (on-demand skill, not referenced by any agent; recoverable from git history). `memory`, `verifying-github-actions`, `update-ai-setup` stay.
6. **Language pass**: compress the always-loaded prose (orchestrator prompt, `AGENTS.md` guardrail, Task-listing agent descriptions) and all 12 specialist prompts into simplified technical English. Content preserved — `code-reviewer` verifies no semantic loss on the diff.
7. **Workflow gates become explicit**: brainstorming produces a spec and the user approves it; `technical-writer` produces the implementation plan with the `writing-plans` skill and the user approves it; only then the implementation loop runs. Both gates are written into the orchestrator lifecycle.
8. **Docs layout**: `docs/superpowers/specs` → `docs/specs`, `docs/superpowers/plans` → `docs/plans`; references updated everywhere.
9. **Release 0.2.0** (breaking: superpowers removed, caveman extras pruned, docs paths moved).

## Config sync strategy (fixes the clobber bug)

Today the updater copies `opencode/opencode.json` over the live config, which would wipe machine-local providers. New rule: deep-merge the repo config **into** the live config:

- Repo wins on every key it defines (so repo changes apply).
- `provider` keys that exist only in the live config are preserved (local models).
- Array values (`plugin`, `skills.paths`) are unioned so local additions survive.

Implemented with a short `python3` stdlib snippet in the updater — no `jq` dependency.

## Changes by file

**Repo:**
- `opencode/opencode.json` — add `mcp.sonarqube` (enabled) and the `plugin` entries (`./plugins/caveman/plugin.js`, `opencode-cmd-provider`). Local providers stay out.
- `skills/brainstorming/SKILL.md` — new, adapted: paths `docs/specs`, handoff to `writing-plans`, no visual companion / reviewer-prompt / style-skill references.
- `skills/writing-plans/SKILL.md` — new, adapted: `docs/plans`, execution handoff = orchestrator lifecycle (implement → test-engineer → code-reviewer → git-expert), no superpowers sub-skill references.
- `skills/caveman/SKILL.md` — new, trimmed (~2 KB), installer-prune overlays this version after any caveman installer run.
- `skills/go-review/` — deleted.
- `agents/orchestrator.md` — lifecycle gains the spec-approval and plan-approval gates; compressed.
- `agents/*.md` (12 specialists) — language pass, no content loss.
- `AGENTS.md` — guardrail updated (no superpowers references), compressed.
- `skills/update-ai-setup/SKILL.md` — rewritten: config merge, new skill set, caveman prune + overlay, stale superpowers artifact removal, verification.
- `INSTALL.md`, `README.md` — match the new flow; `CHANGELOG.md` — 0.2.0 entry; tag + GitHub release.

**This machine (via the new updater steps):**
- Remove `~/.config/opencode/superpowers/`, `plugins/superpowers.js`, `skills/superpowers`.
- Prune caveman extras + cavecrew artifacts; overwrite caveman SKILL.md with the trimmed one.
- Merge repo config into live (local providers preserved).
- Install vendored skills + updated agents.

## Always-loaded context budget (estimate)

| Item | Before | After |
|---|---|---|
| SonarQube MCP tools + instructions | ~8–10 KB | ~8–10 KB (unchanged, now in repo) |
| Caveman ruleset injection (per turn) | ~6.5 KB | ~2 KB |
| Superpowers bootstrap injection | ~3.9 KB | 0 |
| Skill descriptions listed | ~4.4 KB (26 skills) | ~1.3 KB (9 skills) |
| Agent descriptions (Task listing) | ~3 KB | ~1.8 KB |
| Orchestrator prompt | 6.7 KB | ~3.5 KB |
| AGENTS.md (global + project) | ~2.3 KB | ~1.8 KB |
| `cmd_plan_summary` tool | ~0.5 KB | ~0.5 KB (unchanged, now in repo) |

Net: roughly **–12 KB per session, –4.5 KB per request** (caveman injection).

## Verification

- Repo: `opencode.json` valid JSON; `grep` for superpowers/cavecrew/caveman-extras references returns only intended ones; skill scan on a fresh checkout lists exactly the 9 expected skills.
- Updater: idempotent (re-run changes nothing); local providers still present in live config after merge.
- Live: superpowers artifacts gone; caveman plugin loads; trimmed SKILL.md in place; `opencode` session starts after restart.

## Out of scope

- Disabling SonarQube MCP or moving it to per-project config (cost accepted for now).
- Vendoring anything else from caveman upstream besides the trimmed base skill.
- Further changes to model limits/providers.
