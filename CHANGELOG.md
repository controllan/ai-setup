# Changelog

All notable changes to this project are documented here. Versioning follows
SemVer (`feat!`/`BREAKING CHANGE` → major, `feat` → minor, else patch —
determined from conventional commits since the previous tag). Each finished
feature branch ends with a dated entry below plus a `vX.Y.Z` tag and GitHub
release. The updater skill (`skills/update-ai-setup`) syncs local installs to
the newest version listed here.

## [Unreleased]

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
