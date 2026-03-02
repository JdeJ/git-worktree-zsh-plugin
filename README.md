# Git Worktree Enhanced - ZSH Plugin

> Elegant workflow for parallel development with git worktrees, VSCode, and Claude

## Philosophy

This plugin embodies the principle that great tools should be **invisible**—they should make the complex feel effortless. Instead of juggling branches, stashing changes, or managing multiple repo clones, you simply type `wtn feature-name` and everything just works.

## Features

- 🚀 **One Command Setup**: Create branch + worktree + VSCode + Claude terminals in one go
- 📁 **Organized Structure**: All worktrees in `.worktrees/` folder (auto-added to .gitignore)
- 🖥️ **Automated IDE**: Opens VSCode with 2 terminals - Claude ready, dependencies auto-installing
- 🔧 **Smart File Handling**: Auto-copies all .env files recursively and .husky hooks to each worktree
- 📦 **Auto Dependencies**: Detects package manager (pnpm/bun/yarn/npm) and auto-installs dependencies
- ⚙️ **Configurable**: Per-repository `.config.json` to customize file copying and automation features
- 🎨 **Beautiful Output**: Color-coded feedback with clear status indicators
- 🧹 **Clean Management**: Easy list, remove, and cleanup commands
- ⚡ **Fast Context Switch**: Jump between worktrees instantly

## Configuration

Customize behavior per-repository with a `.config.json` file in your repository root.

**Why configure?** Different projects have different needs:

- **Copy essential files**: `.env`, `.clauderc`, VSCode settings, and more
- **Control automation**: Enable/disable dependencies install, VSCode opening, Claude startup
- **Set defaults**: Custom base branch, worktree directory location

**Example configuration:**

```json
{
  "copyFiles": {
    "enabled": true,
    "patterns": [
      { "path": ".husky/", "type": "directory", "description": "Git hooks" },
      { "path": "**/.env*", "type": "glob", "description": "All .env files" },
      { "path": ".clauderc", "type": "file", "description": "Claude config" },
      {
        "path": ".vscode/settings.json",
        "type": "file",
        "description": "VSCode"
      }
    ]
  },
  "features": {
    "installDependencies": true, // Auto-install with detected package manager
    "openVSCode": true, // Open VSCode automatically
    "startClaude": true, // Start Claude in terminal
    "splitTerminal": true // Split terminal (Claude + install)
  },
  "defaults": {
    "baseBranch": "main", // Default base for new branches
    "worktreeDirectory": ".worktrees" // Where to create worktrees
  },
  "customCommand": "" // Optional: Run custom command after setup
}
```

**Configuration options:**

- **No config?** Uses sensible defaults (copies `.husky/` and `.env*`, all features enabled)
- **Custom command:** Run your own script/command after worktree setup completes
- **Commit it:** Share configuration with your team
- **Gitignore it:** Keep configuration personal

**See [CONFIGURATION.md](./CONFIGURATION.md) for complete guide with examples for different workflows.**

## Installation

### With Oh-My-Zsh (Recommended)

1. Clone or symlink this plugin to your Oh-My-Zsh custom plugins:

```bash
# If you've symlinked (already done):
# ~/.oh-my-zsh/custom/plugins/git-worktree -> ~/dev/git-worktree-zsh-plugin

# Or clone directly:
git clone https://github.com/yourusername/git-worktree-zsh-plugin \
~/.oh-my-zsh/custom/plugins/git-worktree
```

2. Enable the plugin in your `~/.zshrc`:

```bash
plugins=(
git
git-worktree # Add this
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
# Create new branch from main (auto-detected)
wtn feature-auth

# Use existing branch (if it exists)
wtn feature-auth # Uses existing branch instead of creating new one

# Create from specific base branch
wtn hotfix-urgent main
```

**Example output (new branch):**

```bash
wtn hotfix-urgent main

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
# → Setting up gitignored configs and environment files...
# • Copying .husky/ (including hook scripts)
# • Finding all .env files (respecting .gitignore)...
# • Copying .env
# • Copying apps/frontend/.env
# ✓ Copied 2 .env file(s)
# → Detected package manager: pnpm
# → Opening VSCode...
# → Setting up fullscreen and terminal with Claude...
# ✓ Success! Worktree 'hotfix-urgent' is ready
# Location: /Users/you/project/.worktrees/hotfix-urgent
# Claude is running in the left terminal
# Installing dependencies with pnpm in the right terminal
```

**Example output (existing branch with remote):**

```bash
wtn feature-auth

# Checking requirements...
# ✓ All systems ready!
#
# → Branch 'feature-auth' already exists, creating worktree from it
# → Setting up tracking with origin/feature-auth
# → Creating worktree at .worktrees/feature-auth...
# → Setting up gitignored configs and environment files...
# • Copying .husky/ (including hook scripts)
# • Finding all .env files (respecting .gitignore)...
# ✓ Copied 2 .env file(s)
# → Detected package manager: pnpm
# → Opening VSCode...
# → Setting up fullscreen and terminal with Claude...
# ✓ Success! Worktree 'feature-auth' is ready
# Location: /Users/you/project/.worktrees/feature-auth
# Claude is running in the left terminal
# Installing dependencies with pnpm in the right terminal
```

**Example output (existing branch without remote):**

```bash
wtn local-branch

# → Branch 'local-branch' already exists, creating worktree from it
# ℹ No upstream configured - use 'git push -u origin local-branch' for first push
# → Creating worktree at .worktrees/local-branch...
# ...
```

**What it does:**

1. ✓ Checks system requirements (Git, VSCode, Claude, etc.)
2. ✓ Validates you're in a git repository
3. ✓ Auto-detects base branch (main/master) or uses specified branch
4. ✓ **Smart branch handling:**

- If branch exists: Uses existing branch for worktree
- If branch doesn't exist: Creates new branch from base branch (defaults to main/master)

5. ✓ Creates worktree in `.worktrees/<folder-name>` (slashes in branch names become hyphens)
6. ✓ Adds `.worktrees/` to `.gitignore` (first time)
7. ✓ Copies gitignored files you need:

- `.husky/` directory (including `_/` subdirectory with hook scripts)
- All `.env*` files recursively (e.g., `.env`, `apps/frontend/.env`, etc.) while respecting .gitignore

8. ✓ Detects package manager (pnpm, bun, yarn, npm) from lockfiles
9. ✓ Opens VSCode at the worktree location
10. ✓ Opens two integrated terminals:

- **Left terminal**: Starts Claude automatically
- **Right terminal**: Auto-installs dependencies with detected package manager

11. ✓ Runs custom command if configured (e.g., open alternative terminal, run setup script)
12. ✓ Leaves you with a fully configured environment ready for development

**Branch Behavior:**

- **Existing branch**: If the branch already exists (not in a worktree), it will be used for the new worktree
- **Automatic upstream tracking**: If the branch exists remotely, automatically sets up tracking
- **Local-only branch**: If no remote branch exists, shows a helpful reminder to use `git push -u`
- **New branch**: If the branch doesn't exist, it will be created from base branch
- **Base branch** (only applies to new branches):
- If no base specified: Auto-detects `main` or `master` (in that order)
- If neither exists: Uses current HEAD
- Specify base explicitly: `wtn hotfix-urgent main`
- **Already in worktree**: If branch already exists in another worktree, shows error

### `wtls` - List Worktrees

Beautifully formatted list of all active worktrees:

```bash
wtls
# Active worktrees:
# /Users/you/project abc123f [main]
# /Users/you/project/.worktrees/feature-auth def456g [feature-auth]
# /Users/you/project/.worktrees/bugfix-login ghi789h [bugfix-login]
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

### Resume Work on Existing Branch

```bash
# You created a branch earlier but aren't working on it
git branch
# * main
# feature-auth ← Exists but not checked out

# Need to work on it in isolation
wtn feature-auth
# → Automatically detects existing branch
# → Creates worktree from current state of feature-auth
# → Opens VSCode with full setup
# → Resume work immediately!
```

### Urgent Hotfix While on Feature Branch

```bash
# Working on feature branch with uncommitted changes
cd ~/projects/myapp
git checkout feature-payments
# ... 50 lines of uncommitted work ...

# Production breaks! Need hotfix based on main
wtn hotfix-critical-bug main
# → Creates NEW branch from main (not feature-payments!)
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

## Environment & Configuration File Handling

One of the key challenges with git worktrees is that **gitignored files aren't copied**. This plugin solves that automatically:

### Copied Files

These files are **copied** from the main worktree to each new worktree:

**Git Hooks (`.husky/`):**

- The entire `.husky/` directory, including the `_/` subdirectory
- Ensures pre-commit hooks, commit-msg hooks, and other git hooks work in every worktree
- Fixes the common issue where `.husky/_/` doesn't get copied (underscore directory is typically gitignored)

**Environment Files:**

The plugin automatically finds and copies **all `.env` files** throughout your repository:

- Root level: `.env`, `.env.local`, `.env.development`, `.env.test`, `.env.production`
- Subdirectories: `apps/frontend/.env`, `packages/api/.env.local`, etc.
- **Respects .gitignore**: Won't search in ignored directories like `node_modules/`

**Note:** Each worktree gets its own independent copies of these files, allowing you to customize environment variables per worktree if needed.

### Package Manager Detection & Auto-Install

The plugin automatically detects your package manager and installs dependencies in the new worktree:

**Detection Priority** (checks for lockfiles):

1. `pnpm-lock.yaml` → runs `pnpm install`
2. `bun.lockb` → runs `bun install`
3. `yarn.lock` → runs `yarn install`
4. `package-lock.json` → runs `npm install`
5. Only `package.json` → defaults to `npm install`

**Installation:**

- Runs automatically in the right terminal of VSCode
- Silent mode for cleaner output
- If package manager not in PATH, shows helpful message
- Skips installation if no package.json found

### Files Handled by Git

These files are automatically available (tracked by git):

- All source code
- `package.json`, `package-lock.json`, `yarn.lock`, etc.
- Configuration files like `.prettierrc`, `tsconfig.json`, etc.
- `CLAUDE.md` (if tracked by git)

## Directory Structure

```
myapp/ # Main repo
├── .git/ # Shared git directory
├── .gitignore # Auto-includes .worktrees/
├── .husky/ # Git hooks (copied to worktrees)
│ └── _/ # Hook scripts (copied to worktrees)
├── .env # Root env file (copied to worktrees)
├── .env.local # Root env override (copied to worktrees)
├── apps/
│ └── frontend/
│ └── .env # Subdirectory env (copied to worktrees)
├── .worktrees/ # All worktrees here
│ ├── feature-auth/ # Feature branch worktree
│ │ ├── .husky/ # ← Copied from main
│ │ ├── .env # ← Copied from main root
│ │ ├── .env.local # ← Copied from main root
│ │ ├── apps/
│ │ │ └── frontend/
│ │ │ └── .env # ← Copied from main subdirectory
│ │ ├── node_modules/ # ← Auto-installed
│ │ └── src/ # Git-tracked files
│ ├── hotfix-bug/ # Hotfix worktree
│ └── user-feature-123-fix/ # Branch name with slash (user/feature-123-fix)
├── src/ # Your main branch code
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

**Existing vs New Branches:**

`wtn` is smart about branches - it uses existing branches or creates new ones as needed:

```bash
# Branch doesn't exist → creates new branch
$ wtn feature-new
# → Creates feature-new from main ✓

# Branch already exists → uses existing branch
$ wtn feature-new
# → Uses existing feature-new branch ✓
# → Creates worktree from its current state ✓
# → Auto-configures upstream tracking if remote exists ✓
```

**Automatic Upstream Tracking:**

When using an existing branch, `wtn` automatically sets up upstream tracking:

```bash
# Branch exists locally and remotely
$ wtn feature-auth
# → Setting up tracking with origin/feature-auth ✓
# Now git pull/push work without -u flag!

# Branch exists only locally
$ wtn local-feature
# ℹ No upstream configured - use 'git push -u origin local-feature' for first push
# Helpful reminder shown
```

This eliminates the common "no upstream branch" error when pushing/pulling!

**Base Branch Selection (for new branches only):**

When creating a NEW branch, `wtn` defaults to `main` (or `master` if `main` doesn't exist):

```bash
# Auto-detects main/master for new branches
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
# → Creates NEW branch from main, not feature-payments ✓
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

- `feature/user-auth` → Creates folder: `.worktrees/feature-user-auth`
- `bugfix/login-redirect` → Creates folder: `.worktrees/bugfix-login-redirect`
- `hotfix/security-patch` → Creates folder: `.worktrees/hotfix-security-patch`
- `user/feature-123-fix` → Creates folder: `.worktrees/user-feature-123-fix`

**Note:** Slashes in branch names are automatically converted to hyphens in folder names to maintain a flat, organized structure while preserving the original git branch name.

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

- Each branch can only be checked out in ONE worktree at a time
- Solution: Use `wtls` to find the existing worktree, or use a different branch name

**Note:** If a branch exists but is NOT in a worktree, `wtn` will automatically use it - no error!

### Worktree Not Found

If `wtrm` can't find worktree:

- Check actual location with `wtls`
- May be outside `.worktrees/` if created manually
- Use full path: `git worktree remove /full/path`

### Missing .env or .husky Files

If your worktree is missing environment files or git hooks:

- Make sure they exist in the main worktree before creating new worktrees
- Older worktrees created before this feature won't have these files
- Solution: Manually copy them or recreate the worktree

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

## Documentation

- **[CONFIGURATION.md](./CONFIGURATION.md)** - Complete configuration guide with examples
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Visual cheat sheet and command reference
- **[INSTALL.md](./INSTALL.md)** - Installation and setup troubleshooting

## License

MIT

## Credits

Inspired by:

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Working with Git Worktrees](https://medium.com/@weidagang/working-with-git-worktrees-43cdacf5ea9d)
- [AI Development with Git Worktrees](https://stevekinney.com/courses/ai-development/git-worktrees)
- The principle that great tools should feel like magic ✨
