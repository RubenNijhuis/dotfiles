.PHONY: help install update stow unstow macos ssh-setup gpg-setup \
	backup brew-sync brew-audit \
	doctor ops-status stow-report spicetify-status spicetify-apply spicetify-restore \
	hooks format vscode-setup keychain-check automation-setup remove-bloatware new-tool \
	lint-shell test-scripts maint-check bootstrap-verify docs-sync docs-regen \
	automation-list launchd-install-all launchd-uninstall-all launchd-status \
	clean clean-all restore status launchd-check vscode-parity \
	help-setup help-brew help-launchd help-test \
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

# ── Core ─────────────────────────────────────────────────────────────

install: ## Full install (bootstrap + brew + stow + macos)
	@bash $(DOTFILES)/install.sh

update: ## Update repos, brew packages, runtimes, and re-stow configs
	@bash $(DOTFILES)/ops/update.sh

stow: ## Stow all config packages
	@bash $(DOTFILES)/setup/stow-all.sh

stow-report: ## Preview stow conflicts without changing files
	@bash $(DOTFILES)/setup/stow-report.sh

unstow: ## Unstow all config packages
	@bash $(DOTFILES)/setup/unstow-all.sh

macos: ## Apply macOS defaults
	@bash $(DOTFILES)/setup/macos-defaults.sh

# ── Health & Status ──────────────────────────────────────────────────

status: ## Quick system status — shows only actionable items
	@bash $(DOTFILES)/health/doctor.sh --status

doctor: ## Run comprehensive system health check
	@bash $(DOTFILES)/health/doctor.sh

ops-status: ## Show consolidated automation and ops health status
	@bash $(DOTFILES)/ops/automation/ops-status.sh

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

maint-check: lint-shell test-scripts launchd-check docs-sync vscode-parity brew-audit ## Run maintenance validation checks

docs-sync: ## Verify generated documentation is up to date
	@bash $(DOTFILES)/ops/generate-cli-reference.sh --check

docs-regen: ## Regenerate CLI reference documentation
	@bash $(DOTFILES)/ops/generate-cli-reference.sh

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

test-scripts: ## Run lightweight script behavior tests
	@bash $(DOTFILES)/tests/test-idempotency.sh
	@bash $(DOTFILES)/tests/test-cli-contract.sh
	@bash $(DOTFILES)/tests/test-cli-parsing.sh
	@bash $(DOTFILES)/tests/test-install-checkpoint.sh
	@bash $(DOTFILES)/tests/test-error-handling.sh
	@bash $(DOTFILES)/tests/test-backup-restore.sh
	@bash $(DOTFILES)/tests/test-integration.sh
	@printf "  \033[32m✓\033[0m Script tests passed\n"

bootstrap-verify: ## Run strict bootstrap reliability verification suite
	@bash $(DOTFILES)/setup/bootstrap-verify.sh
