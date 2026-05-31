# MCP: Obsidian

OpenCode connects to Obsidian via MCP for persistent memory and knowledge management.

## Prerequisites

- [Obsidian](https://obsidian.md/) installed (on this machine: `snap install obsidian`)
- `uv` installed (comes with Homebrew)
- Obsidian vault at `~/OpenCloud/Personal` (or your vault path)
- Obsidian Local REST API plugin installed and configured

## Local REST API Plugin Setup

1. In Obsidian, install the **Local REST API** community plugin
2. Enable it and set:
   - Port: `27124`
   - API Key: `<your-generated-key>`

## How It Works

The MCP config in `opencode.json` launches `uvx mcp-obsidian` with environment variables:

```
OBSIDIAN_API_KEY=<key>
OBSIDIAN_HOST=127.0.0.1
OBSIDIAN_PORT=27124
```

## Updating the API Key

Edit `~/.config/opencode/opencode.json` and update the `OBSIDIAN_API_KEY` value in the `mcp.obsidian.command` field. The key is set inline via `export` in the sh -c command.

## Verify Connection

In OpenCode, ask: "read my daily note from Obsidian"

If you see a connection error, check:
1. Obsidian is running with Local REST API plugin enabled
2. The port and API key match
3. `uvx mcp-obsidian` is available (`uv tool install mcp-obsidian` if missing)
