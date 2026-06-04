# AI Setup

Complete AI development environment — **OpenCode + Superpowers + Caveman + Agents + MCP**.
Fully reproducible via a two-phase installation.

## What's Inside

| Component | Description | Source |
|-----------|-------------|--------|
| **OpenCode** | AI coding agent for the terminal | Homebrew |
| **Superpowers** | 14 composable dev workflow skills | [obra/superpowers](https://github.com/obra/superpowers) |
| **Caveman** | Token compression (cuts ~75% output) | Local skill |
| **Memory** | Persistent agent memory via Obsidian | Local skill |
| **20 Agents** | Specialized subagents (backend, frontend, security, etc.) | Custom |
| **MCP** | Obsidian integration for note/memory access | uvx mcp-obsidian |

## Installation (Two Phases)

### Phase 1: Prerequisites (bash)

One-liner — installs brew, zsh, opencode, shell config, oh-my-zsh, plugins:

```bash
curl -fsSL https://raw.githubusercontent.com/controllan/ai-setup/main/bootstrap.sh | bash
```

Or if you already cloned the repo:

```bash
cd ~/ai-setup && bash bootstrap.sh
```

**What Phase 1 installs:**
- Homebrew + Homebrew packages (from `tools/Brewfile`)
- zsh + oh-my-zsh + powerlevel10k theme
- zsh-autosuggestions + zsh-syntax-highlighting
- OpenCode (latest from Homebrew)
- Shell config (`.zshrc`, `.p10k.zsh`, `.gitconfig`)

### Phase 2: The AI Stack (OpenCode-driven)

Start OpenCode and paste this command:

```
fetch and follow instructions from https://raw.githubusercontent.com/controllan/ai-setup/main/INSTALL.md
```

OpenCode will read `INSTALL.md` and execute every step automatically, handling errors as they come:

| Step | What happens |
|------|-------------|
| 1 | Clone/update this repo |
| 2 | Copy `opencode.json`, `package.json` → `~/.config/opencode/`, run `npm install` |
| 3 | Copy 20 agent files → `~/.config/opencode/agents/` |
| 4 | Copy personal skills (caveman, memory) → `~/.config/opencode/skills/` |
| 5 | Clone `obra/superpowers`, create plugin + skills symlinks |
| 6 | Verify everything is in place |
| 7 | Print remaining manual steps |

### After Phase 2

1. **Edit `~/.gitconfig`** — set your name and email
2. **Edit `~/.config/opencode/opencode.json`** — set your [Obsidian API key](mcp/obsidian-setup.md)
3. **Restart your terminal** — or run `exec zsh`
4. **Start OpenCode** — run `opencode` and ask: "do you have superpowers?"

## Directory Layout

```
~/.config/opencode/
├── opencode.json           # Main config (MCP, agents)
├── package.json            # Plugin deps
├── agents/                 # 20 subagent definitions
├── skills/                 # Skills directory
│   ├── superpowers/        # → symlink → superpowers/skills (14 skills)
│   ├── caveman/
│   ├── caveman-commit/
│   ├── caveman-review/
│   └── memory/
├── plugins/
│   └── superpowers.js      # → symlink → superpowers/.opencode/plugins/superpowers.js
└── superpowers/            # Cloned from obra/superpowers
```

## Manual Installation

If you prefer step-by-step, follow [`INSTALL.md`](INSTALL.md) directly.

## Updating

```bash
# This repo
cd ~/ai-setup && git pull && bash bootstrap.sh

# Superpowers
cd ~/.config/opencode/superpowers && git pull
```

## Troubleshooting

### "I don't have superpowers" — plugin not loading

```bash
ls -la ~/.config/opencode/plugins/superpowers.js  # Should be a symlink
ls ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js  # Must exist
```

### Skills not found

```bash
ls -la ~/.config/opencode/skills/superpowers  # Should be a symlink
# Should point to: ~/.config/opencode/superpowers/skills
```

### npm install failures

```bash
cd ~/.config/opencode && npm install --no-fund --no-audit
```
