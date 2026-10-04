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

> **Note:** On a fresh install, copy the config below. Existing installs use
> the updater skill, which deep-merges the repo config into the live config
> (repo wins; local-only provider keys survive).

Copy the main config files (`opencode.json` sets `default_agent: orchestrator`
and Task allowlists so only the 12 specialists can be delegated to —
`general`/`explore`/`build`/`plan` are denied):

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

`agents/orchestrator.md` is the default primary entrypoint; the 12 specialists
are `mode: subagent` leaf workers (their Task tool is denied in `opencode.json`,
and each file states the leaf-worker agreement). The orchestrator runs the team
lifecycle (brainstorm → architect/ux gates → technical-writer plan → per-part
loop of implement + e2e test → review → git-expert commit → security review)
and delegates ONLY via the Task tool with `subagent_type` set to a specialist —
never `general`/`explore`/`build`/`plan`. Agents inherit your session model
(no per-agent pins).

---

## Step 3b: Use the AGENTS.md routing guardrail in your projects

`AGENTS.md` (repo root) is loaded by OpenCode every session and overrides any
skill text telling you to use a general-purpose subagent. Copy it into each
project that uses this team:

```bash
cp "$REPO_DIR/AGENTS.md" /path/to/your/project/AGENTS.md
```

---

## Step 4: Install repo skills (8)

```bash
mkdir -p "$OPENCODE_CONFIG/skills"
for skill in brainstorming writing-plans visual-companion caveman go-review memory update-ai-setup verifying-github-actions; do
  mkdir -p "$OPENCODE_CONFIG/skills/$skill"
  cp -R "$REPO_DIR/skills/$skill/." "$OPENCODE_CONFIG/skills/$skill/"
done
chmod +x "$OPENCODE_CONFIG/skills/visual-companion/scripts/start-server.sh" \
         "$OPENCODE_CONFIG/skills/visual-companion/scripts/stop-server.sh"
```

`update-ai-setup` is the self-updater skill — saying "update my ai-setup" later
refreshes the install to the repo state by re-running the updater steps (repo
pull, config deep-merge, agents, skills, caveman overlay + prune, artifact
removal, verify). It does not redo Neovim, git config, dev tools, or `gh` auth.

---

## Step 4b: Install caveman (official installer + overlay + prune)

Caveman is from [github.com/JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — use the official installer, then overlay the trimmed base skill. Pre-remove the skill first: the installer refuses to overwrite modified user content (ownership digest mismatch):

```bash
rm -rf "$OPENCODE_CONFIG/skills/caveman"
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
cp "$REPO_DIR/skills/caveman/SKILL.md" "$OPENCODE_CONFIG/skills/caveman/SKILL.md"
```

Prune extras + cavecrew after every installer run (`commands/caveman.md` is kept):

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

---

## Step 5: Remove legacy Superpowers artifacts

Superpowers is no longer used. Remove its artifacts:

```bash
rm -rf "$OPENCODE_CONFIG/superpowers" "$OPENCODE_CONFIG/skills/superpowers"
rm -f "$OPENCODE_CONFIG/plugins/superpowers.js"
```

## Step 5b: Pi (dual harness)

Pi (`pi-coding-agent`) is the second harness. Shared config lives in `$REPO_DIR/pi/`; local providers stay machine-local.

Set the Pi agent dir:

```bash
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
mkdir -p "$PI_AGENT_DIR"
```

Install Pi:

```bash
command -v pi >/dev/null || brew install pi-coding-agent
brew outdated pi-coding-agent >/dev/null 2>&1 && brew upgrade pi-coding-agent || true
```

Merge `pi/models.json` into the live `models.json` — repo wins; live-only provider keys survive (local providers are never clobbered):

```bash
python3 - "$REPO_DIR/pi/models.json" "$PI_AGENT_DIR/models.json" <<'PY'
import json, sys

repo_path, live_path = sys.argv[1], sys.argv[2]
repo = json.load(open(repo_path))
try:
    live = json.load(open(live_path))
except FileNotFoundError:
    live = {}

# No array unions: repo values replace. Live-only provider keys survive by dict merge.
UNION_PATHS = set()

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
lost = [key for key in live.get("providers", {}) if key not in merged.get("providers", {})]
assert not lost, "local providers lost: " + ", ".join(lost)
with open(live_path, "w") as fh:
    fh.write(json.dumps(merged, indent=2, ensure_ascii=False) + "\n")
print("merged " + live_path)
PY
```

Merge `pi/settings.json` — repo wins; `packages` unioned (repo entries first, deduped); live-only keys like `theme` and `lastChangelogVersion` preserved:

```bash
python3 - "$REPO_DIR/pi/settings.json" "$PI_AGENT_DIR/settings.json" <<'PY'
import json, sys

repo_path, live_path = sys.argv[1], sys.argv[2]
repo = json.load(open(repo_path))
try:
    live = json.load(open(live_path))
except FileNotFoundError:
    live = {}

# Arrays unioned instead of replaced: repo entries first, then live-only entries, deduped.
UNION_PATHS = {("packages",)}

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
with open(live_path, "w") as fh:
    fh.write(json.dumps(merged, indent=2, ensure_ascii=False) + "\n")
print("merged " + live_path)
PY
```

Copy repo files over live (repo wins):

```bash
mkdir -p "$PI_AGENT_DIR/agents" "$PI_AGENT_DIR/extensions/pi-permission-system"
cp "$REPO_DIR/pi/AGENTS.md" "$PI_AGENT_DIR/AGENTS.md"
cp "$REPO_DIR/pi/agents/"*.md "$PI_AGENT_DIR/agents/"
cp "$REPO_DIR/pi/extensions/pi-permission-system/config.json" "$PI_AGENT_DIR/extensions/pi-permission-system/config.json"
```

Symlink skills — `$OPENCODE_CONFIG/skills` is the only skills source. A real dir is user data: warn + skip, never delete:

```bash
if [ -d "$PI_AGENT_DIR/skills" ] && [ ! -L "$PI_AGENT_DIR/skills" ]; then
  echo "WARN: skills is a real dir — skipping symlink"
else
  rm -f "$PI_AGENT_DIR/skills" && ln -sfn "$OPENCODE_CONFIG/skills" "$PI_AGENT_DIR/skills"
fi
```

Install the 4 Pi packages (idempotent):

```bash
for pkg in @narumitw/pi-plan-mode @juicesharp/rpiv-todo @gotgenes/pi-permission-system @tintinweb/pi-subagents; do
  pi list | grep -q "npm:$pkg" || pi install "npm:$pkg"
done
```

Existing installs: the updater skill ("update my ai-setup") runs the same steps.

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
grep -q '"default_agent": "orchestrator"' "$OPENCODE_CONFIG/opencode.json" && echo "default_agent orchestrator: OK" || echo "default_agent orchestrator: MISSING"
grep -q '"general": "deny"' "$OPENCODE_CONFIG/opencode.json" && echo "general denied in Task: OK" || echo "general denied in Task: MISSING"

echo "=== Agents ==="
ls "$OPENCODE_CONFIG/agents/"*.md | wc -l
grep -l "mode: primary" "$OPENCODE_CONFIG/agents/"*.md
grep -rn "subagent_type.*general\|general-purpose" "$OPENCODE_CONFIG/agents/" && echo "GENERAL LEAK: fix" || echo "no general delegation in agents: OK"

echo "=== Skills ==="
for skill in brainstorming writing-plans visual-companion caveman go-review memory update-ai-setup verifying-github-actions; do
  [ -f "$OPENCODE_CONFIG/skills/$skill/SKILL.md" ] && echo "$skill: OK" || echo "$skill: MISSING (run Step 4)"
done

echo "=== Config ==="
grep -q '"sonarqube"' "$OPENCODE_CONFIG/opencode.json" && echo "sonarqube entry: OK" || echo "sonarqube entry: MISSING"
python3 - "$OPENCODE_CONFIG/opencode.json" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
assert cfg["mcp"]["sonarqube"]["enabled"] is False, "sonarqube must be disabled"
print("sonarqube disabled: OK")
PY

echo "=== Superpowers removed ==="
[ ! -e "$OPENCODE_CONFIG/superpowers" ] && [ ! -e "$OPENCODE_CONFIG/skills/superpowers" ] && [ ! -e "$OPENCODE_CONFIG/plugins/superpowers.js" ] && echo "superpowers artifacts: none" || echo "superpowers artifacts: FOUND"

echo "=== Pi (dual harness) ==="
pi --version
python3 -m json.tool "$PI_AGENT_DIR/models.json" >/dev/null && echo "pi models JSON: OK" || echo "pi models JSON: INVALID"
python3 - "$PI_AGENT_DIR/models.json" <<'PY'
import json, sys
providers = json.load(open(sys.argv[1]))["providers"]
assert "commandcode" in providers, "commandcode provider missing"
assert len(providers["commandcode"]["models"]) == 81, "expected 81 commandcode models, got " + str(len(providers["commandcode"]["models"]))
print("pi models: 81 commandcode models: OK")
PY
ls "$PI_AGENT_DIR/agents/"*.md | wc -l   # expect 12
[ -L "$PI_AGENT_DIR/skills" ] && [ "$(readlink "$PI_AGENT_DIR/skills")" = "$OPENCODE_CONFIG/skills" ] && echo "pi skills symlink: OK" || echo "pi skills symlink: MISSING"
for pkg in @tintinweb/pi-subagents @narumitw/pi-plan-mode @juicesharp/rpiv-todo @gotgenes/pi-permission-system; do pi list | grep -q "npm:$pkg" && echo "pi pkg $pkg: OK" || echo "pi pkg $pkg: MISSING"; done
pi -p "reply OK"   # optional smoke; expect a short answer

echo "=== Neovim ==="
nvim --version | head -1
ls ~/.config/nvim/init.lua 2>/dev/null && echo "nvim config: OK" || echo "nvim config: MISSING"

echo "=== Brew tools ==="
for tool in gh kubectl k9s uv go kubectx node; do
  command -v "$tool" &>/dev/null && echo "$tool: OK" || echo "$tool: MISSING"
done
```

Record the installed version for the updater skill:

```bash
grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$REPO_DIR/CHANGELOG.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' > "$OPENCODE_CONFIG/.ai-setup-version"
cat "$OPENCODE_CONFIG/.ai-setup-version"
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
3. **Start OpenCode** — run `opencode`
4. **Pi (dual harness)** — restart Pi after an update: it reads `~/.pi/agent` at start. Default model is `deepseek/deepseek-v4.1-flash` (provider `commandcode`) — switch with the `/model` picker; thinking levels via `pi --thinking high`. Pi shares skills with OpenCode via the `~/.pi/agent/skills` symlink.

---

## Step 12: Done

Phase 2 complete. The AI stack is installed and ready.
