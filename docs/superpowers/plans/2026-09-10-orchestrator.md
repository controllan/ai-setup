# Orchestrator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `agents/orchestrator.md` as the primary routing agent and normalize all 12 agent frontmatters to description + mode + model only, with muse-spark-1.3 on the high tier and mimo-v2.5 on the low tier.

**Architecture:** One new primary agent file embeds Step-0 brainstorming, the conditional architect gate, the intent routing table, and the three lifecycle flows; eleven existing specialist files get frontmatter-only edits (strip `temperature`/`permission`, retier `model`). README count and table updated; INSTALL needs no edit (verified below).

**Tech Stack:** OpenCode agent markdown frontmatter (`description`, `mode`, `model`), bash/grep verification, no code changes.

---

## File structure

| File | Action | Responsibility |
|------|--------|----------------|
| `agents/orchestrator.md` | Create | Primary entrypoint: Step-0 brainstorm, routing table, lifecycle flows, best-guess rule, delegation format |
| `agents/software-architect.md` | Modify frontmatter only | High tier model, strip temperature/permissions |
| `agents/code-reviewer.md` | Modify frontmatter only | High tier model, strip temperature/permissions |
| `agents/security-reviewer.md` | Modify frontmatter only | High tier model, strip temperature/permissions |
| `agents/go-developer.md` | Modify frontmatter only | Low tier model (already mimo-v2.5), strip permissions |
| `agents/java-developer.md` | Modify frontmatter only | Low tier model (already mimo-v2.5), strip permissions |
| `agents/frontend-developer.md` | Modify frontmatter only | Low tier model (already mimo-v2.5), strip permissions |
| `agents/go-wasm-developer.md` | Modify frontmatter only | Low tier model (already mimo-v2.5), strip permissions |
| `agents/github-actions-engineer.md` | Modify frontmatter only | Low tier model (already mimo-v2.5), strip permissions |
| `agents/git-expert.md` | Modify frontmatter only | Migrate deepseek-v4-flash → mimo-v2.5, strip temperature/permissions |
| `agents/ux-ui-designer.md` | Modify frontmatter only | Low tier model (already mimo-v2.5), strip permissions |
| `agents/test-engineer.md` | Modify frontmatter only | Low tier model (already mimo-v2.5), strip permissions |
| `opencode/opencode.json` | Modify only if high-tier ID missing | Register muse-spark-1.3 model limits alongside the 1.2 entry |
| `README.md` | Modify | Agent count 11 → 12, orchestrator table row |
| `INSTALL.md` | No change | Verified: Step 3 uses `*.md` glob, Step 9 counts via `wc -l` with no hardcoded number |

Model constants used throughout this plan: `HIGH = opencode-go/muse-spark-1.3`, `LOW = opencode-go/mimo-v2.5`. If Task 1 resolves a different provider-qualified ID for muse-spark-1.3, substitute it everywhere.

---

### Task 1: Resolve and register the high-tier model ID

**Files:**
- Modify: `opencode/opencode.json` (only if the 1.3 ID is absent)
- Test: shell verification commands

- [ ] **Step 1: Check which muse-spark IDs the config already knows**

Run: `grep -n "muse-spark" opencode/opencode.json`
Expected: one hit — `muse-spark-1.2-contributor` (line ~27). No 1.3 entry exists, so registration is required.

- [ ] **Step 2: Register the 1.3 model limits entry**

Old string in `opencode/opencode.json`:
```json
"muse-spark-1.2-contributor": { "limit": { "context": 262144, "output": 131072 } },
```
New string:
```json
"muse-spark-1.2-contributor": { "limit": { "context": 262144, "output": 131072 } },
"muse-spark-1.3": { "limit": { "context": 262144, "output": 131072 } },
```
Rationale: mirror the 1.2 limits exactly; adjust only if the provider documents different limits for 1.3. If the provider exposes 1.3 under a different ID (e.g. a `-contributor` suffix variant), use that exact ID as HIGH everywhere in Tasks 2–3 instead.

- [ ] **Step 3: Verify the JSON still parses**

Run: `python3 -c "import json; json.load(open('opencode/opencode.json')); print('JSON OK')"`
Expected: `JSON OK`

- [ ] **Step 4: Commit**

```bash
git add opencode/opencode.json
git commit -m "feat(agents): register muse-spark-1.3 model for high-tier agents"
```

---

### Task 2: Create the orchestrator primary agent

**Files:**
- Create: `agents/orchestrator.md`
- Test: frontmatter parse + content checks (see steps)

- [ ] **Step 1: Create `agents/orchestrator.md` with this exact content**

```markdown
---
description: Primary orchestrator — routes requests to the 11 specialist subagents, enforces team lifecycle. Default entrypoint.
mode: primary
model: opencode-go/muse-spark-1.3
---

You are the orchestrator, the default entrypoint. You route every request to the right specialist subagent(s) and enforce the team lifecycle. You delegate work; you do not implement directly when a specialist owns the task.

## Non-negotiable rules

1. **KISS** — simplest solution that satisfies the spec. No speculative features, no premature abstractions.
2. **Never assume** — if the spec is unclear, incomplete, or contradictory: STOP and ask. Do not guess.
3. **Minimal but extensible** — smallest implementation that works and can grow. Meaningful tradeoffs → present options and ask.
4. **Scalability** — every design must run with 2+ replicas: no state lost on crash, new instances ready in <5s (ideally <1s).
5. **Responsiveness** — never add artificial delays (sleeps, fixed waits) to code, scripts, or tests.
6. **Living documentation** — docs updated with every change; docs are part of the deliverable.
7. **Best practices** — prefer common, established approaches over invention.

## Step 0 — brainstorm first (unless trivial)

Every non-trivial request starts with brainstorming: restate intent, clarify only what blocks routing, sketch 2–3 approaches with trade-offs before delegating. Trivial means single file, known location, direct answer — skip to routing.

## Architect gate (conditional, not mandatory)

Invoke `software-architect` only for greenfield projects, architectural decisions, design, restructure/re-design, or architecture guidance/questions. All other requests route direct to the relevant specialist — never force architect into the chain.

## Routing table

| Signal | Agent(s) |
|--------|----------|
| New project, concept, ADRs, OpenAPI, mermaid, module boundaries (gate above met) | `software-architect` |
| Go / go-gin REST, franz-go Kafka, JSON logging | `go-developer` |
| Quarkus, Maven, JUnit 5, Panache, Kafka/IBM MQ/Postgres (Java) | `java-developer` |
| TypeScript, Next.js/React/Angular, CSS, jest, pnpm | `frontend-developer` (+ `ux-ui-designer` when UI spec/theming/flows needed) |
| Go browser UI, go-app WASM | `go-wasm-developer` |
| `.github/workflows`, SonarQube/CodeQL gates, SemVer releases | `github-actions-engineer` |
| Test strategy, unit/integration/e2e, playwright journeys | `test-engineer` |
| Review request (quality/KISS/scalability/docs) | `code-reviewer` + `security-reviewer` in parallel |
| Commits, branching, tags, `.gitignore` | `git-expert` |
| UI spec, themes (dark default/light), minimal clicks, icon-first, info tooltips | `ux-ui-designer` |
| Multi-match, independent work | Parallel fan-out, synthesize results |

## Flows

- **Greenfield:** Step 0 → architect → ux-ui-designer (if UI) → developers in parallel → test-engineer → code-reviewer + security-reviewer in parallel → fixes → git-expert.
- **Feature/fix:** Step 0 → architect-lite only if the gate is met (else skip) → developer → test-engineer → reviewers → git-expert.
- **Single-shot:** Step 0 (light) → one agent (or parallel reviewers) → done. No forced chaining.
- Test + review always precede git-expert in chained flows.

## Ambiguity — best-guess, never block

On ambiguous requests proceed with the best-guess agent(s) plus a one-line assumption note (e.g. "Routing to go-developer — assuming gin REST; correct me if Quarkus."). Direct `@mention` from the user always bypasses routing.

## Delegation format

Each delegation states: goal with success criteria, file paths and scope boundaries, existing patterns to follow, what is out of scope. Verify results before reporting done: diagnostics clean on changed files, build/test output when applicable.

```

- [ ] **Step 2: Verify frontmatter parses and mode is primary**

Run: `python3 -c "import yaml; d=yaml.safe_load(open('agents/orchestrator.md').read().split('---')[1]); print(d)"`
Expected: `{'description': ..., 'mode': 'primary', 'model': 'opencode-go/muse-spark-1.3'}` — exactly three keys, no `temperature`, no `permission`.

- [ ] **Step 3: Commit**

```bash
git add agents/orchestrator.md
git commit -m "feat(agents): add primary orchestrator for specialist routing"
```

---

### Task 3: Retier the high-tier specialists (architect + reviewers)

**Files:**
- Modify: `agents/software-architect.md`, `agents/code-reviewer.md`, `agents/security-reviewer.md` (frontmatter only — bodies untouched)
- Test: grep checks in Task 6

- [ ] **Step 1: Rewrite `agents/software-architect.md` frontmatter**

Old string:
```markdown
---
description: Senior software architect — concepts, architecture docs, mermaid diagrams, ADRs, module boundaries, API contracts, scalability design. First step on greenfield projects.
mode: subagent
model: opencode-go/glm-5.3-flash
temperature: 0.2
permission:
  edit: allow
  bash: ask
  webfetch: allow
---
```
New string:
```markdown
---
description: Senior software architect — concepts, architecture docs, mermaid diagrams, ADRs, module boundaries, API contracts, scalability design. First step on greenfield projects.
mode: subagent
model: opencode-go/muse-spark-1.3
---
```

- [ ] **Step 2: Rewrite `agents/code-reviewer.md` frontmatter**

Old string:
```markdown
---
description: Code reviewer — reviews code AND tests for quality, simplicity, scalability, responsiveness, and documentation. Read-only; findings with severity, location, and concrete fix.
mode: subagent
model: opencode-go/glm-5.3-flash
temperature: 0.1
permission:
  edit: deny
  bash: ask
  webfetch: allow
---
```
New string:
```markdown
---
description: Code reviewer — reviews code AND tests for quality, simplicity, scalability, responsiveness, and documentation. Read-only; findings with severity, location, and concrete fix.
mode: subagent
model: opencode-go/muse-spark-1.3
---
```

- [ ] **Step 3: Rewrite `agents/security-reviewer.md` frontmatter**

Old string:
```markdown
---
description: Security reviewer — audits code for vulnerabilities, backdoors, and exploits; pnpm/maven supply-chain attack prevention. Read-only; findings with severity and remediation.
mode: subagent
model: opencode-go/glm-5.3-flash
temperature: 0.1
permission:
  edit: deny
  bash: ask
  webfetch: allow
---
```
New string:
```markdown
---
description: Security reviewer — audits code for vulnerabilities, backdoors, and exploits; pnpm/maven supply-chain attack prevention. Read-only; findings with severity and remediation.
mode: subagent
model: opencode-go/muse-spark-1.3
---
```

- [ ] **Step 4: Commit**

```bash
git add agents/software-architect.md agents/code-reviewer.md agents/security-reviewer.md
git commit -m "feat(agents): retier architect and reviewers to muse-spark-1.3, drop temperature and permissions"
```

---

### Task 4: Normalize the low-tier specialists to mimo-v2.5

**Files:**
- Modify: `agents/go-developer.md`, `agents/java-developer.md`, `agents/frontend-developer.md`, `agents/go-wasm-developer.md`, `agents/github-actions-engineer.md`, `agents/git-expert.md`, `agents/ux-ui-designer.md`, `agents/test-engineer.md` (frontmatter only — bodies untouched)

- [ ] **Step 1: Strip the permission block from the seven files that already use mimo-v2.5**

For each of `agents/go-developer.md`, `agents/java-developer.md`, `agents/frontend-developer.md`, `agents/go-wasm-developer.md`, `agents/github-actions-engineer.md`, run: remove these exact four lines from the frontmatter, keeping `description`, `mode: subagent`, and the existing `model: opencode-go/mimo-v2.5` line untouched:
```markdown
permission:
  edit: allow
  bash: allow
  webfetch: allow
```
For `agents/ux-ui-designer.md`, remove these exact four lines instead (note `bash: ask`):
```markdown
permission:
  edit: allow
  bash: ask
  webfetch: allow
```
For `agents/test-engineer.md`, remove these exact four lines:
```markdown
permission:
  edit: allow
  bash: allow
  webfetch: allow
```
Resulting frontmatter example (`agents/go-developer.md`):
```markdown
---
description: Senior Go developer — REST backends with go-gin, Kafka consumers/producers with franz-go, JSON logging, table-driven tests. Implements what the architect specified.
mode: subagent
model: opencode-go/mimo-v2.5
---
```

- [ ] **Step 2: Migrate `agents/git-expert.md` off deepseek**

Old string:
```markdown
---
description: Git expert — conventional commits, logical component commits, branching strategy, SemVer tags, .gitignore hygiene. Read-only on code, acts through git.
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.1
permission:
  edit: deny
  bash: allow
  webfetch: deny
---
```
New string:
```markdown
---
description: Git expert — conventional commits, logical component commits, branching strategy, SemVer tags, .gitignore hygiene. Read-only on code, acts through git.
mode: subagent
model: opencode-go/mimo-v2.5
---
```

- [ ] **Step 3: Commit**

```bash
git add agents/go-developer.md agents/java-developer.md agents/frontend-developer.md agents/go-wasm-developer.md agents/github-actions-engineer.md agents/git-expert.md agents/ux-ui-designer.md agents/test-engineer.md
git commit -m "feat(agents): normalize low tier to mimo-v2.5, drop temperature and permissions"
```

---

### Task 5: Update README (INSTALL verified no-change)

**Files:**
- Modify: `README.md`
- Test: grep count checks in Task 6

- [ ] **Step 1: Update the component table row**

Old string:
```markdown
| **11 Agents** | Specialist engineering team (architect, devs, test, reviewers) | Custom |
```
New string:
```markdown
| **12 Agents** | Orchestrator + 11 specialists (architect, devs, test, reviewers) | Custom |
```

- [ ] **Step 2: Add the orchestrator row at the top of the agent table**

Old string:
```markdown
| Agent | When to use |
|-------|-------------|
| `software-architect` | First step on greenfield projects: concept, architecture (mermaid), ADRs, OpenAPI contracts, handoff plan |
```
New string:
```markdown
| Agent | When to use |
|-------|-------------|
| `orchestrator` | Default entrypoint: brainstorms, then auto-routes to the right specialist(s) and enforces the team lifecycle |
| `software-architect` | Only on greenfield / architectural decisions / design / restructure / architecture guidance: concept, architecture (mermaid), ADRs, OpenAPI contracts, handoff plan |
```

- [ ] **Step 3: Update the Phase 2 copy-count row**

Old string:
```markdown
| 3 | Copy 11 agent files → `~/.config/opencode/agents/` |
```
New string:
```markdown
| 3 | Copy 12 agent files → `~/.config/opencode/agents/` |
```

- [ ] **Step 4: Update the directory layout comment**

Old string:
```
├── agents/                 # 11 subagent definitions
```
New string:
```
├── agents/                 # 12 agent definitions (orchestrator + 11 specialists)
```

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: register orchestrator as default entrypoint, 11 to 12 agents"
```

---

### Task 6: Verify the whole agent set

**Files:** none (verification only)

- [ ] **Step 1: Confirm 12 agent files exist**

Run: `ls agents/*.md | wc -l`
Expected: `12`

- [ ] **Step 2: Confirm no temperature or permission keys remain**

Run: `grep -rn "temperature\|permission" agents/ || echo CLEAN`
Expected: `CLEAN`

- [ ] **Step 3: Confirm exactly two model tiers with the right split**

Run: `grep -h "^model:" agents/*.md | sort | uniq -c`
Expected:
```
4 opencode-go/muse-spark-1.3
8 opencode-go/mimo-v2.5
```
(Substitute the Task-1-resolved HIGH ID on the first line if it differs.)

- [ ] **Step 4: Confirm every frontmatter parses with exactly three keys**

Run: `python3 -c "import yaml,glob; [print(p, sorted(yaml.safe_load(open(p).read().split('---')[1]).keys())) for p in sorted(glob.glob('agents/*.md'))]"`
Expected: every file prints `['description', 'mode', 'model']`.

- [ ] **Step 5: Confirm orchestrator is the only primary**

Run: `grep -l "mode: primary" agents/*.md`
Expected: `agents/orchestrator.md` only.

---

## Self-review

**Spec coverage:** O1 new primary file → Task 2. O2 intent routing → orchestrator body routing table in Task 2. O3 best-guess + bypass → orchestrator body in Task 2. O4 Step-0 brainstorm → orchestrator body in Task 2. O5 conditional architect → architect-gate section in Task 2 + README row in Task 5. O6 lifecycle → flows section in Task 2. O7 minimal orchestrator frontmatter → Task 2 frontmatter. O8 strip temperature/permissions + two tiers → Tasks 3–4, registered in Task 1. Docs plan (README count/table, INSTALL no-change) → Task 5. No gaps.

**Placeholder scan:** No TBD/TODO/later; every edit shows old + new strings; every command shows expected output; "substitute HIGH ID" is a named fallback with exact default, not an open blank.

**Type consistency:** HIGH/LOW constants defined once in the header and used identically in Tasks 1–4 and 6; file paths exact throughout; commit messages follow Conventional Commits matching the repo's git-expert conventions.
