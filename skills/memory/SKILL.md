---
name: memory
description: >
  Persistent memory via Obsidian vault/memory/. Use ONLY when the user refers to
  memory: "remember", "remember last time", "check memory", "recall",
  "previous context", "save to memory". Never load memory at session start.
---

## Memory Structure

```
vault/memory/
├── global.md          # User prefs, common context, global state
└── projects/
    ├── project-A.md # Project-specific memory
    └── project-B.md
```

## When Triggered

Read:
1. `vault/memory/global.md`
2. Detect project: current working dir or as user says
3. `vault/memory/projects/{project-name}.md` if exists

Write — only on explicit user request ("remember …", "save …"):
- New info about prefs, tools, workflow → append to `global.md`
- New info about current project → append to `projects/{project-name}.md`
- Use `mcp-obsidian_append_content` tool to add

## Format

```markdown
# global

## prefs
- key: value

## context
- date: note

# projects/{name}

## current-task
- task description

## recent-context
- date: what happened
```

## Tools

Use `mcp-obsidian_append_content` tool from the obsidian MCP.
Use `mcp-obsidian_get_file_contents` to read memory files.
Use `mcp-obsidian_search` to find context.
