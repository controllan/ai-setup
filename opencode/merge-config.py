#!/usr/bin/env python3
"""Merge the ai-setup OpenCode config into a live config.

- Migrates V1 fields to the native V2 shape before merging.
- Repo wins on defined keys; live-only providers and agents survive.
- `plugins` and `skills` arrays are unioned, repo entries first.
- Caveman plugin entries are dropped: caveman ships as skill + always-on
  AGENTS.md rules, not as a dynamic plugin.

Usage: merge-config.py REPO_CONFIG LIVE_CONFIG
"""

import copy
import json
import sys
from pathlib import Path

UNION_PATHS = {("plugins",), ("skills",)}
REMOVED_PLUGINS = (
    "caveman-opencode-plugin",
    "./plugins/caveman",
    "plugins/caveman",
    "../plugins/caveman",
)
ACTION_MAP = {"bash": "shell", "task": "subagent", "write": "edit", "patch": "edit"}


def dedupe(items):
    out = []
    for item in items:
        if item not in out:
            out.append(item)
    return out


def permission_rules(value):
    """Translate a V1 permission value into ordered V2 permission rules."""
    if isinstance(value, str):
        return [{"action": "*", "resource": "*", "effect": value}]
    if not isinstance(value, dict):
        return []
    rules = []
    for action, resources in value.items():
        action = ACTION_MAP.get(action, action)
        if isinstance(resources, str):
            rules.append({"action": action, "resource": "*", "effect": resources})
        elif isinstance(resources, dict):
            for resource, effect in resources.items():
                rules.append({"action": action, "resource": resource, "effect": effect})
    return rules


def migrate_model(model):
    out = copy.deepcopy(model)
    if "id" in out:
        out.setdefault("modelID", out.pop("id"))
    if "tool_call" in out:
        out.setdefault("capabilities", {})["tools"] = out.pop("tool_call")
    if "modalities" in out:
        modalities = out.pop("modalities")
        capabilities = out.setdefault("capabilities", {})
        if isinstance(modalities, dict):
            if "input" in modalities:
                capabilities["input"] = modalities["input"]
            if "output" in modalities:
                capabilities["output"] = modalities["output"]
    if "options" in out:
        out.setdefault("settings", out.pop("options"))
    if "cache_read" in out or "cache_write" in out:
        cache = out.setdefault("cost", {}).setdefault("cache", {})
        if "cache_read" in out:
            cache["read"] = out.pop("cache_read")
        if "cache_write" in out:
            cache["write"] = out.pop("cache_write")
    if out.get("status") == "deprecated":
        out.pop("status")
        out["disabled"] = True
    return out


def migrate_provider(provider):
    out = copy.deepcopy(provider)
    package = out.pop("npm", None)
    if isinstance(package, str):
        out["package"] = package if package.startswith("aisdk:") else "aisdk:" + package
    endpoint = out.pop("api", None)
    options = out.pop("options", {})
    settings = out.get("settings", {})
    if not isinstance(settings, dict):
        settings = {}
    if isinstance(endpoint, str):
        settings.setdefault("baseURL", endpoint)
    if isinstance(options, dict):
        settings.update(options)
    if settings:
        out["settings"] = settings
    models = out.get("models")
    if isinstance(models, dict):
        out["models"] = {name: migrate_model(model) for name, model in models.items()}
    return out


def migrate_agent(agent):
    out = copy.deepcopy(agent)
    if "prompt" in out:
        out.setdefault("system", out.pop("prompt"))
    if "disable" in out:
        out.setdefault("disabled", out.pop("disable"))
    if "permission" in out:
        out.setdefault("permissions", permission_rules(out.pop("permission")))
    if "maxSteps" in out:
        out.setdefault("steps", out.pop("maxSteps"))
    if "variant" in out and isinstance(out.get("model"), str):
        out["model"] = out["model"] + "#" + str(out.pop("variant"))
    return out


def migrate_mcp(config):
    mcp = config.get("mcp")
    if not isinstance(mcp, dict):
        return
    servers = mcp.get("servers")
    if servers is None:
        servers = mcp
        config["mcp"] = {"servers": servers}
    if not isinstance(servers, dict):
        return
    for name, entry in list(servers.items()):
        if not isinstance(entry, dict):
            continue
        if "enabled" in entry:
            entry["disabled"] = not entry.pop("enabled")
        timeout = entry.get("timeout")
        if isinstance(timeout, (int, float)):
            entry["timeout"] = {
                "startup": timeout,
                "catalog": timeout,
                "execution": timeout,
            }


def migrate_plugins(config):
    plugins = config.pop("plugin", None)
    if isinstance(plugins, str):
        plugins = [plugins]
    if not isinstance(plugins, list):
        plugins = []
    normalized = []
    for item in plugins:
        if isinstance(item, (list, tuple)) and len(item) == 2:
            normalized.append({"package": item[0], "options": item[1]})
        else:
            normalized.append(item)
    existing = config.get("plugins")
    if not isinstance(existing, list):
        existing = []
    config["plugins"] = dedupe(normalized + existing)


def normalize_v1(config):
    """Return a native V2 config. Safe to run on an already native config."""
    out = copy.deepcopy(config)

    providers = out.pop("provider", None)
    if isinstance(providers, dict):
        merged = out.get("providers", {})
        if not isinstance(merged, dict):
            merged = {}
        for name, provider in providers.items():
            merged[name] = migrate_provider(provider) if name not in merged else merged[name]
        out["providers"] = merged
    if isinstance(out.get("providers"), dict):
        out["providers"] = {
            name: migrate_provider(provider)
            for name, provider in out["providers"].items()
        }

    agents = out.pop("agent", None)
    if isinstance(agents, dict):
        merged = out.get("agents", {})
        if not isinstance(merged, dict):
            merged = {}
        for name, agent in agents.items():
            merged[name] = migrate_agent(agent) if name not in merged else merged[name]
        out["agents"] = merged
    if isinstance(out.get("agents"), dict):
        out["agents"] = {
            name: migrate_agent(agent)
            for name, agent in out["agents"].items()
        }

    if "permission" in out:
        out.setdefault("permissions", permission_rules(out.pop("permission")))

    commands = out.pop("command", None)
    if isinstance(commands, dict):
        merged = out.get("commands", {})
        if not isinstance(merged, dict):
            merged = {}
        for name, command in commands.items():
            if name in merged:
                continue
            command = copy.deepcopy(command)
            if "subtask" in command:
                command["subagent"] = command.pop("subtask")
            merged[name] = command
        out["commands"] = merged

    skills = out.get("skills")
    if isinstance(skills, dict):
        out["skills"] = list(skills.get("paths", [])) + list(skills.get("urls", []))

    if "snapshot" in out:
        out.setdefault("snapshots", out.pop("snapshot"))
    if "attachment" in out:
        out.setdefault("media", out.pop("attachment"))

    migrate_mcp(out)
    migrate_plugins(out)
    return out


def is_removed_plugin(item):
    target = item if isinstance(item, str) else item.get("package", "") if isinstance(item, dict) else ""
    return any(
        target == removed or target.startswith(removed + "/")
        for removed in REMOVED_PLUGINS
    )


def merge(repo_value, live_value, path=()):
    if isinstance(repo_value, dict) and isinstance(live_value, dict):
        out = copy.deepcopy(live_value)
        for key, value in repo_value.items():
            out[key] = merge(value, live_value[key], path + (key,)) if key in live_value else copy.deepcopy(value)
        return out
    if (
        isinstance(repo_value, list)
        and isinstance(live_value, list)
        and path in UNION_PATHS
    ):
        return dedupe(repo_value + live_value)
    return copy.deepcopy(repo_value)


def load(path):
    try:
        return json.loads(Path(path).read_text())
    except FileNotFoundError:
        return {}


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: merge-config.py REPO_CONFIG LIVE_CONFIG")
    repo_path, live_path = sys.argv[1], sys.argv[2]
    repo = load(repo_path)
    live = normalize_v1(load(live_path))

    merged = merge(repo, live)
    merged["plugins"] = [
        item for item in merged.get("plugins", []) if not is_removed_plugin(item)
    ]
    if "plugins" in repo:
        missing = [item for item in repo["plugins"] if item not in merged["plugins"]]
        assert not missing, "repo plugins missing: " + ", ".join(map(str, missing))

    lost_providers = [key for key in live.get("providers", {}) if key not in merged.get("providers", {})]
    assert not lost_providers, "live providers lost: " + ", ".join(lost_providers)
    lost_agents = [key for key in live.get("agents", {}) if key not in merged.get("agents", {})]
    assert not lost_agents, "live agents lost: " + ", ".join(lost_agents)

    Path(live_path).write_text(json.dumps(merged, indent=2, ensure_ascii=False) + "\n")
    print("merged " + live_path)
    print("providers: " + ", ".join(sorted(merged.get("providers", {}))))
    print("agents: " + str(len(merged.get("agents", {}))))
    print("plugins: " + ", ".join(str(item) for item in merged.get("plugins", [])))


if __name__ == "__main__":
    main()
