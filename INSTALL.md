# AI Setup — Phase 2 Instructions

Follow these steps to complete the AI stack installation.
Read each step, execute it, then move to the next.

**Prerequisite:** Phase 1 (bootstrap.sh) must have completed — Homebrew, zsh, opencode must be installed.

---

## Step 1: Clone this repo (if not already cloned)

```bash
cd ~ && git clone git@github.com:controllan/ai-setup.git ~/ai-setup 2>/dev/null || (cd ~/ai-setup && git pull --ff-only)
```

Set REPO_DIR for subsequent steps:

```bash
REPO_DIR="$HOME/ai-setup"
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
```

---

## Step 2: Set up OpenCode config

Copy the main config files:

```bash
mkdir -p "$OPENCODE_CONFIG"
cp "$REPO_DIR/opencode/opencode.json" "$OPENCODE_CONFIG/opencode.json"
cp "$REPO_DIR/opencode/package.json" "$OPENCODE_CONFIG/package.json"
```

Install npm dependencies:

```bash
cd "$OPENCODE_CONFIG" && npm install --no-fund --no-audit
```

---

## Step 3: Install agents

```bash
mkdir -p "$OPENCODE_CONFIG/agents"
cp "$REPO_DIR/agents/"*.md "$OPENCODE_CONFIG/agents/"
```

---

## Step 4: Install personal skills

```bash
for skill in caveman caveman-commit caveman-review memory; do
  if [ -f "$REPO_DIR/skills/$skill/SKILL.md" ]; then
    mkdir -p "$OPENCODE_CONFIG/skills/$skill"
    cp "$REPO_DIR/skills/$skill/SKILL.md" "$OPENCODE_CONFIG/skills/$skill/SKILL.md"
  fi
done
```

---

## Step 5: Clone and configure Superpowers

Clone the repo:

```bash
if [ ! -d "$OPENCODE_CONFIG/superpowers/.git" ]; then
  rm -rf "$OPENCODE_CONFIG/superpowers" 2>/dev/null
  git clone git@github.com:obra/superpowers.git "$OPENCODE_CONFIG/superpowers"
else
  cd "$OPENCODE_CONFIG/superpowers" && git pull --ff-only
fi
```

Create plugin symlink:

```bash
mkdir -p "$OPENCODE_CONFIG/plugins"
ln -sf "$OPENCODE_CONFIG/superpowers/.opencode/plugins/superpowers.js" "$OPENCODE_CONFIG/plugins/superpowers.js"
```

Create skills symlink:

```bash
ln -sfn "$OPENCODE_CONFIG/superpowers/skills" "$OPENCODE_CONFIG/skills/superpowers"
```

---

## Step 6: Verify installations

Check that everything is in place:

```bash
echo "=== OpenCode ==="
opencode --version

echo "=== Config files ==="
ls "$OPENCODE_CONFIG/opencode.json"

echo "=== Agents ==="
ls "$OPENCODE_CONFIG/agents/"*.md | wc -l

echo "=== Skills ==="
ls "$OPENCODE_CONFIG/skills/caveman/SKILL.md" 2>/dev/null && echo "caveman: OK" || echo "caveman: MISSING"
ls "$OPENCODE_CONFIG/skills/superpowers" 2>/dev/null && echo "superpowers symlink: OK" || echo "superpowers symlink: MISSING"

echo "=== Plugin ==="
ls -la "$OPENCODE_CONFIG/plugins/superpowers.js" 2>/dev/null && echo "plugin: OK" || echo "plugin: MISSING"

echo "=== Superpowers repo ==="
ls "$OPENCODE_CONFIG/superpowers/.git" 2>/dev/null && echo "superpowers repo: OK" || echo "superpowers repo: MISSING"
```

---

## Step 7: Remaining manual steps

Tell the user:

1. **Edit `~/.gitconfig`** — set your name and email
2. **Edit `~/.config/opencode/opencode.json`** — set your Obsidian API key in the MCP config
3. **Install Obsidian** — `snap install obsidian` (Linux) or download from obsidian.md
4. **Install Obsidian Local REST API plugin** — configure port 27124, generate an API key
5. **Restart your terminal** — or run `exec zsh` to apply shell changes
6. **Start OpenCode** — run `opencode` and ask: "do you have superpowers?"

---

## Step 8: Done

Phase 2 complete. The AI stack is installed and ready.
