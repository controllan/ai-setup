# Pi Dual-Harness Support — Design

**Date:** 2026-10-04 · **Status:** draft, awaiting user review
**Goal:** add Pi (`pi-coding-agent`) as second harness beside OpenCode. Shared config lives in repo `pi/`; updater + INSTALL sync it. Same team: 12 specialists, caveman, permission policy.

## Decisions

1. **Repo structure:** new `pi/` directory = source of truth for shared Pi config:
   - `pi/models.json` — `commandcode` provider only (81 models). Local providers stay machine-local.
   - `pi/settings.json` — `packages` + defaults.
   - `pi/AGENTS.md` — caveman block + Pi orchestrator routing/lifecycle.
   - `pi/agents/*.md` — 12 specialists.
   - `pi/extensions/pi-permission-system/config.json` — permission policy.
2. **Updater:** new step in `skills/update-ai-setup/SKILL.md`: ensure Pi installed, sync `~/.pi/agent`.
3. **INSTALL.md:** new "Step 5b: Pi (dual harness)" after caveman/superpowers steps; update Step 9 verify + Step 11 notes.
4. **README.md:** components table + dual-harness section + directory tree + Pi troubleshooting.
5. **CHANGELOG 0.3.0** (`feat`) after implementation; release tag flow unchanged.
6. **Maintenance:** 81-model list = snapshot from commandcode plugin catalog. Regeneration manual; procedure documented (see below).

## Live state (validated spike)

| Item | Value |
|---|---|
| Pi | `brew install pi-coding-agent`, 0.87.1 |
| Provider `commandcode` | baseUrl `https://api.commandcode.ai/provider/v1`, api `openai-completions`, 81 models |
| apiKey | `!python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.local/share/opencode/auth.json')))['commandcode']['key'])"` |
| Model enrichment | reasoning/thinkingLevelMap/compat/contextWindow/maxTokens/input/cost inherited from Pi bundled catalogs |
| Defaults | `defaultProvider: commandcode`, `defaultModel: deepseek/deepseek-v4.1-flash` |
| Machine-local providers | `ollama` (2), `omlx` (9), `mtplx` (1), `mlx-lm` (1) — never committed |
| Packages | `npm:@narumitw/pi-plan-mode`, `npm:@juicesharp/rpiv-todo`, `npm:@gotgenes/pi-permission-system`, `npm:@tintinweb/pi-subagents`; `pi-web-access` dropped |
| Agents | 12 specialists in `~/.pi/agent/agents/*.md`; frontmatter `name`, `description`, `tools`; no model pins (all inherit session model); `code-reviewer` + `security-reviewer` read-only |
| Skills | `~/.pi/agent/skills` symlink → `~/.config/opencode/skills` |
| Permission config | reads anywhere silent; writes outside cwd ask; secrets deny; destructive bash deny/ask |

Smoke results: `pi -p` answers on default model; `software-architect` subagent delegation works; `--thinking high` works; `pi --list-models` shows 81 commandcode models.

## Updater step (new)

Variables:

```bash
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
```

Order:

1. **Ensure Pi installed.**
   ```bash
   command -v pi >/dev/null || brew install pi-coding-agent
   brew outdated pi-coding-agent >/dev/null 2>&1 && brew upgrade pi-coding-agent || true
   ```
2. **Merge `pi/models.json` into live `models.json`.** Deep-merge like `opencode.json`: repo wins defined keys; live-only provider keys preserved; `python3` stdlib. Result: `commandcode` from repo (81 models); `ollama`, `omlx`, `mtplx`, `mlx-lm` untouched. Assert: no live-only provider lost.
3. **Merge `pi/settings.json`.** Repo wins; `packages` array unioned (repo entries first, then live-only, deduped) so local packages survive; live-only keys (`theme`, `lastChangelogVersion`) preserved.
4. **Copy files (repo wins).**
   - `pi/AGENTS.md` → `$PI_AGENT_DIR/AGENTS.md`
   - `pi/agents/*.md` → `$PI_AGENT_DIR/agents/` (12 files)
   - `pi/extensions/pi-permission-system/config.json` → `$PI_AGENT_DIR/extensions/pi-permission-system/config.json`
5. **Symlink skills.** `$OPENCODE_CONFIG/skills` is the only skills source. Real dir → warn + skip (never delete user data); symlink → replace:
   ```bash
   if [ -d "$PI_AGENT_DIR/skills" ] && [ ! -L "$PI_AGENT_DIR/skills" ]; then
     echo "WARN: skills is a real dir — skipping symlink"
   else
     rm -f "$PI_AGENT_DIR/skills" && ln -sfn "$OPENCODE_CONFIG/skills" "$PI_AGENT_DIR/skills"
   fi
   ```
6. **Ensure packages.** Check `pi list`; install missing:
   ```bash
   for pkg in @narumitw/pi-plan-mode @juicesharp/rpiv-todo @gotgenes/pi-permission-system @tintinweb/pi-subagents; do
     pi list | grep -q "npm:$pkg" || pi install "npm:$pkg"
   done
   ```
7. **Verify** (below).

## INSTALL.md

**Step 5b: Pi (dual harness)** — after Step 5 (superpowers removal). Mirror updater: install Pi, merge `models.json` + `settings.json`, copy `AGENTS.md` / 12 agents / permission config, symlink skills, install 4 packages. Same merge rules, same verification.

**Step 9 verify** — add Pi block: `pi --version`; JSON valid; 81 commandcode models; 12 agents; skills symlink correct; 4 packages in `pi list`; optional `pi -p "reply OK"` smoke.

**Step 11 notes** — add: Pi reads `~/.pi/agent` at start; restart Pi after update; `pi` shares `~/.config/opencode/skills` via symlink.

## README.md

- Components table: add **Pi** row (second harness, same team/config).
- Dual-harness section: OpenCode + Pi share agents, skills, caveman, permission principles; `pi/` = Pi config source; local providers machine-local.
- Directory tree: add `pi/` layout (models.json, settings.json, AGENTS.md, agents/, extensions/).
- Pi troubleshooting: missing `pi` binary; fewer than 81 models; subagent delegation fails; skills symlink broken.

## Maintenance: 81-model snapshot regeneration

Manual. Pi bundled catalogs refresh via `pi update`; repo `pi/models.json` does not.

1. Extract `MODEL_DEALS` keys from:
   `~/.cache/opencode/packages/opencode-cmd-provider@latest/node_modules/opencode-cmd-provider/dist/src/deals/catalog.js`
2. Enrich `reasoning`/`thinkingLevelMap`/`compat`/`contextWindow`/`maxTokens`/`input`/`cost` from Pi bundled catalogs.
3. Write `pi/models.json` with `commandcode` only. Preserve `apiKey` command exact (see table).
4. Verify 81 models, valid JSON.

## Verification

- Repo: `pi/models.json` valid JSON, 81 commandcode models, one provider only; `pi/settings.json` has 4 packages + commandcode defaults; 12 agent files; `pi/AGENTS.md` has caveman block + routing table; permission config matches live policy.
- Updater: idempotent re-run changes nothing; local providers survive merge; live-only settings keys survive; skills symlink resolves to `$OPENCODE_CONFIG/skills`.
- Live: `pi list` shows 4 packages; `pi --list-models` shows 81 commandcode models; 12 agents load; optional headless smoke `pi -p "reply OK"` answers on default model.
- INSTALL + README checklists match updater steps.

## Out of scope

- Local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) in repo.
- Per-agent model pins.
- `pi-web-access` package.
- OpenCode config/agent changes.
