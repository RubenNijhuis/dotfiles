#!/usr/bin/env bash
# Explicit opt-in cryptographic test: never use the user's keys or agent.
set -euo pipefail
gpg_bin="${1:-gpg}"
command -v "$gpg_bin" >/dev/null || { echo "GPG executable not found: $gpg_bin" >&2; exit 1; }
test_root="$(mktemp -d /tmp/dotfiles-gpg.XXXXXX)"
keyring="$test_root/gnupg"
mkdir -m700 "$keyring"
gpgconf_bin="$(dirname "$(command -v "$gpg_bin")")/gpgconf"
cleanup() {
  "$gpgconf_bin" --homedir "$keyring" --kill gpg-agent 2>/dev/null || true
  rm -rf "$test_root"
}
trap cleanup EXIT
gpg_test() { "$gpg_bin" --homedir "$keyring" --batch --no-tty "$@"; }

gpg_test --pinentry-mode loopback --passphrase '' --quick-generate-key \
  'Dotfiles disposable test <dotfiles-test@example.invalid>' ed25519 sign 0
fingerprint="$(gpg_test --with-colons --list-keys | awk -F: '$1 == "fpr" {print $10; exit}')"
[[ -n "$fingerprint" ]]
gpg_test --pinentry-mode loopback --passphrase '' --quick-add-key "$fingerprint" cv25519 encr 0
printf 'Dotfiles isolated signing and encryption roundtrip.\n' > "$test_root/plaintext"
gpg_test --output "$test_root/signature" --detach-sign "$test_root/plaintext"
gpg_test --verify "$test_root/signature" "$test_root/plaintext"
gpg_test --trust-model always --recipient "$fingerprint" --output "$test_root/encrypted" \
  --encrypt "$test_root/plaintext"
gpg_test --output "$test_root/decrypted" --decrypt "$test_root/encrypted"
cmp "$test_root/plaintext" "$test_root/decrypted"
printf 'PASS: %s signing, verification, encryption, and decryption; real keyrings untouched\n' "$gpg_bin"
