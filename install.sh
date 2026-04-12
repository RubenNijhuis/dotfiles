#!/usr/bin/env bash
# Bootstrap script for a fresh machine
# Usage: git clone https://github.com/<user>/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
source "$DOTFILES/lib/env.sh"
dotfiles_load_env "$DOTFILES"
source "$DOTFILES/lib/brew.sh"
DEVELOPER_ROOT="$DOTFILES_DEVELOPER_ROOT"
PREFERENCES_FILE="$HOME/.config/dotfiles-install-preferences"
INSTALL_LOG="$HOME/.cache/dotfiles-install.log"
CHECKPOINT_FILE="$HOME/.config/dotfiles-install-checkpoint"
SELF_TEST_CHECKPOINT=false

# Create directories
mkdir -p "$(dirname "$INSTALL_LOG")" "$(dirname "$CHECKPOINT_FILE")"

# Source shared output helpers (lives in the git clone, always available)
source "$DOTFILES/lib/output.sh" "$@"

TOTAL_STEPS=9
CURRENT_STEP=0
OS="$(uname -s)"
ARCH="$(uname -m)"

NON_INTERACTIVE=false
DRY_RUN=false
FROM_STEP=1
FROM_STEP_SET=false
MACOS_PREF="auto"
SSH_PREF="auto"
GPG_PREF="auto"
BLOATWARE_PREF="auto"

APPLY_MACOS_DEFAULTS="no"
SETUP_SSH="no"
SETUP_GPG="no"
REMOVE_BLOATWARE="no"

STEP_NAMES=(
  "Detecting system"
  "Xcode Command Line Tools"
  "Installing Homebrew"
  "Installing packages"
  "Stowing config packages"
  "Setting up runtime tools"
  "Applying macOS defaults"
  "Removing macOS bloatware"
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
  --from-step <1-9>             Start execution from a specific step
  --with-macos-defaults         Apply macOS defaults
  --without-macos-defaults      Skip macOS defaults
  --with-ssh                    Generate SSH keys
  --without-ssh                 Skip SSH key generation
  --with-gpg                    Generate GPG key
  --without-gpg                 Skip GPG key generation
  --with-bloatware-removal      Remove common macOS bloatware apps
  --without-bloatware-removal   Skip bloatware removal
  --no-color                    Disable colored output
  --self-test-checkpoint        Run checkpoint/resume logic tests and exit
  --help, -h                    Show this help message
EOF2
}


has_gum() {
  command -v gum &>/dev/null && [[ -t 0 ]] && [[ -t 1 ]] && ! $NON_INTERACTIVE
}

step_begin() {
  local label="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  printf '\n%s[%s/%s]%s %s...\n' "${BLUE}" "$CURRENT_STEP" "$TOTAL_STEPS" "${NC}" "$label"
}

step_done() {
  print_success "Done"
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
          print_error "Missing value for --from-step"
          usage
          exit 1
        fi
        FROM_STEP="$2"
        FROM_STEP_SET=true
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
      --with-bloatware-removal)
        BLOATWARE_PREF="yes"
        shift
        ;;
      --without-bloatware-removal)
        BLOATWARE_PREF="no"
        shift
        ;;
      --no-color)
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
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  if ! [[ "$FROM_STEP" =~ ^[0-9]+$ ]] || [[ "$FROM_STEP" -lt 1 || "$FROM_STEP" -gt "$TOTAL_STEPS" ]]; then
    print_error "--from-step must be a number between 1 and $TOTAL_STEPS"
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
  printf '\n%sInstallation failed at step %s%s\n' "${RED}" "$CURRENT_STEP" "${NC}"
  printf 'Check log: %s\n' "$INSTALL_LOG"
  printf 'To resume, re-run: ./install.sh\n'
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
      print_warning "Retry $retry/$max_retries..."
      sleep 2
    fi
  done

  print_error "Failed after $max_retries attempts"
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
  print_header "Dotfiles Installation"
  print_status_row "Log" info "$INSTALL_LOG"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
}

handle_resume() {
  local last_completed
  last_completed=$(load_checkpoint)

  if [[ $last_completed -le 0 ]] || $FROM_STEP_SET || $DRY_RUN; then
    return
  fi

  printf '\n'
  printf '%sPrevious installation stopped at step %s%s\n' "${YELLOW}" "$last_completed" "${NC}"
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

  if [[ "$MACOS_PREF" == "auto" && -n "${PREF_MACOS_DEFAULTS:-}" ]]; then
    MACOS_PREF="$PREF_MACOS_DEFAULTS"
  fi
  if [[ "$SSH_PREF" == "auto" && -n "${PREF_SETUP_SSH:-}" ]]; then
    SSH_PREF="$PREF_SETUP_SSH"
  fi
  if [[ "$GPG_PREF" == "auto" && -n "${PREF_SETUP_GPG:-}" ]]; then
    GPG_PREF="$PREF_SETUP_GPG"
  fi
  if [[ "$BLOATWARE_PREF" == "auto" && -n "${PREF_REMOVE_BLOATWARE:-}" ]]; then
    BLOATWARE_PREF="$PREF_REMOVE_BLOATWARE"
  fi
}

save_selected_preferences() {
  mkdir -p "$(dirname "$PREFERENCES_FILE")"
  cat > "$PREFERENCES_FILE" <<EOF
PREF_MACOS_DEFAULTS="$APPLY_MACOS_DEFAULTS"
PREF_SETUP_SSH="$SETUP_SSH"
PREF_SETUP_GPG="$SETUP_GPG"
PREF_REMOVE_BLOATWARE="$REMOVE_BLOATWARE"
EOF
}

collect_preferences() {
  printf '\n'
  printf '%sInstaller Preferences%s\n' "${BLUE}" "${NC}"
  printf '%s\n' "----------------------------------------"

  APPLY_MACOS_DEFAULTS=$(resolve_preference "$MACOS_PREF" "no" "Apply macOS defaults?")
  SETUP_SSH=$(resolve_preference "$SSH_PREF" "no" "Generate SSH keys for Git?")
  SETUP_GPG=$(resolve_preference "$GPG_PREF" "no" "Generate GPG key for commit signing?")
  REMOVE_BLOATWARE=$(resolve_preference "$BLOATWARE_PREF" "no" "Remove macOS bloatware apps (Tips, Chess, Stocks…)?")

  echo ""
  echo "Summary:"
  echo "  Apply macOS defaults: $APPLY_MACOS_DEFAULTS"
  echo "  Generate SSH keys: $SETUP_SSH"
  echo "  Generate GPG key: $SETUP_GPG"
  echo "  Remove bloatware: $REMOVE_BLOATWARE"

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
        print_info "DRY RUN: would execute step logic"
      fi
    else
      "$handler"
      save_checkpoint
    fi
    step_done
  fi
}

step_detect_system() {
  print_success "OS: $OS ($ARCH)"
  if [[ "$OS" != "Darwin" ]]; then
    print_error "Unsupported OS: $OS. This repository is macOS-only."
    exit 1
  fi

  local missing=0
  local cmd
  for cmd in osascript launchctl plutil security xcode-select; do
    if ! command -v "$cmd" &>/dev/null; then
      print_error "Missing required macOS command: $cmd"
      missing=$((missing + 1))
    fi
  done

  if [[ $missing -gt 0 ]]; then
    echo "Required macOS tooling is unavailable. Check Xcode CLT and system path integrity."
    exit 1
  fi

  local brew_bin
  if brew_bin="$(detect_brew_binary)"; then
    print_info "Detected Homebrew binary: $brew_bin"
  else
    print_info "Homebrew not detected yet; installer will bootstrap it."
  fi
}

step_install_xcode_clt() {
  if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    if [[ -t 0 ]]; then
      echo "Press enter after Xcode CLT finishes installing."
      read -r
    else
      echo "Waiting for Xcode CLT installation to complete (up to 10 minutes)..."
      local wait_count=0
      until xcode-select -p &>/dev/null; do
        sleep 5
        wait_count=$((wait_count + 1))
        if [[ $wait_count -ge 120 ]]; then
          print_error "Xcode CLT installation timed out after 10 minutes"
          exit 1
        fi
      done
    fi
  else
    print_success "Xcode CLT already installed"
  fi
}

step_install_homebrew() {
  local brew_bin=""
  brew_bin="$(detect_brew_binary || true)"

  if [[ -z "$brew_bin" ]]; then
    /bin/bash -c "$(curl --max-time 120 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_bin="$(detect_brew_binary || true)"
  fi

  if [[ -z "$brew_bin" ]]; then
    print_error "Homebrew installation failed"
    exit 1
  fi

  eval "$("$brew_bin" shellenv)"
  print_success "Homebrew ready"
}

step_install_packages() {
  local brewfile_name brewfile_path
  while IFS= read -r brewfile_name; do
    brewfile_path="$DOTFILES/brew/$brewfile_name"
    print_status_row "Brewfile" info "$brewfile_name"
    install_brew_bundle "$brewfile_path"
  done < <(dotfiles_profile_brewfiles)
  print_success "Packages installed"
}

step_stow_configs() {
  bash "$DOTFILES/setup/stow-all.sh"
  print_success "Configs stowed"
}

step_setup_runtimes() {
  if command -v mise &>/dev/null; then
    mise install --yes
    print_success "Runtimes installed via mise (node, ruby)"
  else
    print_warning "mise not found — install via Homebrew: brew install mise"
  fi

  if command -v bun &>/dev/null; then
    print_success "Bun already installed"
  else
    if curl -fsSL https://bun.sh/install | bash; then
      print_success "Bun installed"
    else
      print_warning "Bun install failed — install manually: curl -fsSL https://bun.sh/install | bash"
    fi
  fi

  if command -v uv &>/dev/null; then
    print_success "uv already installed"
  else
    print_warning "uv not found — install via Homebrew: brew install uv"
  fi
}

step_apply_macos_defaults() {
  if [[ "$APPLY_MACOS_DEFAULTS" == "yes" ]]; then
    bash "$DOTFILES/setup/macos-defaults.sh"
    print_success "macOS defaults applied"
  else
    print_success "Skipped"
  fi
}

step_remove_bloatware() {
  if [[ "$REMOVE_BLOATWARE" == "yes" ]]; then
    bash "$DOTFILES/setup/remove-bloatware.sh" --yes
    print_success "Bloatware removal complete"
  else
    print_success "Skipped"
  fi
}

step_final_setup() {
  mkdir -p "$DEVELOPER_ROOT/personal/projects" \
           "$DEVELOPER_ROOT/personal/experiments" \
           "$DEVELOPER_ROOT/personal/learning" \
           "$DEVELOPER_ROOT/work/clients" \
           "$DEVELOPER_ROOT/archive"
  print_success "Created developer structure at $DEVELOPER_ROOT"

  if [[ "$SETUP_SSH" == "yes" ]]; then
    bash "$DOTFILES/setup/generate-ssh-keys.sh"
  fi

  if [[ "$SETUP_GPG" == "yes" ]]; then
    bash "$DOTFILES/setup/generate-gpg-keys.sh"
  fi

  if command -v code &>/dev/null; then
    printf '%sInstalling VS Code extensions...%s\n' "${BLUE}" "${NC}"
    local ext_file="$DOTFILES/config/vscode/Library/Application Support/Code/User/extensions.txt"
    if [[ -f "$ext_file" ]]; then
      grep -v '^#' "$ext_file" | grep -v '^$' | cut -d' ' -f1 | xargs -L 1 code --install-extension 2>/dev/null || true
      print_success "VS Code extensions installed"
    else
      print_warning "VS Code extensions file not found"
    fi
  fi

  printf '%sInstalling git hooks...%s\n' "${BLUE}" "${NC}"
  if bash "$DOTFILES/setup/install-hooks.sh"; then
    print_success "Git hooks installed"
  else
    print_warning "Git hooks installation failed (non-critical)"
  fi
}

print_install_summary() {
  print_section "Install Summary"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
  print_status_row "Brewfiles" info "$(brew_profile_summary)"
  print_status_row "macOS defaults" info "$APPLY_MACOS_DEFAULTS"
  print_status_row "SSH keys" info "$SETUP_SSH"
  print_status_row "GPG key" info "$SETUP_GPG"
  print_status_row "Bloatware removal" info "$REMOVE_BLOATWARE"
  print_status_row "Install log" info "$INSTALL_LOG"
}

run_post_install_health_check() {
  if $DRY_RUN; then
    return
  fi
  if [[ ! -x "$DOTFILES/health/doctor.sh" ]]; then
    return
  fi

  printf '\n'
  printf '%sPost-install quick health check%s\n' "${BLUE}" "${NC}"
  set +e
  bash "$DOTFILES/health/doctor.sh" --quick --no-color >"${TMPDIR:-/tmp}/dotfiles-install-doctor-quick.out" 2>&1
  local doctor_code=$?
  set -e

  if [[ $doctor_code -eq 0 ]]; then
    print_success "doctor-quick passed"
  else
    print_warning "doctor-quick reported issues (exit $doctor_code)"
    print_info "Run: make doctor"
  fi
}

main() {
  parse_args "$@"

  if $SELF_TEST_CHECKPOINT; then
    run_checkpoint_self_test
    exit 0
  fi

  exec > >(tee -a "$INSTALL_LOG") 2>&1
  trap cleanup_on_error ERR

  show_header
  load_saved_preferences
  if $DRY_RUN; then
    print_warning "DRY RUN mode enabled - no changes will be made"
  fi
  handle_resume
  collect_preferences

  if $FROM_STEP_SET; then
    CURRENT_STEP=$((FROM_STEP - 1))
    print_info "Starting from step $FROM_STEP: ${STEP_NAMES[$((FROM_STEP - 1))]}"
  fi

  run_step 1 step_detect_system
  run_step 2 step_install_xcode_clt
  run_step 3 step_install_homebrew
  run_step 4 step_install_packages
  run_step 5 step_stow_configs
  run_step 6 step_setup_runtimes
  run_step 7 step_apply_macos_defaults
  run_step 8 step_remove_bloatware
  run_step 9 step_final_setup

  if ! $DRY_RUN; then
    rm -f "$CHECKPOINT_FILE"
  fi
  run_post_install_health_check
  print_success "Setup complete"
  print_install_summary
  local next_steps=("Open a new terminal to load the new shell config" "Add machine-specific config to ~/.config/shell/local.sh")
  if [[ "$SETUP_SSH" == "yes" ]]; then
    next_steps+=("Add SSH public keys to GitHub/GitLab: pbcopy < ~/.ssh/id_ed25519_personal.pub")
  fi
  if [[ "$SETUP_GPG" == "yes" ]]; then
    next_steps+=("Add your GPG public key to GitHub/GitLab")
    next_steps+=("Update signingkey in git configs: bash health/gpg-info.sh")
  fi
  print_next_steps "${next_steps[@]}"
}

main "$@"
