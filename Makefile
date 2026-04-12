.PHONY: help install update stow unstow macos ssh-setup gpg-setup \
	backup brew-sync brew-audit \
	doctor ops-status stow-report \
	hooks format vscode-setup keychain-check automation-setup remove-bloatware new-tool \
	lint-shell test-scripts maint-check bootstrap-verify docs-sync docs-regen \
	automation-list launchd-install-all launchd-uninstall-all launchd-status \
	clean clean-all restore status launchd-check vscode-parity \
	help-setup help-brew help-launchd help-test

DOTFILES := $(shell pwd)

# ── Help ─────────────────────────────────────────────────────────────

help: ## Show commands
	@printf "\n\033[1mDotfiles Command Center\033[0m\n"
	@printf "%s\n\n" "Use the commands below by intent: daily checks first, setup tools second, deeper maintenance when needed."
	@printf "\033[1mStart Here\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "status" "Fast daily snapshot of machine health"
	@printf "  \033[36m%-20s\033[0m %s\n" "doctor" "Full diagnostic pass with next-step guidance"
	@printf "  \033[36m%-20s\033[0m %s\n" "ops-status" "Automation dashboard for launchd tasks"
	@printf "\n\033[1mDaily Work\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "update" "Update repos, brew, runtimes, and re-stow"
	@printf "  \033[36m%-20s\033[0m %s\n" "stow" "Apply all config packages into \$$HOME"
	@printf "  \033[36m%-20s\033[0m %s\n" "unstow" "Remove all config packages from \$$HOME"
	@printf "  \033[36m%-20s\033[0m %s\n" "backup" "Create a fresh dotfiles backup"
	@printf "  \033[36m%-20s\033[0m %s\n" "clean" "Remove caches, logs, and repo clutter"
	@printf "\n\033[1mSetup And Repair\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "install" "Bootstrap a new machine"
	@printf "  \033[36m%-20s\033[0m %s\n" "automation-setup" "Install and load all launchd agents"
	@printf "  \033[36m%-20s\033[0m %s\n" "restore" "Restore from the latest backup"
	@printf "  \033[36m%-20s\033[0m %s\n" "macos" "Apply macOS defaults"
	@printf "\n\033[1mMaintenance\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "maint-check" "Lint, test, and validate repository contracts"
	@printf "  \033[36m%-20s\033[0m %s\n" "format" "Run Biome formatting"
	@printf "  \033[36m%-20s\033[0m %s\n" "docs-sync" "Fail if generated docs are stale"
	@printf "  \033[36m%-20s\033[0m %s\n" "brew-audit" "Check Brewfiles for drift"
	@printf "  \033[36m%-20s\033[0m %s\n" "clean-all" "Deep clean including backups and brew cache"
	@printf "\n\033[2mMore help:\033[0m\n"
	@printf "  \033[2m%-20s %s\033[0m\n" "help-setup" "SSH, GPG, hooks, VS Code, keychain"
	@printf "  \033[2m%-20s %s\033[0m\n" "help-brew" "Brew sync and audit commands"
	@printf "  \033[2m%-20s %s\033[0m\n" "help-launchd" "Automation and launchd commands"
	@printf "  \033[2m%-20s %s\033[0m\n" "help-test" "Tests and verification commands"
	@printf "\n\033[2mSuggested flow: make status -> make doctor -> make update\033[0m\n"

help-setup: ## Setup commands
	@printf "\n\033[1mSetup Toolkit\033[0m\n"
	@printf "%s\n\n" "Use these when bootstrapping a machine or fixing missing local setup."
	@printf "  \033[36m%-20s\033[0m %s\n" "ssh-setup" "Generate SSH keys"
	@printf "  \033[36m%-20s\033[0m %s\n" "gpg-setup" "Generate GPG key and configure Git signing"
	@printf "  \033[36m%-20s\033[0m %s\n" "vscode-setup" "Install VS Code extensions"
	@printf "  \033[36m%-20s\033[0m %s\n" "hooks" "Install git hooks"
	@printf "  \033[36m%-20s\033[0m %s\n" "keychain-check" "Validate required keychain entries"
	@printf "  \033[36m%-20s\033[0m %s\n" "automation-setup" "Setup all LaunchD automations"
	@printf "  \033[36m%-20s\033[0m %s\n" "remove-bloatware" "Remove common macOS built-in apps"
	@printf "  \033[36m%-20s\033[0m %s\n" "new-tool NAME=<n>" "Scaffold a new config package"
	@printf "\n\033[2mSuggested flow: ssh-setup -> gpg-setup -> hooks -> automation-setup\033[0m\n"

help-brew: ## Brew management commands
	@printf "\n\033[1mBrew Toolkit\033[0m\n"
	@printf "%s\n\n" "Use these to sync package state and inspect Brewfile drift."
	@printf "  \033[36m%-20s\033[0m %s\n" "brew-sync" "Sync installed packages to Brewfiles"
	@printf "  \033[36m%-20s\033[0m %s\n" "brew-audit" "Audit Brewfiles for drift"
	@printf "\n\033[2mSuggested flow: brew-audit -> brew-sync -> brew-audit\033[0m\n"

help-launchd: ## LaunchD automation commands
	@printf "\n\033[1mLaunchd Toolkit\033[0m\n"
	@printf "%s\n\n" "Use these to inspect and manage recurring automations."
	@printf "  \033[36m%-20s\033[0m %s\n" "ops-status" "Automation dashboard with recent task results"
	@printf "  \033[36m%-20s\033[0m %s\n" "automation-list" "List all managed agents"
	@printf "  \033[36m%-20s\033[0m %s\n" "launchd-status" "Show agent load status"
	@printf "  \033[36m%-20s\033[0m %s\n" "launchd-install-all" "Install and load all agents"
	@printf "  \033[36m%-20s\033[0m %s\n" "launchd-uninstall-all" "Unload and remove all agents"
	@printf "\n\033[2mSuggested flow: ops-status -> automation-list -> launchd-status\033[0m\n"

help-test: ## Testing & verification commands
	@printf "\n\033[1mVerification Toolkit\033[0m\n"
	@printf "%s\n\n" "Use these to validate behavior, contracts, and generated artifacts."
	@printf "  \033[36m%-20s\033[0m %s\n" "lint-shell" "Run shellcheck on all scripts"
	@printf "  \033[36m%-20s\033[0m %s\n" "test-scripts" "Run script behavior tests"
	@printf "  \033[36m%-20s\033[0m %s\n" "bootstrap-verify" "Strict bootstrap reliability checks"
	@printf "  \033[36m%-20s\033[0m %s\n" "stow-report" "Preview stow conflicts"
	@printf "  \033[36m%-20s\033[0m %s\n" "docs-sync" "Verify generated docs are current"
	@printf "  \033[36m%-20s\033[0m %s\n" "docs-regen" "Regenerate CLI reference"
	@printf "\n\033[2mSuggested flow: lint-shell -> test-scripts -> bootstrap-verify\033[0m\n"

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
