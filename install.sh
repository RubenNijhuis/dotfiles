#!/usr/bin/env bash
# Bootstrap script for a fresh machine
# Usage: git clone https://github.com/<user>/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
PROFILE_FILE="$HOME/.config/dotfiles-profile"
PREFERENCES_FILE="$HOME/.config/dotfiles-install-preferences"
INSTALL_LOG="$HOME/.cache/dotfiles-install.log"
CHECKPOINT_FILE="$HOME/.config/dotfiles-install-checkpoint"
SELF_TEST_CHECKPOINT=false

# Create directories
mkdir -p "$(dirname "$INSTALL_LOG")" "$(dirname "$CHECKPOINT_FILE")"

# Colors (disable when output is not a terminal)
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'
  NC=$'\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

TOTAL_STEPS=10
CURRENT_STEP=0
OS="$(uname -s)"
ARCH="$(uname -m)"
PROFILE="${PROFILE:-}"

NON_INTERACTIVE=false
DRY_RUN=false
PROFILE_OVERRIDE=""
FROM_STEP=1
FROM_STEP_SET=false
MACOS_PREF="auto"
SSH_PREF="auto"
GPG_PREF="auto"

APPLY_MACOS_DEFAULTS="no"
SETUP_SSH="no"
SETUP_GPG="no"

STEP_NAMES=(
  "Detecting system"
  "Setting up profile"
  "Xcode Command Line Tools"
  "Installing Homebrew"
  "Installing common packages"
  "Installing profile packages"
  "Stowing config packages"
  "Setting up runtime tools"
  "Applying macOS defaults"
  "Final setup"
)

detect_brew_binary() {
  if command -v brew &>/dev/null; then
    command -v brew
    return 0
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    echo "/opt/homebrew/bin/brew"
    return 0
  fi

  if [[ -x "/usr/local/bin/brew" ]]; then
    echo "/usr/local/bin/brew"
    return 0
  fi

  return 1
}

usage() {
  cat <<EOF2
Usage: $0 [options]

Options:
  --yes                         Non-interactive mode with defaults
  --dry-run                     Preview all steps without making changes
  --from-step <1-10>            Start execution from a specific step
  --profile <personal|work>     Set profile without prompting
  --with-macos-defaults         Apply macOS defaults
  --without-macos-defaults      Skip macOS defaults
  --with-ssh                    Generate SSH keys
  --without-ssh                 Skip SSH key generation
  --with-gpg                    Generate GPG key
  --without-gpg                 Skip GPG key generation
  --self-test-checkpoint        Run checkpoint/resume logic tests and exit
  --help, -h                    Show this help message
EOF2
}

success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${BLUE}i${NC} $1"; }

has_gum() {
  command -v gum &>/dev/null && [[ -t 0 ]] && [[ -t 1 ]] && ! $NON_INTERACTIVE
}

step_begin() {
  local label="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo -e "\n${BLUE}[$CURRENT_STEP/$TOTAL_STEPS]${NC} $label..."
}

step_done() {
  success "Done"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes)
        NON_INTERACTIVE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --from-step)
        if [[ $# -lt 2 ]]; then
          error "Missing value for --from-step"
          usage
          exit 1
        fi
        FROM_STEP="$2"
        FROM_STEP_SET=true
        shift 2
        ;;
      --profile)
        if [[ $# -lt 2 ]]; then
          error "Missing value for --profile"
          usage
          exit 1
        fi
        PROFILE_OVERRIDE="$2"
        shift 2
        ;;
      --with-macos-defaults)
        MACOS_PREF="yes"
        shift
        ;;
      --without-macos-defaults)
        MACOS_PREF="no"
        shift
        ;;
      --with-ssh)
        SSH_PREF="yes"
        shift
        ;;
      --without-ssh)
        SSH_PREF="no"
        shift
        ;;
      --with-gpg)
        GPG_PREF="yes"
        shift
        ;;
      --without-gpg)
        GPG_PREF="no"
        shift
        ;;
      --self-test-checkpoint)
        SELF_TEST_CHECKPOINT=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [[ -n "$PROFILE_OVERRIDE" && "$PROFILE_OVERRIDE" != "personal" && "$PROFILE_OVERRIDE" != "work" ]]; then
    error "--profile must be 'personal' or 'work'"
    exit 1
  fi

  if ! [[ "$FROM_STEP" =~ ^[0-9]+$ ]] || [[ "$FROM_STEP" -lt 1 || "$FROM_STEP" -gt "$TOTAL_STEPS" ]]; then
    error "--from-step must be a number between 1 and $TOTAL_STEPS"
    exit 1
  fi
}

save_checkpoint() {
  echo "$CURRENT_STEP" > "$CHECKPOINT_FILE"
}

load_checkpoint() {
  if [[ -f "$CHECKPOINT_FILE" ]]; then
    cat "$CHECKPOINT_FILE"
  else
    echo "0"
  fi
}

cleanup_on_error() {
  local exit_code=$?
  echo -e "\n${RED}Installation failed at step $CURRENT_STEP${NC}"
  echo "Check log: $INSTALL_LOG"
  echo "To resume, re-run: ./install.sh"
  exit $exit_code
}

install_brew_bundle() {
  local brewfile="$1"
  local max_retries=3
  local retry=0

  while [[ $retry -lt $max_retries ]]; do
    if brew bundle --file="$brewfile"; then
      return 0
    fi

    retry=$((retry + 1))
    if [[ $retry -lt $max_retries ]]; then
      warning "Retry $retry/$max_retries..."
      sleep 2
    fi
  done

  error "Failed after $max_retries attempts"
  return 1
}

prompt_yes_no() {
  local prompt="$1"
  local default="$2" # Y or N
  local answer

  if has_gum; then
    if [[ "$default" == "Y" ]]; then
      gum confirm --default=true "$prompt"
    else
      gum confirm --default=false "$prompt"
    fi
    return
  fi

  while true; do
    read -rp "$prompt" answer
    answer="${answer:-$default}"
    case "$answer" in
      Y|y) return 0 ;;
      N|n) return 1 ;;
      *) echo "Please enter y or n." ;;
    esac
  done
}

choose_profile() {
  local default_profile="$1"
  local input

  if has_gum; then
    PROFILE=$(gum choose --header "Select profile" --selected="$default_profile" personal work)
    return 0
  fi

  while true; do
    read -rp "Profile [personal/work] (default: $default_profile): " input
    input="${input:-$default_profile}"
    case "$input" in
      personal|work)
        PROFILE="$input"
        return 0
        ;;
      *)
        echo "Please enter 'personal' or 'work'."
        ;;
    esac
  done
}

resolve_preference() {
  local pref="$1"
  local default_value="$2"
  local prompt="$3"

  if [[ "$pref" == "yes" ]]; then
    echo "yes"
    return
  fi
  if [[ "$pref" == "no" ]]; then
    echo "no"
    return
  fi

  if $NON_INTERACTIVE; then
    echo "$default_value"
    return
  fi

  if [[ "$default_value" == "yes" ]]; then
    if prompt_yes_no "$prompt [Y/n] " "Y"; then
      echo "yes"
    else
      echo "no"
    fi
  else
    if prompt_yes_no "$prompt [y/N] " "N"; then
      echo "yes"
    else
      echo "no"
    fi
  fi
}

show_header() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE} Dotfiles Installation${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo "Log: $INSTALL_LOG"
}

handle_resume() {
  local last_completed
  last_completed=$(load_checkpoint)

  if [[ $last_completed -le 0 ]] || $FROM_STEP_SET || $DRY_RUN; then
    return
  fi

  echo ""
  echo -e "${YELLOW}Previous installation stopped at step $last_completed${NC}"
  if [[ $last_completed -ge 1 && $last_completed -le $TOTAL_STEPS ]]; then
    echo "Last completed: ${STEP_NAMES[$((last_completed - 1))]}"
  fi
  if [[ $last_completed -lt $TOTAL_STEPS ]]; then
    echo "Next step: ${STEP_NAMES[$last_completed]}"
  fi

  local choice
  if $NON_INTERACTIVE; then
    choice="r"
  elif has_gum; then
    choice=$(gum choose --header "Resume installer?" "resume" "start over" "quit")
  else
    while true; do
      read -rp "Choose [r]esume, [s]tart over, [q]uit (default: r): " choice
      choice="${choice:-r}"
      case "$choice" in
        r|R|s|S|q|Q) break ;;
        *) echo "Please choose r, s, or q." ;;
      esac
    done
  fi

  case "$choice" in
    resume)
      CURRENT_STEP=$last_completed
      echo "Resuming from step $((CURRENT_STEP + 1))..."
      ;;
    "start over")
      echo "Starting fresh installation..."
      rm -f "$CHECKPOINT_FILE"
      CURRENT_STEP=0
      ;;
    quit)
      echo "Installation cancelled."
      exit 0
      ;;
    r|R)
      CURRENT_STEP=$last_completed
      echo "Resuming from step $((CURRENT_STEP + 1))..."
      ;;
    s|S)
      echo "Starting fresh installation..."
      rm -f "$CHECKPOINT_FILE"
      CURRENT_STEP=0
      ;;
    q|Q)
      echo "Installation cancelled."
      exit 0
      ;;
  esac
}

load_saved_preferences() {
  if [[ ! -f "$PREFERENCES_FILE" ]]; then
    return
  fi

  # shellcheck disable=SC1090
  source "$PREFERENCES_FILE"

  if [[ -n "${PREF_PROFILE:-}" && -z "$PROFILE_OVERRIDE" ]]; then
    PROFILE="$PREF_PROFILE"
  fi
  if [[ "$MACOS_PREF" == "auto" && -n "${PREF_MACOS_DEFAULTS:-}" ]]; then
    MACOS_PREF="$PREF_MACOS_DEFAULTS"
  fi
  if [[ "$SSH_PREF" == "auto" && -n "${PREF_SETUP_SSH:-}" ]]; then
    SSH_PREF="$PREF_SETUP_SSH"
  fi
  if [[ "$GPG_PREF" == "auto" && -n "${PREF_SETUP_GPG:-}" ]]; then
    GPG_PREF="$PREF_SETUP_GPG"
  fi
}

save_selected_preferences() {
  mkdir -p "$(dirname "$PREFERENCES_FILE")"
  cat > "$PREFERENCES_FILE" <<EOF
PREF_PROFILE="$PROFILE"
PREF_MACOS_DEFAULTS="$APPLY_MACOS_DEFAULTS"
PREF_SETUP_SSH="$SETUP_SSH"
PREF_SETUP_GPG="$SETUP_GPG"
EOF
}

collect_preferences() {
  local existing_profile=""
  if [[ -f "$PROFILE_FILE" ]]; then
    existing_profile="$(cat "$PROFILE_FILE")"
  fi

  local default_profile="${PROFILE_OVERRIDE:-${existing_profile:-personal}}"

  echo ""
  echo -e "${BLUE}Installer Preferences${NC}"
  echo "----------------------------------------"

  if [[ -n "$PROFILE_OVERRIDE" ]]; then
    PROFILE="$PROFILE_OVERRIDE"
  elif $NON_INTERACTIVE; then
    PROFILE="$default_profile"
  else
    choose_profile "$default_profile"
  fi

  if [[ "$OS" == "Darwin" ]]; then
    APPLY_MACOS_DEFAULTS=$(resolve_preference "$MACOS_PREF" "no" "Apply macOS defaults?")
  else
    APPLY_MACOS_DEFAULTS="no"
  fi

  SETUP_SSH=$(resolve_preference "$SSH_PREF" "no" "Generate SSH keys for Git?")
  SETUP_GPG=$(resolve_preference "$GPG_PREF" "no" "Generate GPG key for commit signing?")

  echo ""
  echo "Summary:"
  echo "  Profile: $PROFILE"
  echo "  Apply macOS defaults: $APPLY_MACOS_DEFAULTS"
  echo "  Generate SSH keys: $SETUP_SSH"
  echo "  Generate GPG key: $SETUP_GPG"

  if ! $NON_INTERACTIVE; then
    if ! prompt_yes_no "Proceed with installation? [Y/n] " "Y"; then
      echo "Installation cancelled."
      exit 0
    fi
  fi

  if ! $DRY_RUN; then
    save_selected_preferences
  fi
}

run_checkpoint_self_test() {
  local temp_dir
  temp_dir="$(mktemp -d)"
  local original_checkpoint_file="$CHECKPOINT_FILE"
  local original_install_log="$INSTALL_LOG"
  local original_current_step="$CURRENT_STEP"

  CHECKPOINT_FILE="$temp_dir/checkpoint"
  INSTALL_LOG="$temp_dir/install.log"

  CURRENT_STEP=3
  save_checkpoint
  if [[ "$(load_checkpoint)" != "3" ]]; then
    echo "Checkpoint self-test failed: save/load mismatch"
    rm -rf "$temp_dir"
    exit 1
  fi

  CURRENT_STEP=0
  NON_INTERACTIVE=true
  handle_resume
  if [[ "$CURRENT_STEP" -ne 3 ]]; then
    echo "Checkpoint self-test failed: resume did not restore step"
    rm -rf "$temp_dir"
    exit 1
  fi

  rm -f "$CHECKPOINT_FILE"
  echo "Checkpoint self-test passed"
  rm -rf "$temp_dir"

  CHECKPOINT_FILE="$original_checkpoint_file"
  INSTALL_LOG="$original_install_log"
  CURRENT_STEP="$original_current_step"
}

run_step() {
  local target_step="$1"
  local handler="$2"

  if [[ $CURRENT_STEP -lt $target_step ]]; then
    step_begin "${STEP_NAMES[$((target_step - 1))]}"
    if $DRY_RUN; then
      if [[ "$target_step" -eq 1 ]]; then
        "$handler"
      else
        info "DRY RUN: would execute step logic"
      fi
    else
      "$handler"
      save_checkpoint
    fi
    step_done
  fi
}

step_detect_system() {
  success "OS: $OS ($ARCH)"
  if [[ "$OS" != "Darwin" ]]; then
    error "Unsupported OS: $OS. This repository is macOS-only."
    exit 1
  fi

  local missing=0
  local cmd
  for cmd in osascript launchctl plutil security xcode-select; do
    if ! command -v "$cmd" &>/dev/null; then
      error "Missing required macOS command: $cmd"
      missing=$((missing + 1))
    fi
  done

  if [[ $missing -gt 0 ]]; then
    echo "Required macOS tooling is unavailable. Check Xcode CLT and system path integrity."
    exit 1
  fi

  local brew_bin
  if brew_bin="$(detect_brew_binary)"; then
    info "Detected Homebrew binary: $brew_bin"
  else
    info "Homebrew not detected yet; installer will bootstrap it."
  fi
}

step_setup_profile() {
  mkdir -p "$(dirname "$PROFILE_FILE")"
  echo "$PROFILE" > "$PROFILE_FILE"
  success "Profile: $PROFILE"
}

step_install_xcode_clt() {
  if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    echo "Press enter after Xcode CLT finishes installing."
    read -r
  else
    success "Xcode CLT already installed"
  fi
}

step_install_homebrew() {
  local brew_bin=""
  brew_bin="$(detect_brew_binary || true)"

  if [[ -z "$brew_bin" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_bin="$(detect_brew_binary || true)"
  fi

  if [[ -z "$brew_bin" ]]; then
    error "Homebrew installation failed"
    exit 1
  fi

  eval "$("$brew_bin" shellenv)"
  success "Homebrew ready"
}

step_install_common_packages() {
  install_brew_bundle "$DOTFILES/brew/Brewfile.common"
  success "Common packages installed"
}

step_install_profile_packages() {
  install_brew_bundle "$DOTFILES/brew/Brewfile.$PROFILE"
  success "$PROFILE packages installed"
}

step_stow_configs() {
  bash "$DOTFILES/scripts/stow-all.sh"
  success "Configs stowed"
}

step_setup_runtimes() {
  if command -v fnm &>/dev/null; then
    eval "$(fnm env)"
    if ! fnm ls | grep -q "lts"; then
      fnm install --lts
      success "Node LTS installed via fnm"
    else
      success "Node LTS already installed"
    fi
  fi

  if command -v bun &>/dev/null; then
    success "Bun already installed"
  else
    curl -fsSL https://bun.sh/install | bash
    success "Bun installed"
  fi
}

step_apply_macos_defaults() {
  if [[ "$APPLY_MACOS_DEFAULTS" == "yes" ]]; then
    bash "$DOTFILES/macos/defaults.sh"
    success "macOS defaults applied"
  else
    success "Skipped"
  fi
}

step_final_setup() {
  mkdir -p "$HOME/Developer/personal/projects" \
           "$HOME/Developer/personal/experiments" \
           "$HOME/Developer/personal/learning" \
           "$HOME/Developer/work/projects" \
           "$HOME/Developer/work/clients" \
           "$HOME/Developer/archive"
  success "Created ~/Developer structure"

  if [[ -d "$HOME/Developer/repositories" ]]; then
    local legacy_repo_count
    legacy_repo_count=$(find "$HOME/Developer/repositories" -name ".git" -type d 2>/dev/null | wc -l | xargs)
    if [[ "$legacy_repo_count" -gt 0 ]]; then
      warning "Detected legacy ~/Developer/repositories with $legacy_repo_count repo(s)"
      echo "  Run migration after install:"
      echo "    make migrate-dev-dryrun"
      echo "    make migrate-dev"
      echo "    make complete-migration"
    fi
  fi

  if [[ -f ~/.ssh/id_ed25519 && ! -f ~/.ssh/id_ed25519_personal ]]; then
    warning "Found existing SSH key that needs migration"
    if $NON_INTERACTIVE || prompt_yes_no "Migrate ~/.ssh/id_ed25519 to ~/.ssh/id_ed25519_personal? [y/N] " "N"; then
      bash "$DOTFILES/scripts/migrate-ssh-keys.sh" --no-color
    fi
  fi

  if [[ "$SETUP_SSH" == "yes" ]]; then
    bash "$DOTFILES/templates/ssh/generate-keys.sh"
  fi

  if [[ "$SETUP_GPG" == "yes" ]]; then
    bash "$DOTFILES/templates/gpg/generate-keys.sh"
  fi

  echo -e "${BLUE}Installing git hooks...${NC}"
  if bash "$DOTFILES/git-hooks/install-hooks.sh"; then
    success "Git hooks installed"
  else
    warning "Git hooks installation failed (non-critical)"
  fi
}

print_next_steps() {
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN} Setup complete! Profile: $PROFILE${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "Configuration recap:"
  echo "  Profile: $PROFILE"
  echo "  Apply macOS defaults: $APPLY_MACOS_DEFAULTS"
  echo "  Generated SSH keys: $SETUP_SSH"
  echo "  Generated GPG key: $SETUP_GPG"
  echo ""
  echo "Next steps:"
  echo "  - Open a new terminal to load the new shell config"
  echo "  - Add machine-specific config to ~/.config/shell/local.sh"

  if [[ "$SETUP_SSH" == "yes" ]]; then
    echo "  - Add SSH public keys to GitHub/GitLab"
    echo "    Personal: pbcopy < ~/.ssh/id_ed25519_personal.pub"
    if [[ "$PROFILE" == "work" ]]; then
      echo "    Work: pbcopy < ~/.ssh/id_ed25519_work.pub"
    fi
  fi

  if [[ "$SETUP_GPG" == "yes" ]]; then
    echo "  - Add GPG public key to GitHub/GitLab (see templates/gpg/README.md)"
    echo "  - Update signingkey in git configs: make gpg-info"
  fi

  echo ""
  echo "Installation log saved to: $INSTALL_LOG"
}

run_post_install_health_check() {
  if $DRY_RUN; then
    return
  fi
  if [[ ! -x "$DOTFILES/scripts/doctor.sh" ]]; then
    return
  fi

  echo ""
  echo -e "${BLUE}Post-install quick health check${NC}"
  set +e
  bash "$DOTFILES/scripts/doctor.sh" --quick --no-color >/tmp/dotfiles-install-doctor-quick.out 2>&1
  local doctor_code=$?
  set -e

  if [[ $doctor_code -eq 0 ]]; then
    success "doctor-quick passed"
  else
    warning "doctor-quick reported issues (exit $doctor_code)"
    info "Run: make doctor"
  fi
}

main() {
  parse_args "$@"

  if $SELF_TEST_CHECKPOINT; then
    run_checkpoint_self_test
    exit 0
  fi

  trap cleanup_on_error ERR
  exec > >(tee -a "$INSTALL_LOG") 2>&1

  show_header
  load_saved_preferences
  if $DRY_RUN; then
    warning "DRY RUN mode enabled - no changes will be made"
  fi
  handle_resume

  if [[ -z "$PROFILE" && -f "$PROFILE_FILE" ]]; then
    PROFILE="$(cat "$PROFILE_FILE")"
  fi

  collect_preferences

  if $FROM_STEP_SET; then
    CURRENT_STEP=$((FROM_STEP - 1))
    info "Starting from step $FROM_STEP: ${STEP_NAMES[$((FROM_STEP - 1))]}"
  fi

  run_step 1 step_detect_system
  run_step 2 step_setup_profile
  run_step 3 step_install_xcode_clt
  run_step 4 step_install_homebrew
  run_step 5 step_install_common_packages
  run_step 6 step_install_profile_packages
  run_step 7 step_stow_configs
  run_step 8 step_setup_runtimes
  run_step 9 step_apply_macos_defaults
  run_step 10 step_final_setup

  if ! $DRY_RUN; then
    rm -f "$CHECKPOINT_FILE"
  fi
  run_post_install_health_check
  print_next_steps
}

main "$@"
