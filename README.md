# Git Worktree Enhanced - ZSH Plugin

> Elegant workflow for parallel development with git worktrees, VSCode, and Claude

## Philosophy

This plugin embodies the principle that great tools should be **invisible**—they should make the complex feel effortless. Instead of juggling branches, stashing changes, or managing multiple repo clones, you simply type `wtn feature-name` and everything just works.

## Features

- 🚀 **One Command Setup**: Create branch + worktree + VSCode + Claude terminals in one go
- 📁 **Organized Structure**: All worktrees in `.worktrees/` folder (auto-added to .gitignore)
- 🖥️ **Automated IDE**: Opens VSCode with 2 terminals, Claude auto-starting in one
- 🎨 **Beautiful Output**: Color-coded feedback with clear status indicators
- 🧹 **Clean Management**: Easy list, remove, and cleanup commands
- ⚡ **Fast Context Switch**: Jump between worktrees instantly

## Installation

### With Oh-My-Zsh (Recommended)

1. Clone or symlink this plugin to your Oh-My-Zsh custom plugins:

```bash
# If you've symlinked (already done):
# ~/.oh-my-zsh/custom/plugins/git-worktree -> <path>/git-worktree-zsh-plugin

# Or clone directly:
git clone https://github.com/JdeJ/git-worktree-zsh-plugin \
  ~/.oh-my-zsh/custom/plugins/git-worktree
```

2. Enable the plugin in your `~/.zshrc`:

```bash
plugins=(
  git
  git-worktree  # Add this
  # ... other plugins
)
```

3. Reload your shell:

```bash
source ~/.zshrc
```

### Manual Installation

Add this to your `~/.zshrc`:

```bash
source /path/to/git-worktree-zsh-plugin/git-worktree.plugin.zsh
```

## System Status Check

Every command now includes **automatic pre-flight checks** to ensure your environment is properly configured. Before creating worktrees or running operations, the plugin validates:

- ✓ Git repository detection
- ✓ Git version (2.5+ required for worktree support)
- ✓ macOS platform (for AppleScript automation)
- ⚠ VSCode CLI availability
- ⚠ Claude CLI availability
- ℹ Accessibility permissions guidance

Critical requirements (marked with ✗) will prevent operations. Warnings (marked with ⚠) allow you to proceed with reduced functionality.

### `wtstatus` - Check System Requirements

Run a comprehensive system check at any time:

```bash
wtstatus
# System Status Check
# ──────────────────
# ✓ Git repository detected
# ✓ Git 2.39.5 (worktree support)
# ✓ macOS detected (AppleScript available)
# ✓ VSCode CLI found (/usr/local/bin/code)
# ✓ Claude CLI found (/Users/you/.local/bin/claude)
# ℹ VSCode not currently running
# ℹ Accessibility permissions: Grant to VSCode if automation fails
#
# ✓ All systems ready!
```

**Use this command to:**

- Diagnose setup issues before creating worktrees
- Verify all dependencies are installed
- Get actionable fix instructions for missing requirements
- Check if your environment is ready for automation

## Commands

### `wtn <branch-name> [base-branch]` - Create New Worktree

The star of the show. Creates everything you need for parallel development:

```bash
# Create from current HEAD (default)
wtn feature-auth

# Create from specific branch (e.g., main)
wtn hotfix-urgent main

# Example output:
# Checking requirements...
# ✓ Git repository detected
# ✓ Git 2.39.5 (worktree support)
# ✓ macOS detected (AppleScript available)
# ✓ VSCode CLI found
# ✓ Claude CLI found
# ✓ All systems ready!
#
# → Creating branch from 'main'
# → Creating branch 'hotfix-urgent'...
# → Creating worktree at .worktrees/hotfix-urgent...
# → Opening VSCode...
# → Setting up terminals with Claude...
# ✓ Success! Worktree 'hotfix-urgent' is ready
```

**What it does:**

1. ✓ Checks system requirements (Git, VSCode, Claude, etc.)
2. ✓ Validates you're in a git repository
3. ✓ Auto-detects base branch (main/master) or uses specified branch
4. ✓ Creates new branch from base branch (defaults to main/master)
5. ✓ Creates worktree in `.worktrees/<branch-name>`
6. ✓ Adds `.worktrees/` to `.gitignore` (first time)
7. ✓ Opens VSCode at the worktree location
8. ✓ Splits terminal and starts Claude
9. ✓ Leaves you with a clean terminal alongside Claude

**Base Branch Behavior:**

- If no base branch specified: Auto-detects `main` or `master` (in that order)
- If neither exists: Uses current HEAD
- Specify base explicitly: `wtn hotfix-urgent main`

### `wtls` - List Worktrees

Beautifully formatted list of all active worktrees:

```bash
wtls
# Active worktrees:
#   /Users/you/project            abc123f [main]
#   /Users/you/project/.worktrees/feature-auth  def456g [feature-auth]
#   /Users/you/project/.worktrees/bugfix-login  ghi789h [bugfix-login]
```

### `wtrm <branch-name>` - Remove Worktree

Safely removes a worktree and optionally deletes the branch:

```bash
wtrm feature-auth
# → Removing worktree 'feature-auth'...
# ✓ Worktree removed
# Delete branch 'feature-auth' too? [y/N]:
```

### `wtcd <branch-name>` - Jump to Worktree

Quick navigation to a worktree directory:

```bash
wtcd feature-auth
# ✓ Switched to worktree: feature-auth
# (now in .worktrees/feature-auth)
```

### `wtprune` - Clean Stale Metadata

Removes stale worktree metadata (useful after manual deletions):

```bash
wtprune
# → Pruning stale worktree metadata...
# ✓ Done
```

## Aliases

For Oh-My-Zsh git plugin compatibility:

- `gwt` → `git worktree`
- `gwtl` → `wtls`
- `gwta` → `wtn`
- `gwtr` → `wtrm`
- `gwtp` → `wtprune`

## Workflow Examples

### Urgent Hotfix While on Feature Branch

```bash
# Working on feature branch with uncommitted changes
cd ~/projects/myapp
git checkout feature-payments
# ... 50 lines of uncommitted work ...

# Production breaks! Need hotfix based on main
wtn hotfix-critical-bug main
# → Creates branch from main (not feature-payments!)
# → Opens VSCode with clean environment
# → Make fixes, test, commit, push
# → Close VSCode

# Back to your feature work
cd ~/projects/myapp
# All uncommitted changes still here!
# No stashing required!
```

### Code Review Without Context Switching

```bash
# Currently working on feature-a
cd ~/projects/myapp/.worktrees/feature-a

# Teammate asks you to review their PR
wtn review-teammate-pr
# → Opens new VSCode instance
# → Checkout their branch, review code
# → Run tests, leave comments
# → Close when done

# Return to your feature
wtcd feature-a
# Back to work, no stashing needed
```

### Multiple Claude Instances

```bash
# Refactor authentication
wtn refactor-auth
# → Claude instance 1 working on auth

# While that's running, start new feature
wtn feature-payments
# → Claude instance 2 working on payments
# → Both running independently!
```

## Directory Structure

```
myapp/                          # Main repo
├── .git/                       # Shared git directory
├── .gitignore                  # Auto-includes .worktrees/
├── .worktrees/                 # All worktrees here
│   ├── feature-auth/           # Feature branch worktree
│   ├── hotfix-bug/             # Hotfix worktree
│   └── review-pr/              # PR review worktree
├── src/                        # Your main branch code
└── ...
```

## Requirements

- **macOS**: AppleScript automation is Mac-specific
- **Visual Studio Code**: Installed with `code` command in PATH
- **Claude Code CLI**: Installed and available as `claude` command
- **Git**: Version 2.5+ (for worktree support)
- **ZSH**: For shell plugin support

## Tips & Best Practices

### Understanding Git Worktree Behavior

**Base Branch Selection:**

By default, `wtn` creates branches from `main` (or `master` if `main` doesn't exist):

```bash
# Auto-detects main/master
$ wtn feature-new
# → Creates feature-new from main ✓

# Explicitly specify base branch
$ wtn hotfix-urgent main
# → Creates hotfix-urgent from main

# Create from current HEAD if you want
$ wtn feature-new HEAD
# → Creates from wherever you are now
```

**This solves the hotfix problem:**

```bash
# Working on feature-payments with uncommitted changes
$ git branch
* feature-payments

# Need hotfix based on main? Easy!
$ wtn hotfix-urgent main
# → Creates from main, not feature-payments ✓
# → Your uncommitted work stays untouched ✓
```

**Your uncommitted changes are SAFE:**

- Creating a worktree does NOT touch your current working directory
- Uncommitted changes stay where they are
- No need to stash or commit before creating worktrees
- The new worktree starts with a clean working directory

**For detailed explanation:** See [GIT-BEHAVIOR.md](./GIT-BEHAVIOR.md) for deep dive into:

- How branch creation works
- What happens to uncommitted changes
- Staging area isolation
- Common scenarios and best practices

### Branch Naming

Use descriptive, hierarchical names:

- `feature/user-auth`
- `bugfix/login-redirect`
- `hotfix/security-patch`
- `review/pr-123`

### Cleanup Routine

Periodically clean up old worktrees:

```bash
# List all worktrees
wtls

# Remove merged features
wtrm feature/old-thing

# Clean stale metadata
wtprune
```

### VSCode Settings

For the best experience, ensure VSCode terminal integration is configured:

```json
{
  "terminal.integrated.automationProfile.osx": {
    "path": "/bin/zsh"
  }
}
```

## Troubleshooting

### First Step: Run System Check

Before troubleshooting specific issues, always run:

```bash
wtstatus
```

This will show you:

- Missing dependencies with installation instructions
- Git repository status
- VSCode and Claude CLI availability
- Accessibility permissions reminders
- Actionable fixes for any problems

### AppleScript Automation Not Working

If terminals don't auto-setup:

1. Grant VSCode accessibility permissions: System Settings → Privacy & Security → Accessibility
2. Ensure VSCode is fully loaded (plugin waits 2.5 seconds)
3. Manually: `⌃\`` to open terminal, use your split terminal shortcut to split

### Branch Already in Use

Error: "Branch already exists in a worktree"

- Each branch can only be checked out in ONE worktree
- Solution: Use `wtls` to find existing worktree, or create a new branch name

### Worktree Not Found

If `wtrm` can't find worktree:

- Check actual location with `wtls`
- May be outside `.worktrees/` if created manually
- Use full path: `git worktree remove /full/path`

## Philosophy & Design Decisions

### Why `.worktrees/` folder?

- **Organization**: Keeps all worktrees in one place
- **Hidden**: Dot prefix hides from file browsers
- **Ignored**: Auto-added to .gitignore prevents confusion
- **Convention**: Matches common patterns in the community

### Why Auto-start Claude?

- **Consistency**: Every worktree gets the same setup
- **Efficiency**: One less manual step in your workflow
- **Intent**: The whole point is parallel Claude instances

### Why VSCode?

- **Integration**: Best terminal + editor integration
- **Workspaces**: Each worktree becomes its own workspace
- **Extensions**: Your setup works everywhere automatically

## Contributing

Improvements welcome! This plugin was crafted with obsessive attention to:

- **Elegance**: Simple commands that do complex things
- **Reliability**: Extensive validation and error handling
- **Beauty**: Color-coded output with meaningful symbols
- **Thoughtfulness**: Anticipating what users need next

## License

MIT

## Credits

Inspired by:

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Working with Git Worktrees](https://medium.com/@weidagang/working-with-git-worktrees-43cdacf5ea9d)
- [AI Development with Git Worktrees](https://stevekinney.com/courses/ai-development/git-worktrees)
- The principle that great tools should feel like magic ✨
