#!/usr/bin/env bash
# macOS system preferences via `defaults write`
# Run once after fresh install, then selectively as needed.

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib/env.sh
source "$DOTFILES_ROOT/scripts/lib/env.sh"
dotfiles_load_env "$DOTFILES_ROOT"

echo "Applying macOS defaults..."

# Close System Preferences to prevent overrides
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# === Finder ===
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # Search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"  # Default to list view
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# === Dock ===
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock mru-spaces -bool false

if command -v dockutil >/dev/null 2>&1; then
    dockutil --no-restart --remove all

    dock_apps=()
    if [[ -f "$DOTFILES_ROOT/local/dock-apps.txt" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"   # strip comments
            line="${line#"${line%%[![:space:]]*}"}"  # trim leading whitespace
            line="${line%"${line##*[![:space:]]}"}"  # trim trailing whitespace
            [[ -n "$line" ]] && dock_apps+=("$line")
        done < "$DOTFILES_ROOT/local/dock-apps.txt"
    else
        dock_apps=(
            "/Applications/Zen.app"
            "/Applications/Rider.app"
            "/Applications/Visual Studio Code.app"
            "/Applications/OrbStack.app"
            "/Applications/Ghostty.app"
            "/Applications/DBeaver.app"
            "/Applications/Linear.app"
            "/Applications/Obsidian.app"
            "/Applications/Slack.app"
            "/Applications/WhatsApp.app"
            "/Applications/Spotify.app"
            "/Applications/Figma.app"
            "/Applications/LM Studio.app"
            "/Applications/Claude.app"
            "/System/Applications/System Settings.app"
        )
    fi

    for app_path in "${dock_apps[@]}"; do
        if [[ -e "$app_path" ]]; then
            dockutil --no-restart --add "$app_path"
        fi
    done

    if [[ -d "$HOME/Downloads" ]]; then
        dockutil --no-restart --add "$HOME/Downloads" --view grid --display stack --sort dateadded --section others
    fi
fi

# === Keyboard ===
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false  # Enable key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# === Trackpad ===
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain ContextMenuGesture -int 1

# === Appearance (Tokyo Night) ===
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleAccentColor -int -2                # Blue (closest to Tokyo Night)
defaults write NSGlobalDomain AppleAquaColorVariant -int 1
defaults write NSGlobalDomain AppleHighlightColor -string "0.478431 0.635294 0.968627 Other"  # #7aa2f7

# === Global UI ===
defaults write NSGlobalDomain AppleShowScrollBars -string "Automatic"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# === Screenshots ===
defaults write com.apple.screencapture location -string "$DOTFILES_SCREENSHOTS_PATH"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true
mkdir -p "$DOTFILES_SCREENSHOTS_PATH"

# === Security & Privacy ===
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# === Filesystem visibility ===
chflags nohidden "$HOME/Library" 2>/dev/null || true

# === Touch ID for sudo ===
if [[ -f /etc/pam.d/sudo_local.template ]]; then
    if [[ ! -f /etc/pam.d/sudo_local ]]; then
        sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local > /dev/null
        echo "Touch ID for sudo enabled."
    fi
fi

# === Restart affected apps ===
for app in "Finder" "Dock" "SystemUIServer"; do
    killall "$app" &>/dev/null || true
done

echo "macOS defaults applied. Some changes require a logout/restart."
