#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ai-setup — Full AI Stack Installer
# ============================================================
# Installs: OpenCode + Superpowers + Caveman + Agents + MCP
# Idempotent: safe to re-run
# ============================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { printf "${GREEN}[INFO]${NC}  %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }

# --- Prerequisites -------------------------------------------------------
step_prereqs() {
  info "Checking prerequisites..."

  # Git
  if ! command -v git &>/dev/null; then
    error "git is required. Install it first."
    exit 1
  fi
  info "git: OK"

  # Homebrew
  if ! command -v brew &>/dev/null; then
    warn "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  info "brew: OK"

  # OpenCode + tools via Brewfile
  if [ -f "$REPO_DIR/tools/Brewfile" ]; then
    info "Installing Homebrew packages from Brewfile..."
    brew bundle --file="$REPO_DIR/tools/Brewfile" --no-lock || warn "Some brew formulas may already be installed (this is fine)"
  fi
  info "brew bundle: OK"
}

# --- Shell Config --------------------------------------------------------
step_shell() {
  info "Setting up shell config..."

  mkdir -p "$HOME"

  if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
    warn "Backed up existing .zshrc"
  fi
  cp "$REPO_DIR/shell/.zshrc" "$HOME/.zshrc"
  info ".zshrc: OK"

  if [ -f "$REPO_DIR/shell/.p10k.zsh" ]; then
    cp "$REPO_DIR/shell/.p10k.zsh" "$HOME/.p10k.zsh"
    info ".p10k.zsh: OK"
  fi

  if [ -f "$REPO_DIR/shell/.gitconfig" ]; then
    if [ ! -f "$HOME/.gitconfig" ]; then
      cp "$REPO_DIR/shell/.gitconfig" "$HOME/.gitconfig"
      info ".gitconfig: OK (edit ~/.gitconfig to set your name/email)"
    else
      warn "~/.gitconfig already exists, skipping (merge manually if needed)"
    fi
  fi
}

# --- OpenCode Config -----------------------------------------------------
step_opencode_config() {
  info "Setting up OpenCode config..."

  OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
  mkdir -p "$OPENCODE_CONFIG"

  # Core config files
  cp "$REPO_DIR/opencode/opencode.json" "$OPENCODE_CONFIG/opencode.json"
  cp "$REPO_DIR/opencode/package.json" "$OPENCODE_CONFIG/package.json"

  # npm dependencies
  if command -v npm &>/dev/null; then
    cd "$OPENCODE_CONFIG"
    npm install --no-fund --no-audit 2>/dev/null || warn "npm install had issues (may affect plugin loading)"
    cd "$REPO_DIR"
  fi
  info "opencode config: OK"
}

# --- Agents --------------------------------------------------------------
step_agents() {
  info "Installing agents..."

  OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
  mkdir -p "$OPENCODE_CONFIG/agents"

  for agent_file in "$REPO_DIR/agents/"*.md; do
    [ -f "$agent_file" ] || continue
    cp "$agent_file" "$OPENCODE_CONFIG/agents/"
  done
  info "agents ($(ls -1 "$REPO_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')): OK"
}

# --- Personal Skills -----------------------------------------------------
step_skills() {
  info "Installing personal skills..."

  OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
  SKILLS_DIR="$OPENCODE_CONFIG/skills"

  # Caveman skills
  for skill in caveman caveman-commit caveman-review; do
    if [ -f "$REPO_DIR/skills/$skill/SKILL.md" ]; then
      mkdir -p "$SKILLS_DIR/$skill"
      cp "$REPO_DIR/skills/$skill/SKILL.md" "$SKILLS_DIR/$skill/SKILL.md"
    fi
  done

  # Memory skill
  if [ -f "$REPO_DIR/skills/memory/SKILL.md" ]; then
    mkdir -p "$SKILLS_DIR/memory"
    cp "$REPO_DIR/skills/memory/SKILL.md" "$SKILLS_DIR/memory/SKILL.md"
  fi
  info "personal skills: OK"
}

# --- Superpowers ---------------------------------------------------------
step_superpowers() {
  info "Setting up Superpowers..."

  OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"

  # Clone superpowers if not present
  if [ ! -d "$OPENCODE_CONFIG/superpowers/.git" ]; then
    if [ -d "$OPENCODE_CONFIG/superpowers" ]; then
      warn "superpowers directory exists but is not a git repo, removing..."
      rm -rf "$OPENCODE_CONFIG/superpowers"
    fi
    info "Cloning obra/superpowers..."
    git clone git@github.com:obra/superpowers.git "$OPENCODE_CONFIG/superpowers"
  else
    info "Superpowers already cloned, updating..."
    cd "$OPENCODE_CONFIG/superpowers"
    git pull --ff-only
    cd "$REPO_DIR"
  fi
  info "superpowers repo: OK"

  # Plugin symlink
  mkdir -p "$OPENCODE_CONFIG/plugins"
  PLUGIN_SRC="$OPENCODE_CONFIG/superpowers/.opencode/plugins/superpowers.js"
  PLUGIN_DST="$OPENCODE_CONFIG/plugins/superpowers.js"
  if [ -f "$PLUGIN_SRC" ]; then
    ln -sf "$PLUGIN_SRC" "$PLUGIN_DST"
    info "plugin symlink: OK"
  else
    warn "Plugin source not found at $PLUGIN_SRC"
  fi

  # Skills symlink
  SKILLS_SRC="$OPENCODE_CONFIG/superpowers/skills"
  SKILLS_DST="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/skills/superpowers"
  if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$(dirname "$SKILLS_DST")"
    ln -sfn "$SKILLS_SRC" "$SKILLS_DST"
    info "skills symlink: OK"
  else
    warn "Skills source not found at $SKILLS_SRC"
  fi
}

# --- Post-install Info ---------------------------------------------------
step_post_install() {
  echo ""
  info "=========================================="
  info "  AI Stack Installation Complete!"
  info "=========================================="
  echo ""
  echo "  What's installed:"
  echo "    • OpenCode $(opencode --version 2>/dev/null || echo '?')"
  echo "    • Superpowers (obra/superpowers)"
  echo "    • Caveman skills (caveman, caveman-commit, caveman-review)"
  echo "    • Memory skill"
  echo "    • $(ls -1 "$REPO_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ') agent definitions"
  echo ""
  echo "  Manual steps remaining:"
  echo "    1. Edit ~/.gitconfig — set your name and email"
  echo "    2. Edit ~/.config/opencode/opencode.json — set your MCP Obsidian API key"
  echo "    3. Install Oh-My-Zsh if missing:"
  echo "       sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  echo "    4. Install Powerlevel10k theme:"
  echo "       git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k"
  echo "    5. Install zsh-autosuggestions:"
  echo "       git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  echo "    6. Install zsh-syntax-highlighting:"
  echo "       git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/zsh-syntax-highlighting"
  echo "    7. Restart OpenCode to activate Superpowers plugin"
  echo ""
  echo "  Verify:"
  echo "    Ask OpenCode: 'do you have superpowers?'"
  echo "    It should mention having Superpowers loaded."
  echo ""
}

# --- Main ----------------------------------------------------------------
main() {
  echo ""
  info "=== AI Setup Installer ==="
  echo ""

  step_prereqs
  step_shell
  step_opencode_config
  step_agents
  step_skills
  step_superpowers
  step_post_install
}

main "$@"
