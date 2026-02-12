#!/usr/bin/env bash
# Comprehensive system health check for dotfiles setup
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASSED=0
WARNINGS=0
ERRORS=0

# Suggestions array
declare -a SUGGESTIONS

# Parse arguments
QUICK_MODE=false
SECTION=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --quick)
      QUICK_MODE=true
      shift
      ;;
    --section)
      SECTION="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--quick] [--section <name>]"
      exit 1
      ;;
  esac
done

# Check result helper
# Args: check_name, status (0=pass, 1=warning, 2=error), message
record_result() {
  local name="$1"
  local status="$2"
  local message="$3"

  case $status in
    0)
      echo -e "${GREEN}✓${NC} $name"
      echo "  $message"
      ((PASSED++))
      ;;
    1)
      echo -e "${YELLOW}⚠${NC} $name"
      echo "  ⚠ $message"
      ((WARNINGS++))
      ;;
    2)
      echo -e "${RED}✗${NC} $name"
      echo "  ✗ $message"
      ((ERRORS++))
      ;;
  esac
  echo ""
}

# Add suggestion helper
add_suggestion() {
  SUGGESTIONS+=("$1")
}

# ============================================================================
# CHECK FUNCTIONS
# ============================================================================

check_stow() {
  echo -e "${BLUE}Checking Stow Configuration...${NC}"
  echo ""

  local dotfiles_dir="$HOME/dotfiles"
  local stow_dir="$dotfiles_dir/stow"

  if [[ ! -d "$stow_dir" ]]; then
    record_result "Stow Configuration" 2 "Stow directory not found at $stow_dir"
    add_suggestion "Ensure dotfiles are cloned to ~/dotfiles"
    return
  fi

  # Expected packages
  local packages=(bat ghostty git gpg shell ssh vim vscode zsh)
  local symlinked=0
  local total=${#packages[@]}

  for pkg in "${packages[@]}"; do
    local pkg_dir="$stow_dir/$pkg"
    if [[ -d "$pkg_dir" ]]; then
      ((symlinked++))
    fi
  done

  # Check for broken symlinks in home directory
  local broken_count=0
  while IFS= read -r link; do
    if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
      ((broken_count++))
    fi
  done < <(find "$HOME" -maxdepth 1 -type l 2>/dev/null)

  if [[ $symlinked -eq $total ]] && [[ $broken_count -eq 0 ]]; then
    record_result "Stow Configuration" 0 "$symlinked/$total packages properly symlinked, no broken symlinks found"
  elif [[ $broken_count -gt 0 ]]; then
    record_result "Stow Configuration" 2 "Found $broken_count broken symlinks in home directory"
    add_suggestion "Run: make unstow && make stow to fix symlinks"
  else
    record_result "Stow Configuration" 2 "Only $symlinked/$total packages found"
    add_suggestion "Ensure all stow packages exist in ~/dotfiles/stow/"
  fi
}

check_ssh() {
  echo -e "${BLUE}Checking SSH Configuration...${NC}"
  echo ""

  local issues=0
  local details=""

  # Check personal key
  if [[ -f "$HOME/.ssh/id_ed25519_personal" ]]; then
    local perms=$(stat -f "%OLp" "$HOME/.ssh/id_ed25519_personal" 2>/dev/null || echo "")
    if [[ "$perms" == "600" ]]; then
      details+="Personal key: ~/.ssh/id_ed25519_personal (600)\n  "
    else
      details+="Personal key: incorrect permissions ($perms, expected 600)\n  "
      ((issues++))
      add_suggestion "Fix permissions: chmod 600 ~/.ssh/id_ed25519_personal"
    fi
  else
    details+="Personal key: missing\n  "
    ((issues++))
    add_suggestion "Generate personal SSH key: make ssh-setup"
  fi

  # Check work key (optional - warning only)
  if [[ -f "$HOME/.ssh/id_ed25519_work" ]]; then
    local perms=$(stat -f "%OLp" "$HOME/.ssh/id_ed25519_work" 2>/dev/null || echo "")
    if [[ "$perms" == "600" ]]; then
      details+="Work key: ~/.ssh/id_ed25519_work (600)\n  "
    else
      details+="Work key: incorrect permissions ($perms, expected 600)\n  "
      ((issues++))
      add_suggestion "Fix permissions: chmod 600 ~/.ssh/id_ed25519_work"
    fi
  else
    details+="⚠ Work key: not configured (optional)\n  "
  fi

  # Check SSH config includes
  if [[ -f "$HOME/.ssh/config" ]]; then
    if grep -q "Include" "$HOME/.ssh/config" 2>/dev/null; then
      local includes_count=$(find "$HOME/.ssh/config.d" -name "*.conf" 2>/dev/null | wc -l | xargs)
      details+="SSH config includes: $includes_count loaded"
    else
      details+="SSH config: Include directive missing"
      ((issues++))
      add_suggestion "Re-stow SSH config: cd ~/dotfiles && make stow"
    fi
  else
    details+="SSH config: missing"
    ((issues++))
  fi

  # Check SSH agent (warning only)
  if ssh-add -l &>/dev/null; then
    local loaded_keys=$(ssh-add -l | wc -l | xargs)
    details+="\n  SSH agent: $loaded_keys keys loaded"
  else
    details+="\n  ⚠ SSH agent: no keys loaded"
    add_suggestion "Load SSH keys: ssh-add ~/.ssh/id_ed25519_personal ~/.ssh/id_ed25519_work"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "SSH Configuration" 0 "$details"
  else
    record_result "SSH Configuration" 2 "$details"
  fi
}

check_gpg() {
  echo -e "${BLUE}Checking GPG Configuration...${NC}"
  echo ""

  local issues=0
  local details=""

  # Check if GPG key exists
  if gpg --list-secret-keys &>/dev/null; then
    local key_id=$(gpg --list-secret-keys --keyid-format=long | grep sec | head -1 | awk '{print $2}' | cut -d'/' -f2)
    details+="Secret key: $key_id\n  "
  else
    details+="No GPG secret key found\n  "
    ((issues++))
    add_suggestion "Generate GPG key: make gpg-setup"
  fi

  # Check Git signing config
  if git config --global user.signingkey &>/dev/null; then
    details+="Git signing: enabled\n  "
  else
    details+="Git signing: not configured\n  "
    ((issues++))
    add_suggestion "Configure GPG signing: make gpg-setup"
  fi

  # Test GPG sign (warning only)
  if ! echo "test" | gpg --clear-sign &>/dev/null; then
    details+="⚠ GPG test sign failed"
    add_suggestion "Check GPG agent: pkill gpg-agent && gpgconf --launch gpg-agent"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "GPG Configuration" 0 "$details"
  else
    record_result "GPG Configuration" 2 "$details"
  fi
}

check_git() {
  echo -e "${BLUE}Checking Git Configuration...${NC}"
  echo ""

  local issues=0
  local details=""

  # Check conditional includes exist in .gitconfig
  if [[ -f "$HOME/.gitconfig" ]]; then
    if grep -q "includeIf" "$HOME/.gitconfig"; then
      details+="Conditional includes: configured\n  "
    else
      details+="Conditional includes: missing from .gitconfig\n  "
      ((issues++))
      add_suggestion "Re-stow git config: cd ~/dotfiles && make stow"
    fi
  else
    details+="No .gitconfig found\n  "
    ((issues++))
    add_suggestion "Re-stow git config: cd ~/dotfiles && make stow"
  fi

  # Test in personal repo (if exists)
  if [[ -d "$HOME/Developer/personal/projects/dotfiles/.git" ]]; then
    cd "$HOME/Developer/personal/projects/dotfiles"
    local ssh_cmd=$(git config core.sshCommand || echo "")
    if [[ "$ssh_cmd" == *"id_ed25519_personal"* ]]; then
      details+="Personal repos: using id_ed25519_personal\n  "
    else
      details+="Personal repos: incorrect SSH key\n  "
      ((issues++))
      add_suggestion "Check .gitconfig-personal conditional include"
    fi
  fi

  # Test in work repo (if exists)
  if [[ -d "$HOME/Developer/work/clients" ]]; then
    local work_repo=$(find "$HOME/Developer/work/clients" -name ".git" -type d | head -1)
    if [[ -n "$work_repo" ]]; then
      cd "$(dirname "$work_repo")"
      local ssh_cmd=$(git config core.sshCommand || echo "")
      if [[ "$ssh_cmd" == *"id_ed25519_work"* ]]; then
        details+="Work repos: using id_ed25519_work"
      else
        details+="Work repos: incorrect SSH key"
        ((issues++))
        add_suggestion "Check .gitconfig-work conditional include"
      fi
    fi
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Git Configuration" 0 "$details"
  else
    record_result "Git Configuration" 2 "$details"
  fi
}

check_shell() {
  echo -e "${BLUE}Checking Shell Configuration...${NC}"
  echo ""

  local issues=0
  local details=""

  # Source shell config in subshell to check functions/aliases
  # We need to check if the config files exist and are properly linked
  local shell_files=(
    "$HOME/.zshrc"
    "$HOME/.config/shell/functions.sh"
    "$HOME/.config/shell/aliases.sh"
  )

  local missing_files=0
  for file in "${shell_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      ((missing_files++))
    fi
  done

  if [[ $missing_files -eq 0 ]]; then
    details+="Shell config files: all present\n  "

    # Count functions defined in functions.sh
    local func_count=$(grep -c "^[a-z_]*() {" "$HOME/.config/shell/functions.sh" 2>/dev/null || echo "0")
    if [[ $func_count -gt 0 ]]; then
      details+="Functions: $func_count defined\n  "
    else
      details+="Functions: none found\n  "
      ((issues++))
    fi

    # Count aliases defined in aliases.sh
    local alias_count=$(grep -c "^alias " "$HOME/.config/shell/aliases.sh" 2>/dev/null || echo "0")
    if [[ $alias_count -gt 0 ]]; then
      details+="Aliases: $alias_count defined\n  "
    else
      details+="Aliases: none found\n  "
      ((issues++))
    fi
  else
    details+="Shell config files: $missing_files missing\n  "
    ((issues++))
    add_suggestion "Re-stow shell config: cd ~/dotfiles && make stow"
  fi

  # Check PATH
  local path_items=(fnm bun brew)
  local path_ok=true

  for item in "${path_items[@]}"; do
    if ! command -v "$item" &>/dev/null; then
      path_ok=false
      details+="⚠ $item not found in PATH\n  "
    fi
  done

  if $path_ok; then
    details+="PATH: fnm, Bun, Homebrew found"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Shell Configuration" 0 "$details"
  else
    record_result "Shell Configuration" 2 "$details"
  fi
}

check_developer() {
  echo -e "${BLUE}Checking Developer Directory...${NC}"
  echo ""

  local issues=0
  local details=""

  # Check structure exists
  local dirs=(
    "$HOME/Developer/personal/projects"
    "$HOME/Developer/personal/experiments"
    "$HOME/Developer/personal/learning"
    "$HOME/Developer/work/clients"
    "$HOME/Developer/archive"
  )

  local missing=0
  for dir in "${dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
      ((missing++))
    fi
  done

  if [[ $missing -eq 0 ]]; then
    details+="Structure: complete\n  "
  else
    details+="Structure: $missing directories missing\n  "
    ((issues++))
    add_suggestion "Create structure: mkdir -p ~/Developer/{personal/{projects,experiments,learning},work/clients,archive}"
  fi

  # Count repos per category
  local total=$(find "$HOME/Developer" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local personal_projects=$(find "$HOME/Developer/personal/projects" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local personal_experiments=$(find "$HOME/Developer/personal/experiments" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local personal_learning=$(find "$HOME/Developer/personal/learning" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local work=$(find "$HOME/Developer/work" -name ".git" -type d 2>/dev/null | wc -l | xargs)
  local archive=$(find "$HOME/Developer/archive" -name ".git" -type d 2>/dev/null | wc -l | xargs)

  details+="Repositories: $total total\n  "
  details+="  - personal/projects: $personal_projects\n  "
  details+="  - personal/experiments: $personal_experiments\n  "
  details+="  - personal/learning: $personal_learning\n  "
  details+="  - work/clients: $work\n  "
  details+="  - archive: $archive"

  # Check old structure removed
  if [[ -d "$HOME/Developer/repositories" ]]; then
    details+="\n  ⚠ Old repositories/ folder still exists"
    add_suggestion "Complete migration: make complete-migration"
  fi

  if [[ $issues -eq 0 ]]; then
    record_result "Developer Directory" 0 "$details"
  else
    record_result "Developer Directory" 2 "$details"
  fi
}

check_runtime() {
  echo -e "${BLUE}Checking Runtime Environments...${NC}"
  echo ""

  local details=""

  # Node.js via fnm
  if command -v node &>/dev/null; then
    local node_version=$(node --version)
    details+="Node.js: $node_version (via fnm)\n  "
  else
    details+="Node.js: not installed\n  "
    add_suggestion "Install Node.js: fnm install --lts"
  fi

  # Bun
  if command -v bun &>/dev/null; then
    local bun_version=$(bun --version)
    details+="Bun: $bun_version"
  else
    details+="Bun: not installed"
    add_suggestion "Install Bun: curl -fsSL https://bun.sh/install | bash"
  fi

  record_result "Runtime Environments" 0 "$details"
}

check_launchd() {
  if $QUICK_MODE; then
    return
  fi

  echo -e "${BLUE}Checking LaunchD Agents...${NC}"
  echo ""

  local details=""
  local agent_count=$(launchctl list | grep com.user 2>/dev/null | wc -l | xargs)

  if [[ $agent_count -gt 0 ]]; then
    details+="Loaded agents: $agent_count\n  "

    # Check obsidian-sync specifically
    if launchctl list | grep -q com.user.obsidian-sync; then
      details+="com.user.obsidian-sync: running"
    fi
  else
    details+="No user agents loaded"
  fi

  # Check log directory exists
  if [[ ! -d "$HOME/.local/log" ]]; then
    details+="\n  ⚠ Log directory missing"
    add_suggestion "Create log directory: mkdir -p ~/.local/log"
  fi

  record_result "LaunchD Agents" 0 "$details"
}

check_homebrew() {
  if $QUICK_MODE; then
    return
  fi

  echo -e "${BLUE}Checking Homebrew...${NC}"
  echo ""

  local details=""

  if command -v brew &>/dev/null; then
    local brew_version=$(brew --version | head -1)
    details+="Homebrew: $brew_version\n  "

    # Check for outdated packages (warning only)
    local outdated=$(brew outdated 2>/dev/null | wc -l | xargs)
    if [[ $outdated -gt 0 ]]; then
      details+="⚠ $outdated outdated packages"
      add_suggestion "Update packages: brew upgrade"
    else
      details+="All packages up to date"
    fi
  else
    details+="Homebrew: not installed"
    add_suggestion "Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  fi

  # Check profile
  if [[ -f "$HOME/.config/dotfiles-profile" ]]; then
    local profile=$(cat "$HOME/.config/dotfiles-profile")
    details+="\n  Profile: $profile"
  fi

  record_result "Homebrew" 0 "$details"
}

# ============================================================================
# MAIN
# ============================================================================

echo -e "${BLUE}System Health Check${NC}"
echo "==================="
echo ""

# Run checks based on section filter
if [[ -z "$SECTION" ]] || [[ "$SECTION" == "stow" ]]; then
  check_stow
fi

if [[ -z "$SECTION" ]] || [[ "$SECTION" == "ssh" ]]; then
  check_ssh
fi

if [[ -z "$SECTION" ]] || [[ "$SECTION" == "gpg" ]]; then
  check_gpg
fi

if [[ -z "$SECTION" ]] || [[ "$SECTION" == "git" ]]; then
  check_git
fi

if [[ -z "$SECTION" ]] || [[ "$SECTION" == "shell" ]]; then
  check_shell
fi

if [[ -z "$SECTION" ]] || [[ "$SECTION" == "developer" ]]; then
  check_developer
fi

if [[ -z "$SECTION" ]] || [[ "$SECTION" == "runtime" ]]; then
  check_runtime
fi

if [[ -z "$SECTION" ]] || [[ "$SECTION" == "launchd" ]]; then
  check_launchd
fi

if [[ -z "$SECTION" ]] || [[ "$SECTION" == "homebrew" ]]; then
  check_homebrew
fi

# Summary
echo -e "${BLUE}Summary${NC}"
echo "-------"
echo -e "${GREEN}$PASSED checks passed${NC}"
if [[ $WARNINGS -gt 0 ]]; then
  echo -e "${YELLOW}$WARNINGS warnings found${NC}"
fi
if [[ $ERRORS -gt 0 ]]; then
  echo -e "${RED}$ERRORS errors found${NC}"
fi
echo ""

# Suggestions
if [[ ${#SUGGESTIONS[@]} -gt 0 ]]; then
  echo -e "${BLUE}Suggested fixes:${NC}"
  for suggestion in "${SUGGESTIONS[@]}"; do
    echo "- $suggestion"
  done
  echo ""
fi

# Exit code
if [[ $ERRORS -gt 0 ]]; then
  exit 2
elif [[ $WARNINGS -gt 0 ]]; then
  exit 1
else
  exit 0
fi
