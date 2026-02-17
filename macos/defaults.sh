#!/usr/bin/env bash
# macOS system preferences via `defaults write`
# Run once after fresh install, then selectively as needed.

set -euo pipefail

echo "Applying macOS defaults..."

# Close System Preferences to prevent overrides
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# === Finder ===
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # Search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# === Dock ===
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock minimize-to-application -bool true

# === Keyboard ===
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false  # Enable key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# === Trackpad ===
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# === Screenshots ===
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true
mkdir -p "$HOME/Desktop/Screenshots"

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
