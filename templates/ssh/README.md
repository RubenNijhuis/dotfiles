# SSH Key Setup

This guide will help you generate SSH keys for personal and work profiles.

## Quick Setup

Run the provided script:

```bash
bash ~/dotfiles/templates/ssh/generate-keys.sh
```

## Manual Setup

### Generate Personal SSH Key

```bash
ssh-keygen -t ed25519 -C "contact@rubennijhuis.com" -f ~/.ssh/id_ed25519_personal
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal
```

### Generate Work SSH Key

```bash
ssh-keygen -t ed25519 -C "ruben@work.com" -f ~/.ssh/id_ed25519_work
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_work
```

### Add to GitHub/GitLab

1. Copy your public key:

   ```bash
   pbcopy < ~/.ssh/id_ed25519_personal.pub
   ```

2. Add to GitHub:
   - Go to Settings → SSH and GPG keys → New SSH key
   - Paste and save

3. Test connection:
   ```bash
   ssh -T git@github.com
   ```

## Key Management

- Personal keys: `~/.ssh/id_ed25519_personal` and `id_ed25519_personal.pub`
- Work keys: `~/.ssh/id_ed25519_work` and `id_ed25519_work.pub`
- Keys are automatically used based on repository location:
  - `~/personal/*` → personal key
  - `~/work/*` → work key

## Security Notes

- Never commit private keys (`.ssh/id_*` without `.pub`)
- Use strong passphrases
- Store passphrases in macOS Keychain
- Rotate keys periodically (every 1-2 years)
