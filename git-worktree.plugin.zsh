#!/usr/bin/env zsh
# Git Worktree Enhanced Plugin
# Elegant workflow for creating worktrees with VSCode and Claude integration

autoload -U colors && colors

# System requirements check
_wt_check_requirements() {
local check_type="${1:-full}" # 'full' or 'git-only'
local show_header="${2:-true}"
local has_errors=0
local has_warnings=0

if [[ "$show_header" == "true" ]]; then
echo "${fg[cyan]}System Status Check${reset_color}"
echo "${fg[cyan]}──────────────────${reset_color}"
fi

# Check 1: Git repository (critical)
if git rev-parse --is-inside-work-tree &>/dev/null; then
echo "${fg[green]}✓${reset_color} Git repository detected"
else
echo "${fg[red]}✗${reset_color} Not in a git repository"
echo " ${fg[blue]}→${reset_color} Navigate to a git repository first: ${fg_bold[white]}cd /path/to/repo${reset_color}"
has_errors=1
fi

if [[ "$check_type" == "git-only" ]]; then
return $has_errors
fi

# Check 2: Git version (critical)
local git_version=$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [[ -n "$git_version" ]]; then
local major=$(echo $git_version | cut -d. -f1)
local minor=$(echo $git_version | cut -d. -f2)
if [[ $major -gt 2 ]] || [[ $major -eq 2 && $minor -ge 5 ]]; then
echo "${fg[green]}✓${reset_color} Git $git_version (worktree support)"
else
echo "${fg[red]}✗${reset_color} Git $git_version (need 2.5+)"
echo " ${fg[blue]}→${reset_color} Update git: ${fg_bold[white]}brew upgrade git${reset_color}"
has_errors=1
fi
else
echo "${fg[red]}✗${reset_color} Git not found"
has_errors=1
fi

# Check 3: macOS platform (for AppleScript automation)
if [[ "$(uname)" == "Darwin" ]]; then
echo "${fg[green]}✓${reset_color} macOS detected (AppleScript available)"
else
echo "${fg[yellow]}⚠${reset_color} Not on macOS (terminal automation unavailable)"
echo " ${fg[blue]}→${reset_color} VSCode will open but you'll need to manually create terminals"
has_warnings=1
fi

# Check 4: VSCode CLI (warning if missing)
if command -v code &>/dev/null; then
local code_path=$(which code)
echo "${fg[green]}✓${reset_color} VSCode CLI found ($code_path)"
else
echo "${fg[yellow]}⚠${reset_color} VSCode 'code' command not found"
echo " ${fg[blue]}→${reset_color} Install it: VSCode → Cmd+Shift+P → 'Shell Command: Install code command'"
echo " ${fg[blue]}→${reset_color} Or add to PATH: ${fg_bold[white]}export PATH=\"\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin\"${reset_color}"
has_warnings=1
fi

# Check 5: Claude CLI (warning if missing)
if command -v claude &>/dev/null; then
local claude_path=$(which claude)
echo "${fg[green]}✓${reset_color} Claude CLI found ($claude_path)"
else
echo "${fg[yellow]}⚠${reset_color} Claude CLI not found"
echo " ${fg[blue]}→${reset_color} Install from: ${fg_bold[white]}https://claude.ai/download${reset_color}"
echo " ${fg[blue]}→${reset_color} Or check if it's in your PATH"
has_warnings=1
fi

# Check 6: Accessibility permissions (best effort on macOS)
if [[ "$(uname)" == "Darwin" ]]; then
# We can't directly check accessibility permissions, but we can check if VSCode is running
# and provide helpful guidance
if pgrep -x "Code" >/dev/null; then
echo "${fg[green]}✓${reset_color} VSCode is running"
else
echo "${fg[blue]}ℹ${reset_color} VSCode not currently running"
fi

# Check if accessibility database exists (indicates some apps have permissions)
if [[ -f "/Library/Application Support/com.apple.TCC/TCC.db" ]] || [[ -f "$HOME/Library/Application Support/com.apple.TCC/TCC.db" ]]; then
echo "${fg[blue]}ℹ${reset_color} Accessibility permissions: Grant to VSCode if automation fails"
echo " ${fg[blue]}→${reset_color} System Settings → Privacy & Security → Accessibility"
fi
fi

# Summary
echo ""
if [[ $has_errors -eq 0 && $has_warnings -eq 0 ]]; then
echo "${fg[green]}✓ All systems ready!${reset_color}"
return 0
elif [[ $has_errors -eq 0 ]]; then
echo "${fg[yellow]}⚠ Ready with warnings (see above for fixes)${reset_color}"
return 0
else
echo "${fg[red]}✗ Critical requirements missing (see above for fixes)${reset_color}"
return 1
fi
}

# Status command - manual system check
wtstatus() {
_wt_check_requirements "full" "true"
}

# Main function: Create new branch + worktree + VSCode with Claude
wtn() {
local branch_name="$1"
local base_branch="$2"

# Validation
if [[ -z "$branch_name" ]]; then
echo "${fg[red]}✗ Error: Branch name required${reset_color}"
echo "${fg[blue]}Usage: wtn <branch-name> [base-branch]${reset_color}"
echo "${fg[blue]}Example: wtn hotfix-urgent main${reset_color}"
return 1
fi

# Run system check
echo "${fg[cyan]}Checking requirements...${reset_color}\n"
if ! _wt_check_requirements "full" "false"; then
echo "\n${fg[red]}Cannot proceed due to missing requirements${reset_color}"
echo "${fg[blue]}Run 'wtstatus' for detailed diagnostics${reset_color}"
return 1
fi
echo ""

# Get repo root
local repo_root=$(git rev-parse --show-toplevel)
local worktree_dir="$repo_root/.worktrees"
# Sanitize branch name for folder: replace slashes with hyphens to avoid nested dirs
local folder_name="${branch_name//\//-}"
local worktree_path="$worktree_dir/$folder_name"

# Determine base branch
if [[ -z "$base_branch" ]]; then
# Auto-detect main/master
if git show-ref --verify --quiet refs/heads/main; then
base_branch="main"
elif git show-ref --verify --quiet refs/heads/master; then
base_branch="master"
else
# Fallback to current HEAD
base_branch="HEAD"
echo "${fg[yellow]}ℹ No base branch specified, using current HEAD${reset_color}"
fi
else
# Validate base branch exists
if ! git show-ref --verify --quiet refs/heads/"$base_branch" && [[ "$base_branch" != "HEAD" ]]; then
echo "${fg[red]}✗ Error: Base branch '$base_branch' does not exist${reset_color}"
echo "\n${fg[blue]}Available branches:${reset_color}"
git branch --list
return 1
fi
fi

# Show what we're doing
if [[ "$base_branch" == "HEAD" ]]; then
local current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "${fg[cyan]}→ Creating branch from current location ($current_branch)${reset_color}"
else
echo "${fg[cyan]}→ Creating branch from '$base_branch'${reset_color}"
fi

# Check if branch already exists in a worktree
if git worktree list | grep -q " \[$branch_name\]"; then
echo "${fg[red]}✗ Error: Branch '$branch_name' already exists in a worktree${reset_color}"
echo "\n${fg[blue]}Current worktrees:${reset_color}"
git worktree list
return 1
fi

# Create .worktrees directory if it doesn't exist
if [[ ! -d "$worktree_dir" ]]; then
echo "${fg[blue]}→ Creating .worktrees directory...${reset_color}"
mkdir -p "$worktree_dir"
fi

# Add .worktrees to .gitignore if not already there
local gitignore="$repo_root/.gitignore"
if [[ -f "$gitignore" ]] && ! grep -q "^\.worktrees/" "$gitignore"; then
echo "${fg[blue]}→ Adding .worktrees/ to .gitignore...${reset_color}"
echo ".worktrees/" >> "$gitignore"
elif [[ ! -f "$gitignore" ]]; then
echo "${fg[blue]}→ Creating .gitignore with .worktrees/...${reset_color}"
echo ".worktrees/" > "$gitignore"
fi

# Create new branch
echo "${fg[green]}→ Creating branch '$branch_name'...${reset_color}"
if ! git branch "$branch_name" "$base_branch"; then
echo "${fg[red]}✗ Error: Failed to create branch${reset_color}"
return 1
fi

# Create worktree
echo "${fg[green]}→ Creating worktree at .worktrees/$folder_name...${reset_color}"
if ! git worktree add "$worktree_path" "$branch_name"; then
echo "${fg[red]}✗ Error: Failed to create worktree${reset_color}"
git branch -d "$branch_name" 2>/dev/null
return 1
fi

# Copy/link gitignored but important files/directories
echo "${fg[blue]}→ Setting up gitignored configs and environment files...${reset_color}"

# Copy .husky directory (including the _ subdirectory with hooks)
if [[ -d "$repo_root/.husky" ]]; then
echo "${fg[blue]} • Copying .husky/ (including hook scripts)${reset_color}"
cp -R "$repo_root/.husky" "$worktree_path/"
fi

# Copy .env files (common patterns)
for env_file in .env .env.local .env.development .env.test .env.production; do
if [[ -f "$repo_root/$env_file" ]]; then
echo "${fg[blue]} • Copying $env_file${reset_color}"
cp "$repo_root/$env_file" "$worktree_path/"
fi
done

# Open VSCode
echo "${fg[green]}→ Opening VSCode...${reset_color}"
code "$worktree_path" --new-window

# Give VSCode time to fully load
sleep 2.5

# Run AppleScript to setup terminal with Claude and fullscreen
echo "${fg[cyan]}→ Setting up fullscreen and terminal with Claude...${reset_color}"

osascript <<'APPLESCRIPT'
tell application "Visual Studio Code"
activate
delay 1.5
end tell

tell application "System Events"
tell process "Code"
set frontmost to true
delay 1

-- Open integrated terminal (Ctrl+`)
keystroke "`" using control down
delay 1.5

-- Start claude in the terminal
keystroke "claude"
delay 0.3
key code 36 -- Enter
delay 0.5
end tell
end tell
APPLESCRIPT

local exit_code=$?

if [[ $exit_code -eq 0 ]]; then
echo "\n${fg[green]}✓ Success! Worktree '$branch_name' is ready${reset_color}"
echo "${fg[blue]} Location: $worktree_path${reset_color}"
echo "${fg[cyan]} Claude is starting in the left terminal${reset_color}"
else
echo "\n${fg[yellow]}⚠ Worktree created but terminal automation failed${reset_color}"
echo "${fg[blue]} Please manually open terminals in VSCode${reset_color}"
fi
}

# List all worktrees with elegant formatting
wtls() {
_wt_check_requirements "git-only" "false" || return 1

echo ""
echo "${fg[cyan]}Active worktrees:${reset_color}"
git worktree list | while IFS= read -r line; do
echo " $line"
done
}

# Remove worktree and optionally delete branch
wtrm() {
local branch_name="$1"

if [[ -z "$branch_name" ]]; then
echo "${fg[red]}✗ Error: Branch name required${reset_color}"
echo "${fg[blue]}Usage: wtrm <branch-name>${reset_color}"
return 1
fi

_wt_check_requirements "git-only" "false" || return 1
echo ""

local repo_root=$(git rev-parse --show-toplevel)
# Sanitize branch name for folder: replace slashes with hyphens to avoid nested dirs
local folder_name="${branch_name//\//-}"
local worktree_path="$repo_root/.worktrees/$folder_name"

if [[ ! -d "$worktree_path" ]]; then
echo "${fg[yellow]}⚠ Warning: Worktree not found at expected location${reset_color}"
echo "${fg[blue]}Current worktrees:${reset_color}"
git worktree list
return 1
fi

echo "${fg[yellow]}→ Removing worktree '$branch_name'...${reset_color}"

if git worktree remove "$worktree_path" --force; then
echo "${fg[green]}✓ Worktree removed${reset_color}"

# Check if branch still exists
if git show-ref --verify --quiet refs/heads/"$branch_name"; then
echo -n "${fg[blue]}Delete branch '$branch_name' too? [y/N]: ${reset_color}"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
if git branch -D "$branch_name"; then
echo "${fg[green]}✓ Branch deleted${reset_color}"
else
echo "${fg[red]}✗ Failed to delete branch${reset_color}"
fi
fi
fi
else
echo "${fg[red]}✗ Error: Failed to remove worktree${reset_color}"
return 1
fi
}

# Prune stale worktree metadata
wtprune() {
_wt_check_requirements "git-only" "false" || return 1
echo ""

echo "${fg[blue]}→ Pruning stale worktree metadata...${reset_color}"
git worktree prune -v
echo "${fg[green]}✓ Done${reset_color}"
}

# Quick jump to worktree directory
wtcd() {
local branch_name="$1"

if [[ -z "$branch_name" ]]; then
echo "${fg[red]}✗ Error: Branch name required${reset_color}"
echo "${fg[blue]}Usage: wtcd <branch-name>${reset_color}"
return 1
fi

_wt_check_requirements "git-only" "false" || return 1

local repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
# Sanitize branch name for folder: replace slashes with hyphens to avoid nested dirs
local folder_name="${branch_name//\//-}"
local worktree_path="$repo_root/.worktrees/$folder_name"

if [[ -d "$worktree_path" ]]; then
cd "$worktree_path"
echo "${fg[green]}✓ Switched to worktree: $branch_name${reset_color}"
else
echo "${fg[red]}✗ Error: Worktree '$branch_name' not found${reset_color}"
return 1
fi
}
