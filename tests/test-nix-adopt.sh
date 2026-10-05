#!/usr/bin/env bash
# Exercise handoff preflight in a temporary fixture, never the real home.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/home/.ssh/config.d" "$test_root/home/.gnupg"
# Substitute only the script's target paths; do not change the test's HOME.
sed "s|\$HOME|$test_root/home|g" "$repo_root/setup/adopt-nix-configs.sh" > "$test_root/adopt.sh"
targets=(.ssh/config .ssh/config.d/common.conf .ssh/config.d/personal.conf .gnupg/gpg.conf .gnupg/gpg-agent.conf)
for target in "${targets[@]}"; do
  printf 'original\n' > "$test_root/home/$target"
done
bash "$test_root/adopt.sh" ssh-gpg --dry-run > "$test_root/output"
[[ "$(wc -l < "$test_root/output" | tr -d ' ')" == 5 ]]
for target in "${targets[@]}"; do
  [[ -f "$test_root/home/$target" && ! -e "$test_root/home/$target.pre-nix" ]]
done
ln -s missing "$test_root/home/.gnupg/gpg-agent.conf.pre-nix"
if bash "$test_root/adopt.sh" ssh-gpg > "$test_root/output" 2>&1; then
  echo 'FAIL: accepted a broken backup symlink'; exit 1
fi
for target in "${targets[@]}"; do [[ -f "$test_root/home/$target" ]]; done
unlink "$test_root/home/.gnupg/gpg-agent.conf.pre-nix"
bash "$test_root/adopt.sh" ssh-gpg
for target in "${targets[@]}"; do
  [[ ! -e "$test_root/home/$target" && -f "$test_root/home/$target.pre-nix" ]]
  [[ "$(< "$test_root/home/$target.pre-nix")" == original ]]
done
bash "$test_root/adopt.sh" ssh-gpg
if bash "$test_root/adopt.sh" ssh-gpg --bogus >/dev/null 2>&1; then exit 1; fi
echo 'PASS: adoption preview, all-file preflight, backup preservation, and idempotence'

# Profile selections must be real filenames, not capability nicknames that
# silently skip exceptions in the installer/updater.
source "$repo_root/lib/env.sh"
# shellcheck disable=SC1090 # Deliberately exercise every tracked profile.
for profile_file in "$repo_root"/profiles/*.env; do
  while IFS= read -r brewfile; do
    [[ -f "$repo_root/brew/$brewfile" ]] || {
      printf 'FAIL: profile selects missing Brewfile: %s\n' "$brewfile"
      exit 1
    }
  done < <(source "$profile_file"; dotfiles_profile_brewfiles)
done
echo 'PASS: all profile-selected Homebrew exception files exist'

# A Nix build must never depend on the retired template engine's source tree.
if rg --case-sensitive -q '\.\./\.\./chezmoi|pkgs\.chezmoi|^[[:space:]]+chezmoi$|local\.sh\.tmpl' "$repo_root/nix/home" "$repo_root/nix/profiles"; then
  echo 'FAIL: Nix modules still depend on retired source state'; exit 1
fi
echo 'PASS: Nix configuration has no ChezMoi or private-template dependency'

mkdir -p "$test_root/home/.config/spicetify/Themes/TokyoNight"
for target in color.ini user.css; do
  printf 'original theme\n' > "$test_root/home/.config/spicetify/Themes/TokyoNight/$target"
done
printf 'application-owned runtime\n' > "$test_root/home/.config/spicetify/config-xpui.ini"
bash "$test_root/adopt.sh" spicetify --dry-run >/dev/null
[[ ! -e "$test_root/home/.config/spicetify/Themes/TokyoNight/color.ini.pre-nix" ]]
bash "$test_root/adopt.sh" spicetify
bash "$test_root/adopt.sh" spicetify
for target in color.ini user.css; do
  [[ "$( < "$test_root/home/.config/spicetify/Themes/TokyoNight/$target.pre-nix")" == 'original theme' ]]
done
[[ "$( < "$test_root/home/.config/spicetify/config-xpui.ini")" == 'application-owned runtime' ]]
echo 'PASS: theme adoption preserves originals and leaves writable runtime state alone'
