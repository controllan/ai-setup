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

Set up secrets directory (for GitHub MCP token):

```bash
mkdir -p ~/.config/opencode/.secrets
chmod 700 ~/.config/opencode/.secrets
touch ~/.config/opencode/.secrets/github-pat
chmod 600 ~/.config/opencode/.secrets/github-pat
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

## Step 6: Install and configure Neovim

Install Neovim via Homebrew and copy the config:

```bash
brew install neovim
mkdir -p ~/.config/nvim
cp "$REPO_DIR/nvim/init.lua" ~/.config/nvim/init.lua
```

Install LSP servers and ensure plugins are set up:

```bash
# Open neovim once to let lazy.nvim install all plugins + LSP servers
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
# Ensure Mason LSP servers are installed
nvim --headless "+MasonInstall gopls html ts_ls jdtls pyright" +qa 2>/dev/null || true
echo "Neovim: OK"
```

> **Note:** The first time you open Neovim, lazy.nvim will download and install all plugins automatically. LSP servers (gopls, html-lsp, ts_ls, jdtls, pyright) will be installed via Mason. This may take a minute.
>
> For Java LSP (jdtls): This is a large download (~200MB). If you don't need Java, you can skip it:
> ```bash
> nvim --headless "+MasonUninstall jdtls" +qa
> ```
> Then remove `"jdtls"` from the `ensure_installed` list in `~/.config/nvim/init.lua`.

Keybindings included in the config:

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files (fzf) |
| `<leader>fg` | Live grep (fzf) |
| `gd` | Go to definition |
| `K` | Hover documentation |
| `gr` | Find references |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `Tab` / `S-Tab` | Cycle autocomplete suggestions |

---

## Step 7: Verify installations

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

echo "=== Neovim ==="
nvim --version | head -1
ls ~/.config/nvim/init.lua 2>/dev/null && echo "nvim config: OK" || echo "nvim config: MISSING"
```

---

## Step 8: Remaining manual steps

Tell the user:

1. **Edit `~/.gitconfig`** — set your name and email
2. **Edit `~/.config/opencode/opencode.json`** — set your Obsidian API key in the MCP config
3. **Create a GitHub PAT** — go to https://github.com/settings/personal-access-tokens/new (fine-grained, with `Contents: RW`, `Pull requests: RW`, `Issues: R`) and paste it into `~/.config/opencode/.secrets/github-pat`
4. **Install Obsidian** — `snap install obsidian` (Linux) or download from obsidian.md
5. **Install Obsidian Local REST API plugin** — configure port 27124, generate an API key
6. **Restart your terminal** — or run `exec zsh` to apply shell changes
7. **Start OpenCode** — run `opencode` and ask: "do you have superpowers?"

---

## Step 9: Done

Phase 2 complete. The AI stack is installed and ready.
