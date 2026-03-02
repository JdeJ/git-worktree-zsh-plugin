# Configuration File (.config.json)

This file controls how the git-worktree plugin behaves in this repository.

## Location

Place this file in your **repository root** (same level as `.git/`):

```
your-repo/
├── .git/
├── .config.json ← Here
├── package.json
└── src/
```

## What This File Does

When you run `wtn branch-name`, the plugin:

1. **Reads `.config.json`** from repository root
2. **Copies files** based on `copyFiles.patterns`
3. **Controls automation** based on `features` flags
4. **Uses defaults** from `defaults` section
5. **Runs custom command** if `customCommand` is set

## Quick Examples

### Minimal Setup (Fast PR Review)

```json
{
  "copyFiles": { "enabled": false },
  "features": {
    "installDependencies": false,
    "openVSCode": true,
    "startClaude": false,
    "splitTerminal": false
  }
}
```

### Full Development Environment

```json
{
  "copyFiles": {
    "enabled": true,
    "patterns": [
      { "path": ".husky/", "type": "directory" },
      { "path": "**/.env*", "type": "glob" },
      { "path": ".clauderc", "type": "file" }
    ]
  },
  "features": {
    "installDependencies": true,
    "openVSCode": true,
    "startClaude": true,
    "splitTerminal": true
  }
}
```

### Custom Terminal (Alternative to VSCode)

```json
{
  "features": {
    "openVSCode": false,
    "installDependencies": false,
    "startClaude": false,
    "splitTerminal": false
  },
  "customCommand": "open -a iTerm \"$WT_WORKTREE_PATH\""
}
```

### Custom Setup Script

```json
{
  "features": {
    "installDependencies": true,
    "openVSCode": true,
    "startClaude": false,
    "splitTerminal": false
  },
  "customCommand": "cd \"$WT_WORKTREE_PATH\" && ./scripts/post-setup.sh \"$WT_BRANCH_NAME\""
}
```

## Should You Commit This File?

**Commit if:**

- ✅ Your team should use the same setup
- ✅ Project needs specific files copied (`.clauderc`, `.env`, etc.)
- ✅ Everyone benefits from consistent defaults

**Gitignore if:**

- ✅ You want personal customization
- ✅ Different developers have different workflows
- ✅ Configuration contains sensitive paths

## More Information

- **[CONFIGURATION.md](./CONFIGURATION.md)** - Complete configuration guide
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Configuration-based workflow examples
- **[README.md](./README.md)** - Main documentation

## Troubleshooting

**Config not working?**

```bash
# Validate JSON syntax
cat .config.json | jq .

# Test with defaults (remove config temporarily)
mv .config.json .config.json.bak
wtn test-branch

# Restore config
mv .config.json.bak .config.json
```

**Files not being copied?**

- Check `copyFiles.enabled` is `true`
- Verify file paths are relative to repository root
- Ensure files are gitignored: `git status --ignored`
