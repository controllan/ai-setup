---
name: update-ai-setup
description: >
  Use when the user asks to update, upgrade, refresh, reinstall, or sync their
  ai-setup installation — agents, skills, instructions, or config. Trigger
  phrases include "update my ai-setup", "update ai-setup", "refresh my agents",
  "refresh my skills", "sync the AI setup".
---

# Update AI Setup

Refresh an existing ai-setup installation to the repo state. Every step is idempotent — safe to re-run. Assumes `bootstrap.sh` ran at least once.

## Variables

```bash
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/ai-setup")"
```

## Workflow

### 1. Update the repo itself

```bash
cd "$REPO_DIR" && git pull --ff-only
```

No checkout on this machine? Ask where the clone lives; if none, clone it:

```bash
git clone git@github.com:controllan/ai-setup.git ~/ai-setup
```

### 1b. Newer version? (state file decides)

```bash
INSTALLED="$(cat "$OPENCODE_CONFIG/.ai-setup-version" 2>/dev/null || echo "0.0.0")"
REPO_VER="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$REPO_DIR/CHANGELOG.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
[ "$INSTALLED" = "$REPO_VER" ] && echo "already on v$INSTALLED — verify only" || echo "updating v$INSTALLED → v$REPO_VER"
```

Versions match: skip to step 8 (verify-only). Otherwise run steps 2–7; step 8 stamps.

### 2. Merge config (never blind-copy)

Repo wins on defined keys. Live-only keys survive — local providers are never clobbered. Arrays `plugin` and `skills.paths`: repo entries first, then live-only entries, deduped.

```bash
python3 - "$REPO_DIR/opencode/opencode.json" "$OPENCODE_CONFIG/opencode.json" <<'PY'
import json, sys

repo_path, live_path = sys.argv[1], sys.argv[2]
repo = json.load(open(repo_path))
try:
    live = json.load(open(live_path))
except FileNotFoundError:
    live = {}

# Arrays unioned instead of replaced: repo entries first, then live-only entries, deduped.
UNION_PATHS = {("plugin",), ("skills", "paths")}

def merge(repo_val, live_val, path):
    if isinstance(repo_val, dict) and isinstance(live_val, dict):
        out = dict(live_val)
        for key, value in repo_val.items():
            out[key] = merge(value, live_val[key], path + (key,)) if key in live_val else value
        return out
    if isinstance(repo_val, list) and isinstance(live_val, list) and path in UNION_PATHS:
        out = []
        for item in repo_val + live_val:
            if item not in out:
                out.append(item)
        return out
    return repo_val

merged = merge(repo, live, ())
# Belt-and-braces: never lose a live-only provider entry.
lost = [key for key in live.get("provider", {}) if key not in merged.get("provider", {})]
assert not lost, "local providers lost: " + ", ".join(lost)
with open(live_path, "w") as fh:
    fh.write(json.dumps(merged, indent=2, ensure_ascii=False) + "\n")
print("merged " + live_path)
PY
cp "$REPO_DIR/opencode/package.json" "$OPENCODE_CONFIG/package.json"
cd "$OPENCODE_CONFIG" && npm install --no-fund --no-audit
```

### 3. Agents (13 files: orchestrator + 12 specialists, no model pins)

```bash
mkdir -p "$OPENCODE_CONFIG/agents"
cp "$REPO_DIR/agents/"*.md "$OPENCODE_CONFIG/agents/"
```

### 4. Repo skills (8)

```bash
for skill in brainstorming writing-plans visual-companion caveman go-review memory update-ai-setup verifying-github-actions; do
  mkdir -p "$OPENCODE_CONFIG/skills/$skill"
  cp -R "$REPO_DIR/skills/$skill/." "$OPENCODE_CONFIG/skills/$skill/"
done
chmod +x "$OPENCODE_CONFIG/skills/visual-companion/scripts/start-server.sh" \
         "$OPENCODE_CONFIG/skills/visual-companion/scripts/stop-server.sh"
```

### 5. Caveman (installer + overlay + prune)

Pre-remove the overlay first — the installer refuses to overwrite modified user content (ownership digest mismatch):

```bash
rm -rf "$OPENCODE_CONFIG/skills/caveman"
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
```

Overlay the trimmed base skill (the installer ships the full 7 KB version):

```bash
cp "$REPO_DIR/skills/caveman/SKILL.md" "$OPENCODE_CONFIG/skills/caveman/SKILL.md"
```

Prune extras + cavecrew after every installer run. Keep `commands/caveman.md`.

```bash
rm -rf "$OPENCODE_CONFIG/skills/caveman-commit" "$OPENCODE_CONFIG/skills/caveman-review" \
       "$OPENCODE_CONFIG/skills/caveman-compress" "$OPENCODE_CONFIG/skills/caveman-help" \
       "$OPENCODE_CONFIG/skills/caveman-stats" "$OPENCODE_CONFIG/skills/cavecrew"
rm -f "$OPENCODE_CONFIG/commands/caveman-commit.md" "$OPENCODE_CONFIG/commands/caveman-review.md" \
      "$OPENCODE_CONFIG/commands/caveman-compress.md" "$OPENCODE_CONFIG/commands/caveman-help.md" \
      "$OPENCODE_CONFIG/commands/caveman-stats.md"
rm -f "$OPENCODE_CONFIG/agents/cavecrew-builder.md" "$OPENCODE_CONFIG/agents/cavecrew-investigator.md" \
      "$OPENCODE_CONFIG/agents/cavecrew-reviewer.md"
```

Needs Node ≥18. Safe to re-run.

### 6. Remove superpowers artifacts

```bash
rm -rf "$OPENCODE_CONFIG/superpowers" "$OPENCODE_CONFIG/skills/superpowers"
rm -f "$OPENCODE_CONFIG/plugins/superpowers.js"
```

### 7. AGENTS.md routing guardrail

Offer to copy it into the current project — ask first, never overwrite an existing project `AGENTS.md` without confirmation:

```bash
cp "$REPO_DIR/AGENTS.md" /path/to/your/project/AGENTS.md
```

### 8. Verify + stamp

```bash
python3 -m json.tool "$OPENCODE_CONFIG/opencode.json" >/dev/null && echo "config JSON: OK" || echo "config JSON: INVALID"
python3 - "$OPENCODE_CONFIG/opencode.json" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
assert cfg["mcp"]["sonarqube"]["enabled"] is False, "sonarqube must be disabled"
assert cfg["plugin"][:2] == ["./plugins/caveman/plugin.js", "opencode-cmd-provider"], cfg["plugin"]
assert cfg.get("provider"), "provider config empty"
print("config merge: OK")
PY
for skill in brainstorming writing-plans visual-companion caveman go-review memory update-ai-setup verifying-github-actions; do
  [ -f "$OPENCODE_CONFIG/skills/$skill/SKILL.md" ] && echo "$skill: OK" || echo "$skill: MISSING"
done
[ -x "$OPENCODE_CONFIG/skills/visual-companion/scripts/start-server.sh" ] && echo "companion scripts: OK" || echo "companion scripts: MISSING"
[ ! -e "$OPENCODE_CONFIG/superpowers" ] && [ ! -e "$OPENCODE_CONFIG/skills/superpowers" ] && [ ! -e "$OPENCODE_CONFIG/plugins/superpowers.js" ] && echo "superpowers removed: OK" || echo "superpowers artifacts: FOUND"
[ ! -e "$OPENCODE_CONFIG/skills/cavecrew" ] && [ ! -e "$OPENCODE_CONFIG/skills/caveman-commit" ] && echo "prune: OK" || echo "prune: INCOMPLETE"
ls "$OPENCODE_CONFIG/agents/"*.md | wc -l   # expect 13
grep -rn "^model:" "$OPENCODE_CONFIG/agents/" && echo "MODEL PINS: fix" || echo "no model pins: OK"
```

On success, stamp the version:

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

- Ask before overwriting a project's `AGENTS.md` or installing anything the user previously declined.
- Never commit or print secrets (`.secrets/` contents stay private).
- End with a compact OK/MISSING table. Tell the user to restart their opencode session so the new agents, skills, and config take effect.
