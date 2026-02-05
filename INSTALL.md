# Installation Complete! ✓

The plugin has been installed and enabled in your shell.

## Quick Start

1. **Reload your shell:**
      `bash
   source ~/.zshrc
   `

2. **Navigate to a git repository:**
      `bash
   cd ~/path/to/your/project
   `

3. **Create your first worktree:**
      `bash
   wtn feature-test
   `

This will:
   - Create a new branch `feature-test`
   - Create worktree in `.worktrees/feature-test`
   - Open VSCode with 2 terminals
   - Start Claude in the left terminal

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
# → Opening VSCode...
# → Setting up terminals with Claude...
# ✓ Success! Worktree 'test-branch' is ready
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

### Terminals don't auto-create

- Grant accessibility permissions (see above)
- VSCode must be fully loaded (plugin waits 2.5s)
- Fallback: Manually press `⌃\`` then your split terminal shortcut

### Claude doesn't start

- Check: `which claude`
- Ensure Claude Code CLI is installed
- Manually type `claude` in terminal

### Plugin commands not found

- Check: `echo $ZSH_CUSTOM`
- Verify: `ls -la $ZSH_CUSTOM/plugins/git-worktree`
- Reload: `source ~/.zshrc`

## Tips for Success

1. **Use descriptive branch names**: `feature/`, `bugfix/`, `hotfix/`
2. **Clean up regularly**: `wtls` to see all, `wtrm` to remove old ones
3. **Parallel work**: Multiple worktrees = multiple Claude instances
4. **Git operations are shared**: Commits in one worktree are visible in all

## Next Steps

- Read the [README.md](./README.md) for comprehensive documentation
- Check out workflow examples for parallel development
- Customize the plugin for your specific needs

---

**Need help?** Check the troubleshooting section or open an issue!

Enjoy your elegant worktree workflow! ✨
