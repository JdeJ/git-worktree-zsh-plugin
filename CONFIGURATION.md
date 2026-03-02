# Worktree Configuration

The plugin supports per-repository configuration through a `.config.json` file in your repository root.

## Setup

Create a `.config.json` file in your repository:

```json
{
  "copyFiles": {
    "enabled": true,
    "patterns": [
      {
        "path": ".husky/",
        "type": "directory",
        "description": "Git hooks directory"
      },
      {
        "path": "**/.env*",
        "type": "glob",
        "description": "All .env files"
      },
      {
        "path": ".clauderc",
        "type": "file",
        "description": "Claude Code configuration"
      }
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

## Configuration Options

### copyFiles

Controls which files and directories are copied from the main worktree to new worktrees.

**enabled** (boolean): Enable/disable file copying

- `true`: Copy files based on patterns (default)
- `false`: Skip all file copying

**patterns** (array): List of files/directories to copy

Each pattern has:

- **path** (string): File path, directory path, or glob pattern
- **type** (string): One of:
- `"file"`: Single file (e.g., `.clauderc`)
- `"directory"`: Entire directory (e.g., `.husky/`)
- `"glob"`: Pattern matching multiple files (e.g., `**/.env*`)
- **description** (string): Human-readable description

**Pattern types:**

```json
{
"path": ".clauderc",
"type": "file"
}
// Copies .clauderc if it exists

{
"path": ".husky/",
"type": "directory"
}
// Recursively copies entire .husky directory

{
"path": "**/.env*",
"type": "glob"
}
// Copies all .env files (respects .gitignore)
```

### features

Controls which automation features are enabled.

**installDependencies** (boolean): Auto-install dependencies

- `true`: Detect package manager and run install in split terminal (default)
- `false`: Skip dependency installation

**openVSCode** (boolean): Open VSCode automatically

- `true`: Open VSCode in new worktree (default)
- `false`: Skip VSCode opening

**startClaude** (boolean): Start Claude in terminal

- `true`: Launch Claude in left terminal (default)
- `false`: Skip Claude startup

**splitTerminal** (boolean): Split terminal for parallel work

- `true`: Create split terminal (Claude left, install right) (default)
- `false`: Single terminal only

### defaults

Default values for various settings.

**baseBranch** (string): Default base branch for new branches

- Default: `"main"`
- If specified branch doesn't exist, falls back to main/master auto-detection

**worktreeDirectory** (string): Directory for worktrees

- Default: `".worktrees"`
- Relative to repository root

### customCommand

Custom shell command to execute after worktree setup completes. This runs **after** all built-in automation (file copying, VSCode opening, terminal setup).

**customCommand** (string): Shell command to run

- Default: `""` (empty, no custom command)
- Executed in the context of the main worktree directory
- Has access to environment variables (see below)

**Available Environment Variables:**

Your custom command can use these exported variables:

- `$WT_WORKTREE_PATH` - Full absolute path to the new worktree
- `$WT_BRANCH_NAME` - Name of the branch for this worktree
- `$WT_PACKAGE_MANAGER` - Detected package manager (pnpm/bun/yarn/npm/empty)
- `$WT_REPO_ROOT` - Repository root directory path

**Example commands:**

```json
{
  "customCommand": "cd \"$WT_WORKTREE_PATH\" && ./scripts/post-setup.sh"
}
```

```json
{
  "customCommand": "open -a iTerm \"$WT_WORKTREE_PATH\""
}
```

```json
{
  "customCommand": "echo 'Worktree ready at $WT_WORKTREE_PATH' && open http://localhost:3000"
}
```

**Use Cases:**

- Open alternative terminal applications (iTerm, Warp, Alacritty)
- Run custom setup scripts
- Open browsers or other tools
- Send notifications
- Execute project-specific initialization

**Note:** Failed custom commands show a warning but don't block worktree creation.

## Examples

### Minimal Configuration

Only copy essential files, no automation:

```json
{
  "copyFiles": {
    "enabled": true,
    "patterns": [
      {
        "path": ".env",
        "type": "file"
      }
    ]
  },
  "features": {
    "installDependencies": false,
    "openVSCode": false,
    "startClaude": false,
    "splitTerminal": false
  }
}
```

### Review PR Configuration

Fast setup for reviewing PRs without installing dependencies:

```json
{
  "features": {
    "installDependencies": false,
    "openVSCode": true,
    "startClaude": false,
    "splitTerminal": false
  }
}
```

### Full Team Configuration

Copy all important configs and enable full automation:

```json
{
  "copyFiles": {
    "enabled": true,
    "patterns": [
      { "path": ".husky/", "type": "directory" },
      { "path": "**/.env*", "type": "glob" },
      { "path": ".clauderc", "type": "file" },
      { "path": ".vscode/settings.json", "type": "file" },
      { "path": ".editorconfig", "type": "file" }
    ]
  },
  "features": {
    "installDependencies": true,
    "openVSCode": true,
    "startClaude": true,
    "splitTerminal": true
  },
  "defaults": {
    "baseBranch": "develop",
    "worktreeDirectory": ".worktrees"
  }
}
```

### Custom Terminal Setup (iTerm)

Use iTerm instead of VSCode with custom automation:

```json
{
  "features": {
    "installDependencies": false,
    "openVSCode": false,
    "startClaude": false,
    "splitTerminal": false
  },
  "customCommand": "open -a iTerm \"$WT_WORKTREE_PATH\" && osascript -e 'tell app \"iTerm\" to tell current window to tell current session to write text \"cd $WT_WORKTREE_PATH && $WT_PACKAGE_MANAGER install && claude\"'"
}
```

### Run Custom Setup Script

Execute a project-specific setup script after worktree creation:

```json
{
  "features": {
    "installDependencies": true,
    "openVSCode": true,
    "startClaude": false,
    "splitTerminal": false
  },
  "customCommand": "cd \"$WT_WORKTREE_PATH\" && ./scripts/worktree-init.sh \"$WT_BRANCH_NAME\""
}
```

### Notification on Completion

Open VSCode and send a system notification when ready:

```json
{
  "features": {
    "installDependencies": true,
    "openVSCode": true,
    "startClaude": true,
    "splitTerminal": true
  },
  "customCommand": "osascript -e 'display notification \"Worktree $WT_BRANCH_NAME is ready\" with title \"Git Worktree\"'"
}
```

## Fallback Behavior

If `.config.json` doesn't exist, the plugin uses sensible defaults:

- Copies `.husky/` directory and all `.env*` files
- Enables all automation features (VSCode, Claude, dependencies install)
- Uses `main` as default base branch
- Uses `.worktrees` as worktree directory
- No custom command runs (empty string)

## Committing Configuration

You can either:

- **Commit `.config.json`**: Share configuration with your team
- **Add to `.gitignore`**: Keep configuration personal

Most teams benefit from committing a shared configuration.
