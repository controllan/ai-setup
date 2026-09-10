# Orchestrator Design — ai-setup

Date: 2026-09-10
Status: Approved

## Context

The ai-setup repo ships 11 specialist subagents (`agents/*.md`, `mode: subagent`) orchestrated manually via @mention in lifecycle order. The 2026-09-02 agent-team spec decided D2: no lead agent, manual orchestration. This spec reverses D2: add a single primary orchestrator that routes requests to the 11 specialists as subagents. D1 (11-role roster), D4 (self-contained files), D5 (`agents/` location) stay in force. D3 (glm/mimo/deepseek tiers + temperature + permissions) is superseded by O8 below.

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| O1 | Single primary `agents/orchestrator.md`, `mode: primary` (Approach A) | Matches D4 self-contained pattern; INSTALL Step 3 glob picks it up with zero config changes. Rejected: thin-primary + routing skill (two files, sync cost) and config-default routing (invasive, removes user choice). |
| O2 | Intent-based auto-routing over keyword mapping | Keywords miss intent (e.g. "slow page" = frontend + test + review). Orchestrator reasons over request intent + touched files/stacks. |
| O3 | Best-guess routing on ambiguity, never blocks | User override 2026-09-10: proceed with best-guess agent(s) + noted assumption. Direct `@mention` from user always bypasses routing. |
| O4 | Step 0 = brainstorming skill inside orchestrator | User requirement: first step is brainstorming (clarify purpose/constraints/success, 2–3 approaches unless trivial single-file fix) before any delegation. |
| O5 | Architect is conditional, not mandatory | Architect only on greenfield, architectural decisions, design, restructure/re-design, or architecture guidance/questions. All other requests route direct to the relevant specialist. |
| O6 | Lifecycle enforced when multi-step, single-shot otherwise | Greenfield/feature flows chain stages; isolated requests route singly. Test + review always precede git-expert in chained flows. |
| O7 | Orchestrator frontmatter is minimal: `description`, `mode: primary`, `model` per O8 high tier. No `temperature`, no `permission` block | User requirement 2026-09-10: strip temperature + permissions from all agents. Orchestrator is reasoning-heavy → high tier. Inherits the 7 universal rules verbatim. |
| O8 | Strip `temperature` + `permission` from all 12 agent files. Two model tiers only: high = muse-spark-1.3, low = `opencode-go/mimo-v2.5` | User requirement. High tier (orchestrator, software-architect, code-reviewer, security-reviewer). Low tier (go-developer, java-developer, frontend-developer, go-wasm-developer, github-actions-engineer, git-expert, ux-ui-designer, test-engineer — git-expert migrates from deepseek-v4-flash to mimo-v2.5). Exact 1.3 model ID to resolve at implementation (`opencode.json` currently lists muse-spark-1.2-contributor; add 1.3 entry if the provider exposes it under a different ID). |

## Routing table (intent → agent)

| Signal | Agent(s) |
|--------|----------|
| New project, concept, ADRs, OpenAPI, mermaid, module boundaries | `software-architect` (only per O5 conditions) |
| Go / go-gin REST, franz-go Kafka, JSON logging | `go-developer` |
| Quarkus, Maven, JUnit 5, Panache, Kafka/IBM MQ/Postgres (Java) | `java-developer` |
| TypeScript, Next.js/React/Angular, CSS, jest, pnpm | `frontend-developer` (+ `ux-ui-designer` when UI spec/theming/flows needed) |
| Go browser UI, go-app WASM | `go-wasm-developer` |
| `.github/workflows`, SonarQube/CodeQL gates, SemVer releases | `github-actions-engineer` |
| Test strategy, unit/integration/e2e, playwright journeys | `test-engineer` |
| Review request (quality/KISS/scalability/docs) | `code-reviewer` + `security-reviewer` in parallel (security-reviewer owns vulns/supply-chain) |
| Commits, branching, tags, `.gitignore` | `git-expert` |
| UI spec, themes (dark default/light), minimal clicks, icon-first, info tooltips | `ux-ui-designer` |
| Multi-match, independent work | Parallel fan-out, orchestrator synthesizes |

## Flows

**Step 0 (always, unless trivial single-file fix):** brainstorming — restate intent, clarify only what blocks routing, sketch 2–3 approaches for non-trivial work. Trivial (typo, single known file, direct answer) skips to routing.

**Greenfield:** Step 0 → architect (concept, architecture, ADRs, contracts, handoff) → ux-ui-designer (if UI) → developers in parallel per stack → test-engineer → code-reviewer + security-reviewer in parallel → fixes → git-expert.

**Feature/fix in existing codebase:** Step 0 → architect-lite only if O5 conditions met (else skip) → developer → test-engineer → reviewers → git-expert.

**Single-shot:** Step 0 (light) → one agent (or parallel reviewers) → done. No forced chaining.

**Ambiguity:** best-guess + one-line assumption note (e.g. "Routing to go-developer — assuming gin REST; correct me if Quarkus."). No blocking questions.

## Orchestrator file outline (`agents/orchestrator.md`)

Frontmatter: `description` (routes requests to 11 specialists, enforces lifecycle), `mode: primary`, `model` = high tier (muse-spark-1.3). No `temperature`, no `permission` block (O8). Body: universal rules block, Step 0 brainstorming rule, O5 architect gate, routing table, the three flows, best-guess + bypass rules, delegation format (goal, success criteria, scope, patterns to follow), verification (diagnostics/tests before done).

## Documentation plan

- `README.md`: agent count 11 → 12, orchestrator row on top (when-to-use: default entrypoint, auto-routes).
- `INSTALL.md`: Step 3 unchanged (glob covers new file); Step 9 count 11 → 12.
- This spec: design record + D2 reversal note.

## Out of scope

- No changes to file bodies beyond O8 frontmatter retiering (rules blocks, duties stay as-is).
- No changes to bootstrap.sh, shell, nvim, MCP setup.
- No `opencode.json` default-agent switch (user keeps choice of primary).
- No workflow plugin or slash command (revisit only if routing prompt outgrows one file).

## Self-review

Placeholders: one — exact 1.3 provider model ID, resolved at implementation (see O8). Consistency: O3 best-guess aligns with bypass rule; O5 conditional architect aligns with both flows; O6 lifecycle aligns with test-before-git gate; O7/O8 agree (no temperature/permissions anywhere). Scope: one new file + 11 frontmatter-only edits + two doc touch-ups, fits one implementation plan. Ambiguity: "trivial" means single file, known location, direct answer — stated in Flows. "Very high level" mapped as orchestrator/architect/reviewers; all else low tier.
