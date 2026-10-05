#!/usr/bin/env bash
# Status must not run any Spicetify command or mutate app-owned files.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/bin" "$test_root/config/spicetify/Themes/TokyoNight" "$test_root/Spotify Resources"
cat > "$test_root/bin/spicetify" <<'EOF'
#!/usr/bin/env bash
echo 'FAIL: status invoked the Spicetify CLI' >&2
exit 99
EOF
chmod +x "$test_root/bin/spicetify"
config="$test_root/config/spicetify/config-xpui.ini"
cat > "$config" <<EOF
[Setting]
spotify_path = $test_root/Spotify Resources
current_theme = TokyoNight
color_scheme = Night
[AdditionalOptions]
custom_apps =
[Backup]
version = 1.2.92.test
EOF
touch "$test_root/config/spicetify/Themes/TokyoNight/color.ini" "$test_root/config/spicetify/Themes/TokyoNight/user.css"
cp "$config" "$test_root/original"
output="$(SPICETIFY_CONFIG="$test_root/config/spicetify" XDG_CONFIG_HOME="$test_root/config" PATH="$test_root/bin:$PATH" \
  bash "$repo_root/ops/spicetify.sh" --no-color status 2>&1)"
[[ "$output" == *'application-owned runtime state'* && "$output" != *'FAIL:'* ]]
cmp "$config" "$test_root/original"

# Missing configuration must not be silently created by a CLI getter.
mv "$config" "$test_root/saved-config"
if SPICETIFY_CONFIG="$test_root/config/spicetify" XDG_CONFIG_HOME="$test_root/config" PATH="$test_root/bin:$PATH" \
  bash "$repo_root/ops/spicetify.sh" --no-color status > "$test_root/output" 2>&1; then
  echo 'FAIL: accepted missing runtime configuration'; exit 1
fi
[[ ! -e "$config" ]]
if rg -q 'FAIL: status invoked' "$test_root/output"; then exit 1; fi

# Explicit mutation commands also refuse an immutable Nix store path.
sed 's|^spotify_path = .*|spotify_path = /nix/store|' "$test_root/saved-config" > "$config"
if SPICETIFY_CONFIG="$test_root/config/spicetify" XDG_CONFIG_HOME="$test_root/config" PATH="$test_root/bin:$PATH" \
  bash "$repo_root/ops/spicetify.sh" --no-color apply > "$test_root/output" 2>&1; then
  echo 'FAIL: accepted immutable Spotify path'; exit 1
fi
rg -q 'Refusing to patch' "$test_root/output"
echo 'PASS: read-only status, missing-config safety, and immutable-app guard'
