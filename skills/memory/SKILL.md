---
name: memory
description: >
  Persistent memory skill using Obsidian. Reads/writes to vault/memory/ folder.
  Global context: vault/memory/global.md. Project context: vault/memory/projects/{project-name}.md.
  Use on session start. Trigger words: "remember", "memory", "context", "previous".
---

## Memory Structure

```
vault/memory/
├── global.md          # User prefs, common context, global state
└── projects/
    ├── project-A.md # Project-specific memory
    └── project-B.md
```

## On Session Start

1. Read `vault/memory/global.md`
2. Detect project: look at current working dir or user says
3. Read `vault/memory/projects/{project-name}.md` if exists

## On User Context

- New info about prefs, tools, workflow → append to `global.md`
- New info about current project → append to `projects/{project-name}.md`
- Use obsidian_append_content tool to add

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

## Auto-Trigger

- Session start: read memory files
- User mentions preferences, past context → save to memory
- New project context → create project file