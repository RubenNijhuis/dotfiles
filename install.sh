#!/usr/bin/env bash
# Nix-first bootstrap script for a fresh Mac.
# Usage: git clone https://github.com/<user>/dotfiles.git ~/Developer/personal/dotfiles && cd ~/Developer/personal/dotfiles && ./install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
source "$DOTFILES/lib/env.sh"
dotfiles_load_env "$DOTFILES"
source "$DOTFILES/lib/brew.sh"
DEVELOPER_ROOT="$DOTFILES_DEVELOPER_ROOT"
INSTALL_LOG="$HOME/.cache/dotfiles-install.log"
CHECKPOINT_FILE="$HOME/.config/dotfiles-install-checkpoint"
SELF_TEST_CHECKPOINT=false

# Source shared output helpers (lives in the git clone, always available)
source "$DOTFILES/lib/output.sh" "$@"

TOTAL_STEPS=7
CURRENT_STEP=0
OS="$(uname -s)"
ARCH="$(uname -m)"

NON_INTERACTIVE=false
DRY_RUN=false
FROM_STEP=1
FROM_STEP_SET=false
SSH_PREF="auto"
GPG_PREF="auto"

SETUP_SSH="no"
SETUP_GPG="no"

STEP_NAMES=(
  "Detecting system"
  "Xcode Command Line Tools"
  "Installing Lix/Nix"
  "Verifying the locked configuration"
  "Applying the Nix configuration"
  "Installing documented macOS exceptions"
  "Final local setup"
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
  --from-step <1-$TOTAL_STEPS>             Start execution from a specific step
  --with-ssh                    Generate SSH keys
  --without-ssh                 Skip SSH key generation
  --with-gpg                    Generate GPG key
  --without-gpg                 Skip GPG key generation
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
    print_info "Homebrew not detected; it is only installed for selected macOS exceptions."
  fi

  check_macos_and_clt_freshness
}

check_macos_and_clt_freshness() {
  # Warn (don't fail) when macOS or Xcode Command Line Tools are old enough
  # that Homebrew is likely to refuse compiling formulae from source.
  # Homebrew supports current + 2 prior macOS majors; bump MIN_MACOS_MAJOR
  # when that window shifts.
  local MIN_MACOS_MAJOR=15
  local macos_version macos_major clt_version clt_major
  macos_version="$(sw_vers -productVersion 2>/dev/null || echo unknown)"
  macos_major="${macos_version%%.*}"
  print_info "macOS: $macos_version"

  if [[ "$macos_major" =~ ^[0-9]+$ ]] && [[ "$macos_major" -lt "$MIN_MACOS_MAJOR" ]]; then
    print_warning "macOS $macos_version is older than Homebrew's supported floor (macOS $MIN_MACOS_MAJOR+)"
    print_info "Update via: System Settings > General > Software Update"
  fi

  if clt_version="$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/^version:/{print $2}')"; then
    clt_major="${clt_version%%.*}"
    print_info "Xcode CLT: $clt_version"
    if [[ "$macos_major" =~ ^[0-9]+$ ]] && [[ "$clt_major" =~ ^[0-9]+$ ]] && \
       [[ "$clt_major" -lt "$macos_major" ]]; then
      print_warning "CLT major ($clt_major) trails macOS major ($macos_major) — Homebrew source builds may fail"
      print_info "Refresh: sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --install"
    fi
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

trust_declared_taps() {
  # Homebrew requires explicit trust for third-party taps before bundle
  # will load their formulae. Trust every currently-installed tap plus
  # every `tap "..."` line in the profile's Brewfiles. Covers both fresh
  # installs and existing machines with leftover taps. Idempotent —
  # `brew trust` on an already-trusted tap is a no-op.
  local brewfile_name brewfile_path tap
  local -a taps=()

  while IFS= read -r tap; do
    [[ -n "$tap" ]] && taps+=("$tap")
  done < <(brew tap 2>/dev/null)

  while IFS= read -r brewfile_name; do
    brewfile_path="$DOTFILES/brew/$brewfile_name"
    [[ -f "$brewfile_path" ]] || continue
    while IFS= read -r tap; do
      taps+=("$tap")
    done < <(awk -F'"' '/^tap "/{print $2}' "$brewfile_path")
  done < <(dotfiles_profile_brewfiles)

  local unique_tap
  for unique_tap in $(printf '%s\n' "${taps[@]}" | sort -u); do
    brew trust "$unique_tap" >/dev/null 2>&1 || \
      print_warning "Could not trust tap: $unique_tap"
  done
}

step_install_packages() {
  trust_declared_taps
  local brewfile_name brewfile_path
  while IFS= read -r brewfile_name; do
    brewfile_path="$DOTFILES/brew/$brewfile_name"
    print_status_row "Brewfile" info "$brewfile_name"
    install_brew_bundle "$brewfile_path"
  done < <(dotfiles_profile_brewfiles)
  print_success "Packages installed"
}

print_install_summary() {
  print_section "Install Summary"
  print_status_row "Profile" info "${DOTFILES_PROFILE:-unknown}"
  print_status_row "Brewfiles" info "$(brew_profile_summary)"
  print_status_row "SSH keys" info "$SETUP_SSH"
  print_status_row "GPG key" info "$SETUP_GPG"
  print_status_row "Install log" info "$INSTALL_LOG"
}

profile_has_brew_exceptions() {
  local brewfile
  while IFS= read -r brewfile; do
    [[ -n "$brewfile" ]] && return 0
  done < <(dotfiles_profile_brewfiles)
  return 1
}

step_install_lix() {
  if command -v nix >/dev/null 2>&1; then
    print_success "$(nix --version)"
    return
  fi

  print_info "Installing Lix with the supported installer"
  curl -sSf -L https://install.lix.systems/lix | sh -s -- install

  # The installer updates shell startup files. Load its canonical location so
  # this run can continue without requiring a new terminal.
  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  command -v nix >/dev/null 2>&1 || {
    print_error "Lix installed, but nix is not available in this shell. Open a new terminal and rerun ./install.sh."
    return 1
  }
}

step_verify_nix_configuration() {
  print_status_row "Nix" info "$(nix --version)"
  make -C "$DOTFILES" nix-check
  make -C "$DOTFILES" nix-build
  print_success "Locked Nix configuration builds"
}

step_apply_nix_configuration() {
  make -C "$DOTFILES" nix-switch
  print_success "Nix configuration applied"
}

step_install_brew_exceptions() {
  if ! profile_has_brew_exceptions; then
    print_success "No Homebrew exceptions selected for this profile"
    return
  fi

  print_info "Installing only the profile's documented macOS exceptions"
  step_install_homebrew
  step_install_packages
}

step_finish_nix_install() {
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

  git -C "$DOTFILES" config core.hooksPath "$DOTFILES/hooks"
  print_success "Git hooks enabled for this repository"
}

collect_nix_preferences() {
  printf '\n%sNix-first installer preferences%s\n' "${BLUE}" "${NC}"
  printf '%s\n' "----------------------------------------"

  SETUP_SSH=$(resolve_preference "$SSH_PREF" "no" "Generate SSH keys for Git?")
  SETUP_GPG=$(resolve_preference "$GPG_PREF" "no" "Generate GPG key for commit signing?")

  if ! $NON_INTERACTIVE; then
    if ! prompt_yes_no "Proceed with Nix-first installation? [Y/n] " "Y"; then
      echo "Installation cancelled."
      exit 0
    fi
  fi
}

nix_main() {
  parse_args "$@"

  if $SELF_TEST_CHECKPOINT; then
    run_checkpoint_self_test
    exit 0
  fi

  if ! $DRY_RUN; then
    mkdir -p "$(dirname "$INSTALL_LOG")" "$(dirname "$CHECKPOINT_FILE")"
    exec > >(tee -a "$INSTALL_LOG") 2>&1
  fi
  trap cleanup_on_error ERR

  show_header
  if $DRY_RUN; then
    print_warning "DRY RUN mode enabled - no changes will be made"
  fi
  handle_resume
  collect_nix_preferences

  if $FROM_STEP_SET; then
    CURRENT_STEP=$((FROM_STEP - 1))
    print_info "Starting from step $FROM_STEP: ${STEP_NAMES[$((FROM_STEP - 1))]}"
  fi

  run_step 1 step_detect_system
  run_step 2 step_install_xcode_clt
  run_step 3 step_install_lix
  run_step 4 step_verify_nix_configuration
  run_step 5 step_apply_nix_configuration
  run_step 6 step_install_brew_exceptions
  # Runtimes and app configuration belong to Nix modules or their respective
  # applications, not this installer.
  run_step 7 step_finish_nix_install

  if ! $DRY_RUN; then
    rm -f "$CHECKPOINT_FILE"
  fi
  run_post_install_health_check
  print_success "Nix-first setup complete"
  print_install_summary
  print_next_steps "Open a new terminal to load the managed shell configuration"
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

nix_main "$@"
