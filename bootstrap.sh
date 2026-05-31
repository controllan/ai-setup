#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Bootstrap: One-liner to clone and install the AI stack
# ============================================================
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<user>/ai-setup/main/bootstrap.sh | bash
# ============================================================

REPO_URL="${REPO_URL:-git@github.com:controllan/ai-setup.git}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/ai-setup}"

if [ -d "$INSTALL_DIR" ]; then
  echo "[INFO] ai-setup already cloned, updating..."
  cd "$INSTALL_DIR"
  git pull --ff-only
else
  echo "[INFO] Cloning ai-setup..."
  git clone "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

bash setup.sh
