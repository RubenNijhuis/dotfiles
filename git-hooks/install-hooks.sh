#!/usr/bin/env bash
# Install git hooks from git-hooks directory to .git/hooks
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_DIR="$DOTFILES/git-hooks"
GIT_HOOK_DIR="$DOTFILES/.git/hooks"
HOOK_NAMES=(
  "pre-commit"
  "commit-msg"
  "pre-push"
)

source "$DOTFILES/scripts/lib/output.sh"

print_header "Installing Git Hooks"

# Ensure .git/hooks exists
if [[ ! -d "$GIT_HOOK_DIR" ]]; then
  print_error ".git/hooks directory not found"
  print_info "Are you in the dotfiles repository?"
  exit 1
fi

# Install each hook
INSTALLED=0
for hook_name in "${HOOK_NAMES[@]}"; do
  hook="$HOOK_DIR/$hook_name"
  target="$GIT_HOOK_DIR/$hook_name"

  if [[ ! -f "$hook" ]]; then
    print_warning "$hook_name (missing in git-hooks/, skipping)"
    continue
  fi

  # Create symlink
  if [[ -L "$target" ]]; then
    print_warning "$hook_name (already linked)"
  elif [[ -f "$target" ]]; then
    print_warning "$hook_name (file exists, backing up)"
    mv "$target" "$target.backup"
    ln -s "$hook" "$target"
    print_success "$hook_name (installed, old hook backed up)"
    INSTALLED=$((INSTALLED + 1))
  else
    ln -s "$hook" "$target"
    print_success "$hook_name (installed)"
    INSTALLED=$((INSTALLED + 1))
  fi

  # Ensure hook is executable
  chmod +x "$hook"
done

printf '\n'
if [[ $INSTALLED -eq 0 ]]; then
  print_info "All hooks already installed"
else
  print_success "Installed $INSTALLED hook(s)"
fi

print_info "Hooks location: $HOOK_DIR"
