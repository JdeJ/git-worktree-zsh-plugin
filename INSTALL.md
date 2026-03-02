# Installation Complete! ✓

The plugin has been installed and enabled in your shell.

## Quick Start

1. **Reload your shell:**

```bash
source ~/.zshrc
```

2. **Navigate to a git repository:**

```bash
cd ~/path/to/your/project
```

3. **Create your first worktree:**

```bash
wtn feature-test
```

This will:

- Create a new branch `feature-test`
- Create worktree in `.worktrees/feature-test`
- Copy all `.env` files and `.husky/` directory (default behavior)
- Detect package manager (pnpm/bun/yarn/npm)
- Open VSCode with 2 terminals
- Start Claude in the left terminal
- Auto-install dependencies in the right terminal

4. **(Optional) Configure per-repository:**

```bash
# Create .config.json in your repository root
cat > .config.json <<'EOF'
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
},
"defaults": {
"baseBranch": "main",
"worktreeDirectory": ".worktrees"
}
}
EOF
```

**See [CONFIGURATION.md](./CONFIGURATION.md) for complete configuration guide.**

## Verify Installation

### Quick Check

Run this to check if commands are available:

```bash
type wtn wtls wtrm wtcd wtprune wtstatus
```

You should see output confirming each command is a shell function.

### System Status Check

Run a comprehensive environment check:

```bash
wtstatus
```

This will verify:

- ✓ Git repository (when in a repo)
- ✓ Git version 2.5+ (required for worktrees)
- ✓ macOS platform (for AppleScript automation)
- ✓ VSCode CLI availability
- ✓ Claude CLI availability
- ℹ Accessibility permissions guidance

**Expected output when all is ready:**

```
System Status Check
──────────────────
✓ Git repository detected
✓ Git 2.39.5 (worktree support)
✓ macOS detected (AppleScript available)
✓ VSCode CLI found (/usr/local/bin/code)
✓ Claude CLI found (/Users/you/.local/bin/claude)
ℹ VSCode not currently running
ℹ Accessibility permissions: Grant to VSCode if automation fails

✓ All systems ready!
```

Any missing requirements will show actionable fix instructions.

## First Time Setup

### 1. Grant Accessibility Permissions

For AppleScript automation to work:

1. Open **System Settings**
2. Go to **Privacy & Security** → **Accessibility**
3. Ensure **Visual Studio Code** is checked
4. If not listed, click `+` and add VSCode

### 2. Verify VSCode CLI

Ensure `code` command is in your PATH:

```bash
which code
# Should output: /usr/local/bin/code
```

If not found:

1. Open VSCode
2. Press `⌘⇧P` (Command Palette)
3. Type: "Shell Command: Install 'code' command in PATH"
4. Press Enter

### 3. Verify Claude CLI

Ensure `claude` command is available:

```bash
which claude
# Should output path to claude executable
```

## Test Drive

Let's create a test worktree to verify everything works:

```bash
# Create a test directory (or use existing repo)
mkdir -p ~/test-worktree && cd ~/test-worktree
git init
echo "# Test" > README.md
git add . && git commit -m "Initial commit"

# Create your first worktree
wtn test-branch

# You should see:
# Checking requirements...
# ✓ Git repository detected
# ✓ Git 2.39.5 (worktree support)
# ✓ macOS detected (AppleScript available)
# ✓ VSCode CLI found
# ✓ Claude CLI found
# ✓ All systems ready!
#
# → Creating branch 'test-branch'...
# → Creating worktree at .worktrees/test-branch...
# → Setting up gitignored configs and environment files...
# → Detected package manager: npm
# → Opening VSCode...
# → Setting up terminals with Claude...
# ✓ Success! Worktree 'test-branch' is ready
# Location: ~/test-worktree/.worktrees/test-branch
# Claude is running in the left terminal
# Installing dependencies with npm in the right terminal
```

## Available Commands

| Command       | Description                                    |
| ------------- | ---------------------------------------------- |
| `wtn <name>`  | Create new branch + worktree + VSCode setup    |
| `wtls`        | List all worktrees                             |
| `wtrm <name>` | Remove worktree (optionally delete branch)     |
| `wtcd <name>` | Jump to worktree directory                     |
| `wtprune`     | Clean stale worktree metadata                  |
| `wtstatus`    | Check system requirements and show diagnostics |

## Troubleshooting

### First Step: Always Run

```bash
wtstatus
```

This command checks all requirements and provides specific fix instructions for any issues.

### VSCode doesn't open

- Check: `which code`
- Install: VSCode Command Palette → "Install 'code' command"

### Terminals don't auto-create or split

- Grant accessibility permissions (see above)
- VSCode must be fully loaded (plugin waits 2.5s)
- **Split method**: Plugin uses Command Palette (Cmd+Shift+P → "Terminal: Split Terminal")
- Works with all keyboard layouts (no physical key codes)
- If Command Palette is slow, increase delays in the AppleScript section
- Fallback: Manually press ` ⌃\`` then use Command Palette (Cmd+Shift+P) → type "split" → select "Terminal: Split Terminal", run  `claude` in left and your package manager install command in right

### Claude doesn't start

- Check: `which claude`
- Ensure Claude Code CLI is installed
- Manually type `claude` in terminal

### Plugin commands not found

- Check: `echo $ZSH_CUSTOM`
- Verify: `ls -la $ZSH_CUSTOM/plugins/git-worktree`
- Reload: `source ~/.zshrc`

### Configuration not working

- Verify config file location: `.config.json` must be in repository root
- Check JSON syntax: Use `cat .config.json | jq .` to validate
- Test with defaults: Remove `.config.json` temporarily to test with built-in defaults
- View what's being used: Plugin will use defaults if config file is invalid

### Files not being copied

- Check `copyFiles.enabled` is `true` in `.config.json`
- Verify paths are correct (relative to repository root)
- Ensure files exist and are gitignored (use `git status --ignored`)
- For glob patterns like `**/.env*`, files must be in gitignore

## Tips for Success

1. **Use descriptive branch names**: `feature/`, `bugfix/`, `hotfix/`
2. **Clean up regularly**: `wtls` to see all, `wtrm` to remove old ones
3. **Parallel work**: Multiple worktrees = multiple Claude instances
4. **Git operations are shared**: Commits in one worktree are visible in all

## Next Steps

- **[CONFIGURATION.md](./CONFIGURATION.md)** - Learn how to customize behavior per-repository
- **[README.md](./README.md)** - Comprehensive documentation and features
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Visual cheat sheet and command reference
- Check out configuration-based workflow examples for different scenarios
- Commit `.config.json` to share team setup or add to `.gitignore` for personal use

---

**Need help?** Check the troubleshooting section or open an issue!

Enjoy your elegant worktree workflow! ✨
