# Pi Dual-Harness Setup Implementation Plan

> **For agentic workers:** execute this plan via the orchestrator loop: implement → verify → `code-reviewer` → `git-expert` commit. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add Pi (`pi-coding-agent`) as second harness: repo `pi/` = source of truth (81-model commandcode provider, settings, AGENTS.md, 12 agents, permission policy); updater + INSTALL sync it; live machine synced; release 0.3.0.

**Architecture:** New repo dir `pi/` snapshots shared Pi config from the live machine. Local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) stay machine-local. Updater gains a Pi step with python3 deep-merge (repo wins; live-only provider keys and settings keys survive; `packages` unioned). Skills shared via `~/.pi/agent/skills` symlink → `~/.config/opencode/skills`. Live sync last, then release checkpoint.

**Tech Stack:** Markdown, JSON, python3 stdlib (no jq), bash, Homebrew, `pi` CLI, git.

**Spec:** `docs/specs/2026-10-04-pi-dual-setup-design.md` — executors read both; plan argues from spec.

## Global Constraints

- Branch `main`. One conventional commit per logical part, via `git-expert`.
- Repo `pi/` = source of truth. `pi/models.json`: exactly ONE provider `commandcode`, exactly 81 models. Provider fields verbatim: `baseUrl` `https://api.commandcode.ai/provider/v1`, `api` `openai-completions`, `apiKey` `!python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.local/share/opencode/auth.json')))['commandcode']['key'])"`.
- Local providers (`ollama` (2), `omlx` (9), `mtplx` (1), `mlx-lm` (1)) stay OUT of the repo. Merge NEVER drops them.
- `pi/settings.json` repo copy: packages + `commandcode` defaults ONLY; NO `theme`, NO `lastChangelogVersion` (live-only keys survive merge).
- Settings exact content verbatim: `{"packages":["npm:@tintinweb/pi-subagents","npm:@narumitw/pi-plan-mode","npm:@juicesharp/rpiv-todo","npm:@gotgenes/pi-permission-system"],"defaultProvider":"commandcode","defaultModel":"deepseek/deepseek-v4.1-flash"}`.
- Skills symlink: `~/.pi/agent/skills` is a symlink to `~/.config/opencode/skills`; real dir → warn + skip, never delete user data.
- Packages exactly 4: `@narumitw/pi-plan-mode`, `@juicesharp/rpiv-todo`, `@gotgenes/pi-permission-system`, `@tintinweb/pi-subagents`. No `pi-web-access`.
- 12 agents, no model pins; `code-reviewer` + `security-reviewer` stay read-only.
- Pi reads `~/.pi/agent` at start: restart a RUNNING Pi session to apply changes. Live-sync checkpoint: Pi not running during sync → no restart needed now.
- No artificial delays anywhere. Wait on conditions, not clocks.
- Compact doc style for committed docs (caveman ultra + Simplified Technical English). Never alter: paths, commands, code, numbers, negations, acceptance criteria.
- Docs are part of the deliverable; updated in the same change.
- Never commit or print secrets.

## File Structure

| Path | Action |
|---|---|
| `docs/plans/2026-10-04-pi-dual-setup.md` | create (this plan) |
| `pi/models.json` | create: live snapshot, `commandcode` only (81 models) |
| `pi/settings.json` | create: exact content above |
| `pi/AGENTS.md` | create: byte copy of live |
| `pi/agents/*.md` (12) | create: byte copies of live |
| `pi/extensions/pi-permission-system/config.json` | create: byte copy of live |
| `skills/update-ai-setup/SKILL.md` | modify: +variables, +step 7 Pi, renumber 8/9, +verify, +Rules, +maintainer note |
| `INSTALL.md` | modify: +Step 5b, +Step 9 Pi block, +Step 11 note |
| `README.md` | modify: +components row, +dual-harness section, +trees, +troubleshooting, +updating note |
| `CHANGELOG.md` | modify: +`[0.3.0]` |

## Task 1: Create repo `pi/` from live state

**Files:**
- Create: `pi/models.json`, `pi/settings.json`, `pi/AGENTS.md`, `pi/agents/*.md` (12), `pi/extensions/pi-permission-system/config.json`

**Interfaces:**
- Consumes: live `~/.pi/agent/models.json` (commandcode 81 + ollama 2 + omlx 9 + mtplx 1 + mlx-lm 1), live `~/.pi/agent/settings.json`, live `~/.pi/agent/AGENTS.md`, live `~/.pi/agent/agents/*.md`, live `~/.pi/agent/extensions/pi-permission-system/config.json`.
- Produces: repo `pi/` source of truth. Consumed by Task 2 (updater scripts), Task 3 (INSTALL), Task 4 (README), Task 6 (live sync).

- [ ] **Step 1: Write `pi/models.json`** — copy live, keep ONLY provider `commandcode`. Script validated read-only on 2026-10-04 against a `/tmp` copy: wrote 81-model file, dropped `mlx-lm`, `mtplx`, `ollama`, `omlx`.

```bash
mkdir -p pi
python3 - <<'PY'
import json, os

src = os.path.expanduser("~/.pi/agent/models.json")
dst = "pi/models.json"

with open(src) as fh:
    models = json.load(fh)

dropped = sorted(key for key in models["providers"] if key != "commandcode")
models["providers"] = {"commandcode": models["providers"]["commandcode"]}

with open(dst, "w") as fh:
    fh.write(json.dumps(models, indent=2, ensure_ascii=False) + "\n")
print("wrote " + dst + " — kept commandcode (" + str(len(models["providers"]["commandcode"]["models"])) + " models); dropped: " + ", ".join(dropped))
PY
```

- [ ] **Step 2: Verify models**

Run:
```bash
python3 -m json.tool pi/models.json >/dev/null && echo "pi/models.json: valid JSON"
python3 - <<'PY'
import json
providers = json.load(open("pi/models.json"))["providers"]
assert list(providers) == ["commandcode"], list(providers)
assert len(providers["commandcode"]["models"]) == 81, len(providers["commandcode"]["models"])
print("providers: commandcode only, 81 models: OK")
PY
grep -nE '"(ollama|omlx|mtplx|mlx-lm)"' pi/models.json || echo "local providers absent: OK"
python3 - <<'PY'
import json
p = json.load(open("pi/models.json"))["providers"]["commandcode"]
assert p["baseUrl"] == "https://api.commandcode.ai/provider/v1", p["baseUrl"]
assert p["api"] == "openai-completions", p["api"]
assert p["apiKey"] == "!python3 -c \"import json,os;print(json.load(open(os.path.expanduser('~/.local/share/opencode/auth.json')))['commandcode']['key'])\"", p["apiKey"]
print("commandcode provider fields: OK")
PY
```
Expected: `pi/models.json: valid JSON`; `providers: commandcode only, 81 models: OK`; `local providers absent: OK`; `commandcode provider fields: OK`.

- [ ] **Step 3: Write `pi/settings.json`** — exact content, one line + trailing newline:

```bash
printf '%s\n' '{"packages":["npm:@tintinweb/pi-subagents","npm:@narumitw/pi-plan-mode","npm:@juicesharp/rpiv-todo","npm:@gotgenes/pi-permission-system"],"defaultProvider":"commandcode","defaultModel":"deepseek/deepseek-v4.1-flash"}' > pi/settings.json
```

- [ ] **Step 4: Verify settings**

Run:
```bash
python3 -m json.tool pi/settings.json >/dev/null && echo "pi/settings.json: valid JSON"
python3 - <<'PY'
import json
cfg = json.load(open("pi/settings.json"))
assert cfg == {
    "packages": [
        "npm:@tintinweb/pi-subagents",
        "npm:@narumitw/pi-plan-mode",
        "npm:@juicesharp/rpiv-todo",
        "npm:@gotgenes/pi-permission-system",
    ],
    "defaultProvider": "commandcode",
    "defaultModel": "deepseek/deepseek-v4.1-flash",
}, cfg
print("pi/settings.json: exact values OK")
PY
```
Expected: `pi/settings.json: valid JSON`; `pi/settings.json: exact values OK`.

- [ ] **Step 5: Copy live files** (byte copies; repo becomes source of truth):

```bash
mkdir -p pi/agents pi/extensions/pi-permission-system
cp ~/.pi/agent/AGENTS.md pi/AGENTS.md
cp ~/.pi/agent/agents/*.md pi/agents/
cp ~/.pi/agent/extensions/pi-permission-system/config.json pi/extensions/pi-permission-system/config.json
```

- [ ] **Step 6: Verify copies**

Run:
```bash
ls pi/agents/*.md | wc -l   # expect 12
diff -r pi/agents ~/.pi/agent/agents >/dev/null && echo "agents byte-identical: OK" || echo "agents DIFFER"
cmp pi/AGENTS.md ~/.pi/agent/AGENTS.md && echo "AGENTS.md byte-identical: OK"
cmp pi/extensions/pi-permission-system/config.json ~/.pi/agent/extensions/pi-permission-system/config.json && echo "permission config byte-identical: OK"
for f in pi/agents/*.md; do n=$(basename "$f" .md); grep -q "^name: $n$" "$f" || echo "FRONTMATTER MISMATCH: $f"; done
grep -q "caveman-begin" pi/AGENTS.md && grep -q "Pi orchestrator" pi/AGENTS.md && echo "AGENTS.md headers: OK"
python3 -m json.tool pi/extensions/pi-permission-system/config.json >/dev/null && echo "permission config: valid JSON"
```
Expected: `12`; `agents byte-identical: OK`; `AGENTS.md byte-identical: OK`; `permission config byte-identical: OK`; `AGENTS.md headers: OK`; `permission config: valid JSON`; no `FRONTMATTER MISMATCH` lines; no `agents DIFFER`.

- [ ] **Step 7: Commit**

```bash
git add pi/
git commit -m "feat(pi): add shared Pi config snapshot for dual-harness setup"
```

---

## Task 2: Rewrite updater skill — Pi step, verify, maintainer note

**Files:**
- Modify: `skills/update-ai-setup/SKILL.md`

**Interfaces:**
- Consumes: `pi/` files from Task 1; variables `REPO_DIR`, `OPENCODE_CONFIG` (existing).
- Produces: `### 7. Pi (dual harness)` step + step 9 Pi verify + maintainer model-list note. Executed by Task 6; mirrored by Task 3; documented by Task 4.

- [ ] **Step 1: Append variable** in `## Variables` code block, after the `REPO_DIR=` line:

```bash
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
```

- [ ] **Step 2: Renumber the version gate.** In `### 1b. Newer version? (state file decides)`, replace exact line:

`Versions match: skip to step 8 (verify-only). Otherwise run steps 2–7; step 8 stamps.`

with:

`Versions match: skip to step 9 (verify-only). Otherwise run steps 2–8; step 9 stamps.`

- [ ] **Step 3: Insert new step** after the `### 6. Remove superpowers artifacts` block (after its `rm -f "$OPENCODE_CONFIG/plugins/superpowers.js"` fence) and before `### 7. AGENTS.md routing guardrail`. Then renumber: old `### 7. AGENTS.md routing guardrail` → `### 8. AGENTS.md routing guardrail`; old `### 8. Verify + stamp` → `### 9. Verify + stamp`. Full inserted text:

````markdown
### 7. Pi (dual harness)

Source of truth: `pi/` in the repo. Existing installs keep local providers — the merge never drops provider keys absent from the repo.

Ensure Pi is installed and the agent dir exists:

```bash
command -v pi >/dev/null || brew install pi-coding-agent
brew outdated pi-coding-agent >/dev/null 2>&1 && brew upgrade pi-coding-agent || true
mkdir -p "$PI_AGENT_DIR"
```

Merge `pi/models.json` into live `models.json` (repo wins; live-only provider keys survive; python3 stdlib). Result: `commandcode` from repo (81 models); `ollama`, `omlx`, `mtplx`, `mlx-lm` untouched. Assert: no live-only provider lost.

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

Merge `pi/settings.json` (repo wins; `packages` unioned repo-first, deduped; live-only keys like `theme`, `lastChangelogVersion` preserved).

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

Symlink skills — `$OPENCODE_CONFIG/skills` is the only skills source. Real dir → warn + skip (never delete user data); symlink → replace:

```bash
if [ -d "$PI_AGENT_DIR/skills" ] && [ ! -L "$PI_AGENT_DIR/skills" ]; then
  echo "WARN: skills is a real dir — skipping symlink"
else
  rm -f "$PI_AGENT_DIR/skills" && ln -sfn "$OPENCODE_CONFIG/skills" "$PI_AGENT_DIR/skills"
fi
```

Ensure packages:

```bash
for pkg in @narumitw/pi-plan-mode @juicesharp/rpiv-todo @gotgenes/pi-permission-system @tintinweb/pi-subagents; do
  pi list | grep -q "npm:$pkg" || pi install "npm:$pkg"
done
```
````

- [ ] **Step 4: Add Pi verify** inside `### 9. Verify + stamp`, after the line `grep -rn "^model:" "$OPENCODE_CONFIG/agents/" && echo "MODEL PINS: fix" || echo "no model pins: OK"` and before the closing fence of that bash block:

```bash
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
python3 - "$PI_AGENT_DIR/settings.json" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
for pkg in ("npm:@narumitw/pi-plan-mode", "npm:@juicesharp/rpiv-todo", "npm:@gotgenes/pi-permission-system", "npm:@tintinweb/pi-subagents"):
    assert pkg in cfg["packages"], "package missing: " + pkg
assert cfg["defaultProvider"] == "commandcode", cfg["defaultProvider"]
assert cfg["defaultModel"] == "deepseek/deepseek-v4.1-flash", cfg["defaultModel"]
print("pi settings: OK")
PY
ls "$PI_AGENT_DIR/agents/"*.md | wc -l   # expect 12
[ -L "$PI_AGENT_DIR/skills" ] && [ "$(readlink "$PI_AGENT_DIR/skills")" = "$OPENCODE_CONFIG/skills" ] && echo "pi skills symlink: OK" || echo "pi skills symlink: MISSING"
pi list | grep -c "npm:@"   # expect 4
```

- [ ] **Step 5: Update Rules.** Replace exact line:

`- End with a compact OK/MISSING table. Tell the user to restart their opencode session so the new agents, skills, and config take effect.`

with:

`- End with a compact OK/MISSING table. Tell the user to restart their opencode session and any running Pi session so the new agents, skills, and config take effect.`

- [ ] **Step 6: Add maintainer note** in `skills/update-ai-setup/SKILL.md`, between the `## Releasing a new version (maintainer — inside the ai-setup repo)` section (after its last line `Users pick the release up automatically next time they say "update my ai-setup".`) and `## Rules`:

````markdown
### Maintaining the commandcode model list

`pi/models.json` is a manual snapshot; `pi update` refreshes Pi bundled catalogs only. Regenerate with `MODEL_DEALS` keys from `~/.cache/opencode/packages/opencode-cmd-provider@latest/node_modules/opencode-cmd-provider/dist/src/deals/catalog.js`, enrich `reasoning`/`thinkingLevelMap`/`compat`/`contextWindow`/`maxTokens`/`input`/`cost` from the pi bundled catalogs (`.../pi-ai/dist/providers/data/*.json`), and keep local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) out of the repo copy.
````

- [ ] **Step 7: Verify skill structure + merge behavior**

Run:
```bash
grep -n "^### 7. Pi (dual harness)" skills/update-ai-setup/SKILL.md
grep -n "^### 8. AGENTS.md routing guardrail" skills/update-ai-setup/SKILL.md
grep -n "^### 9. Verify + stamp" skills/update-ai-setup/SKILL.md
grep -n "skip to step 9 (verify-only). Otherwise run steps 2–8; step 9 stamps." skills/update-ai-setup/SKILL.md
grep -n "restart their opencode session and any running Pi session" skills/update-ai-setup/SKILL.md
grep -n "Maintaining the commandcode model list" skills/update-ai-setup/SKILL.md
grep -c "PI_AGENT_DIR" skills/update-ai-setup/SKILL.md
python3 - <<'PY'
import json, pathlib, re, shutil, subprocess, tempfile

text = pathlib.Path("skills/update-ai-setup/SKILL.md").read_text()
pattern = r"python3 - \"\$REPO_DIR/pi/(models|settings)\.json\" \"[^\"]+\" <<'PY'\n(.*?)\nPY"
blocks = re.findall(pattern, text, re.S)
assert len(blocks) == 2, len(blocks)
scripts = {name: body for name, body in blocks}
assert 'live.get("providers", {})' in scripts["models"], "models script missing provider assert"
assert 'UNION_PATHS = {("packages",)}' in scripts["settings"], "settings script missing package union"

tmp = pathlib.Path(tempfile.mkdtemp())
repo_models = tmp / "repo-models.json"
live_models = tmp / "live-models.json"
repo_models.write_text(json.dumps({"providers": {"commandcode": {"models": [{"id": "m" + str(i)} for i in range(81)]}}}))
live_models.write_text(json.dumps({"providers": {"commandcode": {"models": [{"id": "old"}]}, "ollama": {"models": [{"id": "o"}]}}}))
subprocess.run(["python3", "-c", scripts["models"], str(repo_models), str(live_models)], check=True)
merged = json.loads(live_models.read_text())
assert len(merged["providers"]["commandcode"]["models"]) == 81, merged["providers"]["commandcode"]
assert "ollama" in merged["providers"], merged["providers"]

repo_settings = tmp / "repo-settings.json"
live_settings = tmp / "live-settings.json"
repo_settings.write_text(json.dumps({"packages": ["npm:a", "npm:b"], "defaultProvider": "commandcode"}))
live_settings.write_text(json.dumps({"packages": ["npm:b", "npm:c"], "theme": "dark"}))
subprocess.run(["python3", "-c", scripts["settings"], str(repo_settings), str(live_settings)], check=True)
merged = json.loads(live_settings.read_text())
assert merged["packages"] == ["npm:a", "npm:b", "npm:c"], merged["packages"]
assert merged["theme"] == "dark", merged
shutil.rmtree(tmp)
print("pi merge scripts: behavior OK")
PY
```
Expected: headings found at `### 7`/`### 8`/`### 9`; renumbered gate line found; Rules line found; maintainer note found; `PI_AGENT_DIR` count ≥ 10; `pi merge scripts: behavior OK`.

- [ ] **Step 8: Commit**

```bash
git add skills/update-ai-setup/SKILL.md
git commit -m "feat(updater): sync Pi dual-harness config, packages, and skills symlink"
```

---

## Task 3: INSTALL.md — Step 5b, Step 9 verify, Step 11 notes

**Files:**
- Modify: `INSTALL.md`

**Interfaces:**
- Consumes: `pi/` from Task 1; updater Pi step from Task 2 (same commands mirrored).
- Produces: fresh-install path + verification + restart notes.

- [ ] **Step 1: Insert `## Step 5b: Pi (dual harness)`** between the Step 5 code block (after `rm -f "$OPENCODE_CONFIG/plugins/superpowers.js"` fence) and the `---` / `## Step 6: Install and configure Neovim` boundary. Full inserted text:

````markdown
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
````

- [ ] **Step 2: Add Pi block to `## Step 9: Verify installations`** — insert before `echo "=== Neovim ==="`:

```bash
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
pi list | grep -c "npm:@"   # expect 4
pi -p "reply OK"   # optional smoke; expect a short answer
```

- [ ] **Step 3: Add Step 11 note** — after item `3. **Start OpenCode** — run \`opencode\`` in `## Step 11: Remaining manual steps`:

```markdown
4. **Pi (dual harness)** — restart Pi after an update: it reads `~/.pi/agent` at start. Default model is `deepseek/deepseek-v4.1-flash` (provider `commandcode`) — switch with the `/model` picker; thinking levels via `pi --thinking high`. Pi shares skills with OpenCode via the `~/.pi/agent/skills` symlink.
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -n "^## Step 5b: Pi (dual harness)" INSTALL.md
awk '/^## Step 5b/,/^## Step 6/' INSTALL.md > /tmp/install-step5b.md
grep -c "PI_AGENT_DIR" /tmp/install-step5b.md   # expect ≥ 8
grep -c 'pi install "npm:' /tmp/install-step5b.md   # expect 1
grep -n "=== Pi (dual harness) ===" INSTALL.md
grep -n "expect 12" INSTALL.md
grep -n "pi -p \"reply OK\"" INSTALL.md
grep -n "restart Pi after an update" INSTALL.md
grep -c '^4\. \*\*Pi (dual harness)\*\*' INSTALL.md   # expect 1
```
Expected: Step 5b heading found; PI_AGENT_DIR ≥ 8 in extracted block; 1 package-install line; Pi verify block present; agents `expect 12` present; smoke command present; restart note present; Step 11 item count 1.

- [ ] **Step 5: Commit**

```bash
git add INSTALL.md
git commit -m "docs(install): add Pi dual-harness step and verification"
```

---

## Task 4: README.md — components, dual harness, trees, troubleshooting, updating

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: `pi/` layout (Task 1), updater Pi step (Task 2).
- Produces: user-facing dual-harness docs.

- [ ] **Step 1: Components table row.** In `## What's Inside`, insert after the `**OpenCode**` row:

```markdown
| **Pi** | Second harness (`pi-coding-agent`) — same agents, skills, caveman; `pi/` is the shared Pi config source | Homebrew |
```

- [ ] **Step 2: Dual-harness section.** Insert after the Agents section (after the design-rationale paragraph) and before `## Installation (Two Phases)`:

````markdown
## Dual Harness (OpenCode + Pi)

OpenCode and Pi are both supported. The repo is the source of truth for shared config.

| Shared (synced from repo) | Where |
|---|---|
| Skills | `~/.pi/agent/skills` symlinks to `~/.config/opencode/skills` |
| Agents (12 specialists) | `pi/agents/*.md` → `~/.pi/agent/agents/` |
| Instructions | `pi/AGENTS.md` (caveman block + routing/lifecycle) → `~/.pi/agent/AGENTS.md` |
| Models config | `pi/models.json`: `commandcode` provider, 81 models |
| Defaults | `defaultProvider: commandcode`, `defaultModel: deepseek/deepseek-v4.1-flash` |
| Packages | pi-plan-mode, rpiv-todo, pi-permission-system, pi-subagents |
| Permission policy | `pi/extensions/pi-permission-system/config.json` |

Machine-local, never committed: local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) and local settings keys (`theme`, `lastChangelogVersion`). The updater deep-merges: repo wins, local values survive.
````

- [ ] **Step 3: Directory layout.** In `## Directory Layout`, append after the existing opencode tree:

````markdown
Repo Pi config (`pi/`):

```
pi/
├── models.json               # commandcode provider only (81 models)
├── settings.json             # packages + default provider/model
├── AGENTS.md                 # caveman block + Pi routing/lifecycle
├── agents/                   # 12 specialist definitions
└── extensions/
    └── pi-permission-system/
        └── config.json       # permission policy
```

Live Pi install (`~/.pi/agent/`):

```
~/.pi/agent/
├── models.json               # commandcode (81) + machine-local providers
├── settings.json             # synced keys + live-only keys
├── AGENTS.md
├── agents/                   # 12 specialists
├── skills -> ~/.config/opencode/skills
└── extensions/
    └── pi-permission-system/
        └── config.json
```
````

- [ ] **Step 4: Updating note.** In `## Updating`, replace sentence (it wraps across a line break in the source file: `The` ends one line, `config sync ...` starts the next — match ignoring the wrap):

``The config sync deep-merges: repo wins; local providers survive; arrays unioned.``

with:

``The config sync deep-merges: repo wins; local providers survive; arrays unioned — Pi too (`pi/models.json` repo wins, local providers survive, `packages` unioned).``

- [ ] **Step 5: Pi troubleshooting.** Append at the end of `## Troubleshooting` (after the `### npm install failures` section):

````markdown
### Pi — `pi` not found

```bash
brew install pi-coding-agent
```

### Pi — models missing or fewer than 81

```bash
python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.pi/agent/models.json')));print(len(d['providers']['commandcode']['models']))"   # expect 81
```

Re-run the updater ("update my ai-setup"), which deep-merges `pi/models.json` into `~/.pi/agent/models.json`.

### Pi — subagents not loading

```bash
ls ~/.pi/agent/agents/*.md | wc -l   # expect 12
pi list | grep -c "npm:@"             # expect 4
```

Restart Pi after syncing `~/.pi/agent` (Pi reads it at start).

### Pi — permission prompts

Policy lives in `~/.pi/agent/extensions/pi-permission-system/config.json`: reads anywhere allowed; writes outside cwd ask; secrets deny; destructive bash deny/ask. Re-run the updater Pi step to restore the repo policy.

### Pi — skills symlink broken

```bash
readlink ~/.pi/agent/skills   # expect ~/.config/opencode/skills
```
````

- [ ] **Step 6: Verify**

Run:
```bash
grep -q "^## Dual Harness (OpenCode + Pi)$" README.md && echo "dual-harness section: OK"
grep -q '| \*\*Pi\*\* |' README.md && echo "components row: OK"
grep -q "Repo Pi config (\`pi/\`)" README.md && echo "repo pi tree: OK"
grep -q 'pi/models.json` repo wins, local providers survive, `packages` unioned' README.md && echo "updating note: OK"
grep -c "^### Pi — " README.md   # expect 5
```
Expected: `dual-harness section: OK`; `components row: OK`; `repo pi tree: OK`; `updating note: OK`; count `5`.

- [ ] **Step 7: Commit**

```bash
git add README.md
git commit -m "docs(readme): document Pi dual harness, layout, troubleshooting"
```

---

## Task 5: CHANGELOG 0.3.0

**Files:**
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: version heading read by updater version gate (`REPO_VER`) and release task.

- [ ] **Step 1: Replace the `## [Unreleased]` section** (heading + `### Changed` memory entry) with:

```markdown
## [Unreleased]

## [0.3.0] - 2026-10-04

### Added

- Pi (`pi-coding-agent`) as second harness: shared config snapshot in `pi/`
  (models.json, settings.json, AGENTS.md, 12 agents, permission policy).
- 81 `commandcode` models (defaults `commandcode` /
  `deepseek/deepseek-v4.1-flash`); Pi packages: pi-plan-mode, rpiv-todo,
  pi-permission-system, pi-subagents.
- Updater + INSTALL.md sync Pi: install, deep-merge models/settings, copy
  agents/AGENTS.md/permission config, symlink skills, ensure packages.

### Changed

- `memory` skill is trigger-only: no session-start auto-load. Read/write happens
  only when the user refers to memory ("remember", "check memory", …).
- Pi local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) and local settings
  keys stay machine-local; the repo never stores them.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "^## \[Unreleased\]$" CHANGELOG.md
grep -n "^## \[0.3.0\] - 2026-10-04$" CHANGELOG.md
grep -q "81 \`commandcode\` models" CHANGELOG.md && echo "81 models note: OK"
grep -q "Pi local providers (\`ollama\`, \`omlx\`, \`mtplx\`, \`mlx-lm\`)" CHANGELOG.md && echo "local providers note: OK"
grep -n "memory. skill is trigger-only" CHANGELOG.md
```
Expected: both headings found; `81 models note: OK`; `local providers note: OK`; memory entry retained under 0.3.0.

- [ ] **Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): add 0.3.0 — Pi dual-harness support"
```

---

## Task 6: Sync live machine (checkpoint)

**Files:** none in repo — machine-local `~/.pi/agent/`.

**Interfaces:**
- Consumes: Tasks 1–5 committed; `skills/update-ai-setup/SKILL.md` step `### 7. Pi (dual harness)`.
- Produces: live Pi install on repo state.

- [ ] **Step 1: Back up live Pi config**

```bash
cp ~/.pi/agent/models.json /tmp/pi-models-backup.json
cp ~/.pi/agent/settings.json /tmp/pi-settings-backup.json
```

- [ ] **Step 2: Run the Pi actions** — execute `### 7. Pi (dual harness)` from `skills/update-ai-setup/SKILL.md` against this machine (`REPO_DIR` = this repo checkout, `OPENCODE_CONFIG` = `$HOME/.config/opencode`, `PI_AGENT_DIR` = `$HOME/.pi/agent`). Steps: ensure Pi installed, `mkdir -p "$PI_AGENT_DIR"`, merge models, merge settings, copy AGENTS.md/agents/permission config, symlink skills, ensure packages.

- [ ] **Step 3: Verify live state**

Run:
```bash
python3 -m json.tool ~/.pi/agent/models.json >/dev/null && echo "live pi models JSON: OK"
python3 - <<'PY'
import json, os
providers = json.load(open(os.path.expanduser("~/.pi/agent/models.json")))["providers"]
assert list(providers)[0] == "commandcode", list(providers)
assert len(providers["commandcode"]["models"]) == 81, len(providers["commandcode"]["models"])
for p, n in (("ollama", 2), ("omlx", 9), ("mtplx", 1), ("mlx-lm", 1)):
    assert p in providers, "local provider lost: " + p
    assert len(providers[p]["models"]) == n, (p, len(providers[p]["models"]))
print("live providers: commandcode 81 + locals preserved: OK")
PY
python3 - <<'PY'
import json, os
cfg = json.load(open(os.path.expanduser("~/.pi/agent/settings.json")))
assert cfg["packages"] == [
    "npm:@tintinweb/pi-subagents",
    "npm:@narumitw/pi-plan-mode",
    "npm:@juicesharp/rpiv-todo",
    "npm:@gotgenes/pi-permission-system",
], cfg["packages"]
assert cfg["defaultProvider"] == "commandcode", cfg["defaultProvider"]
assert cfg["defaultModel"] == "deepseek/deepseek-v4.1-flash", cfg["defaultModel"]
assert "theme" in cfg and "lastChangelogVersion" in cfg, cfg
print("live pi settings: packages + defaults OK, live-only keys preserved")
PY
diff -r pi/agents ~/.pi/agent/agents >/dev/null && echo "live agents match repo: OK"
cmp pi/AGENTS.md ~/.pi/agent/AGENTS.md && echo "live AGENTS.md matches repo: OK"
cmp pi/extensions/pi-permission-system/config.json ~/.pi/agent/extensions/pi-permission-system/config.json && echo "live permission config matches repo: OK"
[ -L ~/.pi/agent/skills ] && [ "$(readlink ~/.pi/agent/skills)" = "$HOME/.config/opencode/skills" ] && echo "live skills symlink: OK"
pi list | grep -c "npm:@"                 # expect 4
pi --list-models | grep -c commandcode    # expect 81
```
Expected: `live pi models JSON: OK`; `live providers: commandcode 81 + locals preserved: OK`; `live pi settings: packages + defaults OK, live-only keys preserved`; `live agents match repo: OK`; `live AGENTS.md matches repo: OK`; `live permission config matches repo: OK`; `live skills symlink: OK`; `4`; `81`.

- [ ] **Step 4: Idempotence — run the two merge scripts again, then compare**

```bash
cp ~/.pi/agent/models.json /tmp/pi-models-second.json
cp ~/.pi/agent/settings.json /tmp/pi-settings-second.json
# re-run the two merge scripts from SKILL step 7 (same repo + live paths)
cmp /tmp/pi-models-second.json ~/.pi/agent/models.json && echo "second run models: unchanged"
cmp /tmp/pi-settings-second.json ~/.pi/agent/settings.json && echo "second run settings: unchanged"
rm -f /tmp/pi-models-second.json /tmp/pi-settings-second.json
```
Expected: `second run models: unchanged`; `second run settings: unchanged`.

- [ ] **Step 5: Optional smoke**

```bash
pi -p "reply OK"   # optional; expect a short answer on default model
```

- [ ] **Step 6: CHECKPOINT.** No Pi restart needed now — Pi is not running during the sync. Pi reads `~/.pi/agent` at start; restart a running Pi session to pick up changes. No repo commit for this task (machine-local only).

---

## Task 7: Release v0.3.0 (checkpoint)

**Files:** none — annotated tag + GitHub release.

**Interfaces:**
- Consumes: Tasks 1–5 committed on `main`; `## [0.3.0] - 2026-10-04` in `CHANGELOG.md`.
- Produces: tag `v0.3.0` + GitHub release.

- [ ] **Step 1: Preconditions**

```bash
git status --porcelain          # expect empty
git log --oneline -5
grep -n "^## \[0.3.0\] - 2026-10-04$" CHANGELOG.md
gh auth status
git tag --list v0.3.0           # expect empty
```
Expected: clean tree; `## [0.3.0] - 2026-10-04` present; `gh auth status` authenticated; no existing `v0.3.0` tag. If work happened on a feature branch, `git-expert` merges it to `main` first.

- [ ] **Step 2: CHECKPOINT — ask the user to confirm the release before pushing.**

- [ ] **Step 3: Tag + push + release**

```bash
git push origin main
git tag -a v0.3.0 -m "v0.3.0"
git push --follow-tags
gh release create v0.3.0 --title "v0.3.0" --notes "See CHANGELOG.md"
```

- [ ] **Step 4: Verify**

```bash
git tag --list v0.3.0
gh release view v0.3.0 --json tagName,url
```
Expected: tag `v0.3.0`; release exists with URL.

---

## Execution Handoff

Commit this plan first (via `git-expert`):

```bash
git add docs/plans/2026-10-04-pi-dual-setup.md
git commit -m "docs(plans): add Pi dual-harness setup implementation plan"
```

Then per logical part (Tasks 1–7):

1. Implement — specialist agent; orchestrator implements config/docs-only parts itself when no specialist fits.
2. Verify — run the task's verification commands; compare against expected output.
3. `code-reviewer` reviews the part diff — fix findings, re-review until clean.
4. `git-expert` commits the logical part.

Then next part. Tasks 6 and 7 are checkpoints: live sync (no Pi restart needed; no commit) and release confirmation (ask user before push).
