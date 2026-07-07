---
name: verifying-github-actions
description: Use when editing or creating GitHub Actions workflow files (.github/workflows/*.yml) or composite action files (.github/actions/*/action.yml) to verify syntax before commit
---

# Verifying GitHub Actions

## Overview

Always verify GitHub Actions workflows and composite actions with actionlint after editing. Catch syntax errors before push.

## When to Use

- Editing any `.github/workflows/*.yml` file
- Editing any `.github/actions/*/action.yml` file
- Creating new workflow or action files
- Before committing CI/CD changes

## Quick Reference

| Task | Command |
|------|---------|
| Install actionlint | `curl -sL https://github.com/rhysd/actionlint/releases/download/v1.7.7/actionlint_1.7.7_linux_amd64.tar.gz \| tar xz && sudo mv actionlint /usr/local/bin/` |
| Check workflows | `actionlint .github/workflows/*.yml` |
| Check specific file | `actionlint .github/workflows/ci.yml` |
| Verbose output | `actionlint -color .github/workflows/*.yml` |

## Workflow

```bash
# 1. After editing workflow/action files, run:
actionlint .github/workflows/*.yml

# 2. If errors found, fix them before committing

# 3. For local testing (optional, requires Docker + act):
act push -j <job-name>
```

## Common Errors

| Error | Fix |
|-------|-----|
| `"on" section is missing` | Composite action treated as workflow — check file path |
| `unexpected key "timeout-minutes"` | Composite actions don't support timeout-minutes at step level |
| `Unrecognized named-value: 'secrets'` | Composite actions can't access secrets directly — pass as inputs |
| `unexpected key "description"` | Action file missing `runs.using: 'composite'` |

## Composite Action Template

```yaml
name: 'Action Name'
description: 'Action description'

inputs:
  my-input:
    description: 'Input description'
    required: true

runs:
  using: 'composite'
  steps:
    - name: Step name
      uses: actions/checkout@v4
      env:
        MY_VAR: ${{ inputs.my-input }}
```

## Notes

- actionlint treats composite actions as workflows by default — errors about missing "on"/"jobs" sections are expected when checking action files
- Focus on workflow file errors (`.github/workflows/*.yml`)
- For local testing with `act`, see https://github.com/nektos/act
