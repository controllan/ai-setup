# Changelog

All notable changes to this project are documented here. Versioning follows
SemVer (`feat!`/`BREAKING CHANGE` → major, `feat` → minor, else patch —
determined from conventional commits since the previous tag). Each finished
feature branch ends with a dated entry below plus a `vX.Y.Z` tag and GitHub
release. The updater skill (`skills/update-ai-setup`) syncs local installs to
the newest version listed here.

## [Unreleased]

## [0.3.0] - 2026-10-04

### Added

- Pi (`pi-coding-agent`) as second harness: shared config snapshot in `pi/`
  (models.json, settings.json, AGENTS.md, 12 agents, permission policy).
- 81 `commandcode` models (defaults `commandcode` /
  `deepseek/deepseek-v4.1-flash`); Pi packages: pi-plan-mode, rpiv-todo,
  pi-permission-system, pi-subagents.
- Updater + INSTALL.md sync Pi: install, deep-merge models/settings, copy
  agents/AGENTS.md/permission config, symlink skills, ensure packages.

### Changed

- `memory` skill is trigger-only: no session-start auto-load. Read/write happens
  only when the user refers to memory ("remember", "check memory", …).
- Pi local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) and local settings
  keys stay machine-local; the repo never stores them.

## [0.2.0] - 2026-09-28

### Breaking

- Superpowers removed: clone, skills symlink, plugin symlink. `brainstorming`,
  `writing-plans`, `visual-companion` are vendored + adapted instead (compact
  doc style, explicit spec/plan user approval gates).
- Caveman extras pruned: `caveman-commit`, `caveman-review`, `caveman-compress`,
  `caveman-help`, `caveman-stats` skills + commands; cavecrew skill + 3 agents.
  `/caveman` command and the trimmed base skill stay.
- SonarQube MCP is opt-in: committed `"enabled": false`; enable per project via
  project `opencode.json`.
- Docs moved: `docs/superpowers/{specs,plans}` → `docs/specs`, `docs/plans`.

### Added

- Updater deep-merges `opencode.json`: repo wins, live-only provider keys
  survive, `plugin` and `skills.paths` arrays unioned.
- Repo config lists plugins `./plugins/caveman/plugin.js` and
  `opencode-cmd-provider`.
- Compact doc style for committed specs/plans (caveman ultra + Simplified
  Technical English).

### Changed

- Agent prompts and `AGENTS.md` compacted; orchestrator gained explicit spec and
  plan user-approval gates (technical-writer authors both).
- `go-review` skill compacted (content preserved); live copy kept in sync.

## [0.1.0] - 2026-09-16

Initial versioned release of the AI stack.

### Added

- 13 OpenCode agents: `orchestrator` primary entrypoint + 12 specialist
  subagents (architect, go/java/frontend/wasm developers, actions engineer,
  git-expert, ux-ui-designer, test-engineer, technical-writer, code + security
  reviewers). All inherit the session model (no per-agent pins).
- Orchestrator team lifecycle: brainstorm (superpowers skill when installed,
  ask-to-confirm, never guess) → architect/ux gates → technical-writer plan →
  per-logical-part loop (implement + e2e test → review → git-expert commit)
  → security review per finished feature/component/phase.
- `AGENTS.md` routing guardrail: Task-tool delegation to specialists only;
  `general`/`explore`/`build`/`plan` denied via `opencode.json` Task
  allowlists; `default_agent: orchestrator`; specialists are leaf workers.
- Updater skill: "update my ai-setup" refreshes the local install to the repo
  version, tracked in `~/.config/opencode/.ai-setup-version`.
- Rules: tests live in the project folder (never temp dirs); pnpm-first
  frontend toolchain; KISS / 2+ replica / no-artificial-delays standards.
