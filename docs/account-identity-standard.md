# Account identity standard

The non-secret identity source is [nix/lib/identity.nix](../nix/lib/identity.nix):

- Name: Ruben Nijhuis
- Public contact address: contact@rubennijhuis.com

Use those details for new personal accounts unless a service requires a
different legal, billing, or recovery identity. Do not store passwords,
recovery codes, private addresses, or account databases in this repository.

## Source of truth by account type

| Account type | Standard | Where it is managed |
| --- | --- | --- |
| Developer identity | Name and public contact address above | Nix, currently applied to Git |
| Apple Account | Same display name; iCloud stays Apple-device specific | Apple Account settings |
| Operational calendar | Apple Calendar on Apple devices, backed by the chosen synced calendar account | iCloud or another deliberately selected provider; no parallel copies of events |
| Mail | `contact@rubennijhuis.com` as public-facing address | Thunderbird account settings and mail provider |
| Browser | Zen profile and Zen Sync are user-owned | Zen, never Nix |
| ChatGPT/Codex | Same display name; preferred-app policy | ChatGPT/Codex settings |
| Recovery and billing | Legal identity where required | Provider account settings; never Nix |

## Current Mac audit

- Apple Account: signed in as Ruben Nijhuis, with iCloud Calendar available.
- Internet Accounts: iCloud plus a separate Mail/Notes account; no shared
  operational calendar account is connected yet.
- Thunderbird: `contact@rubennijhuis.com` is configured.
- Git: matches the Nix identity source.
- Zen: Nix manages the application; profile, Sync, history, and logins remain
  local and user-controlled.

## Calendar handoff

Google is not a required calendar provider. Verify the intended iCloud calendar
is selected for new events and notifications work on the phone and watch.
The audit above is historical, not proof that every account remains configured.
