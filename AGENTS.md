# AGENTS.md — Routing

Loaded every session; overrides conflicting skill text about which agent to use.

## Routing (mandatory)

- Default entrypoint: `orchestrator` — brainstorms, routes specialists, enforces lifecycle.
- Delegate ONLY via Task, `subagent_type` one of 12 specialists:
  `software-architect`, `go-developer`, `java-developer`, `frontend-developer`,
  `go-wasm-developer`, `github-actions-engineer`, `git-expert`, `ux-ui-designer`,
  `test-engineer`, `technical-writer`, `code-reviewer`, `security-reviewer`.
- NEVER invoke Task with `subagent_type` `general`, `explore`, `build`, `plan` — denied in Task permissions; re-route.
- Skill suggesting a general-purpose subagent: substitute the matching specialist; other skill text applies.
- Specialists are leaf workers with no Task access — never ask them to delegate; give complete, self-contained prompts.
- Direct `@mention` by the user always bypasses routing.

Committed specs and plans: compact doc style — caveman ultra + Simplified Technical English. Fragments OK; tables/lists over prose. Keep verbatim: paths, commands, numbers, negations, acceptance criteria. Code blocks unchanged; clarity wins.

## Universal rules (all agents)

KISS; never assume (ask instead); minimal-but-extensible; 2+ replica scalability
(<5s startup, no state lost on crash); no artificial delays; living documentation; best practices.
