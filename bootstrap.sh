#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Phase 1: Bootstrap — install prerequisites
#   • Homebrew, zsh, opencode, shell config
# Phase 2: Let OpenCode handle the rest
#   • opencode → "fetch and follow https://raw.githubusercontent.com/controllan/ai-setup/main/INSTALL.md"
# ============================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { printf "${GREEN}[INFO]${NC}  %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }

INFO_FILE="$REPO_DIR/INSTALL.md"

step_brew() {
  info "Checking Homebrew..."
  if command -v brew &>/dev/null; then
    info "brew already installed at $(command -v brew)"
    return
  fi
  warn "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  info "brew: OK"
}

step_zsh() {
  info "Checking zsh..."
  if command -v zsh &>/dev/null; then
    info "zsh already installed"
    return
  fi
  warn "zsh not found. Installing..."
  if command -v apt-get &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq zsh
  elif command -v brew &>/dev/null; then
    brew install zsh
  else
    error "Cannot install zsh — install it manually, then re-run this script"
    exit 1
  fi
  info "zsh: OK"
}

step_opencode() {
  info "Checking OpenCode..."
  if command -v opencode &>/dev/null; then
    info "opencode already installed at $(command -v opencode)"
    return
  fi
  warn "opencode not found. Installing via Homebrew..."
  brew install opencode
  info "opencode: OK ($(opencode --version))"
}

step_shell_config() {
  info "Setting up shell config..."
  mkdir -p "$HOME"

  # .zshrc — back up existing, copy new
  if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
    warn "backed up existing .zshrc"
  fi
  cp "$REPO_DIR/shell/.zshrc" "$HOME/.zshrc"

  # .p10k.zsh
  [ -f "$REPO_DIR/shell/.p10k.zsh" ] && cp "$REPO_DIR/shell/.p10k.zsh" "$HOME/.p10k.zsh"

  # .gitconfig — only if none exists
  if [ ! -f "$HOME/.gitconfig" ]; then
    cp "$REPO_DIR/shell/.gitconfig" "$HOME/.gitconfig"
    info ".gitconfig created — edit it to set your name/email"
  else
    warn ".gitconfig exists, skipping"
  fi
  info "shell config: OK"
}

step_zsh_plugins() {
  info "Checking zsh plugins..."

  # Oh My Zsh
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    info "oh-my-zsh: OK"
  else
    info "oh-my-zsh: already installed"
  fi

  # Powerlevel10k
  P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  if [ ! -d "$P10K_DIR" ]; then
    warn "powerlevel10k not found. Installing..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    info "powerlevel10k: OK"
  else
    info "powerlevel10k: already installed"
  fi

  # zsh-autosuggestions
  ZSUGGEST_DIR="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  if [ ! -d "$ZSUGGEST_DIR" ]; then
    warn "zsh-autosuggestions not found. Installing..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSUGGEST_DIR"
    info "zsh-autosuggestions: OK"
  else
    info "zsh-autosuggestions: already installed"
  fi

  # zsh-syntax-highlighting
  ZSH_HL_DIR="$HOME/zsh-syntax-highlighting"
  if [ ! -d "$ZSH_HL_DIR" ]; then
    warn "zsh-syntax-highlighting not found. Installing..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_HL_DIR"
    info "zsh-syntax-highlighting: OK"
  else
    info "zsh-syntax-highlighting: already installed"
  fi
}

step_set_shell() {
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    warn "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)" 2>/dev/null || warn "Could not change shell (chsh failed — try manually: chsh -s $(command -v zsh))"
  fi
  info "default shell: zsh"
}

step_print_next() {
  echo ""
  info "=========================================="
  info "  Phase 1 Complete!"
  info "=========================================="
  echo ""
  echo "  What's installed:"
  echo "    • Homebrew"
  echo "    • zsh + oh-my-zsh + powerlevel10k"
  echo "    • zsh-autosuggestions + zsh-syntax-highlighting"
  echo "    • OpenCode $(opencode --version 2>/dev/null || echo '?')"
  echo "    • Shell config (.zshrc, .p10k.zsh, .gitconfig)"
  echo ""
  echo "  Next step — Phase 2 (let OpenCode do the rest):"
  echo ""
  echo "  1. Start opencode:"
  echo "       opencode"
  echo ""
  echo "  2. Paste this command:"
  echo "       fetch and follow instructions from https://raw.githubusercontent.com/controllan/ai-setup/main/INSTALL.md"
  echo ""
  echo "  OpenCode will read INSTALL.md and execute every step:"
  echo "    • Copy opencode config"
  echo "    • Install agents and skills"
  echo "    • Clone + configure Superpowers"
  echo "    • Set up MCP Obsidian"
  echo "    • Verify everything"
  echo ""
  echo "  Manual steps remaining after Phase 2:"
  echo "    • Edit ~/.gitconfig — set your name and email"
  echo "    • Edit ~/.config/opencode/opencode.json — set your Obsidian API key"
  echo "    • Restart your terminal (or exec zsh) to apply shell changes"
  echo ""
}

main() {
  echo ""
  info "=== AI Setup — Phase 1: Prerequisites ==="
  echo ""

  step_brew
  step_zsh
  step_opencode
  step_shell_config
  step_zsh_plugins
  step_set_shell
  step_print_next
}

main "$@"
