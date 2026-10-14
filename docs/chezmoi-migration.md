# ChezMoi retirement

ChezMoi is retired. Nix/Home Manager is the sole declarative configuration
owner; applications and the user own their writable/private state. The old
source tree, package, Make targets, health checks, and template tests are gone.
The current contract is the [Nix ownership matrix](nix-ownership-matrix.md).

## Recovery references

Use the [new-Mac checklist](runbooks/new-mac-recovery.md) for recovery and the
[ownership matrix](nix-ownership-matrix.md#current-configuration-coverage) for
SSH/GPG, shell overrides, editors and Spotify. Edit reusable theme source in
`nix/config/spicetify/`; `spicetify color` cannot edit its read-only Nix palette.

Global Mise/Ruby activation is retired. The migration scan found no Ruby
manifest in active personal/work code; Ruby 4.0.5 was moved recoverably to Trash
after approval. That scan is historical evidence, not a future project-runtime
guarantee. Future Ruby projects should pin a devShell; retained older Node/Yarn
installs are compatibility state, not baseline restore requirements.

Historical local-only archives are not installation dependencies. The dated
ChezMoi retirement folder still exists on this Mac (metadata checked
2026-10-13); its contents were not read. It may contain secrets, so do not copy
it into Git or restore it as an active configuration owner. Adjacent `.pre-nix`
files must not be assumed present. Exact retention decisions belong in
[storage maintenance](storage-maintenance.md), not the installation workflow.

After any restore or adoption, run `make nix-switch` and verify links and
actual executable versions. `make gpg-check` tests signing/encryption using
disposable keys only; it does not prove compatibility with personal keys or
replace a real recovery test. Mac pinentry remains a documented Homebrew
exception until Nix supplies a suitable version.
