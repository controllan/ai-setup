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
touch ~/.config/opencode/.secrets/obsidian-api-key
chmod 600 ~/.config/opencode/.secrets/github-pat ~/.config/opencode/.secrets/obsidian-api-key
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
mkdir -p "$OPENCODE_CONFIG/skills/memory"
cp "$REPO_DIR/skills/memory/SKILL.md" "$OPENCODE_CONFIG/skills/memory/SKILL.md"
```

---

## Step 4b: Install caveman skills (external)

Caveman skills are from [github.com/JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — they must be fetched via the official installer, not copied from this repo:

```bash
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
```

This installs `caveman`, `caveman-commit`, `caveman-review`, and `caveman-stats` skills for all detected agents (OpenCode, Claude Code, etc.). Needs Node ≥18. Safe to re-run.

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

## Step 7: Configure Git user

Check if `user.name` and `user.email` are already set in git config:

```bash
git config --global user.name 2>/dev/null && echo "name: OK" || echo "name: MISSING"
git config --global user.email 2>/dev/null && echo "email: OK" || echo "email: MISSING"
```

**If either is missing, you (the AI) must ask the user interactively:**

1. Ask for their full name (used as `user.name`)
2. Ask for their email address (used as `user.email`)
3. Validate the email matches a basic pattern like `*@*.*` — if not, ask again
4. Write both values:
   ```bash
   git config --global user.name "User's Full Name"
   git config --global user.email "user@example.com"
   ```

> Do not proceed if the email is invalid. Keep asking until a valid email is provided.

---

## Step 8: Install development tools

Check which tools are already installed and install missing ones via Homebrew:

```bash
echo "=== Checking installed tools ==="
for tool in gh kubectl k9s uv go kubectx node; do
  command -v "$tool" &>/dev/null && echo "$tool: OK" || echo "$tool: MISSING"
done
# quarkus needs special handling
command -v quarkus &>/dev/null && echo "quarkus: OK" || echo "quarkus: MISSING (requires JVM)"
# obsidian is a GUI app
[ -d "/Applications/Obsidian.app" ] || command -v obsidian &>/dev/null && echo "obsidian: OK" || echo "obsidian: MISSING"
```

**For each missing tool, the AI must ask the user if they want it installed, then install via brew:**

```bash
brew install <tool>
```

Tool-specific notes:
- **obsidian**: `brew install --cask obsidian`
- **quarkus**: Install via SDKMAN (`curl -s "https://get.sdkman.io" | bash` then `sdk install quarkus`), or use the JBang-based CLI: `brew install jbang` then `jbang --preview quarkus@quarkusio`
- **k9s** and **kubectx**: available via brew, may need `brew tap` first
- **uv**: `brew install uv`

> The AI should install each missing tool one at a time, asking the user for confirmation before each one. Skip any the user declines.

---

## Step 9: Verify installations

Check that everything is in place:

```bash
echo "=== OpenCode ==="
opencode --version

echo "=== Config files ==="
ls "$OPENCODE_CONFIG/opencode.json"

echo "=== Agents ==="
ls "$OPENCODE_CONFIG/agents/"*.md | wc -l

echo "=== Skills ==="
ls "$OPENCODE_CONFIG/skills/caveman/SKILL.md" 2>/dev/null && echo "caveman: OK" || echo "caveman: MISSING (run Step 4b)"
ls "$OPENCODE_CONFIG/skills/superpowers" 2>/dev/null && echo "superpowers symlink: OK" || echo "superpowers symlink: MISSING"

echo "=== Plugin ==="
ls -la "$OPENCODE_CONFIG/plugins/superpowers.js" 2>/dev/null && echo "plugin: OK" || echo "plugin: MISSING"

echo "=== Superpowers repo ==="
ls "$OPENCODE_CONFIG/superpowers/.git" 2>/dev/null && echo "superpowers repo: OK" || echo "superpowers repo: MISSING"

echo "=== Neovim ==="
nvim --version | head -1
ls ~/.config/nvim/init.lua 2>/dev/null && echo "nvim config: OK" || echo "nvim config: MISSING"

echo "=== Brew tools ==="
for tool in gh kubectl k9s uv go kubectx node; do
  command -v "$tool" &>/dev/null && echo "$tool: OK" || echo "$tool: MISSING"
done
```

---

## Step 10: Authenticate GitHub CLI

Check if the user is already authenticated with GitHub CLI:

```bash
gh auth status 2>&1 && echo "gh: authenticated" || echo "gh: not authenticated"
```

**If not authenticated, the AI must:**

1. Run `gh auth login` — this opens an interactive flow that lets the user authenticate via browser or paste a token
2. After login succeeds, save the token to the secrets file:
   ```bash
   gh auth token > ~/.config/opencode/.secrets/github-pat
   chmod 600 ~/.config/opencode/.secrets/github-pat
   ```
3. Verify the token was written correctly:
   ```bash
   head -c 20 ~/.config/opencode/.secrets/github-pat && echo "..."
   ```

> After this step, the GitHub PAT is stored in the secrets file and the GitHub MCP server in opencode will pick it up automatically.

---

## Step 11: Remaining manual steps

Tell the user:

1. **Create an Obsidian API key** — install the Obsidian Local REST API plugin in Obsidian, configure port 27124, generate an API key and paste it into `~/.config/opencode/.secrets/obsidian-api-key`
2. **Restart your terminal** — or run `exec zsh` to apply shell changes
3. **Start OpenCode** — run `opencode` and ask: "do you have superpowers?"

---

## Step 12: Done

Phase 2 complete. The AI stack is installed and ready.
