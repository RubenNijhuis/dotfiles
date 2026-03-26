.PHONY: help install update stow unstow macos ssh-setup gpg-setup \
	backup brew-sync brew-audit \
	doctor ops-status stow-report \
	hooks format vscode-setup keychain-check automation-setup remove-bloatware new-tool \
	lint-shell test-scripts maint-check bootstrap-verify docs-sync docs-regen \
	automation-list launchd-install-all launchd-uninstall-all launchd-status \
	clean status \
	help-setup help-brew help-launchd help-test

DOTFILES := $(shell pwd)

# ── Help ─────────────────────────────────────────────────────────────

help: ## Show commands
	@printf "\n\033[1m── Daily ─────────────────────\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "update" "Update brew, runtimes, and re-stow"
	@printf "  \033[36m%-20s\033[0m %s\n" "stow" "Stow all config packages"
	@printf "  \033[36m%-20s\033[0m %s\n" "unstow" "Unstow all config packages"
	@printf "  \033[36m%-20s\033[0m %s\n" "status" "Quick system status"
	@printf "  \033[36m%-20s\033[0m %s\n" "doctor" "Full health check"
	@printf "  \033[36m%-20s\033[0m %s\n" "clean" "Remove caches, logs, .DS_Stores"
	@printf "  \033[36m%-20s\033[0m %s\n" "backup" "Backup dotfiles"
	@printf "\n\033[1m── Occasional ────────────────\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "install" "Full bootstrap (new machine)"
	@printf "  \033[36m%-20s\033[0m %s\n" "macos" "Apply macOS defaults"
	@printf "  \033[36m%-20s\033[0m %s\n" "format" "Run Biome formatting"
	@printf "  \033[36m%-20s\033[0m %s\n" "maint-check" "Lint + test + launchd validation"
	@printf "\n  \033[2m%-20s %s\033[0m\n" "help-setup" "Setup commands (ssh, gpg, hooks...)"
	@printf "  \033[2m%-20s %s\033[0m\n" "help-brew" "Brew management commands"
	@printf "  \033[2m%-20s %s\033[0m\n" "help-launchd" "LaunchD automation commands"
	@printf "  \033[2m%-20s %s\033[0m\n" "help-test" "Testing & verification commands"
	@printf ""

help-setup: ## Setup commands
	@printf "\n\033[1m── Setup ─────────────────────\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "ssh-setup" "Generate SSH keys for current profile"
	@printf "  \033[36m%-20s\033[0m %s\n" "gpg-setup" "Generate GPG key and configure Git signing"
	@printf "  \033[36m%-20s\033[0m %s\n" "vscode-setup" "Install VS Code extensions"
	@printf "  \033[36m%-20s\033[0m %s\n" "hooks" "Install git hooks"
	@printf "  \033[36m%-20s\033[0m %s\n" "keychain-check" "Validate required keychain entries"
	@printf "  \033[36m%-20s\033[0m %s\n" "automation-setup" "Setup all LaunchD automations"
	@printf "  \033[36m%-20s\033[0m %s\n" "remove-bloatware" "Remove common macOS built-in apps"
	@printf "  \033[36m%-20s\033[0m %s\n" "new-tool NAME=<n>" "Scaffold a new stow package"
	@printf ""

help-brew: ## Brew management commands
	@printf "\n\033[1m── Brew ──────────────────────\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "brew-sync" "Sync installed packages to Brewfiles (--dry-run)"
	@printf "  \033[36m%-20s\033[0m %s\n" "brew-audit" "Audit Brewfiles for drift"
	@printf ""

help-launchd: ## LaunchD automation commands
	@printf "\n\033[1m── LaunchD ───────────────────\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "ops-status" "Consolidated automation health"
	@printf "  \033[36m%-20s\033[0m %s\n" "automation-list" "List all managed agents"
	@printf "  \033[36m%-20s\033[0m %s\n" "launchd-status" "Show agent load status"
	@printf "  \033[36m%-20s\033[0m %s\n" "launchd-install-all" "Install and load all agents"
	@printf "  \033[36m%-20s\033[0m %s\n" "launchd-uninstall-all" "Unload and remove all agents"
	@printf ""

help-test: ## Testing & verification commands
	@printf "\n\033[1m── Testing ───────────────────\033[0m\n"
	@printf "  \033[36m%-20s\033[0m %s\n" "lint-shell" "Run shellcheck on all scripts"
	@printf "  \033[36m%-20s\033[0m %s\n" "test-scripts" "Run script behavior tests"
	@printf "  \033[36m%-20s\033[0m %s\n" "bootstrap-verify" "Strict bootstrap reliability checks"
	@printf "  \033[36m%-20s\033[0m %s\n" "stow-report" "Preview stow conflicts"
	@printf "  \033[36m%-20s\033[0m %s\n" "docs-sync" "Verify generated docs are current"
	@printf "  \033[36m%-20s\033[0m %s\n" "docs-regen" "Regenerate CLI reference"
	@printf ""

# ── Core ─────────────────────────────────────────────────────────────

install: ## Full install (bootstrap + brew + stow + macos)
	@bash $(DOTFILES)/install.sh

update: ## Update brew packages, runtimes, and re-stow configs
	@bash $(DOTFILES)/scripts/maintenance/update.sh

stow: ## Stow all config packages
	@bash $(DOTFILES)/scripts/bootstrap/stow-all.sh

stow-report: ## Preview stow conflicts without changing files
	@bash $(DOTFILES)/scripts/bootstrap/stow-report.sh

unstow: ## Unstow all config packages
	@bash $(DOTFILES)/scripts/bootstrap/unstow-all.sh

macos: ## Apply macOS defaults
	@bash $(DOTFILES)/scripts/bootstrap/macos-defaults.sh

# ── Health & Status ──────────────────────────────────────────────────

status: ## Quick system status — shows only actionable items
	@bash $(DOTFILES)/scripts/health/doctor.sh --status

doctor: ## Run comprehensive system health check
	@bash $(DOTFILES)/scripts/health/doctor.sh

ops-status: ## Show consolidated automation and ops health status
	@bash $(DOTFILES)/scripts/automation/ops-status.sh

# ── Setup (one-time) ────────────────────────────────────────────────

ssh-setup: ## Generate SSH keys for current profile
	@bash $(DOTFILES)/templates/ssh/generate-keys.sh

gpg-setup: ## Generate GPG key and configure Git signing
	@bash $(DOTFILES)/templates/gpg/generate-keys.sh

vscode-setup: ## Install VS Code extensions from extensions.txt
	@bash $(DOTFILES)/scripts/bootstrap/vscode-setup.sh

hooks: ## Install git hooks for code quality checks
	@bash $(DOTFILES)/git-hooks/install-hooks.sh

keychain-check: ## Validate required keychain entries
	@bash $(DOTFILES)/scripts/bootstrap/check-keychain.sh

automation-setup: ## Setup all LaunchD automations
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh setup-all

remove-bloatware: ## Remove common macOS built-in apps
	@bash $(DOTFILES)/scripts/bootstrap/remove-bloatware.sh

new-tool: ## Scaffold a new stow package (usage: make new-tool NAME=<name>)
	@bash $(DOTFILES)/scripts/bootstrap/new-tool.sh $(NAME)

# ── Backup ───────────────────────────────────────────────────────────

backup: ## Backup current dotfiles before modifications
	@bash $(DOTFILES)/scripts/backup/backup-dotfiles.sh

# ── Brew ─────────────────────────────────────────────────────────────

brew-sync: ## Sync manually installed packages to Brewfiles
	@bash $(DOTFILES)/scripts/maintenance/sync-brew.sh

brew-audit: ## Audit Brewfiles for missing or undeclared packages
	@bash $(DOTFILES)/scripts/maintenance/brew-audit.sh

# ── Maintenance ──────────────────────────────────────────────────────

format: ## Format all files
	@bash $(DOTFILES)/scripts/maintenance/format-all.sh

clean: ## Remove zsh caches, log files, and .DS_Stores in repo
	@bash $(DOTFILES)/scripts/maintenance/clean.sh

maint-check: lint-shell test-scripts launchd-check ## Run maintenance validation checks

docs-sync: ## Verify generated documentation is up to date
	@bash $(DOTFILES)/scripts/maintenance/generate-cli-reference.sh --check

docs-regen: ## Regenerate CLI reference documentation
	@bash $(DOTFILES)/scripts/maintenance/generate-cli-reference.sh

# ── LaunchD ──────────────────────────────────────────────────────────

automation-list: ## List all managed LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh list

launchd-install-all: ## Install and load all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh install-all

launchd-uninstall-all: ## Unload and remove all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh uninstall-all

launchd-status: ## Show status of all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh status

launchd-check: ## Validate launchd template contracts
	@bash $(DOTFILES)/scripts/health/check-launchd-contracts.sh

# ── Testing ──────────────────────────────────────────────────────────

lint-shell: ## Run syntax and shellcheck on shell scripts
	@bash $(DOTFILES)/scripts/maintenance/lint-shell.sh

test-scripts: ## Run lightweight script behavior tests
	@bash $(DOTFILES)/scripts/tests/test-array-init.sh
	@bash $(DOTFILES)/scripts/tests/test-idempotency.sh
	@bash $(DOTFILES)/scripts/tests/test-cli-contract.sh
	@bash $(DOTFILES)/scripts/tests/test-cli-parsing.sh
	@bash $(DOTFILES)/scripts/tests/test-install-checkpoint.sh
	@printf "  \033[32m✓\033[0m Script tests passed\n"

bootstrap-verify: ## Run strict bootstrap reliability verification suite
	@bash $(DOTFILES)/scripts/bootstrap/bootstrap-verify.sh
