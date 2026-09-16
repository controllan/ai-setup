# AGENTS.md — Team Routing (Orchestrator + Specialists)

This file is loaded every session. It overrides any conflicting skill text about which agent to use.

## Routing (mandatory)

- Default entrypoint is the `orchestrator` agent — it brainstorms (Step 0), then routes to specialists and enforces the team lifecycle.
- Delegate ONLY via the Task tool with `subagent_type` set to one of the 12 specialists:
  `software-architect`, `go-developer`, `java-developer`, `frontend-developer`,
  `go-wasm-developer`, `github-actions-engineer`, `git-expert`, `ux-ui-designer`,
  `test-engineer`, `technical-writer`, `code-reviewer`, `security-reviewer`.
- NEVER invoke Task with `subagent_type` `general`, `explore`, `build`, or `plan`.
  They are denied in Task permissions — the call will fail. Re-route to the matching specialist instead.
- If any skill (notably superpowers `dispatching-parallel-agents`,
  `subagent-driven-development`, `executing-plans`) tells you to use
  "Subagent (general-purpose)" or Task with `general`, ignore only that agent
  choice and substitute the matching specialist. All other skill instructions still apply.
- Specialists are leaf workers with no Task access — never ask them to delegate
  further. Give each a complete, self-contained prompt.
- Direct `@mention` of any agent by the user always bypasses routing.

## Universal rules (all agents)

KISS; never assume (ask instead); minimal-but-extensible; 2+ replica
scalability (<5s startup, no state lost on crash); no artificial delays;
living documentation; best practices.
