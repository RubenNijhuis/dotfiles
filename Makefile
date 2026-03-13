.PHONY: help install update update-brew update-stow stow unstow macos ssh-setup gpg-setup \
	backup brew-sync brew-sync-dry brew-audit \
	doctor ops-status stow-report \
	hooks format vscode-setup keychain-check automation-setup remove-bloatware new-tool \
	lint-shell test-scripts maint-check bootstrap-verify docs-sync \
	launchd-install-all launchd-uninstall-all launchd-status \
	clean status

DOTFILES := $(shell pwd)

# ── Core ──────────────────────────────────────────────────────────────

help: ## Show all commands
	@printf "\n\033[1m── Core ──────────────────────\033[0m\n"
	@printf "  \033[36m%-25s\033[0m %s\n" "install" "Full install (bootstrap + brew + stow + macos)"
	@printf "  \033[36m%-25s\033[0m %s\n" "update" "Update brew packages, runtimes, and re-stow configs"
	@printf "  \033[36m%-25s\033[0m %s\n" "update-brew" "Update only Homebrew packages"
	@printf "  \033[36m%-25s\033[0m %s\n" "update-stow" "Re-stow config packages only"
	@printf "  \033[36m%-25s\033[0m %s\n" "stow" "Stow all config packages"
	@printf "  \033[36m%-25s\033[0m %s\n" "unstow" "Unstow all config packages"
	@printf "  \033[36m%-25s\033[0m %s\n" "macos" "Apply macOS defaults"
	@printf "\n\033[1m── Health & Status ──────────\033[0m\n"
	@printf "  \033[36m%-25s\033[0m %s\n" "status" "Quick system status (shows only actionable items)"
	@printf "  \033[36m%-25s\033[0m %s\n" "doctor" "Run comprehensive system health check"
	@printf "  \033[36m%-25s\033[0m %s\n" "ops-status" "Show consolidated automation and ops health status"
	@printf "  \033[36m%-25s\033[0m %s\n" "stow-report" "Preview stow conflicts without changing files"
	@printf "\n\033[1m── Brew ─────────────────────\033[0m\n"
	@printf "  \033[36m%-25s\033[0m %s\n" "brew-sync" "Sync manually installed packages to Brewfiles"
	@printf "  \033[36m%-25s\033[0m %s\n" "brew-sync-dry" "Preview brew-sync additions without editing Brewfiles"
	@printf "  \033[36m%-25s\033[0m %s\n" "brew-audit" "Audit Brewfiles for missing or undeclared packages"
	@printf "\n\033[1m── Maintenance ──────────────\033[0m\n"
	@printf "  \033[36m%-25s\033[0m %s\n" "format" "Format all files according to EditorConfig"
	@printf "  \033[36m%-25s\033[0m %s\n" "clean" "Remove zsh caches, log files, and .DS_Stores"
	@printf "  \033[36m%-25s\033[0m %s\n" "maint-check" "Run maintenance validation checks (lint + test + launchd)"
	@printf "  \033[36m%-25s\033[0m %s\n" "docs-sync" "Verify generated documentation is up to date"
	@printf "\n\033[1m── Setup (one-time) ─────────\033[0m\n"
	@printf "  \033[36m%-25s\033[0m %s\n" "ssh-setup" "Generate SSH keys for current profile"
	@printf "  \033[36m%-25s\033[0m %s\n" "gpg-setup" "Generate GPG key and configure Git signing"
	@printf "  \033[36m%-25s\033[0m %s\n" "vscode-setup" "Install VS Code extensions"
	@printf "  \033[36m%-25s\033[0m %s\n" "hooks" "Install git hooks"
	@printf "  \033[36m%-25s\033[0m %s\n" "keychain-check" "Validate required keychain entries"
	@printf "  \033[36m%-25s\033[0m %s\n" "automation-setup" "Setup all LaunchD automations"
	@printf "  \033[36m%-25s\033[0m %s\n" "remove-bloatware" "Remove common macOS built-in apps"
	@printf "  \033[36m%-25s\033[0m %s\n" "new-tool NAME=<name>" "Scaffold a new stow package"
	@printf "\n\033[1m── Backup ───────────────────\033[0m\n"
	@printf "  \033[36m%-25s\033[0m %s\n" "backup" "Backup current dotfiles before modifications"
	@printf "\n\033[1m── LaunchD ──────────────────\033[0m\n"
	@printf "  \033[36m%-25s\033[0m %s\n" "launchd-install-all" "Install and load all LaunchD agents"
	@printf "  \033[36m%-25s\033[0m %s\n" "launchd-uninstall-all" "Unload and remove all LaunchD agents"
	@printf "  \033[36m%-25s\033[0m %s\n" "launchd-status" "Show status of all LaunchD agents"
	@printf "\n\033[1m── Testing ──────────────────\033[0m\n"
	@printf "  \033[36m%-25s\033[0m %s\n" "lint-shell" "Run syntax and shellcheck on shell scripts"
	@printf "  \033[36m%-25s\033[0m %s\n" "test-scripts" "Run lightweight script behavior tests"
	@printf "  \033[36m%-25s\033[0m %s\n" "bootstrap-verify" "Strict bootstrap reliability checks"
	@printf ""

install: ## Full install (bootstrap + brew + stow + macos)
	@bash $(DOTFILES)/install.sh

update: ## Update brew packages, runtimes, and re-stow configs
	@bash $(DOTFILES)/scripts/maintenance/update.sh

update-brew: ## Update only Homebrew packages
	@brew update && brew upgrade && brew cleanup

update-stow: ## Re-stow config packages only
	@bash $(DOTFILES)/scripts/bootstrap/stow-all.sh

stow: ## Stow all config packages
	@bash $(DOTFILES)/scripts/bootstrap/stow-all.sh

stow-report: ## Preview stow conflicts without changing files
	@bash $(DOTFILES)/scripts/bootstrap/stow-report.sh

unstow: ## Unstow all config packages
	@bash $(DOTFILES)/scripts/bootstrap/unstow-all.sh

macos: ## Apply macOS defaults
	@bash $(DOTFILES)/macos/defaults.sh

# ── Health & Status ───────────────────────────────────────────────────

status: ## Quick system status — shows only actionable items
	@bash $(DOTFILES)/scripts/health/status.sh

doctor: ## Run comprehensive system health check
	@bash $(DOTFILES)/scripts/health/doctor.sh

ops-status: ## Show consolidated automation and ops health status
	@bash $(DOTFILES)/scripts/automation/ops-status.sh

# ── Setup (one-time) ─────────────────────────────────────────────────

ssh-setup: ## Generate SSH keys for current profile
	@bash $(DOTFILES)/templates/ssh/generate-keys.sh

gpg-setup: ## Generate GPG key and configure Git signing
	@bash $(DOTFILES)/templates/gpg/generate-keys.sh

vscode-setup: ## Install VS Code extensions from extensions.txt
	@bash $(DOTFILES)/scripts/bootstrap/vscode-setup.sh

hooks: ## Install git hooks for code quality checks
	@bash $(DOTFILES)/git-hooks/install-hooks.sh

keychain-check: ## Validate required keychain entries configured in local/keychain-required.txt
	@bash $(DOTFILES)/scripts/bootstrap/check-keychain.sh

automation-setup: ## Setup all LaunchD automations (backup, doctor, repo-update)
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh backup
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh doctor
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh repo-update

remove-bloatware: ## Remove common macOS built-in apps (Tips, Chess, Stocks, etc.)
	@bash $(DOTFILES)/scripts/bootstrap/remove-bloatware.sh

new-tool: ## Scaffold a new stow package (usage: make new-tool NAME=<name>)
	@bash $(DOTFILES)/scripts/bootstrap/new-tool.sh $(NAME)

# ── Backup ────────────────────────────────────────────────────────────

backup: ## Backup current dotfiles before modifications
	@bash $(DOTFILES)/scripts/backup/backup-dotfiles.sh

# ── Brew ──────────────────────────────────────────────────────────────

brew-sync: ## Sync manually installed packages to Brewfiles
	@bash $(DOTFILES)/scripts/maintenance/sync-brew.sh

brew-sync-dry: ## Preview brew-sync additions without editing Brewfiles
	@bash $(DOTFILES)/scripts/maintenance/sync-brew.sh --dry-run

brew-audit: ## Audit Brewfiles for missing or undeclared packages
	@bash $(DOTFILES)/scripts/maintenance/brew-audit.sh

# ── Maintenance ───────────────────────────────────────────────────────

format: ## Format all files according to EditorConfig
	@bash $(DOTFILES)/scripts/maintenance/format-all.sh

clean: ## Remove zsh caches, log files, and .DS_Stores in repo
	@bash $(DOTFILES)/scripts/maintenance/clean.sh

maint-check: lint-shell test-scripts launchd-check ## Run maintenance validation checks (lint + test + launchd)

docs-sync: ## Verify generated documentation is up to date
	@bash $(DOTFILES)/scripts/docs/generate-cli-reference.sh --check

# ── LaunchD ───────────────────────────────────────────────────────────

launchd-install-all: ## Install and load all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh install-all

launchd-uninstall-all: ## Unload and remove all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh uninstall-all

launchd-status: ## Show status of all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh status

launchd-check: ## Validate launchd template contracts
	@bash $(DOTFILES)/scripts/health/check-launchd-contracts.sh

# ── Testing ───────────────────────────────────────────────────────────

lint-shell: ## Run syntax and shellcheck on shell scripts
	@bash $(DOTFILES)/scripts/maintenance/lint-shell.sh

test-scripts: ## Run lightweight script behavior tests
	@bash $(DOTFILES)/scripts/tests/test-array-init.sh
	@bash $(DOTFILES)/scripts/tests/test-idempotency.sh
	@bash $(DOTFILES)/scripts/tests/test-cli-contract.sh
	@bash $(DOTFILES)/scripts/tests/test-cli-parsing.sh
	@bash $(DOTFILES)/scripts/tests/test-install-checkpoint.sh
	@echo "✓ Script tests passed"

bootstrap-verify: ## Run strict bootstrap reliability verification suite
	@bash $(DOTFILES)/scripts/bootstrap/bootstrap-verify.sh
