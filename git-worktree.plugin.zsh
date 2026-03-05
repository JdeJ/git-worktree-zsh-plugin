#!/usr/bin/env zsh
# Git Worktree Enhanced Plugin
# Elegant workflow for creating worktrees with VSCode and Claude integration

autoload -U colors && colors

# Load worktree configuration from .config.json
_wt_load_config() {
local repo_root="$1"
local config_file="$repo_root/.config.json"

# Default configuration
local default_config='{"copyFiles":{"enabled":true,"patterns":[{"path":".husky/","type":"directory"},{"path":"**/.env*","type":"glob"}]},"features":{"installDependencies":true,"openVSCode":true,"startClaude":true,"splitTerminal":true},"defaults":{"baseBranch":"main","worktreeDirectory":".worktrees"},"customCommand":""}'

if [[ -f "$config_file" ]]; then
# Config file exists, read it
cat "$config_file"
else
# Use defaults
echo "$default_config"
fi
}

# Parse config value using grep and sed
_wt_get_config_value() {
local config="$1"
local key="$2"

# Extract boolean value for features
grep -o "\"$key\":[^,}]*" <<< "$config" | sed 's/.*://;s/[^a-z]//g'
}

# Copy files based on config patterns
_wt_copy_files_from_config() {
local repo_root="$1"
local worktree_path="$2"
local config="$3"

# Extract patterns from config (simplified parsing)
# This looks for "path": "value" pairs within the patterns array
local patterns=$(grep -o '"path":"[^"]*"' <<< "$config" | sed 's/"path":"//;s/"//')

# Process patterns without subshell (avoid pipe)
while IFS= read -r pattern; do
[[ -z "$pattern" ]] && continue

# Handle different pattern types
if [[ "$pattern" == *"/" ]]; then
# Directory pattern
local dir_path="${pattern%/}"
if [[ -d "$repo_root/$dir_path" ]]; then
echo "${fg[blue]} • Copying $pattern${reset_color}"
# Use rsync if available (handles symlinks better), otherwise cp
if command -v rsync &>/dev/null; then
rsync -a --quiet "$repo_root/$dir_path" "$worktree_path/" 2>/dev/null || \
cp -R "$repo_root/$dir_path" "$worktree_path/" 2>/dev/null || true
else
cp -R "$repo_root/$dir_path" "$worktree_path/" 2>/dev/null || true
fi
fi
elif [[ "$pattern" == *"*"* ]]; then
# Glob pattern (e.g., **/.env*)
echo "${fg[blue]} • Searching for files matching $pattern${reset_color}"
local glob_pattern="${pattern#**/}"
local files=()

# Use find with -prune to avoid descending into excluded directories
while IFS= read -r file; do
# Make path relative to repo root
local rel_path="${file#$repo_root/}"
files+=("$rel_path")
done < <(find "$repo_root" \( \
-name ".git" -o \
-name ".worktrees" -o \
-name "node_modules" -o \
-name "dist" -o \
-name "build" -o \
-name ".next" \
\) -prune -o -type f -name "$glob_pattern" -print \
2>/dev/null)

if [[ ${#files[@]} -gt 0 ]]; then
echo "${fg[blue]} • Found ${#files[@]} file(s), copying...${reset_color}"
for file in "${files[@]}"; do
local file_dir="${file:h}"
mkdir -p "$worktree_path/$file_dir"
cp "$repo_root/$file" "$worktree_path/$file" 2>/dev/null || true
done
else
echo "${fg[yellow]} No files found${reset_color}"
fi
else
# Single file
if [[ -f "$repo_root/$pattern" ]]; then
echo "${fg[blue]} • Copying $pattern${reset_color}"
local file_dir=$(dirname "$pattern")
if [[ "$file_dir" != "." ]]; then
mkdir -p "$worktree_path/$file_dir"
fi
if cp "$repo_root/$pattern" "$worktree_path/$pattern" 2>/dev/null; then
echo "${fg[green]} ✓ Copied${reset_color}"
else
echo "${fg[red]} ✗ Failed to copy${reset_color}"
fi
else
echo "${fg[yellow]} • Skipping $pattern (not found)${reset_color}"
fi
fi
done <<< "$patterns"
}

# Detect package manager from lockfiles
_wt_detect_package_manager() {
local repo_root="$1"

# Check for lockfiles in priority order
if [[ -f "$repo_root/pnpm-lock.yaml" ]]; then
echo "pnpm"
elif [[ -f "$repo_root/bun.lockb" ]]; then
echo "bun"
elif [[ -f "$repo_root/yarn.lock" ]]; then
echo "yarn"
elif [[ -f "$repo_root/package-lock.json" ]]; then
echo "npm"
elif [[ -f "$repo_root/package.json" ]]; then
# package.json exists but no lockfile - default to npm
echo "npm"
else
# No Node.js project detected
echo ""
fi
}

# Install dependencies in worktree
_wt_install_dependencies() {
local worktree_path="$1"
local pkg_manager="$2"

if [[ -z "$pkg_manager" ]]; then
return 0
fi

echo "${fg[cyan]}→ Installing dependencies with $pkg_manager...${reset_color}"

# Check if package manager is available
if ! command -v "$pkg_manager" &>/dev/null; then
echo "${fg[yellow]} ⚠ $pkg_manager not found in PATH, skipping install${reset_color}"
echo "${fg[blue]} → You can manually run: cd $worktree_path && $pkg_manager install${reset_color}"
return 1
fi

# Run installation in worktree
(
cd "$worktree_path" || return 1

case "$pkg_manager" in
pnpm)
pnpm install --silent
;;
bun)
bun install --silent
;;
yarn)
yarn install --silent
;;
npm)
npm install --silent --no-progress
;;
esac
)

if [[ $? -eq 0 ]]; then
echo "${fg[green]} ✓ Dependencies installed successfully${reset_color}"
return 0
else
echo "${fg[red]} ✗ Failed to install dependencies${reset_color}"
echo "${fg[blue]} → You can manually run: cd $worktree_path && $pkg_manager install${reset_color}"
return 1
fi
}

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

# Load configuration
local config=$(_wt_load_config "$repo_root")
local worktree_dir_from_config=$(grep -o '"worktreeDirectory":"[^"]*"' <<< "$config" | sed 's/.*":\s*"//;s/"//')
local worktree_dir="${worktree_dir_from_config:-$repo_root/.worktrees}"
local worktree_path="$worktree_dir/$branch_name"

# Get feature flags from config
local feat_install_deps=$(_wt_get_config_value "$config" "installDependencies")
local feat_open_vscode=$(_wt_get_config_value "$config" "openVSCode")
local feat_start_claude=$(_wt_get_config_value "$config" "startClaude")
local feat_split_terminal=$(_wt_get_config_value "$config" "splitTerminal")
local copy_files_enabled=$(_wt_get_config_value "$config" "enabled")

# Get custom command from config
local custom_command=$(grep -o '"customCommand":"[^"]*"' <<< "$config" | sed 's/"customCommand":"//;s/"//')

# Determine base branch
if [[ -z "$base_branch" ]]; then
# Get default from config
local config_base_branch=$(grep -o '"baseBranch":"[^"]*"' <<< "$config" | sed 's/.*":\s*"//;s/"//')

# Try config default first, then auto-detect main/master
if [[ -n "$config_base_branch" ]] && git show-ref --verify --quiet refs/heads/"$config_base_branch"; then
base_branch="$config_base_branch"
elif git show-ref --verify --quiet refs/heads/main; then
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

# Check if branch already exists (not in a worktree)
local branch_exists=false
if git show-ref --verify --quiet refs/heads/"$branch_name"; then
branch_exists=true
echo "${fg[cyan]}→ Branch '$branch_name' already exists, creating worktree from it${reset_color}"

# Check if branch has upstream configured
local upstream=$(git rev-parse --abbrev-ref "$branch_name@{upstream}" 2>/dev/null)
if [[ -z "$upstream" ]]; then
# No upstream set - check if remote branch exists
if git ls-remote --exit-code --heads origin "$branch_name" &>/dev/null; then
echo "${fg[blue]} → Setting up tracking with origin/$branch_name${reset_color}"
git branch --set-upstream-to=origin/"$branch_name" "$branch_name" 2>/dev/null
else
echo "${fg[yellow]} ℹ No upstream configured - use 'git push -u origin $branch_name' for first push${reset_color}"
fi
fi
else
# Show what we're doing (only for NEW branches)
if [[ "$base_branch" == "HEAD" ]]; then
local current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "${fg[cyan]}→ Creating branch from current location ($current_branch)${reset_color}"
else
echo "${fg[cyan]}→ Creating branch from '$base_branch'${reset_color}"
fi

# Create new branch
echo "${fg[green]}→ Creating branch '$branch_name'...${reset_color}"
if ! git branch "$branch_name" "$base_branch"; then
echo "${fg[red]}✗ Error: Failed to create branch${reset_color}"
return 1
fi
fi

# Create worktree
echo "${fg[green]}→ Creating worktree at .worktrees/$branch_name...${reset_color}"
if ! git worktree add "$worktree_path" "$branch_name"; then
echo "${fg[red]}✗ Error: Failed to create worktree${reset_color}"
# Only delete the branch if we just created it
if [[ "$branch_exists" == "false" ]]; then
git branch -d "$branch_name" 2>/dev/null
fi
return 1
fi

# Copy files based on configuration
if [[ "$copy_files_enabled" == "true" ]]; then
echo "${fg[blue]}→ Setting up gitignored configs and environment files...${reset_color}"
_wt_copy_files_from_config "$repo_root" "$worktree_path" "$config"
fi

# Detect package manager (will install in VSCode terminal)
local pkg_manager=""
if [[ "$feat_install_deps" == "true" ]]; then
pkg_manager=$(_wt_detect_package_manager "$repo_root")
if [[ -n "$pkg_manager" ]]; then
echo "${fg[blue]}→ Detected package manager: $pkg_manager${reset_color}"
fi
fi

# Open VSCode if enabled
if [[ "$feat_open_vscode" == "true" ]]; then
echo "${fg[green]}→ Opening VSCode...${reset_color}"
code "$worktree_path" --new-window

# Give VSCode time to fully load
sleep 2.5

# Run AppleScript to setup terminal with Claude
if [[ "$feat_start_claude" == "true" ]] || [[ "$feat_split_terminal" == "true" ]]; then
echo "${fg[cyan]}→ Setting up terminal...${reset_color}"

# Build the install command if package manager detected
local install_cmd=""
if [[ -n "$pkg_manager" ]]; then
install_cmd="$pkg_manager install"
fi

# Generate AppleScript based on feature flags
local applescript_content="tell application \"Visual Studio Code\"
activate
delay 2
end tell

tell application \"System Events\"
tell process \"Code\"
set frontmost to true
delay 1.5

-- Open integrated terminal (Ctrl+\`)
keystroke \"\`\" using control down
delay 6"

# Add Claude startup if enabled
if [[ "$feat_start_claude" == "true" ]]; then
applescript_content="$applescript_content

-- Start claude in the first terminal
keystroke \"claude\"
delay 0.5
key code 36 -- Enter
delay 3"
fi

# Add terminal split if enabled
if [[ "$feat_split_terminal" == "true" ]]; then
applescript_content="$applescript_content

-- Split terminal using Command Palette
keystroke \"p\" using {command down, shift down}
delay 0.8
keystroke \"Terminal: Split Terminal\"
delay 0.5
key code 36 -- Enter
delay 2"

# Add install command in split terminal if enabled
if [[ -n "$install_cmd" ]]; then
applescript_content="$applescript_content

-- Run install command in second terminal
keystroke \"$install_cmd\"
delay 0.3
key code 36 -- Enter"
fi
fi

applescript_content="$applescript_content
end tell
end tell"

echo "$applescript_content" | osascript

local exit_code=$?

if [[ $exit_code -eq 0 ]]; then
echo "\n${fg[green]}✓ Success! Worktree '$branch_name' is ready${reset_color}"
echo "${fg[blue]} Location: $worktree_path${reset_color}"

if [[ "$feat_start_claude" == "true" ]]; then
echo "${fg[cyan]} Claude is running in the left terminal${reset_color}"
fi

if [[ -n "$pkg_manager" ]] && [[ "$feat_split_terminal" == "true" ]]; then
echo "${fg[cyan]} Installing dependencies with $pkg_manager in the right terminal${reset_color}"
fi
else
echo "\n${fg[yellow]}⚠ Worktree created but terminal automation failed${reset_color}"
echo "${fg[blue]} Please manually open terminals in VSCode${reset_color}"
fi
fi
else
# VSCode not enabled, just show success
echo "\n${fg[green]}✓ Success! Worktree '$branch_name' is ready${reset_color}"
echo "${fg[blue]} Location: $worktree_path${reset_color}"
fi

# Execute custom command if configured
if [[ -n "$custom_command" ]]; then
echo "${fg[cyan]}→ Running custom command...${reset_color}"

# Export environment variables for the custom command
export WT_WORKTREE_PATH="$worktree_path"
export WT_BRANCH_NAME="$branch_name"
export WT_PACKAGE_MANAGER="$pkg_manager"
export WT_REPO_ROOT="$repo_root"

# Execute the custom command
if eval "$custom_command"; then
echo "${fg[green]} ✓ Custom command completed${reset_color}"
else
echo "${fg[yellow]} ⚠ Custom command failed (exit code: $?)${reset_color}"
fi

# Clean up exported variables
unset WT_WORKTREE_PATH WT_BRANCH_NAME WT_PACKAGE_MANAGER WT_REPO_ROOT
fi
}

# List all worktrees with rich table formatting
wtls() {
_wt_check_requirements "git-only" "false" || return 1

# Detect the current worktree path for the "← current" indicator
local current_path
current_path=$(git rev-parse --show-toplevel 2>/dev/null)

# Parse worktrees via porcelain format
local -a wt_paths wt_branches
local _path="" _branch="" _head=""

while IFS= read -r _line; do
case "$_line" in
"worktree "*)
[[ -n "$_path" ]] && {
wt_paths+=("$_path")
wt_branches+=("${_branch:-HEAD:${_head:0:7}}")
_path="" _branch="" _head=""
}
_path="${_line#worktree }"
;;
"branch "*)
_branch="${_line#branch refs/heads/}"
;;
"HEAD "*)
_head="${_line#HEAD }"
;;
"")
[[ -n "$_path" ]] && {
wt_paths+=("$_path")
wt_branches+=("${_branch:-HEAD:${_head:0:7}}")
_path="" _branch="" _head=""
}
;;
esac
done < <(git worktree list --porcelain 2>/dev/null)
# Capture final entry if not followed by blank line
[[ -n "$_path" ]] && {
wt_paths+=("$_path")
wt_branches+=("${_branch:-HEAD:${_head:0:7}}")
}

local total=${#wt_paths[@]}
if (( total == 0 )); then
echo "${fg[yellow]}No worktrees found${reset_color}"
return 1
fi

# Column widths (visible characters, excluding separators)
local W_BRANCH=45 W_STATUS=8 W_COMMIT=22 W_CHANGES=12

echo ""

# Header — colors wrap the entire format string so %-Ns counts only raw text
printf " ${fg_bold[white]}%-${W_BRANCH}s %-${W_STATUS}s %-${W_COMMIT}s %s${reset_color}\n" \
"BRANCH" "STATUS" "LAST COMMIT" "CHANGES"
echo ""

local now
now=$(date +%s)

# Declare all loop variables up front — avoids zsh reprinting them on iterations 2+
local p branch disp_branch commit_ts age_sec age_days age_str dot_color change_count

for (( i=1; i<=total; i++ )); do
p="${wt_paths[$i]}"
branch="${wt_branches[$i]}"

# Truncate branch name (right-truncate with …)
disp_branch="$branch"
(( ${#branch} > W_BRANCH )) && disp_branch="${branch:0:$(( W_BRANCH - 3 ))}..."

# Last commit age
commit_ts=$(git -C "$p" log -1 --format="%ct" 2>/dev/null)
age_sec=0
[[ -n "$commit_ts" ]] && age_sec=$(( now - commit_ts ))
age_days=$(( age_sec / 86400 ))

if (( age_sec < 60 )); then age_str="just now"
elif (( age_sec < 3600 )); then age_str="$((age_sec / 60))m ago"
elif (( age_sec < 86400 )); then age_str="$((age_sec / 3600))h ago"
elif (( age_days < 7 )); then age_str="${age_days}d ago"
elif (( age_days < 30 )); then age_str="$((age_days / 7))w ago"
elif (( age_days < 365 )); then age_str="$((age_days / 30))mo ago"
else age_str="$((age_days / 365))y ago"
fi

# Status dot color based on commit age
if (( age_days <= 7 )); then dot_color="${fg[green]}"
elif (( age_days <= 30 )); then dot_color="${fg[yellow]}"
else dot_color="${fg[red]}"
fi

# Git change count (-uno skips untracked scan — much faster on large repos)
change_count=$(git -C "$p" status --porcelain -uno 2>/dev/null | wc -l | tr -d ' ')
change_count="${change_count:-0}"

# ── Print row ──────────────────────────────────────────────────────────
printf " "

# BRANCH (cyan, padded via format string so alignment is on raw text)
printf "${fg[cyan]}%-${W_BRANCH}s${reset_color} " "$disp_branch"

# STATUS: colored dot + padding to fill W_STATUS
printf "${dot_color}●${reset_color}"
printf "%-$((W_STATUS - 1))s " ""

# LAST COMMIT: "← current Xh ago" for current worktree, else just time
if [[ "$p" == "$current_path" ]]; then
# "← current" = 9 chars + 1 space = 10, remainder fills W_COMMIT
printf "${fg[cyan]}← current${reset_color} %-$((W_COMMIT - 10))s " "$age_str"
else
printf "%-${W_COMMIT}s " "$age_str"
fi

# CHANGES
if (( change_count > 0 )); then
printf "${fg[yellow]}Dirty +${change_count}${reset_color}\n"
else
printf "${fg[green]}Clean${reset_color}\n"
fi
done

# Footer legend
echo ""
printf " Total: ${total} worktree(s) | Legend: ${fg[green]}●${reset_color} Recent (≤7d) | ${fg[yellow]}●${reset_color} Medium (8-30d) | ${fg[red]}●${reset_color} Stale (30+d)\n"
echo ""
}

# Remove worktree and optionally delete branch
wtrm() {
local branch_name="$1"

_wt_check_requirements "git-only" "false" || return 1

# Get main worktree root (not current worktree)
local main_worktree=$(git worktree list --porcelain 2>/dev/null | grep -m 1 "^worktree" | sed 's/^worktree //')
local worktree_dir="$main_worktree/.worktrees"

if [[ -z "$branch_name" ]]; then
# Collect available worktrees via git (handles namespaced branches like user/feature-x)
local worktrees=()
local _wt_path=""
while IFS= read -r _wt_line; do
if [[ "$_wt_line" == "worktree "* ]]; then
_wt_path="${_wt_line#worktree }"
elif [[ "$_wt_line" == "branch "* ]] && [[ "$_wt_path" == "$worktree_dir/"* ]]; then
worktrees+=("${_wt_line#branch refs/heads/}")
fi
done < <(git worktree list --porcelain 2>/dev/null)

if [[ ${#worktrees[@]} -eq 0 ]]; then
echo "${fg[yellow]}No worktrees found in .worktrees/${reset_color}"
return 1
fi

if command -v fzf &>/dev/null; then
branch_name=$(printf '%s\n' "${worktrees[@]}" | \
fzf --prompt=" Remove worktree: " --height=40% --border --no-info)
else
echo "${fg[cyan]}Available worktrees:${reset_color}"
local i=1
for wt in "${worktrees[@]}"; do
echo " ${fg[blue]}$i)${reset_color} $wt"
(( i++ ))
done
echo ""
echo -n "${fg[blue]}Select [1-${#worktrees[@]}]: ${reset_color}"
read -r choice
if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#worktrees[@]} )); then
branch_name="${worktrees[$choice]}"
else
echo "${fg[red]}✗ Invalid selection${reset_color}"
return 1
fi
fi

[[ -z "$branch_name" ]] && return 0
fi
echo ""

local worktree_path="$worktree_dir/$branch_name"

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

_wt_check_requirements "git-only" "false" || return 1

# Use main worktree root so this works correctly from inside any worktree
local main_worktree=$(git worktree list --porcelain 2>/dev/null | grep -m 1 "^worktree" | sed 's/^worktree //')
local worktree_dir="$main_worktree/.worktrees"

if [[ -z "$branch_name" ]]; then
# Collect available worktrees via git (handles namespaced branches like user/feature-x)
local worktrees=()
local _wt_path=""
while IFS= read -r _wt_line; do
if [[ "$_wt_line" == "worktree "* ]]; then
_wt_path="${_wt_line#worktree }"
elif [[ "$_wt_line" == "branch "* ]] && [[ "$_wt_path" == "$worktree_dir/"* ]]; then
worktrees+=("${_wt_line#branch refs/heads/}")
fi
done < <(git worktree list --porcelain 2>/dev/null)

if [[ ${#worktrees[@]} -eq 0 ]]; then
echo "${fg[yellow]}No worktrees found in .worktrees/${reset_color}"
return 1
fi

# Prepend base repo as first option using dynamic repo name
local _base_label="root [${main_worktree:t}]"
worktrees=("$_base_label" "${worktrees[@]}")

if command -v fzf &>/dev/null; then
branch_name=$(printf '%s\n' "${worktrees[@]}" | \
fzf --prompt=" Jump to worktree: " --height=40% --border --no-info)
else
echo "${fg[cyan]}Available worktrees:${reset_color}"
local i=1
for wt in "${worktrees[@]}"; do
echo " ${fg[blue]}$i)${reset_color} $wt"
(( i++ ))
done
echo ""
echo -n "${fg[blue]}Select [1-${#worktrees[@]}]: ${reset_color}"
read -r choice
if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#worktrees[@]} )); then
branch_name="${worktrees[$choice]}"
else
echo "${fg[red]}✗ Invalid selection${reset_color}"
return 1
fi
fi

# User cancelled (e.g. fzf Escape)
[[ -z "$branch_name" ]] && return 0

# Handle base repo selection
if [[ "$branch_name" == "$_base_label" ]]; then
cd "$main_worktree"
echo "${fg[green]}✓ Switched to ${main_worktree:t}${reset_color}"
return 0
fi
fi

local worktree_path="$worktree_dir/$branch_name"

if [[ -d "$worktree_path" ]]; then
cd "$worktree_path"
echo "${fg[green]}✓ Switched to worktree: $branch_name${reset_color}"
else
echo "${fg[red]}✗ Error: Worktree '$branch_name' not found${reset_color}"
return 1
fi
}
