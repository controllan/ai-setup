# AI Setup

Your complete AI development environment — OpenCode + Superpowers + Caveman + Agents + MCP, fully reproducible.

## What's Inside

| Component | Description | Source |
|-----------|-------------|--------|
| **OpenCode** | AI coding agent for the terminal | Homebrew |
| **Superpowers** | 14 composable dev workflow skills | [obra/superpowers](https://github.com/obra/superpowers) |
| **Caveman** | Token compression (cuts ~75% output) | Local skills |
| **Memory** | Persistent agent memory via Obsidian | Local skill |
| **18 Agents** | Specialized subagents (backend, frontend, security, etc.) | Custom |
| **MCP** | Obsidian integration for note/memory access | uvx mcp-obsidian |

## Quick Install

```bash
git clone git@github.com:controllan/ai-setup.git ~/ai-setup
cd ~/ai-setup && bash setup.sh
```

Or from a fresh machine:

```bash
curl -fsSL https://raw.githubusercontent.com/controllan/ai-setup/main/bootstrap.sh | bash
```

## Step-by-step Manual Install

If you prefer to understand every step:

### 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### 2. Install Packages

```bash
brew install opencode node ripgrep uv gh go git-lfs helm k9s kubectx argocd
```

### 3. Shell Configuration

```bash
cp shell/.zshrc ~/.zshrc
cp shell/.p10k.zsh ~/.p10k.zsh
cp shell/.gitconfig ~/.gitconfig
# Edit ~/.gitconfig with your name/email
```

### 4. OpenCode Config

```bash
mkdir -p ~/.config/opencode
cp opencode/opencode.json ~/.config/opencode/opencode.json
cp opencode/package.json ~/.config/opencode/package.json
cd ~/.config/opencode && npm install
# Edit opencode.json with your Obsidian API key
```

### 5. Agents

```bash
mkdir -p ~/.config/opencode/agents
cp agents/*.md ~/.config/opencode/agents/
```

### 6. Personal Skills

```bash
for skill in caveman caveman-commit caveman-review memory; do
  mkdir -p ~/.config/opencode/skills/$skill
  cp skills/$skill/SKILL.md ~/.config/opencode/skills/$skill/SKILL.md
done
```

### 7. Superpowers

```bash
git clone git@github.com:obra/superpowers.git ~/.config/opencode/superpowers

# Plugin symlink
mkdir -p ~/.config/opencode/plugins
ln -sf ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js ~/.config/opencode/plugins/superpowers.js

# Skills symlink
ln -sfn ~/.config/opencode/superpowers/skills ~/.config/opencode/skills/superpowers
```

### 8. MCP: Obsidian

See [mcp/obsidian-setup.md](mcp/obsidian-setup.md) for detailed setup.

In short:
- Install [Obsidian](https://obsidian.md/) and open your vault
- Install the Local REST API community plugin
- Set port `27124` and generate an API key
- Update the key in `~/.config/opencode/opencode.json`

### 9. Restart

Start a new OpenCode session and ask:

```
do you have superpowers?
```

If everything worked, it will confirm Superpowers are loaded.

## Verifying the Stack

| Test | Expected |
|------|----------|
| `opencode --version` | 1.15.x or later |
| `ls ~/.config/opencode/agents/*.md` | 18 agent files |
| `ls ~/.config/opencode/skills/caveman/SKILL.md` | Caveman skill exists |
| `ls -la ~/.config/opencode/plugins/superpowers.js` | Symlink to superpowers |
| `ls ~/.config/opencode/skills/superpowers` | 14 skill directories |
| `ls ~/.config/opencode/superpowers/.git` | Git repo (cloned) |

## Directory Layout

```
~/.config/opencode/
├── opencode.json           # Main config (MCP, agents)
├── package.json            # Plugin deps
├── agents/                 # 18 subagent definitions
├── skills/                 # Skills directory
│   ├── superpowers/        # → symlink → superpowers/skills
│   ├── caveman/
│   ├── caveman-commit/
│   ├── caveman-review/
│   └── memory/
├── plugins/
│   └── superpowers.js      # → symlink → superpowers/.opencode/plugins/superpowers.js
└── superpowers/            # Cloned from obra/superpowers
```

## Updating

```bash
# Superpowers
cd ~/.config/opencode/superpowers && git pull

# This repo
cd ~/ai-setup && git pull && bash setup.sh
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
