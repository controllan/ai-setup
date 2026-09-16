---
name: update-ai-setup
description: >
  Use when the user asks to update, upgrade, refresh, reinstall, or sync their ai-setup
  installation or AI stack — agents, skills, instructions, config, or Superpowers.
  Trigger phrases include "update my ai-setup", "update ai-setup", "refresh my agents",
  "refresh my skills", "sync the AI setup".
---

# Update AI Setup

Refresh an existing ai-setup installation to the latest repo state. Every step is
idempotent — safe to re-run. Assumes Phase 1 (`bootstrap.sh`) has run at least once.

## Variables

```bash
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
```

Derive the repo dir from the current checkout when possible:

```bash
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/ai-setup")"
```

## Workflow

### 1. Update the repo itself

```bash
cd "$REPO_DIR" && git pull --ff-only
```

If `$REPO_DIR` is not a checkout, ask the user where their ai-setup clone lives;
if they have none, clone it:

```bash
git clone git@github.com:controllan/ai-setup.git ~/ai-setup
```

### 1b. Newer version? (state file decides)

```bash
INSTALLED="$(cat "$OPENCODE_CONFIG/.ai-setup-version" 2>/dev/null || echo "0.0.0")"
REPO_VER="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$REPO_DIR/CHANGELOG.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
[ "$INSTALLED" = "$REPO_VER" ] && echo "already on v$INSTALLED — verify only" || echo "updating v$INSTALLED → v$REPO_VER"
```

If the versions match, skip to step 8 (verify-only). Otherwise run steps 2–6,
then step 8 stamps the new version.

### 2. Config files

`opencode.json` carries `default_agent: orchestrator` and the Task allowlists
(only the 12 specialists; `general`/`explore`/`build`/`plan` denied):

```bash
mkdir -p "$OPENCODE_CONFIG"
cp "$REPO_DIR/opencode/opencode.json" "$OPENCODE_CONFIG/opencode.json"
cp "$REPO_DIR/opencode/package.json" "$OPENCODE_CONFIG/package.json"
cd "$OPENCODE_CONFIG" && npm install --no-fund --no-audit
```

### 3. Agents (13 files: orchestrator + 12 specialists, no model pins)

```bash
mkdir -p "$OPENCODE_CONFIG/agents"
cp "$REPO_DIR/agents/"*.md "$OPENCODE_CONFIG/agents/"
```

### 4. Local skills (memory + update-ai-setup)

```bash
mkdir -p "$OPENCODE_CONFIG/skills/memory" "$OPENCODE_CONFIG/skills/update-ai-setup"
cp "$REPO_DIR/skills/memory/SKILL.md" "$OPENCODE_CONFIG/skills/memory/SKILL.md"
cp "$REPO_DIR/skills/update-ai-setup/SKILL.md" "$OPENCODE_CONFIG/skills/update-ai-setup/SKILL.md"
```

### 5. Caveman skills (external, official installer only)

```bash
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
```

Safe to re-run. Needs Node ≥18.

### 6. Superpowers (pull + symlinks)

```bash
if [ ! -d "$OPENCODE_CONFIG/superpowers/.git" ]; then
  rm -rf "$OPENCODE_CONFIG/superpowers" 2>/dev/null
  git clone git@github.com:obra/superpowers.git "$OPENCODE_CONFIG/superpowers"
else
  cd "$OPENCODE_CONFIG/superpowers" && git pull --ff-only
fi
mkdir -p "$OPENCODE_CONFIG/plugins"
ln -sf "$OPENCODE_CONFIG/superpowers/.opencode/plugins/superpowers.js" "$OPENCODE_CONFIG/plugins/superpowers.js"
ln -sfn "$OPENCODE_CONFIG/superpowers/skills" "$OPENCODE_CONFIG/skills/superpowers"
```

### 7. AGENTS.md routing guardrail

Offer to copy it into the current project — ask first, never overwrite an
existing project `AGENTS.md` without confirmation:

```bash
cp "$REPO_DIR/AGENTS.md" /path/to/your/project/AGENTS.md
```

### 8. Verify (same gates as INSTALL.md Step 9)

```bash
grep -q '"default_agent": "orchestrator"' "$OPENCODE_CONFIG/opencode.json" && echo "default_agent: OK" || echo "default_agent: MISSING"
grep -q '"general": "deny"' "$OPENCODE_CONFIG/opencode.json" && echo "general denied: OK" || echo "general denied: MISSING"
ls "$OPENCODE_CONFIG/agents/"*.md | wc -l
grep -rn "^model:" "$OPENCODE_CONFIG/agents/" && echo "MODEL PINS: fix" || echo "no model pins: OK"
ls "$OPENCODE_CONFIG/skills/update-ai-setup/SKILL.md" 2>/dev/null && echo "updater skill: OK" || echo "updater skill: MISSING"
ls "$OPENCODE_CONFIG/skills/caveman/SKILL.md" 2>/dev/null && echo "caveman: OK" || echo "caveman: MISSING"
ls "$OPENCODE_CONFIG/skills/superpowers" 2>/dev/null && echo "superpowers: OK" || echo "superpowers: MISSING"
ls -la "$OPENCODE_CONFIG/plugins/superpowers.js" 2>/dev/null && echo "plugin: OK" || echo "plugin: MISSING"
```

On a successful sync, stamp the installed version:

```bash
echo "$REPO_VER" > "$OPENCODE_CONFIG/.ai-setup-version"
```

## Releasing a new version (maintainer — inside the ai-setup repo)

Every finished feature branch that changes the stack ends with a release:

1. **Determine the bump** from conventional commits since the last tag:
   ```bash
   git fetch --tags
   git log "$(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)"..HEAD --pretty=format:'%s'
   ```
   `feat!`/`BREAKING CHANGE` → major, `feat` → minor, anything else → patch.
2. **CHANGELOG.md**: move the `## [Unreleased]` entries under a new
   `## [X.Y.Z] - YYYY-MM-DD` heading; leave a fresh empty `## [Unreleased]`
   on top.
3. **Commit, tag, push**: `docs: release vX.Y.Z`, then
   `git tag vX.Y.Z && git push --follow-tags`.
4. **GitHub release** (needs `gh auth status` green — see INSTALL.md Step 10):
   ```bash
   gh release create "vX.Y.Z" --title "vX.Y.Z" --notes "See CHANGELOG.md"
   ```

Users pick the release up automatically next time they say "update my ai-setup".

## Rules

- Ask before overwriting a project's `AGENTS.md` or installing anything the
  user previously declined.
- Never commit or print secrets (`.secrets/` contents stay private).
- End with a compact OK/MISSING table. Tell the user to restart their opencode
  session so the new agents and config take effect.
