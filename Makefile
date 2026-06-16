.PHONY: help install update apply diff macos ssh-setup gpg-setup \
	backup brew-sync brew-audit \
	doctor spicetify-status spicetify-apply spicetify-restore \
	hooks format vscode-setup keychain-check automation-setup remove-bloatware new-tool \
	lint-shell test-scripts maint-check bootstrap-verify docs-sync docs-regen \
	automation-list launchd-install-all launchd-uninstall-all launchd-status \
	clean clean-all restore launchd-check vscode-parity \
	help-setup help-brew help-launchd help-test cheat \
	profile-list profile-show profile-set

DOTFILES := $(shell pwd)

# ── Help ─────────────────────────────────────────────────────────────

help: ## Show commands
	@bash $(DOTFILES)/ops/help.sh main

help-setup: ## Setup commands
	@bash $(DOTFILES)/ops/help.sh setup

help-brew: ## Brew management commands
	@bash $(DOTFILES)/ops/help.sh brew

help-launchd: ## LaunchD automation commands
	@bash $(DOTFILES)/ops/help.sh launchd

help-test: ## Testing & verification commands
	@bash $(DOTFILES)/ops/help.sh test

cheat: ## One-page personal cheatsheet (shadowed defaults, keybindings, shortcuts)
	@bash $(DOTFILES)/ops/cheat.sh

# ── Core ─────────────────────────────────────────────────────────────

install: ## Full install (bootstrap + brew + chezmoi apply + macos)
	@bash $(DOTFILES)/install.sh

update: ## Update repos, brew packages, runtimes, and re-apply chezmoi
	@bash $(DOTFILES)/ops/update.sh

apply: ## Apply chezmoi source state to $$HOME (idempotent)
	@chezmoi apply

diff: ## Preview pending chezmoi changes without applying
	@chezmoi diff

macos: ## Apply macOS defaults
	@bash $(DOTFILES)/setup/macos-defaults.sh

# ── Health & Status ──────────────────────────────────────────────────

doctor: ## Quick health + automation dashboard (use --full for deep checks)
	@bash $(DOTFILES)/health/doctor.sh $(ARGS)

# ── Setup (one-time) ────────────────────────────────────────────────

ssh-setup: ## Generate SSH keys
	@bash $(DOTFILES)/setup/generate-ssh-keys.sh

gpg-setup: ## Generate GPG key and configure Git signing
	@bash $(DOTFILES)/setup/generate-gpg-keys.sh

vscode-setup: ## Install VS Code extensions from extensions.txt
	@bash $(DOTFILES)/setup/vscode-setup.sh

hooks: ## Install git hooks for code quality checks
	@bash $(DOTFILES)/setup/install-hooks.sh

keychain-check: ## Validate required keychain entries
	@bash $(DOTFILES)/setup/check-keychain.sh

automation-setup: ## Setup all LaunchD automations
	@bash $(DOTFILES)/ops/automation/setup-automation.sh setup-all

profile-list: ## List available machine profiles
	@bash $(DOTFILES)/ops/profile/list.sh

profile-show: ## Show the active machine profile
	@bash $(DOTFILES)/ops/profile/show.sh

profile-set: ## Set the active machine profile (usage: make profile-set PROFILE=<name>)
	@bash $(DOTFILES)/ops/profile/set.sh $(PROFILE)

remove-bloatware: ## Remove common macOS built-in apps
	@bash $(DOTFILES)/setup/remove-bloatware.sh

new-tool: ## Scaffold a new config package (usage: make new-tool NAME=<name>)
	@bash $(DOTFILES)/setup/new-tool.sh $(NAME)

# ── Backup ───────────────────────────────────────────────────────────

backup: ## Backup current dotfiles before modifications
	@bash $(DOTFILES)/ops/backup-dotfiles.sh

restore: ## Restore from latest backup
	@bash $(DOTFILES)/ops/restore-backup.sh

# ── Brew ─────────────────────────────────────────────────────────────

brew-sync: ## Sync manually installed packages to Brewfiles
	@bash $(DOTFILES)/ops/sync-brew.sh

brew-audit: ## Audit Brewfiles for missing or undeclared packages
	@bash $(DOTFILES)/ops/brew-audit.sh

spicetify-status: ## Check Spicetify and Spotify theming status
	@bash $(DOTFILES)/ops/spicetify.sh status

spicetify-apply: ## Apply the current Spicetify configuration
	@bash $(DOTFILES)/ops/spicetify.sh apply

spicetify-restore: ## Restore Spotify to the pre-Spicetify backup
	@bash $(DOTFILES)/ops/spicetify.sh restore

# ── Maintenance ──────────────────────────────────────────────────────

format: ## Format all files
	@bash $(DOTFILES)/ops/format-all.sh

clean: ## Remove zsh caches, log files, and .DS_Stores in repo
	@bash $(DOTFILES)/ops/clean.sh

clean-all: ## Full clean: backups, Homebrew cache, and everything from 'clean'
	@bash $(DOTFILES)/ops/clean-all.sh

vscode-parity: ## Check VS Code extension parity with extensions.txt
	@bash $(DOTFILES)/health/check-vscode-parity.sh --check

maint-check: ## Run maintenance validation checks in parallel
	@bash $(DOTFILES)/ops/maint-check.sh

docs-regen: ## Regenerate CLI reference documentation (idempotent — file is gitignored)
	@bash $(DOTFILES)/ops/generate-cli-reference.sh

docs-sync: docs-regen ## Alias for docs-regen (kept for backwards compatibility)

# ── LaunchD ──────────────────────────────────────────────────────────

automation-list: ## List all managed LaunchD agents
	@bash $(DOTFILES)/ops/automation/launchd-manager.sh list

launchd-install-all: ## Install and load all LaunchD agents
	@bash $(DOTFILES)/ops/automation/launchd-manager.sh install-all

launchd-uninstall-all: ## Unload and remove all LaunchD agents
	@bash $(DOTFILES)/ops/automation/launchd-manager.sh uninstall-all

launchd-status: ## Show status of all LaunchD agents
	@bash $(DOTFILES)/ops/automation/launchd-manager.sh status

launchd-check: ## Validate launchd template contracts
	@bash $(DOTFILES)/health/check-launchd-contracts.sh

# ── Testing ──────────────────────────────────────────────────────────

lint-shell: ## Run syntax and shellcheck on shell scripts
	@bash $(DOTFILES)/ops/lint-shell.sh

test: test-scripts ## Alias for test-scripts

test-scripts: ## Run lightweight script behavior tests in parallel
	@bash $(DOTFILES)/tests/run-parallel.sh

bootstrap-verify: ## Run strict bootstrap reliability verification suite
	@bash $(DOTFILES)/setup/bootstrap-verify.sh
