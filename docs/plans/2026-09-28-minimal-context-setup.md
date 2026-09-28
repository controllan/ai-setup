# Minimal Context Setup Implementation Plan

> **For agentic workers:** ORCHESTRATOR LOOP per logical part — implement → verify → `code-reviewer` review → `git-expert` commit; then next part. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cut always-loaded context ≈ –20 KB/session, –4.5 KB/request: sonarqube MCP opt-in, superpowers removed + 3 skills vendored, caveman trimmed, agents/AGENTS.md compacted, docs moved, release 0.2.0.

**Architecture:** Repo is source of truth. Config sync switches from blind `cp` to python3 deep-merge (repo wins; live-only providers survive; arrays unioned). Skills vendored into `skills/`, installed by the rewritten updater. Live machine synced last, then release.

**Tech Stack:** Markdown skills, JSON config, python3 stdlib (no jq), bash, node (companion server).

**Spec:** `docs/specs/2026-09-28-minimal-context-setup-design.md` — executors read both; plan argues from spec.

## Global Constraints

- Branch `main`. One conventional commit per logical part, via `git-expert`.
- SonarQube MCP committed `"enabled": false`, `"timeout": 10000`. Server definition copied verbatim from live config.
- Local providers (`ollama`, `omlx`, `mtplx`, `mlx-lm`) stay OUT of the repo. Never commit or print `.secrets/`.
- Plugin array: `["./plugins/caveman/plugin.js", "opencode-cmd-provider"]`.
- After change: 7 local skills — `brainstorming`, `writing-plans`, `visual-companion`, `caveman`, `memory`, `update-ai-setup`, `verifying-github-actions`. `commands/caveman.md` stays.
- Removed-artifact grep scope: functional files only — `opencode/`, `agents/`, `skills/`, `AGENTS.md`, `README.md`, `INSTALL.md`. Historical docs (CHANGELOG, old specs/plans, this plan) may mention removed names.
- Caveman SKILL.md: ~2 KB target. Intensity table rows `| **level** |` + `- level:` example lines REQUIRED — plugin parses them. Never alter.
- Compact doc style for committed specs/plans: caveman ultra + Simplified Technical English. Fragments OK; tables/lists over prose. NEVER alter or drop: file paths, commands, code, numbers, negations, acceptance criteria, verification commands. Code blocks unchanged. Clarity wins over compression.
- No artificial delays anywhere. Wait on conditions, not clocks.
- Docs part of deliverable: README/INSTALL/CHANGELOG updated in the same change.

## File Structure

| Path | Action |
|---|---|
| `docs/plans/2026-09-28-minimal-context-setup.md` | create (this plan) |
| `opencode/opencode.json` | modify: +`plugin`, +`mcp.sonarqube` (disabled) |
| `skills/brainstorming/SKILL.md` | create |
| `skills/writing-plans/SKILL.md` | create |
| `skills/visual-companion/SKILL.md` | create |
| `skills/visual-companion/scripts/{server.cjs,helper.js,frame-template.html,start-server.sh,stop-server.sh}` | create |
| `skills/caveman/SKILL.md` | create (trimmed) |
| `skills/go-review/` | delete |
| `skills/update-ai-setup/SKILL.md` | rewrite |
| `agents/orchestrator.md` + 12 specialist files | modify (compact + gates) |
| `AGENTS.md` | modify (compact + style rule) |
| `README.md`, `INSTALL.md`, `CHANGELOG.md` | modify |
| `docs/superpowers/specs/*` → `docs/specs/` | git mv |
| `docs/superpowers/plans/*` → `docs/plans/` | git mv |

---

## Task 1: Repo config — SonarQube opt-in + plugin entries

**Files:**
- Modify: `opencode/opencode.json`
- Test: JSON parse + key asserts below

**Interfaces:**
- Produces: `mcp.sonarqube` (full server block, disabled), top-level `plugin` array. Consumed by Task 9 (merge script) and Task 12 (live checks).

- [ ] **Step 1: Add plugin array** after `"default_agent": "orchestrator",`:

```json
  "plugin": [
    "./plugins/caveman/plugin.js",
    "opencode-cmd-provider"
  ],
```

`opencode-cmd-provider` needs no `package.json` change: opencode fetches npm plugins itself into `~/.cache/opencode`.

- [ ] **Step 2: Add sonarqube block** inside `"mcp"`, after the `"github"` object (copy verbatim from live config, except `enabled` is `false`):

```json
    "sonarqube": {
      "type": "local",
      "command": ["podman", "run", "--init", "--pull=always", "-i", "--rm", "-e", "SONARQUBE_TOKEN", "-e", "SONARQUBE_URL", "sonarsource/sonarqube-mcp"],
      "enabled": false,
      "timeout": 10000,
      "environment": {
        "SONARQUBE_URL": "https://sonar.controllan.de",
        "SONARQUBE_TOKEN": "{file:~/.config/opencode/.secrets/sonarqube-token}"
      }
    }
```

- [ ] **Step 3: Verify JSON + values**

Run:
```bash
python3 -m json.tool opencode/opencode.json >/dev/null && echo "JSON: OK"
python3 -c "import json;d=json.load(open('opencode/opencode.json'));assert d['plugin']==['./plugins/caveman/plugin.js','opencode-cmd-provider'],d['plugin'];assert d['mcp']['sonarqube']['enabled'] is False;assert d['mcp']['sonarqube']['timeout']==10000;assert d['mcp']['obsidian']['enabled'] is False;assert d['mcp']['github']['enabled'] is False;print('config: OK')"
grep -nE '"(ollama|omlx|mtplx|mlx-lm)"' opencode/opencode.json || echo "local providers absent: OK"
```
Expected: `JSON: OK`, `config: OK`, `local providers absent: OK`.

- [ ] **Step 4: Commit**

```bash
git add opencode/opencode.json
git commit -m "feat(config): opt-in sonarqube MCP and caveman/cmd plugin entries"
```

---

## Task 2: Vendor `brainstorming` skill

**Files:**
- Create: `skills/brainstorming/SKILL.md`
- Source: `~/.config/opencode/skills/superpowers/brainstorming/SKILL.md` (15,456 B)

**Interfaces:**
- Produces: skill named `brainstorming`. Consumed by Task 7 (orchestrator lifecycle), Task 9 (install), Task 11 (docs).

- [ ] **Step 1: Write the adapted skill.** Keep the source structure, apply keep/remove below.

Keep verbatim: intro; `<HARD-GATE>` block; `## Three Paths`; `## Anti-Pattern: "Too Simple To Need Approval"`; `## Red Flags` table; `## Process Flow` dot graph; `## The Process`; spec self-review (4 checks); user review gate.

Remove: `## Visual Companion` section and its checklist step; `elements-of-style` line; `spec-document-reviewer-prompt` reference; all `superpowers` wording; `.superpowers/` paths.

Change:
- Frontmatter description: `Use before any creative work — features, components, behavior changes. Classify spike/bounded/architectural, refine intent, confirm design decisions, hand the spec to technical-writer, gate on user approval, then writing-plans.`
- Spec path: `docs/specs/YYYY-MM-DD-<topic>-design.md` (all occurrences).
- Architectural checklist: source steps 1,3–5,7–9 kept; source step 6 "Write design doc" replaced by confirm + handoff; renumber. Exact new list:

```markdown
1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to their complexity, get user approval after each section
5. **Confirm design decisions with the user** — brainstorming ends here; brainstorming does not author the spec
6. **Hand off to `technical-writer`** — writes the spec at `docs/specs/YYYY-MM-DD-<topic>-design.md`
7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (fix inline)
8. **User reviews written spec** — ask the user to review the spec at its path before proceeding
9. **Transition to implementation** — `writing-plans` skill
```

- "After the Design" Documentation bullet: `technical-writer` writes the validated design (spec) to `docs/specs/YYYY-MM-DD-<topic>-design.md` and commits it; keep the self-review (4 checks) and user review gate subsections as in source.
- Terminal-states paragraph: `**Terminal states are path-bound.** Architectural: hand the spec to technical-writer, then the ONLY next step is the writing-plans skill. Bounded: after approval, implement through the normal workflow; no plan document. Spike: report a recommendation.`
- Implementation section:

```markdown
## Implementation

- Invoke the `writing-plans` skill to create the implementation plan (technical-writer).
- Do NOT invoke any other skill. writing-plans is the next step.
```

- Append verbatim:

```markdown
## Compact Doc Style (committed specs/plans)

Caveman ultra compression + Simplified Technical English guardrails.

- Fragments OK. Tables and lists over prose. Drop filler.
- NEVER alter or drop: file paths, commands, code, numbers, negations, acceptance criteria, verification commands.
- Code blocks unchanged. Clarity wins over compression.
```

- [ ] **Step 2: Verify**

Run:
```bash
wc -c skills/brainstorming/SKILL.md
grep -n "superpowers\|visual-companion\|elements-of-style\|spec-document-reviewer" skills/brainstorming/SKILL.md || echo "forbidden refs: none"
grep -n "docs/specs/" skills/brainstorming/SKILL.md | wc -l
grep -n "writing-plans" skills/brainstorming/SKILL.md | wc -l
grep -n "technical-writer" skills/brainstorming/SKILL.md | wc -l
grep -n "Write design doc" skills/brainstorming/SKILL.md || echo "brainstormer authorship: gone"
grep -n "HARD-GATE\|spike\|bounded\|architectural\|User Review Gate\|Compact Doc Style" skills/brainstorming/SKILL.md | wc -l
```
Expected: bytes ≤ 9000 (substantially shorter than 15,456); `forbidden refs: none`; `docs/specs/` ≥ 2 occurrences; `writing-plans` ≥ 1; `technical-writer` ≥ 2; `brainstormer authorship: gone`; final keyword count ≥ 6.

- [ ] **Step 3: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat(skills): vendor adapted brainstorming skill"
```

---

## Task 3: Vendor `writing-plans` skill

**Files:**
- Create: `skills/writing-plans/SKILL.md`
- Source: `~/.config/opencode/skills/superpowers/writing-plans/SKILL.md` (7,053 B)

**Interfaces:**
- Produces: skill named `writing-plans`; plan header + execution handoff format consumed by Task 7 and every future plan.

- [ ] **Step 1: Write the adapted skill.** Keep source sections: `## Scope Check`; `## File Structure`; `## Task Right-Sizing`; `## Bite-Sized Task Granularity`; `## Plan Document Header`; `## Task Structure`; `## No Placeholders`; `## Self-Review`.

Remove: worktree context line; `plan-document-reviewer-prompt`; all `superpowers` sub-skill references (`subagent-driven-development`, `executing-plans`, `using-git-worktrees`); two-options execution choice.

Change:
- Save path: `docs/plans/YYYY-MM-DD-<feature-name>.md`.
- Header template agentic-worker line:

```markdown
> **For agentic workers:** execute this plan via the orchestrator loop: implement → verify → `code-reviewer` → `git-expert` commit. Steps use checkbox (`- [ ]`) syntax.
```

- Append verbatim:

```markdown
## Compact Doc Style (committed specs/plans)

Caveman ultra compression + Simplified Technical English guardrails.

- Fragments OK. Tables and lists over prose. Drop filler.
- NEVER alter or drop: file paths, commands, code, numbers, negations, acceptance criteria, verification commands.
- Code blocks unchanged. Clarity wins over compression.
```
- Replace `## Execution Handoff` with:

```markdown
## Execution Handoff

After saving the plan, present it to the user and wait for approval.

Orchestrator execution loop, per logical part:

1. Implement — specialist agent; orchestrator implements config/docs-only parts itself when no specialist fits.
2. Verify — run the plan's verification commands; compare against expected output.
3. `code-reviewer` reviews the part diff — fix findings, re-review until clean.
4. `git-expert` commits the logical part.

Then next part. Tests and review always precede the commit.
```

- [ ] **Step 2: Verify**

Run:
```bash
wc -c skills/writing-plans/SKILL.md
grep -n "superpowers\|worktree\|subagent-driven\|executing-plans\|plan-document-reviewer" skills/writing-plans/SKILL.md || echo "forbidden refs: none"
grep -n "docs/plans/" skills/writing-plans/SKILL.md | wc -l
grep -n "code-reviewer\|git-expert\|wait for approval\|Compact Doc Style" skills/writing-plans/SKILL.md | wc -l
```
Expected: bytes ≤ 7100; `forbidden refs: none`; `docs/plans/` ≥ 1; final keyword count ≥ 4.

- [ ] **Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat(skills): vendor adapted writing-plans skill"
```

---

## Task 4: Vendor `visual-companion` skill + scripts

**Files:**
- Create: `skills/visual-companion/SKILL.md`
- Create: `skills/visual-companion/scripts/{server.cjs,helper.js,frame-template.html,start-server.sh,stop-server.sh}`
- Source: `~/.config/opencode/skills/superpowers/brainstorming/` (`visual-companion.md` + `scripts/`)

**Interfaces:**
- Produces: skill `visual-companion` + runnable scripts. Consumed by Task 9 (install with exec bits) and Task 12 (live check).

- [ ] **Step 1: Copy scripts**

```bash
mkdir -p skills/visual-companion/scripts
cp ~/.config/opencode/skills/superpowers/brainstorming/scripts/server.cjs \
   ~/.config/opencode/skills/superpowers/brainstorming/scripts/helper.js \
   ~/.config/opencode/skills/superpowers/brainstorming/scripts/frame-template.html \
   ~/.config/opencode/skills/superpowers/brainstorming/scripts/start-server.sh \
   ~/.config/opencode/skills/superpowers/brainstorming/scripts/stop-server.sh \
   skills/visual-companion/scripts/
chmod +x skills/visual-companion/scripts/start-server.sh skills/visual-companion/scripts/stop-server.sh
```

- [ ] **Step 2: Strip branding (only edits to vendored scripts)**

`skills/visual-companion/scripts/server.cjs`:
1. Delete line: `const SUPERPOWERS_BRAND_IMAGE_URL = 'https://primeradiant.com/brand/superpowers-visual-brainstorming-logo.png';`
2. Replace whole `brandMarkup()` function with:

```js
function brandMarkup() {
  return '';
}
```

`skills/visual-companion/scripts/frame-template.html`:
3. Replace `<title>Superpowers Brainstorming</title>` with `<title>Brainstorm Companion</title>`.

- [ ] **Step 3: Write `skills/visual-companion/SKILL.md`** — trimmed guide, opencode/Unix only.

Frontmatter:

```markdown
---
name: visual-companion
description: Use when a design or UI question is clearer shown than told — browser mockups, diagrams, side-by-side comparisons during brainstorming. User opt-in per use; offer in its own message.
---
```

Keep from source: `## When to Use` (verbatim); `## How It Works` (verbatim); `## The Loop` (verbatim); `## Writing Content Fragments` (verbatim); `## CSS Classes Available` (verbatim); `## Browser Events Format` (verbatim); `## Design Tips` (verbatim); `## File Naming` (verbatim); `## Cleaning Up` (verbatim); `## Reference` (verbatim); `## Starting a Session` minus platform blocks (drop Claude Code/Codex/Gemini/Copilot/Windows/`run_in_background` paragraphs; keep the `start-server.sh --project-dir … --open` command, the returned JSON fields, `screen_dir`/`state_dir` guidance, the full-URL-with-key paragraph, `$STATE_DIR/server-info` paragraph, `--project-dir` persistence + gitignore reminder, remote-bind `--host 0.0.0.0 --url-host localhost` snippet, `--foreground` note).

Add before `## When to Use`:

```markdown
## Offer Protocol

Offer only when a question is genuinely clearer shown than told: a real mockup, layout, or diagram question — not merely a UI topic.

- First such question: offer in its own message. Only the offer — no question, summary, or other content.
- Opt-in per session. Never start the server before the user accepts.
- Declined: continue text-only. Do not offer again unless the user raises it.

Offer text:

> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. It's still new and can be token-intensive. Want me to? I'll open it for you."

After acceptance: start the server with `--open`, then hand out the complete URL from the `url` field — including the `?key=…` query. Never strip the query string or hand out a bare `http://host:port`.
```

- [ ] **Step 4: Verify**

Run:
```bash
cmp skills/visual-companion/scripts/helper.js ~/.config/opencode/skills/superpowers/brainstorming/scripts/helper.js && echo "helper byte-identical: OK"
cmp skills/visual-companion/scripts/start-server.sh ~/.config/opencode/skills/superpowers/brainstorming/scripts/start-server.sh && echo "start byte-identical: OK"
cmp skills/visual-companion/scripts/stop-server.sh ~/.config/opencode/skills/superpowers/brainstorming/scripts/stop-server.sh && echo "stop byte-identical: OK"
node --check skills/visual-companion/scripts/server.cjs && echo "server syntax: OK"
bash -n skills/visual-companion/scripts/start-server.sh && bash -n skills/visual-companion/scripts/stop-server.sh && echo "shell syntax: OK"
[ -x skills/visual-companion/scripts/start-server.sh ] && [ -x skills/visual-companion/scripts/stop-server.sh ] && echo "exec bits: OK"
grep -n "SUPERPOWERS_BRAND_IMAGE_URL\|obra/superpowers\|Prime Radiant\|Superpowers v\|Superpowers Brainstorming" skills/visual-companion/scripts/server.cjs skills/visual-companion/scripts/frame-template.html || echo "branding: none"
grep -n "Claude Code\|Codex\|Gemini\|Copilot\|Windows" skills/visual-companion/SKILL.md || echo "platform refs: none"
grep -n "own message\|?key=\|\.superpowers/\|--project-dir\|--host 0.0.0.0" skills/visual-companion/SKILL.md | wc -l
```
Expected: all OK lines; `branding: none`; `platform refs: none`; final keyword count ≥ 5.

- [ ] **Step 5: Commit**

```bash
git add skills/visual-companion
git commit -m "feat(skills): vendor visual-companion skill and scripts"
```

---

## Task 5: Trim `caveman` skill

**Files:**
- Create: `skills/caveman/SKILL.md`
- Source: `~/.config/opencode/skills/caveman/SKILL.md` (7 KB; installer ships it full — this file is the overlay)

**Interfaces:**
- Produces: trimmed `caveman` skill. Consumed by Task 9 (copied AFTER every caveman installer run) and the plugin parser (`caveman-config.cjs` reads `skills/caveman/SKILL.md`).

- [ ] **Step 1: Write the file with EXACTLY this content**

````markdown
---
name: caveman
description: Ultra-compressed output mode. Levels lite/full/ultra + wenyan variants. Use for /caveman, "be brief", "less tokens".
---

Respond terse like smart caveman. All technical substance stay. Only fluff die.

## Persistence

Default style every response until "stop caveman" or "normal mode". Default: **full**. Switch: `/caveman lite|full|ultra|wenyan-lite|wenyan-full|wenyan-ultra|off`.

## Rules

Drop articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries, hedging. Fragments OK. No tool-call narration, no emoji, no long raw error-log dumps unless asked. Acronyms OK (DB/API/HTTP); never invent abbreviations (cfg/impl/req/res/fn). No causal arrows (→). Technical terms, code blocks, error strings: exact and unchanged.

Never drop not/never/no/only/except; numbers, units exact. Never ADD words to sound caveman; if caveman phrasing is not shorter than plain, use plain.

Clarity register: mix ASD-STE100 Simplified Technical English, always. One idea per sentence, ≤20 words, active voice. One word one meaning. Instruction = imperative: "Run X". Clarity wins over compression.

Reply in the user's language; compress style, not language. Keep technical terms, code, API names, CLI commands, commit keywords verbatim.

## Intensity

| Level | What change |
|-------|------------|
| **lite** | No filler/hedging. Keep articles + full sentences. Professional, tight |
| **full** | Drop articles, fragments OK, short synonyms. No narration/emoji/log dumps. No invented abbreviations |
| **ultra** | Strip conjunctions when unambiguous. One word enough. Fact once. NO arrows, NO invented abbreviations. Code/API/error strings untouchable |
| **wenyan-lite** | Semi-classical; keep grammar structure, classical register |
| **wenyan-full** | Fully 文言文; 80-90% character reduction, chars not tokens. Verbs precede objects, subjects often omitted |
| **wenyan-ultra** | Extreme abbreviation, classical Chinese feel |

Example "Why React component re-render?"
- full: "New object ref each render. Inline object prop = new ref = re-render. Wrap in `useMemo`."
- ultra: "Inline obj prop, new ref, re-render. `useMemo`."

## Auto-Clarity

Drop caveman for: security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread, compression-created ambiguity, user asks to clarify or repeats. Resume after clear part.

## Boundaries

Persisted outside chat: normal prose for code, comments, commits, docs, issues/PRs, memory files, third-party messages. "stop caveman"/"normal mode": revert. Level persists until changed or session end.
````

- [ ] **Step 2: Verify size + parser format** (`caveman-config.cjs` keeps rows matching `^\|\s*\*\*(\S+?)\*\*\s*\|` and lines matching `^- (\S+?):\s`; all other body lines pass through).

Run:
```bash
wc -c skills/caveman/SKILL.md
grep -c '^| \*\*' skills/caveman/SKILL.md
grep -c '^- ' skills/caveman/SKILL.md
python3 - <<'PY'
import re, pathlib
body = re.sub(r'^---[\s\S]*?---\s*', '', pathlib.Path('skills/caveman/SKILL.md').read_text())
modes = ["lite", "full", "ultra", "wenyan-lite", "wenyan-full", "wenyan-ultra"]
rows = {re.match(r'^\|\s*\*\*(\S+?)\*\*\s*\|', l).group(1) for l in body.split('\n') if re.match(r'^\|\s*\*\*(\S+?)\*\*\s*\|', l)}
examples = {re.match(r'^- (\S+?):\s', l).group(1) for l in body.split('\n') if re.match(r'^- (\S+?):\s', l)}
assert set(modes) <= rows, rows
assert {"full", "ultra"} <= examples, examples
print("parser format: OK")
PY
```
Expected: bytes 2000–2700; table rows count `6`; example lines ≥ `2`; `parser format: OK`.

- [ ] **Step 3: Commit**

```bash
git add skills/caveman/SKILL.md
git commit -m "feat(skills): trim caveman skill for per-request injection"
```

---

## Task 6: Delete `go-review`

**Files:**
- Delete: `skills/go-review/SKILL.md`

- [ ] **Step 1: Remove + verify no refs**

```bash
git rm -r skills/go-review
grep -rn "go-review" agents/ skills/ opencode/ README.md INSTALL.md AGENTS.md || echo "refs: none"
ls skills/go-review 2>/dev/null && echo "STILL PRESENT" || echo "deleted: OK"
```

- [ ] **Step 2: Commit**

```bash
git commit -m "chore(skills): remove unused go-review skill"
```

---

## Task 7: Compact 13 agent prompts + add approval gates

**Files:**
- Modify: `agents/orchestrator.md` (6,771 B → ≤ 4,000 B)
- Modify: 12 specialist files: `software-architect.md`, `go-developer.md`, `java-developer.md`, `frontend-developer.md`, `go-wasm-developer.md`, `github-actions-engineer.md`, `git-expert.md`, `ux-ui-designer.md`, `test-engineer.md`, `code-reviewer.md`, `technical-writer.md`, `security-reviewer.md` (total 45,174 B → ≤ 32,000 B)

**Interfaces:**
- Consumes: skill names from Tasks 2–3.
- Produces: gate wording reused in Task 11 README text.

- [ ] **Step 1: Compress every file.** Simplified Technical English, no semantic loss. Keep: rules, routing table rows, delegation format, specialist-only delegation + leaf-worker clauses, permission/deny statements ("general/explore/build/plan denied"), all acceptance-style constraints. Compress: rationale, repetition, prose. Do not add new rules. Do not add model pins.

- [ ] **Step 2: Orchestrator — replace Step 0** with:

```markdown
## Step 0 — brainstorm first (unless trivial)

Every change request starts with brainstorm: orchestrator + user, via the `brainstorming` skill (vendored). It classifies spike / bounded / architectural and owns the user approval gate. Trivial means single file, known location, direct answer; pure questions/direct answers skip to routing. Never guess; ask.
```

- [ ] **Step 3: Orchestrator — replace the Lifecycle list's steps 1–4** with:

```markdown
1. **Brainstorm** — orchestrator + user, via the `brainstorming` skill. No implementation before user approval.
2. **Architect** — only if the gate above is met (else skip).
3. **UI/UX** — only if UI is involved (else skip).
4. **Spec gate** — `technical-writer` writes the spec to `docs/specs/YYYY-MM-DD-<topic>-design.md`. STOP. User reviews the spec; wait for explicit approval before planning.
5. **Plan gate** — `technical-writer` writes the plan (`writing-plans` skill) to `docs/plans/`. STOP. User reviews the plan; wait for explicit approval before implementation.

Technical-writer authors both spec and plan, always before implementation. Pure questions/direct answers skip the gates.
```

Renumber the following loop/security/final steps 6–8; keep their content.

- [ ] **Step 4: Orchestrator — replace the superpowers skill bullet** in "Task tool — specialist-only delegation" with:

```markdown
- If any loaded skill suggests a general-purpose subagent, ignore that agent choice and substitute the matching specialist. Every other skill instruction still applies.
```

- [ ] **Step 5: Verify**

Run:
```bash
wc -c agents/*.md
grep -rn "superpowers\|cavecrew\|go-review" agents/ || echo "forbidden refs: none"
grep -rn "^model:" agents/ && echo "MODEL PINS: fix" || echo "no model pins: OK"
grep -o "software-architect\|go-developer\|java-developer\|frontend-developer\|go-wasm-developer\|github-actions-engineer\|git-expert\|ux-ui-designer\|test-engineer\|code-reviewer\|technical-writer\|security-reviewer" agents/orchestrator.md | wc -l
grep -n "Spec gate\|Plan gate\|wait for explicit approval\|brainstorming" agents/orchestrator.md | wc -l
```
Expected: orchestrator ≤ 4,000 B; total ≤ 32,000 B; `forbidden refs: none`; `no model pins: OK`; routing-name occurrences ≥ 24; gate lines count ≥ 4.

- [ ] **Step 6: `code-reviewer` semantic-loss review** of the full agents diff. Finding = missing rule, dropped negation, changed commitment. Fix + re-review until clean. (Do not commit before clean.)

- [ ] **Step 7: Commit**

```bash
git add agents/
git commit -m "refactor(agents): compact prompts, add spec and plan approval gates"
```

---

## Task 8: Compact root `AGENTS.md` + doc style rule

**Files:**
- Modify: `AGENTS.md` (1,568 B → ≤ 1,400 B)

- [ ] **Step 1: Rewrite.** Keep: routing section (12 specialist names, `general`/`explore`/`build`/`plan` denial, leaf-worker rule, `@mention` bypass); universal rules (KISS; never assume; minimal-but-extensible; 2+ replicas <5s startup, no state lost; no artificial delays; living documentation; best practices). Drop: superpowers skill names. Add one line:

```markdown
Committed specs and plans: compact doc style — caveman ultra + Simplified Technical English. Fragments OK; tables/lists over prose. Keep verbatim: paths, commands, numbers, negations, acceptance criteria. Code blocks unchanged; clarity wins.
```

- [ ] **Step 2: Verify**

```bash
wc -c AGENTS.md
grep -n "superpowers\|cavecrew\|go-review" AGENTS.md || echo "forbidden refs: none"
grep -o "software-architect\|go-developer\|java-developer\|frontend-developer\|go-wasm-developer\|github-actions-engineer\|git-expert\|ux-ui-designer\|test-engineer\|code-reviewer\|technical-writer\|security-reviewer" AGENTS.md | wc -l
grep -n "compact doc style\|no artificial delays\|2+ replica" AGENTS.md | wc -l
```
Expected: ≤ 1,400 B; `forbidden refs: none`; routing-name occurrences = 12; final keyword count ≥ 3.

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "refactor(agents-md): compact routing guardrail and doc style rule"
```

---

## Task 9: Rewrite updater skill (config merge + install + prune)

**Files:**
- Rewrite: `skills/update-ai-setup/SKILL.md`

**Interfaces:**
- Consumes: skill names (Tasks 2–5), config keys (Task 1), caveman prune list (Task 5 context).
- Produces: merge behavior used by INSTALL (Task 11) and live sync (Task 12); replaces blind `cp` of `opencode.json`.

- [ ] **Step 1: Write the file with EXACTLY this content**

````markdown
---
name: update-ai-setup
description: >
  Use when the user asks to update, upgrade, refresh, reinstall, or sync their
  ai-setup installation — agents, skills, instructions, or config. Trigger
  phrases include "update my ai-setup", "update ai-setup", "refresh my agents",
  "refresh my skills", "sync the AI setup".
---

# Update AI Setup

Refresh an existing ai-setup installation to the repo state. Every step is idempotent — safe to re-run. Assumes `bootstrap.sh` ran at least once.

## Variables

```bash
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/ai-setup")"
```

## Workflow

### 1. Update the repo itself

```bash
cd "$REPO_DIR" && git pull --ff-only
```

No checkout on this machine? Ask where the clone lives; if none, clone it:

```bash
git clone git@github.com:controllan/ai-setup.git ~/ai-setup
```

### 1b. Newer version? (state file decides)

```bash
INSTALLED="$(cat "$OPENCODE_CONFIG/.ai-setup-version" 2>/dev/null || echo "0.0.0")"
REPO_VER="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$REPO_DIR/CHANGELOG.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
[ "$INSTALLED" = "$REPO_VER" ] && echo "already on v$INSTALLED — verify only" || echo "updating v$INSTALLED → v$REPO_VER"
```

Versions match: skip to step 8 (verify-only). Otherwise run steps 2–7; step 8 stamps.

### 2. Merge config (never blind-copy)

Repo wins on defined keys. Live-only keys survive — local providers are never clobbered. Arrays `plugin` and `skills.paths`: repo entries first, then live-only entries, deduped.

```bash
python3 - "$REPO_DIR/opencode/opencode.json" "$OPENCODE_CONFIG/opencode.json" <<'PY'
import json, sys

repo_path, live_path = sys.argv[1], sys.argv[2]
repo = json.load(open(repo_path))
try:
    live = json.load(open(live_path))
except FileNotFoundError:
    live = {}

# Arrays unioned instead of replaced: repo entries first, then live-only entries, deduped.
UNION_PATHS = {("plugin",), ("skills", "paths")}

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
cp "$REPO_DIR/opencode/package.json" "$OPENCODE_CONFIG/package.json"
cd "$OPENCODE_CONFIG" && npm install --no-fund --no-audit
```

### 3. Agents (13 files: orchestrator + 12 specialists, no model pins)

```bash
mkdir -p "$OPENCODE_CONFIG/agents"
cp "$REPO_DIR/agents/"*.md "$OPENCODE_CONFIG/agents/"
```

### 4. Repo skills (7)

```bash
for skill in brainstorming writing-plans visual-companion caveman memory update-ai-setup verifying-github-actions; do
  mkdir -p "$OPENCODE_CONFIG/skills/$skill"
  cp -R "$REPO_DIR/skills/$skill/." "$OPENCODE_CONFIG/skills/$skill/"
done
chmod +x "$OPENCODE_CONFIG/skills/visual-companion/scripts/start-server.sh" \
         "$OPENCODE_CONFIG/skills/visual-companion/scripts/stop-server.sh"
```

### 5. Caveman (installer + overlay + prune)

```bash
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
```

Overlay the trimmed base skill (the installer ships the full 7 KB version):

```bash
cp "$REPO_DIR/skills/caveman/SKILL.md" "$OPENCODE_CONFIG/skills/caveman/SKILL.md"
```

Prune extras + cavecrew + `go-review` after every installer run. Keep `commands/caveman.md`.

```bash
rm -rf "$OPENCODE_CONFIG/skills/caveman-commit" "$OPENCODE_CONFIG/skills/caveman-review" \
       "$OPENCODE_CONFIG/skills/caveman-compress" "$OPENCODE_CONFIG/skills/caveman-help" \
       "$OPENCODE_CONFIG/skills/caveman-stats" "$OPENCODE_CONFIG/skills/cavecrew" \
       "$OPENCODE_CONFIG/skills/go-review"
rm -f "$OPENCODE_CONFIG/commands/caveman-commit.md" "$OPENCODE_CONFIG/commands/caveman-review.md" \
      "$OPENCODE_CONFIG/commands/caveman-compress.md" "$OPENCODE_CONFIG/commands/caveman-help.md" \
      "$OPENCODE_CONFIG/commands/caveman-stats.md"
rm -f "$OPENCODE_CONFIG/agents/cavecrew-builder.md" "$OPENCODE_CONFIG/agents/cavecrew-investigator.md" \
      "$OPENCODE_CONFIG/agents/cavecrew-reviewer.md"
```

Needs Node ≥18. Safe to re-run.

### 6. Remove superpowers artifacts

```bash
rm -rf "$OPENCODE_CONFIG/superpowers" "$OPENCODE_CONFIG/skills/superpowers"
rm -f "$OPENCODE_CONFIG/plugins/superpowers.js"
```

### 7. AGENTS.md routing guardrail

Offer to copy it into the current project — ask first, never overwrite an existing project `AGENTS.md` without confirmation:

```bash
cp "$REPO_DIR/AGENTS.md" /path/to/your/project/AGENTS.md
```

### 8. Verify + stamp

```bash
python3 -m json.tool "$OPENCODE_CONFIG/opencode.json" >/dev/null && echo "config JSON: OK" || echo "config JSON: INVALID"
python3 - "$OPENCODE_CONFIG/opencode.json" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
assert cfg["mcp"]["sonarqube"]["enabled"] is False, "sonarqube must be disabled"
assert cfg["plugin"][:2] == ["./plugins/caveman/plugin.js", "opencode-cmd-provider"], cfg["plugin"]
for provider in ("ollama", "omlx", "mtplx", "mlx-lm"):
    assert provider in cfg["provider"], "local provider lost: " + provider
print("config merge: OK")
PY
for skill in brainstorming writing-plans visual-companion caveman memory update-ai-setup verifying-github-actions; do
  [ -f "$OPENCODE_CONFIG/skills/$skill/SKILL.md" ] && echo "$skill: OK" || echo "$skill: MISSING"
done
[ -x "$OPENCODE_CONFIG/skills/visual-companion/scripts/start-server.sh" ] && echo "companion scripts: OK" || echo "companion scripts: MISSING"
[ ! -e "$OPENCODE_CONFIG/superpowers" ] && [ ! -e "$OPENCODE_CONFIG/skills/superpowers" ] && [ ! -e "$OPENCODE_CONFIG/plugins/superpowers.js" ] && echo "superpowers removed: OK" || echo "superpowers artifacts: FOUND"
[ ! -e "$OPENCODE_CONFIG/skills/cavecrew" ] && [ ! -e "$OPENCODE_CONFIG/skills/caveman-commit" ] && [ ! -e "$OPENCODE_CONFIG/skills/go-review" ] && echo "prune: OK" || echo "prune: INCOMPLETE"
ls "$OPENCODE_CONFIG/agents/"*.md | wc -l   # expect 13
grep -rn "^model:" "$OPENCODE_CONFIG/agents/" && echo "MODEL PINS: fix" || echo "no model pins: OK"
```

On success, stamp the version:

```bash
echo "$REPO_VER" > "$OPENCODE_CONFIG/.ai-setup-version"
```

## Releasing a new version (maintainer — inside the ai-setup repo)

Every finished feature branch that changes the stack ends with a release:

1. **Determine the bump** from conventional commits since the last tag:
   ```bash
   git fetch --tags
   git log "$(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)"..HEAD --pretty=format:'%s'
   ```
   `feat!`/`BREAKING CHANGE` → major, `feat` → minor, anything else → patch.
2. **CHANGELOG.md**: move the `## [Unreleased]` entries under a new `## [X.Y.Z] - YYYY-MM-DD` heading; leave a fresh empty `## [Unreleased]` on top.
3. **Commit, tag, push**: `docs: release vX.Y.Z`, then `git tag vX.Y.Z && git push --follow-tags`.
4. **GitHub release** (needs `gh auth status` green):
   ```bash
   gh release create "vX.Y.Z" --title "vX.Y.Z" --notes "See CHANGELOG.md"
   ```

Users pick the release up automatically next time they say "update my ai-setup".

## Rules

- Ask before overwriting a project's `AGENTS.md` or installing anything the user previously declined.
- Never commit or print secrets (`.secrets/` contents stay private).
- End with a compact OK/MISSING table. Tell the user to restart their opencode session so the new agents, skills, and config take effect.
````

- [ ] **Step 2: Verify skill file + merge behavior**

Run:
```bash
awk '/^python3 - /{flag=1;next} flag && /^PY$/{exit} flag' skills/update-ai-setup/SKILL.md > /tmp/ai-setup-merge.py
grep -c "UNION_PATHS" /tmp/ai-setup-merge.py
cp ~/.config/opencode/opencode.json /tmp/merge-live.json
python3 /tmp/ai-setup-merge.py opencode/opencode.json /tmp/merge-live.json
python3 -c "import json;d=json.load(open('/tmp/merge-live.json'));assert all(p in d['provider'] for p in ('ollama','omlx','mtplx','mlx-lm')),'provider lost';assert d['mcp']['sonarqube']['enabled'] is False,'sonarqube enabled';assert d['plugin'][:2]==['./plugins/caveman/plugin.js','opencode-cmd-provider'],d['plugin'];print('merge live config: OK')"
cp /tmp/merge-live.json /tmp/merge-live.1.json
python3 /tmp/ai-setup-merge.py opencode/opencode.json /tmp/merge-live.json
cmp /tmp/merge-live.1.json /tmp/merge-live.json && echo "merge idempotent: OK"
printf '%s\n' '{"plugin":["a","b"],"skills":{"paths":["/repo","/both"]}}' > /tmp/merge-repo.json
printf '%s\n' '{"plugin":["b","c"],"skills":{"paths":["/both","/live"]}}' > /tmp/merge-fake.json
python3 /tmp/ai-setup-merge.py /tmp/merge-repo.json /tmp/merge-fake.json
python3 -c "import json;d=json.load(open('/tmp/merge-fake.json'));assert d['plugin']==['a','b','c'],d['plugin'];assert d['skills']['paths']==['/repo','/both','/live'],d['skills']['paths'];print('union order+dedupe: OK')"
rm -f /tmp/ai-setup-merge.py /tmp/merge-live.json /tmp/merge-live.1.json /tmp/merge-repo.json /tmp/merge-fake.json
grep -n "superpowers\|cavecrew" skills/update-ai-setup/SKILL.md | grep -vE '\$OPENCODE_CONFIG|Remove superpowers|Prune extras' || echo "stale refs: none"
```
Expected: `UNION_PATHS` count `1`; `merge live config: OK`; `merge idempotent: OK`; `union order+dedupe: OK`; `stale refs: none`. (The live-config merge test needs Task 1 committed — repo config must already carry `mcp.sonarqube` disabled.)

- [ ] **Step 3: Commit**

```bash
git add skills/update-ai-setup/SKILL.md
git commit -m "feat(updater): deep-merge config, install vendored skills, prune legacy artifacts"
```

---

## Task 10: Move docs to new layout

**Files:**
- Move: `docs/superpowers/specs/2026-09-02-agent-team-design.md`, `docs/superpowers/specs/2026-09-10-orchestrator-design.md` → `docs/specs/`
- Move: `docs/superpowers/plans/2026-09-10-orchestrator.md` → `docs/plans/`
- Modify: `README.md` (link only; full README rewrite is Task 11)

**Interfaces:**
- Consumes: new layout used by Tasks 2–3 skills, Task 7 gates.

- [ ] **Step 1: git mv**

```bash
git mv docs/superpowers/specs/2026-09-02-agent-team-design.md docs/specs/
git mv docs/superpowers/specs/2026-09-10-orchestrator-design.md docs/specs/
git mv docs/superpowers/plans/2026-09-10-orchestrator.md docs/plans/
rmdir docs/superpowers/specs docs/superpowers/plans docs/superpowers
```

- [ ] **Step 2: Update refs** — `README.md`: link `docs/superpowers/specs/2026-09-02-agent-team-design.md` → `docs/specs/2026-09-02-agent-team-design.md`. No other functional refs exist (moved docs are historical records; CHANGELOG documents the move).

- [ ] **Step 3: Verify**

```bash
grep -rn "docs/superpowers" README.md INSTALL.md AGENTS.md agents/ skills/ || echo "old paths: none"
[ ! -e docs/superpowers ] && echo "old dir: gone"
ls docs/specs docs/plans
```
Expected: `old paths: none`; `old dir: gone`; `docs/specs` holds 3 files; `docs/plans` holds 2 files.

- [ ] **Step 4: Commit**

```bash
git add -A README.md docs/
git commit -m "docs: move specs and plans to docs/specs and docs/plans"
```

---

## Task 11: Update README, INSTALL, CHANGELOG (0.2.0)

**Files:**
- Modify: `README.md`, `INSTALL.md`, `CHANGELOG.md`

- [ ] **Step 1: README.**
  - Tagline: `Complete AI development environment — **OpenCode + Agents + Workflow Skills + Caveman + MCP**, fully reproducible via a two-phase installation.`
  - Components table: drop the Superpowers row; add `**Workflow skills** | brainstorming, writing-plans, visual-companion — vendored + adapted | Local skills`; Caveman row note trimmed base; MCP row: `Obsidian; SonarQube opt-in (disabled by default) | uvx mcp-obsidian; sonarsource/sonarqube-mcp`.
  - Agents intro: lifecycle text becomes `brainstorm (brainstorming skill) → spec + user approval → writing-plans plan + user approval → per-logical-part loop (implement + e2e test → review → commit) → security review per finished feature/component/phase`.
  - Design-rationale link → `docs/specs/2026-09-02-agent-team-design.md`.
  - Phase 2 table: 4 = copy 7 skills; 5 = caveman installer + overlay + prune; 6 = remove legacy Superpowers artifacts; 7 = verify; 8 = manual steps.
  - After Phase 2: point 2 add `Optional: SonarQube — write your token to ~/.config/opencode/.secrets/sonarqube-token, then enable per project.`; point 4 → `run opencode` (drop "do you have superpowers?").
  - Directory layout: replace tree with:

```
~/.config/opencode/
├── opencode.json           # Main config (agents, MCP, plugins)
├── package.json            # Plugin deps
├── agents/                 # 13 agent definitions (orchestrator + 12 specialists)
├── skills/                 # 7 skills
│   ├── brainstorming/
│   ├── writing-plans/
│   ├── visual-companion/   # browser mockups (+ scripts/)
│   ├── caveman/
│   ├── memory/
│   ├── update-ai-setup/
│   └── verifying-github-actions/
└── plugins/
    └── caveman/            # caveman plugin
```

  - Updating: note deep-merge (`repo wins; local providers survive; arrays unioned`); delete the Superpowers `git pull` snippet.
  - Troubleshooting: replace the two superpowers sections with `SonarQube tools missing` (disabled by default; project `opencode.json` with `{"mcp":{"sonarqube":{"enabled":true}}}`; token file `~/.config/opencode/.secrets/sonarqube-token`), `Skills not found` (`ls ~/.config/opencode/skills` → expect 7 dirs), and `Caveman mode not switching` (`plugin` array contains `./plugins/caveman/plugin.js`; `~/.config/opencode/skills/caveman/SKILL.md` exists; restart opencode). Keep `npm install` section.

- [ ] **Step 2: INSTALL.**
  - Step 2 note: fresh install copies config; existing installs use the updater deep-merge (local providers survive).
  - Step 4 → install 7 repo skills:

```bash
mkdir -p "$OPENCODE_CONFIG/skills"
for skill in brainstorming writing-plans visual-companion caveman memory update-ai-setup verifying-github-actions; do
  mkdir -p "$OPENCODE_CONFIG/skills/$skill"
  cp -R "$REPO_DIR/skills/$skill/." "$OPENCODE_CONFIG/skills/$skill/"
done
chmod +x "$OPENCODE_CONFIG/skills/visual-companion/scripts/start-server.sh" \
         "$OPENCODE_CONFIG/skills/visual-companion/scripts/stop-server.sh"
```

  - Step 4b → official installer, then overlay trimmed base, then prune; text: extras + cavecrew pruned after every installer run; `commands/caveman.md` kept.

```bash
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
cp "$REPO_DIR/skills/caveman/SKILL.md" "$OPENCODE_CONFIG/skills/caveman/SKILL.md"
rm -rf "$OPENCODE_CONFIG/skills/caveman-commit" "$OPENCODE_CONFIG/skills/caveman-review" \
       "$OPENCODE_CONFIG/skills/caveman-compress" "$OPENCODE_CONFIG/skills/caveman-help" \
       "$OPENCODE_CONFIG/skills/caveman-stats" "$OPENCODE_CONFIG/skills/cavecrew"
rm -f "$OPENCODE_CONFIG/commands/caveman-commit.md" "$OPENCODE_CONFIG/commands/caveman-review.md" \
      "$OPENCODE_CONFIG/commands/caveman-compress.md" "$OPENCODE_CONFIG/commands/caveman-help.md" \
      "$OPENCODE_CONFIG/commands/caveman-stats.md"
rm -f "$OPENCODE_CONFIG/agents/cavecrew-builder.md" "$OPENCODE_CONFIG/agents/cavecrew-investigator.md" \
      "$OPENCODE_CONFIG/agents/cavecrew-reviewer.md"
```

  - Step 5 → `Remove legacy Superpowers artifacts`:

```bash
rm -rf "$OPENCODE_CONFIG/superpowers" "$OPENCODE_CONFIG/skills/superpowers"
rm -f "$OPENCODE_CONFIG/plugins/superpowers.js"
```

  - Step 9 → replace superpowers checks with: 7-skill presence loop, `[ ! -e "$OPENCODE_CONFIG/superpowers" ]`, `grep -q '"sonarqube"' "$OPENCODE_CONFIG/opencode.json"`, `grep -q '"enabled": false'` pattern via python3 assert (`mcp.sonarqube.enabled is False`).
  - Step 11 point 3 → `run opencode`.

- [ ] **Step 3: CHANGELOG** — replace `## [Unreleased]` section with:

```markdown
## [Unreleased]

## [0.2.0] - 2026-09-28

### Breaking

- Superpowers removed: clone, skills symlink, plugin symlink. `brainstorming`,
  `writing-plans`, `visual-companion` are vendored + adapted instead (compact
  doc style, explicit spec/plan user approval gates).
- Caveman extras pruned: `caveman-commit`, `caveman-review`, `caveman-compress`,
  `caveman-help`, `caveman-stats` skills + commands; cavecrew skill + 3 agents.
  `/caveman` command and the trimmed base skill stay.
- SonarQube MCP is opt-in: committed `"enabled": false`; enable per project via
  project `opencode.json`.
- Docs moved: `docs/superpowers/{specs,plans}` → `docs/specs`, `docs/plans`.

### Added

- Updater deep-merges `opencode.json`: repo wins, live-only provider keys
  survive, `plugin` and `skills.paths` arrays unioned.
- Repo config lists plugins `./plugins/caveman/plugin.js` and
  `opencode-cmd-provider`.
- Compact doc style for committed specs/plans (caveman ultra + Simplified
  Technical English).

### Removed

- `skills/go-review/` (unreferenced; recoverable from git history).
```

- [ ] **Step 4: Verify**

```bash
grep -rn "superpowers" README.md INSTALL.md || echo "superpowers refs: none"
grep -n "sonarqube\|SonarQube" README.md INSTALL.md | wc -l
grep -n "docs/specs/2026-09-02-agent-team-design.md" README.md
grep -n "## \[0.2.0\] - 2026-09-28" CHANGELOG.md
grep -n "do you have superpowers" README.md INSTALL.md || echo "legacy prompt: gone"
```
Expected: `superpowers refs: none`; SonarQube mentions ≥ 4; README link present; CHANGELOG heading present; `legacy prompt: gone`.

- [ ] **Step 5: Commit**

```bash
git add README.md INSTALL.md CHANGELOG.md
git commit -m "docs: rebrand for 0.2.0, document opt-in sonarqube and deep-merge updater"
```

---

## Task 12: Sync live machine + restart (checkpoint)

**Files:** none in repo — machine-local: `~/.config/opencode/`

**Interfaces:**
- Consumes: all repo changes (Tasks 1–11).
- Produces: live install on 0.2.0.

- [ ] **Step 1: Back up live config**

```bash
cp ~/.config/opencode/opencode.json /tmp/ai-setup-config-backup.json
```

- [ ] **Step 2: Run updater steps 1b–6 and 8** from `skills/update-ai-setup/SKILL.md` against `~/.config/opencode` (skip step 7, the project-copy offer; version gate expects `updating v0.1.0 → v0.2.0`).

- [ ] **Step 3: Verify live**

```bash
python3 -m json.tool ~/.config/opencode/opencode.json >/dev/null && echo "config JSON: OK"
python3 -c "import json;d=json.load(open('$HOME/.config/opencode/opencode.json'));assert all(p in d['provider'] for p in ('ollama','omlx','mtplx','mlx-lm')),'provider lost';assert d['mcp']['sonarqube']['enabled'] is False;assert d['plugin'][:2]==['./plugins/caveman/plugin.js','opencode-cmd-provider'];print('live merge: OK')"
ls ~/.config/opencode/skills
[ ! -e ~/.config/opencode/superpowers ] && [ ! -e ~/.config/opencode/skills/superpowers ] && [ ! -e ~/.config/opencode/plugins/superpowers.js ] && echo "superpowers removed: OK"
[ ! -e ~/.config/opencode/skills/cavecrew ] && [ ! -e ~/.config/opencode/skills/caveman-commit ] && [ ! -e ~/.config/opencode/skills/go-review ] && echo "prune: OK"
ls ~/.config/opencode/agents/*.md | wc -l   # expect 13
cat ~/.config/opencode/.ai-setup-version    # expect 0.2.0
wc -c ~/.config/opencode/skills/caveman/SKILL.md   # expect 2000–2700
```
Expected: `live merge: OK`; skills listing = `brainstorming caveman memory update-ai-setup verifying-github-actions visual-companion writing-plans`; removal/prune OK; agents `13`; version `0.2.0`; caveman bytes in range.

- [ ] **Step 4: Idempotence — run updater steps 2–6 and 8 a second time**

```bash
find ~/.config/opencode/skills -maxdepth 2 -name SKILL.md | sort > /tmp/ai-setup-after-first.txt
cp ~/.config/opencode/opencode.json /tmp/ai-setup-second.json
# run steps 2-6 and 8 again from SKILL.md
cmp /tmp/ai-setup-second.json ~/.config/opencode/opencode.json && echo "second run config: unchanged"
find ~/.config/opencode/skills -maxdepth 2 -name SKILL.md | sort | diff /tmp/ai-setup-after-first.txt - && echo "second run skills list: unchanged"
```
Expected: `second run config: unchanged`; `second run skills list: unchanged`.

- [ ] **Step 5: CHECKPOINT — user action required.** Tell the user: **restart opencode** so agents, skills, and config reload. Then verify in the new session: `/caveman full` switches mode and a fresh session starts clean.

---

## Task 13: Release v0.2.0 (checkpoint)

**Files:** none — tag + GitHub release.

- [ ] **Step 1: Preconditions**

```bash
git status --porcelain          # expect empty
git log --oneline -3
grep -n "## \[0.2.0\] - 2026-09-28" CHANGELOG.md
gh auth status
```
Expected: clean tree; `## [0.2.0] - 2026-09-28` present; `gh auth status` authenticated. If work happened on a feature branch, `git-expert` merges it to `main` first.

- [ ] **Step 2: CHECKPOINT — ask the user to confirm the release before pushing.**

- [ ] **Step 3: Tag + push + release**

```bash
git push origin main
git tag v0.2.0
git push --follow-tags
gh release create v0.2.0 --title "v0.2.0" --notes "See CHANGELOG.md"
```

- [ ] **Step 4: Verify**

```bash
git tag --list v0.2.0
gh release view v0.2.0 --json tagName,url
```
Expected: tag `v0.2.0`; release exists.

---

## Execution Handoff

Commit this plan first (via `git-expert`):

```bash
git add docs/plans/2026-09-28-minimal-context-setup.md
git commit -m "docs(plans): add minimal context setup implementation plan"
```

Then per logical part (Tasks 1–13):

1. Implement — specialist agent; orchestrator implements config/docs-only parts itself when no specialist fits.
2. Verify — run the task's verification commands; compare against expected output.
3. `code-reviewer` reviews the part diff — fix findings, re-review until clean.
4. `git-expert` commits the logical part.

Then next part. Tasks 12 and 13 are checkpoints: user restart (12) and user release confirmation (13). No superpowers sub-skills, no worktrees.
