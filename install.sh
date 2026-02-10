#!/usr/bin/env bash
# Bootstrap script for a fresh machine
# Usage: git clone https://github.com/<user>/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
PROFILE_FILE="$HOME/.config/dotfiles-profile"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

step() { echo -e "\n${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }

# --- 1. Detect OS ---
step "Detecting system..."
OS="$(uname -s)"
ARCH="$(uname -m)"
success "OS: $OS ($ARCH)"

if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
    echo -e "${RED}Unsupported OS: $OS${NC}"
    exit 1
fi

# --- 2. Select profile ---
if [[ -f "$PROFILE_FILE" ]]; then
    PROFILE="$(cat "$PROFILE_FILE")"
    echo "Existing profile found: $PROFILE"
    read -rp "Keep this profile? [Y/n] " keep
    if [[ "${keep:-Y}" =~ ^[Nn] ]]; then
        unset PROFILE
    fi
fi

if [[ -z "${PROFILE:-}" ]]; then
    echo ""
    echo "Select profile:"
    echo "  1) personal"
    echo "  2) work"
    read -rp "Choice [1/2]: " choice
    case "$choice" in
        2) PROFILE="work" ;;
        *) PROFILE="personal" ;;
    esac
    mkdir -p "$(dirname "$PROFILE_FILE")"
    echo "$PROFILE" > "$PROFILE_FILE"
fi
success "Profile: $PROFILE"

# --- 3. Install Xcode CLT (macOS) ---
if [[ "$OS" == "Darwin" ]]; then
    if ! xcode-select -p &>/dev/null; then
        step "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Press enter after Xcode CLT finishes installing."
        read -r
    else
        success "Xcode CLT already installed"
    fi
fi

# --- 4. Install Homebrew ---
if ! command -v brew &>/dev/null; then
    step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    success "Homebrew already installed"
fi

# --- 5. Install Homebrew packages ---
step "Installing common packages..."
brew bundle --file="$DOTFILES/brew/Brewfile.common"

step "Installing $PROFILE packages..."
brew bundle --file="$DOTFILES/brew/Brewfile.$PROFILE"

# --- 6. Install Stow and apply configs ---
step "Stowing config packages..."
bash "$DOTFILES/scripts/stow-all.sh"

# --- 7. Install runtime tools ---
step "Setting up runtime tools..."

# Node via fnm
if command -v fnm &>/dev/null; then
    eval "$(fnm env)"
    if ! fnm ls | grep -q "lts"; then
        fnm install --lts
        success "Node LTS installed via fnm"
    else
        success "Node LTS already installed"
    fi
fi

# Bun
if ! command -v bun &>/dev/null; then
    curl -fsSL https://bun.sh/install | bash
    success "Bun installed"
else
    success "Bun already installed"
fi

# --- 8. Apply macOS defaults ---
if [[ "$OS" == "Darwin" ]]; then
    read -rp "Apply macOS defaults? [y/N] " apply_defaults
    if [[ "${apply_defaults:-N}" =~ ^[Yy] ]]; then
        bash "$DOTFILES/macos/defaults.sh"
    fi
fi

# --- 9. Create directory structure ---
mkdir -p "$HOME/personal" "$HOME/work"
success "Created ~/personal and ~/work directories"

# --- Done ---
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Setup complete! Profile: $PROFILE${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  - Open a new terminal to load the new shell config"
echo "  - Edit ~/.gitconfig-work with your work email"
echo "  - Add machine-specific config to ~/.config/shell/local.sh"
