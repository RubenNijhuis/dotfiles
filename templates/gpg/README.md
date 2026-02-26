# GPG Key Setup for Commit Signing

This guide will help you generate GPG keys for signing Git commits.

## Quick Setup

Run the provided script:
```bash
bash ~/dotfiles/templates/gpg/generate-keys.sh
```

## Manual Setup

### Generate GPG Key

1. Generate a new key:
   ```bash
   gpg --full-generate-key
   ```
   - Select: (1) RSA and RSA
   - Key size: 4096
   - Expiration: 2 years
   - Enter your name and email

2. List your keys:
   ```bash
   gpg --list-secret-keys --keyid-format=long
   ```

3. Note your key ID (the part after `sec rsa4096/`):
   ```
   sec   rsa4096/YOUR_KEY_ID 2024-01-01 [SC]
   ```

4. Configure Git to use your key:
   ```bash
   # Edit ~/.gitconfig-personal and set:
   # signingkey = YOUR_KEY_ID
   # gpgsign = true
   ```

5. Export public key for GitHub/GitLab:
   ```bash
   gpg --armor --export YOUR_KEY_ID | pbcopy
   ```

6. Add to GitHub:
   - Go to Settings → SSH and GPG keys → New GPG key
   - Paste and save

### Test Signing

```bash
cd ~/personal/test-repo
git commit -S -m "Test signed commit"
git log --show-signature
```

## Key Management

- List keys: `gpg --list-secret-keys --keyid-format=long`
- Export public key: `gpg --armor --export KEY_ID`
- Backup private key: `gpg --export-secret-keys --armor KEY_ID > private.asc`
- Import key: `gpg --import private.asc`

## Security Notes

- Use a strong passphrase
- Store passphrase in macOS Keychain (via pinentry-mac)
- Backup your private key securely (offline storage)
- Set expiration dates and renew keys regularly
- Never commit private keys to git
