#!/usr/bin/env bash
# Render the command-center help surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 [--help] [main|setup|brew|launchd|test]

Render the dotfiles command-center help screens.
EOF
}

show_help_if_requested usage "$@"

section="${1:-main}"

print_command() {
  printf "  \033[36m%-20s\033[0m %s\n" "$1" "$2"
}

print_dim_command() {
  printf "  \033[2m%-20s %s\033[0m\n" "$1" "$2"
}

render_main() {
  printf "\n\033[1mDotfiles Command Center\033[0m\n"
  printf "%s\n\n" "Use the commands below by intent: daily checks first, setup tools second, deeper maintenance when needed."
  printf "\033[1mStart Here\033[0m\n"
  print_command "status" "Fast daily snapshot of machine health"
  print_command "doctor" "Full diagnostic pass with next-step guidance"
  print_command "ops-status" "Automation dashboard for launchd tasks"
  printf "\n\033[1mDaily Work\033[0m\n"
  print_command "update" "Update repos, brew, runtimes, and re-stow"
  print_command "stow" "Apply all config packages into \$HOME"
  print_command "unstow" "Remove all config packages from \$HOME"
  print_command "backup" "Create a fresh dotfiles backup"
  print_command "spicetify-status" "Check Spotify theming health"
  print_command "clean" "Remove caches, logs, and repo clutter"
  printf "\n\033[1mSetup And Repair\033[0m\n"
  print_command "install" "Bootstrap a new machine"
  print_command "profile-show" "Show the active machine profile"
  print_command "profile-list" "List available machine profiles"
  print_command "automation-setup" "Install profile-appropriate launchd agents"
  print_command "restore" "Restore from the latest backup"
  print_command "macos" "Apply macOS defaults"
  printf "\n\033[1mMaintenance\033[0m\n"
  print_command "maint-check" "Lint, test, and validate repository contracts"
  print_command "format" "Run Biome formatting"
  print_command "docs-sync" "Fail if generated docs are stale"
  print_command "brew-audit" "Check Brewfiles for drift"
  print_command "clean-all" "Deep clean including backups and brew cache"
  printf "\n\033[2mMore help:\033[0m\n"
  print_dim_command "help-setup" "SSH, GPG, hooks, VS Code, keychain"
  print_dim_command "help-brew" "Brew sync and audit commands"
  print_dim_command "help-launchd" "Automation and launchd commands"
  print_dim_command "help-test" "Tests and verification commands"
  printf "\n\033[2mSuggested flow: make status -> make doctor -> make update\033[0m\n"
}

render_setup() {
  printf "\n\033[1mSetup Toolkit\033[0m\n"
  printf "%s\n\n" "Use these when bootstrapping a machine or fixing missing local setup."
  print_command "ssh-setup" "Generate SSH keys"
  print_command "gpg-setup" "Generate GPG key and configure Git signing"
  print_command "vscode-setup" "Install VS Code extensions"
  print_command "hooks" "Install git hooks"
  print_command "keychain-check" "Validate required keychain entries"
  print_command "automation-setup" "Setup profile-appropriate LaunchD automations"
  print_command "remove-bloatware" "Remove common macOS built-in apps"
  print_command "new-tool NAME=<n>" "Scaffold a new config package"
  printf "\n\033[2mSuggested flow: ssh-setup -> gpg-setup -> hooks -> automation-setup\033[0m\n"
}

render_brew() {
  printf "\n\033[1mBrew Toolkit\033[0m\n"
  printf "%s\n\n" "Use these to sync package state and inspect Brewfile drift."
  print_command "brew-sync" "Sync installed packages to Brewfiles"
  print_command "brew-audit" "Audit Brewfiles for drift"
  print_command "spicetify-status" "Check Spotify theming health"
  print_command "spicetify-apply" "Apply the current Spicetify configuration"
  print_command "spicetify-restore" "Restore Spotify to its backup state"
  printf "\n\033[2mSuggested flow: brew-audit -> brew-sync -> brew-audit\033[0m\n"
}

render_launchd() {
  printf "\n\033[1mLaunchd Toolkit\033[0m\n"
  printf "%s\n\n" "Use these to inspect and manage recurring automations."
  print_command "ops-status" "Automation dashboard with recent task results"
  print_command "automation-list" "List all managed agents"
  print_command "launchd-status" "Show agent load status"
  print_command "launchd-install-all" "Install and load all agents"
  print_command "launchd-uninstall-all" "Unload and remove all agents"
  print_command "automation-setup" "Install profile-appropriate automations"
  printf "\n\033[2mSuggested flow: ops-status -> automation-list -> launchd-status\033[0m\n"
}

render_test() {
  printf "\n\033[1mVerification Toolkit\033[0m\n"
  printf "%s\n\n" "Use these to validate behavior, contracts, and generated artifacts."
  print_command "lint-shell" "Run shellcheck on all scripts"
  print_command "test-scripts" "Run script behavior tests"
  print_command "bootstrap-verify" "Strict bootstrap reliability checks"
  print_command "stow-report" "Preview stow conflicts"
  print_command "docs-sync" "Verify generated docs are current"
  print_command "docs-regen" "Regenerate CLI reference"
  printf "\n\033[2mSuggested flow: lint-shell -> test-scripts -> bootstrap-verify\033[0m\n"
}

case "$section" in
  main) render_main ;;
  setup) render_setup ;;
  brew) render_brew ;;
  launchd) render_launchd ;;
  test) render_test ;;
  *)
    printf 'Unknown help section: %s\n' "$section" >&2
    usage
    exit 1
    ;;
esac
