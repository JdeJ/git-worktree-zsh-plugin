# Quick Reference: Git Worktree with `wtn`

Visual cheat sheet for git worktree behavior and commands.

---

## Command Quick Reference

```bash
wtn <branch> [base]  # Create branch + worktree + VSCode + Claude
                     # Defaults to main/master if base not specified
                     # Example: wtn hotfix-urgent main
wtls                 # List all worktrees
wtrm <branch>        # Remove worktree (ask about branch deletion)
wtcd <branch>        # Jump to worktree directory
wtprune              # Clean stale worktree metadata
wtstatus             # Check system requirements
```

---

## Branch Creation Flow

**Default behavior (auto-detects main/master):**

```
Your Current State:
┌─────────────────────────────┐
│  You're on: feature-old     │
│  Uncommitted changes: YES   │
│  main branch: commit xyz    │
└─────────────────────────────┘
                │
                │  wtn feature-new
                │  (auto-detects main)
                ▼
┌─────────────────────────────┐
│  Git creates:               │
│  feature-new → commit xyz   │
│  (from main, not feature-old!)│
└─────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│  Two separate working directories:      │
│                                          │
│  Original:                New Worktree: │
│  ├── On: feature-old      ├── On: feature-new│
│  ├── Changes: YES         ├── Changes: NO    │
│  └── Files: modified      └── Files: clean   │
└─────────────────────────────────────────┘
```

**Explicit base branch:**

```bash
# Specify base branch explicitly
wtn hotfix-urgent main         # From main
wtn experiment HEAD            # From current HEAD
wtn feature-v2 feature-v1      # From another feature
```

**Key Point:** Defaults to main/master. Your uncommitted work stays safe!

---

## Uncommitted Changes Safety

```
BEFORE wtn:
project/
├── src/
│   ├── auth.js       (modified, uncommitted)
│   └── utils.js      (modified, uncommitted)

RUN: wtn feature-payments

AFTER wtn:
project/
├── src/
│   ├── auth.js       (STILL modified, uncommitted) ✓
│   └── utils.js      (STILL modified, uncommitted) ✓
│
└── .worktrees/
    └── feature-payments/
        └── src/
            ├── auth.js       (clean, committed version) ✓
            └── utils.js      (clean, committed version) ✓
```

**Your uncommitted work is NEVER touched.**

---

## File System Layout

```
project/                              # Main worktree
├── .git/                             # Shared git database
│   ├── objects/       ← ALL commits (shared)
│   ├── refs/          ← ALL branches (shared)
│   │   └── heads/
│   │       ├── main
│   │       └── feature-auth
│   └── worktrees/     ← Worktree metadata
│       └── feature-auth/
│           ├── HEAD   ← Points to feature-auth
│           └── index  ← Separate staging area
│
├── .worktrees/                       # Worktrees directory
│   └── feature-auth/                 # Your new worktree
│       ├── .git       ← FILE (pointer, not directory)
│       └── src/       ← Separate working files
│
└── src/                              # Main worktree files
```

---

## What's Shared vs Isolated

| Shared (All Worktrees)  | Isolated (Per Worktree)  |
| ----------------------- | ------------------------ |
| ✓ Commits               | ✓ Working files          |
| ✓ Branches              | ✓ Staging area (index)   |
| ✓ Tags                  | ✓ Current branch (HEAD)  |
| ✓ Remotes               | ✓ Uncommitted changes    |
| ✓ Config                | ✓ Reflog                 |

**Implication:**

- Commit in worktree → Visible everywhere instantly
- Modify file in worktree → Only that worktree affected

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
    │         │
    │         ├─ YES → Use worktree! (wtn <branch>)
    │         │        No stashing needed ✓
    │         │
    │         └─ NO → Worktree still useful for parallel work
    │                 But could also just checkout
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
Validation:         0.1s
System check:       0.3s
Branch create:      0.1s
Worktree create:    0.5s
VSCode launch:      2.5s
Terminal setup:     5.5s
───────────────────────
Total:             ~9.0s
```

---

## AppleScript Shortcuts Used

| Action          | Shortcut                | What It Does                |
| --------------- | ----------------------- | --------------------------- |
| Open terminal   | `Ctrl + \``             | Opens integrated terminal   |
| Split terminal  | `Ctrl + Opt + Cmd + º`  | Creates side-by-side panes  |
| Switch pane     | `Opt + Cmd + →`         | Focus next terminal pane    |

---

## Troubleshooting Quick Fixes

| Problem                      | Quick Fix                             |
| ---------------------------- | ------------------------------------- |
| "Not in git repo"            | `cd` to a git repository              |
| "Branch exists in worktree"  | Use different name or `wtrm` old one  |
| VSCode doesn't open          | Check: `which code`                   |
| Terminals don't auto-setup   | Grant accessibility permissions       |
| Claude doesn't start         | Check: `which claude`                 |

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

**Alternative approaches (if needed):**

**Option 1: Use git directly (no automation)**

```bash
$ git worktree add -b feature-new .worktrees/feature-new main
# Creates from main but no VSCode/Claude automation
```

**Option 2: Create branch first**

```bash
$ git branch feature-new main
$ wtn feature-new
# Uses existing branch
```

---

## Disk Space

Example repository: 100 MB

```
Without worktree:
├── .git/       50 MB
└── files/      50 MB
Total:         100 MB

With worktree:
├── .git/       50 MB (shared!)
├── files/      50 MB (main)
└── worktree/   50 MB (duplicate files)
Total:         150 MB

vs. Cloning twice: 200 MB

Space saved:    50 MB (25%)
```

**Objects are shared**, only working files duplicated.

---

## Git Commands Under the Hood

What `wtn feature-auth` actually runs:

```bash
git branch feature-auth                    # Create branch from HEAD
git worktree add .worktrees/feature-auth feature-auth  # Create worktree
code .worktrees/feature-auth               # Open VSCode
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

| Document                   | What It Covers                             |
| -------------------------- | ------------------------------------------ |
| [README.md](./README.md)   | Complete features, installation, examples  |
| [INSTALL.md](./INSTALL.md) | Setup and troubleshooting                  |

---

**Remember:** Worktrees let you work in parallel without penalties. Create freely, work safely, merge confidently.
