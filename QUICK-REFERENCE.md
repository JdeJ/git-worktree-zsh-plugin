# Quick Reference: Git Worktree with `wtn`

Visual cheat sheet for git worktree behavior and commands.

---

## Command Quick Reference

```bash
wtn <branch> [base] # Create worktree from existing or new branch
# If branch exists: uses it
# If branch doesn't exist: creates from base (defaults to main/master)
# Behavior controlled by .config.json
# Example: wtn hotfix-urgent main
wtls # List all worktrees
wtrm <branch> # Remove worktree (ask about branch deletion)
wtcd <branch> # Jump to worktree directory
wtprune # Clean stale worktree metadata
wtstatus # Check system requirements
```

---

## Configuration System

Control behavior per-repository with `.config.json`:

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
  },
  "defaults": {
    "baseBranch": "main",
    "worktreeDirectory": ".worktrees"
  },
  "customCommand": ""
}
```

**Environment Variables for customCommand:**

- `$WT_WORKTREE_PATH` - Path to new worktree
- `$WT_BRANCH_NAME` - Branch name
- `$WT_PACKAGE_MANAGER` - Detected package manager
- `$WT_REPO_ROOT` - Repository root

**Configuration Locations:**

- Repository root: `.config.json`
- No config? Uses sensible defaults
- Commit to git: Share with team
- Add to `.gitignore`: Keep personal

**See [CONFIGURATION.md](./CONFIGURATION.md) for complete guide**

---

## Branch Creation Flow

**Default behavior (auto-detects main/master):**

```
Your Current State:
┌─────────────────────────────┐
│ You're on: feature-old │
│ Uncommitted changes: YES │
│ main branch: commit xyz │
└─────────────────────────────┘
│
│ wtn feature-new
│ (auto-detects main)
▼
┌─────────────────────────────┐
│ Git creates: │
│ feature-new → commit xyz │
│ (from main, not feature-old!)│
└─────────────────────────────┘
│
▼
┌─────────────────────────────────────────┐
│ Two separate working directories: │
│ │
│ Original: New Worktree: │
│ ├── On: feature-old ├── On: feature-new│
│ ├── Changes: YES ├── Changes: NO │
│ └── Files: modified └── Files: clean │
└─────────────────────────────────────────┘
```

**Explicit base branch:**

```bash
# Specify base branch explicitly
wtn hotfix-urgent main # From main
wtn experiment HEAD # From current HEAD
wtn feature-v2 feature-v1 # From another feature
```

**Key Point:** Defaults to main/master. Your uncommitted work stays safe!

---

## Existing vs New Branch Behavior

**When branch already exists (not in a worktree):**

```
Your Branches:
├── main
├── feature-auth ← Existing branch
└── feature-payments

Run: wtn feature-auth

┌─────────────────────────────┐
│ Git detects: │
│ Branch 'feature-auth' │
│ already exists! │
└─────────────────────────────┘
│
▼
┌─────────────────────────────────────┐
│ Uses existing branch: │
│ → Creates worktree from │
│ feature-auth (current state) │
│ → No new branch created │
│ → Base branch parameter ignored │
│ → Sets upstream if remote exists │
└─────────────────────────────────────┘
```

**When branch doesn't exist:**

```
Your Branches:
├── main
└── feature-payments

Run: wtn feature-auth

┌─────────────────────────────┐
│ Git detects: │
│ Branch 'feature-auth' │
│ doesn't exist │
└─────────────────────────────┘
│
▼
┌─────────────────────────────────────┐
│ Creates new branch: │
│ → Creates feature-auth from main │
│ (or specified base branch) │
│ → Then creates worktree from it │
└─────────────────────────────────────┘
```

**Use cases:**

- **Existing branch**: Resume work on a branch you created earlier
- **New branch**: Start fresh work from a base branch
- **Flexibility**: Same command works for both scenarios!

---

## Automatic Upstream Tracking

When using existing branches, `wtn` automatically configures upstream tracking:

```
Scenario 1: Branch exists remotely
─────────────────────────────────
$ wtn feature-auth
→ Branch 'feature-auth' already exists, creating worktree from it
→ Setting up tracking with origin/feature-auth
✓ git pull/push now work without flags!

Scenario 2: Local-only branch
─────────────────────────────────
$ wtn local-feature
→ Branch 'local-feature' already exists, creating worktree from it
ℹ No upstream configured - use 'git push -u origin local-feature' for first push
✓ Helpful reminder shown

Benefits:
─────────────────────────────────
✓ No more "no upstream branch" errors
✓ git pull works immediately
✓ git push works (if upstream exists)
✓ One less manual configuration step
```

---

## Uncommitted Changes Safety

```
BEFORE wtn:
project/
├── src/
│ ├── auth.js (modified, uncommitted)
│ └── utils.js (modified, uncommitted)

RUN: wtn feature-payments

AFTER wtn:
project/
├── src/
│ ├── auth.js (STILL modified, uncommitted) ✓
│ └── utils.js (STILL modified, uncommitted) ✓
│
└── .worktrees/
└── feature-payments/
└── src/
├── auth.js (clean, committed version) ✓
└── utils.js (clean, committed version) ✓
```

**Your uncommitted work is NEVER touched.**

---

## Package Manager Auto-Detection

```
wtn feature-auth detects:

pnpm-lock.yaml found → pnpm install (right terminal)
bun.lockb found → bun install (right terminal)
yarn.lock found → yarn install (right terminal)
package-lock.json found → npm install (right terminal)
Only package.json → npm install (right terminal)
No package.json → Skip installation

Installation runs in parallel with Claude startup!
```

---

## File System Layout

```
project/ # Main worktree
├── .git/ # Shared git database
│ ├── objects/ ← ALL commits (shared)
│ ├── refs/ ← ALL branches (shared)
│ │ └── heads/
│ │ ├── main
│ │ ├── feature-auth
│ │ └── user/feature-123-fix ← Branch with slash
│ └── worktrees/ ← Worktree metadata
│ ├── feature-auth/
│ │ ├── HEAD ← Points to feature-auth
│ │ └── index ← Separate staging area
│ └── user-feature-123-fix/ ← Folder name (slash → hyphen)
│ ├── HEAD ← Points to user/feature-123-fix
│ └── index ← Separate staging area
│
├── .config.json # Worktree plugin config (optional)
├── .worktrees/ # Worktrees directory
│ ├── feature-auth/ # Flat folder name
│ │ ├── .git ← FILE (pointer, not directory)
│ │ ├── .clauderc ← Copied from main (if configured)
│ │ ├── .env ← Copied from main (if configured)
│ │ └── src/ ← Separate working files
│ └── user-feature-123-fix/ # Slashes converted to hyphens
│ ├── .git ← FILE (pointer, not directory)
│ └── src/ ← Separate working files
│
└── src/ # Main worktree files
```

---

## What's Shared vs Isolated

| Shared (All Worktrees) | Isolated (Per Worktree) |
| ---------------------- | ----------------------- |
| ✓ Commits              | ✓ Working files         |
| ✓ Branches             | ✓ Staging area (index)  |
| ✓ Tags                 | ✓ Current branch (HEAD) |
| ✓ Remotes              | ✓ Uncommitted changes   |
| ✓ Config               | ✓ Reflog                |

**Implication:**

- Commit in worktree → Visible everywhere instantly
- Modify file in worktree → Only that worktree affected

---

## Configuration-Based Workflows

### Quick PR Review (No Build Needed)

Create `.config.json` in repository:

```json
{
  "copyFiles": {
    "enabled": true,
    "patterns": [{ "path": ".env", "type": "file" }]
  },
  "features": {
    "installDependencies": false,
    "openVSCode": true,
    "startClaude": false,
    "splitTerminal": false
  }
}
```

```bash
$ wtn pr-review-1234
# Opens VSCode only, no dependencies installed
# Fast setup for quick code review
```

### Full Development Environment

Create `.config.json`:

```json
{
  "copyFiles": {
    "enabled": true,
    "patterns": [
      { "path": ".husky/", "type": "directory" },
      { "path": "**/.env*", "type": "glob" },
      { "path": ".clauderc", "type": "file" },
      { "path": ".vscode/settings.json", "type": "file" }
    ]
  },
  "features": {
    "installDependencies": true,
    "openVSCode": true,
    "startClaude": true,
    "splitTerminal": true
  },
  "defaults": {
    "baseBranch": "develop"
  }
}
```

```bash
$ wtn feature-auth
# Full setup: copies all configs, installs deps, starts Claude
# Ready for development immediately
```

### Monorepo with Custom Configs

```json
{
  "copyFiles": {
    "patterns": [
      { "path": ".env", "type": "file" },
      { "path": "apps/frontend/.env", "type": "file" },
      { "path": "apps/backend/.env", "type": "file" },
      { "path": ".clauderc", "type": "file" }
    ]
  },
  "defaults": {
    "baseBranch": "develop",
    "worktreeDirectory": "../worktrees"
  }
}
```

### Custom Terminal (iTerm/Warp)

Use alternative terminal instead of VSCode:

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

Run project-specific initialization:

```json
{
  "features": {
    "installDependencies": true,
    "openVSCode": true,
    "startClaude": false,
    "splitTerminal": false
  },
  "customCommand": "cd \"$WT_WORKTREE_PATH\" && ./scripts/setup.sh"
}
```

---

## Common Workflows

### 1. Urgent Hotfix While Working

```bash
# Working on feature-payments (uncommitted changes)
$ git branch
* feature-payments

# Production breaks! Need hotfix from main
$ wtn hotfix-critical main

# New VSCode opens:
# - Clean working directory
# - Based on main (not feature-payments!)
# - Make fix, commit, push
# - Close when done

# Return to original work:
# - All uncommitted changes still there!
# - No stashing required!
```

### 2. Review PR Without Stashing

```bash
# Working on feature-payments (uncommitted)
$ wtn review-pr-1234

# New worktree:
$ git fetch origin pull/1234/head:pr-1234
$ git checkout pr-1234
# Review, test, comment
# Close VSCode

# Back to feature-payments:
# - Uncommitted changes untouched!
```

### 3. Parallel Claude Instances

```bash
# Terminal 1
$ cd project
$ wtn refactor-auth
# Claude working on auth refactoring

# Terminal 2 (while Claude still working)
$ cd project
$ wtn feature-payments
# Second Claude working on payments

# Both independent!
```

---

## Decision Tree: When to Use Worktrees

```
Need to work on different branch?
│
├─ YES → Do you have uncommitted changes?
│ │
│ ├─ YES → Use worktree! (wtn <branch>)
│ │ No stashing needed ✓
│ │
│ └─ NO → Worktree still useful for parallel work
│ But could also just checkout
│
└─ NO → Stay on current branch
```

**Use worktrees when:**

- ✓ You have uncommitted work to preserve
- ✓ You want to work on multiple branches simultaneously
- ✓ You want to run different development servers in parallel
- ✓ You need to review PRs without context switching

---

## Timing Reference

Total time from `wtn feature-auth` to ready environment:

```
Validation: 0.1s
System check: 0.3s
Branch create: 0.1s
Worktree create: 0.5s
.env file copying: 0.2s
VSCode launch: 2.5s
Terminal setup: 5.5s
───────────────────────
Total: ~9.2s

Dependencies install in parallel (right terminal)
while Claude starts in left terminal
```

---

## AppleScript Automation Used

| Action         | Method                                       | What It Does                        |
| -------------- | -------------------------------------------- | ----------------------------------- |
| Open terminal  | `Ctrl + \``                                  | Opens integrated terminal           |
| Split terminal | Command Palette → "Terminal: Split Terminal" | Creates side-by-side terminal panes |
| Enter command  | `Enter`                                      | Executes typed commands             |

**Terminal Layout:**

- **Left terminal**: Claude starts automatically
- **Right terminal**: Dependencies install automatically (if package.json detected)

**Note:** Terminal splitting uses Command Palette (Cmd+Shift+P) to be keyboard-layout agnostic.

---

## Troubleshooting Quick Fixes

| Problem                     | Quick Fix                            |
| --------------------------- | ------------------------------------ |
| "Not in git repo"           | `cd` to a git repository             |
| "Branch exists in worktree" | Use different name or `wtrm` old one |
| VSCode doesn't open         | Check: `which code`                  |
| Terminals don't auto-setup  | Grant accessibility permissions      |
| Claude doesn't start        | Check: `which claude`                |

**Full diagnostics:** `wtstatus`

---

## Advanced: Creating from Specific Branch

Want new branch based on specific branch while working elsewhere?

**Simple! Just specify the base branch:**

```bash
# On feature-old, create from main
$ wtn feature-new main

# On main, create from another feature
$ wtn experiment feature-v1

# Use current HEAD explicitly
$ wtn feature-v2 HEAD
```

**Working with existing branches:**

```bash
# Create branch first, then worktree (automatically detected)
$ git branch feature-new main
$ wtn feature-new
# → Automatically uses existing branch (base parameter ignored)

# Or if branch already exists elsewhere, just use it
$ wtn existing-branch
# → Uses existing branch for new worktree
```

**Alternative: Use git directly (no automation)**

```bash
$ git worktree add -b feature-new .worktrees/feature-new main
# Creates from main but no VSCode/Claude automation
```

---

## Disk Space

Example repository: 100 MB

```
Without worktree:
├── .git/ 50 MB
└── files/ 50 MB
Total: 100 MB

With worktree:
├── .git/ 50 MB (shared!)
├── files/ 50 MB (main)
└── worktree/ 50 MB (duplicate files)
Total: 150 MB

vs. Cloning twice: 200 MB

Space saved: 50 MB (25%)
```

**Objects are shared**, only working files duplicated.

---

## Git Commands Under the Hood

What `wtn feature-auth` actually runs:

```bash
git branch feature-auth # Create branch from HEAD
git worktree add .worktrees/feature-auth feature-auth # Create worktree
code .worktrees/feature-auth # Open VSCode
# ... AppleScript automation ...
```

---

## Cleanup Checklist

Weekly maintenance:

```bash
# 1. List all worktrees
wtls

# 2. Check which branches are merged
git branch --merged main

# 3. Remove old worktrees
wtrm old-feature-1
wtrm old-feature-2

# 4. Prune stale metadata
wtprune

# 5. Check remaining
wtls
```

---

## Best Practices Summary

✅ **DO:**

- Create worktrees freely (uncommitted changes are safe)
- Use descriptive branch names
- Clean up old worktrees regularly
- Run `wtstatus` to check setup

❌ **DON'T:**

- Manually delete worktree directories (use `wtrm`)
- Forget which branch you're on when creating worktrees
- Leave many stale worktrees (cleanup regularly)
- Try to checkout same branch in multiple worktrees

---

## Further Reading

| Document                   | What It Covers                            |
| -------------------------- | ----------------------------------------- |
| [README.md](./README.md)   | Complete features, installation, examples |
| [INSTALL.md](./INSTALL.md) | Setup and troubleshooting                 |

---

**Remember:** Worktrees let you work in parallel without penalties. Create freely, work safely, merge confidently.
