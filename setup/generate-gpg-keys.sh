#!/usr/bin/env bash
# Check the Nix-selected identity; never create or export private keys.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

usage() {
  cat <<EOF
Usage: $0 [--help] [--no-color]

Check that the selected OpenPGP signing key is available on this device.
Provision private keys securely yourself; Nix owns Git configuration.
EOF
}
show_help_if_requested usage "$@"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-color) shift ;;
    *) print_error "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

signing_key="$(git -C / config --get user.signingkey 2>/dev/null || true)"
gpg_bin="$(git -C / config --get gpg.program 2>/dev/null || true)"
gpg_bin="${gpg_bin:-gpg}"
if [[ "$(git -C / config --get gpg.format 2>/dev/null || true)" != openpgp || -z "$signing_key" ]]; then
  print_error "Select an OpenPGP fingerprint in nix/lib/identity.nix, then apply make nix-switch."
  exit 1
fi
if ! command -v "$gpg_bin" >/dev/null 2>&1; then
  print_error "The declared GnuPG executable is missing; apply make nix-switch."
  exit 1
fi
if ! "$gpg_bin" --batch --no-tty --with-colons --list-secret-keys "$signing_key" 2>/dev/null | grep -q '^sec:'; then
  print_error "Restore/provision the selected private key securely on this device."
  print_info "Do not generate a replacement identity or put private keys in Nix."
  exit 1
fi
print_success "The selected OpenPGP key is available; Git configuration stays Nix-owned."
print_info "This is a metadata check, not an unlock, signed-commit test, or GitHub registration check."
