.PHONY: help help-all install update stow unstow macos ssh-info gpg-info ssh-setup gpg-setup \
	migrate-ssh backup restore brew-sync brew-audit validate-repos migrate-dev-dryrun migrate-dev \
	complete-migration doctor doctor-quick update-repos \
	hooks profile-shell format vscode-setup backup-setup backup-status doctor-setup doctor-status stow-report \
	lint-shell test-scripts maint-check maint-check-ci maint-sync maint-automation maint-full \
	bootstrap-verify docs-generate docs-sync ops-status repo-update-setup repo-update-status \
	keychain-check backup-verify launchd-install-all launchd-uninstall-all launchd-status launchd-check brew-sync-dry doctor-ci \
	cleanup-dotfiles-backups remove-bloatware

DOTFILES := $(shell pwd)

help: ## Show common commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk -F':.*?## ' '$$1 ~ /^(install|update|stow|stow-report|doctor|doctor-quick|format|backup|cleanup-dotfiles-backups|backup-status|doctor-status|ops-status|bootstrap-verify|doctor-ci|docs-sync|launchd-check|brew-sync-dry|maint-check|maint-full|remove-bloatware)$$/ \
		{printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@printf "\nRun \033[36mmake help-all\033[0m to see every target.\n"

help-all: ## Show all commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Full install (bootstrap + brew + stow + macos)
	@bash $(DOTFILES)/install.sh

update: ## Update brew packages and re-stow configs
	@bash $(DOTFILES)/scripts/maintenance/update.sh

stow: ## Stow all config packages
	@bash $(DOTFILES)/scripts/bootstrap/stow-all.sh

stow-report: ## Preview stow conflicts without changing files
	@bash $(DOTFILES)/scripts/bootstrap/stow-report.sh

unstow: ## Unstow all config packages
	@bash $(DOTFILES)/scripts/bootstrap/unstow-all.sh

macos: ## Apply macOS defaults
	@bash $(DOTFILES)/macos/defaults.sh

ssh-info: ## Display SSH key information and status
	@bash $(DOTFILES)/scripts/info/ssh-info.sh

gpg-info: ## Display GPG key information and Git signing config
	@bash $(DOTFILES)/scripts/info/gpg-info.sh

ssh-setup: ## Generate SSH keys for current profile
	@bash $(DOTFILES)/templates/ssh/generate-keys.sh

gpg-setup: ## Generate GPG key and configure Git signing
	@bash $(DOTFILES)/templates/gpg/generate-keys.sh

migrate-ssh: ## Migrate existing SSH keys to new naming
	@bash $(DOTFILES)/scripts/migration/migrate-ssh-keys.sh

backup: ## Backup current dotfiles before modifications
	@bash $(DOTFILES)/scripts/backup/backup-dotfiles.sh

cleanup-dotfiles-backups: ## Remove old ~/dotfiles.backup.* directories
	@bash $(DOTFILES)/scripts/maintenance/cleanup-dotfiles-backups.sh

remove-bloatware: ## Remove common macOS built-in apps (Tips, Chess, Stocks, etc.)
	@bash $(DOTFILES)/scripts/bootstrap/remove-bloatware.sh

restore: ## Restore from latest backup
	@bash $(DOTFILES)/scripts/backup/restore-backup.sh

brew-sync: ## Sync manually installed packages to Brewfiles
	@bash $(DOTFILES)/scripts/maintenance/sync-brew.sh

brew-sync-dry: ## Preview brew-sync additions without editing Brewfiles
	@bash $(DOTFILES)/scripts/maintenance/sync-brew.sh --dry-run

brew-audit: ## Audit Brewfiles for missing or undeclared packages
	@bash $(DOTFILES)/scripts/maintenance/brew-audit.sh

validate-repos: ## Check repos are safe to migrate
	@bash $(DOTFILES)/scripts/migration/validate-repos.sh

migrate-dev-dryrun: ## Preview repository migration from legacy source to target tree
	@bash $(DOTFILES)/scripts/migration/migrate-developer-structure.sh --dry-run

migrate-dev: ## Run automatic repository migration (rule-based)
	@bash $(DOTFILES)/scripts/migration/migrate-developer-structure.sh

complete-migration: ## Run interactive migration mode for remaining repos
	@bash $(DOTFILES)/scripts/migration/migrate-developer-structure.sh --complete

doctor: ## Run comprehensive system health check
	@bash $(DOTFILES)/scripts/health/doctor.sh

doctor-quick: ## Run quick health check (skip optional checks)
	@bash $(DOTFILES)/scripts/health/doctor.sh --quick

update-repos: ## Update all git repositories in $DOTFILES_DEVELOPER_ROOT
	@bash $(DOTFILES)/scripts/maintenance/update-repos.sh

hooks: ## Install git hooks for code quality checks
	@bash $(DOTFILES)/git-hooks/install-hooks.sh

profile-shell: ## Profile shell startup performance
	@bash $(DOTFILES)/scripts/info/profile-shell.sh --full

format: ## Format all files according to EditorConfig
	@bash $(DOTFILES)/scripts/maintenance/format-all.sh

vscode-setup: ## Install VS Code extensions from extensions.txt
	@bash $(DOTFILES)/scripts/bootstrap/vscode-setup.sh

backup-setup: ## Setup automated daily backups via LaunchD
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh backup

backup-status: ## Show backup automation status
	@bash $(DOTFILES)/scripts/automation/show-agent-status.sh \
		"Backup Automation" "com.user.dotfiles-backup" \
		"Recent Backups" "~/.dotfiles-backup/" "dotfiles-backup.*"

doctor-setup: ## Setup automated daily health checks via LaunchD
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh doctor

doctor-status: ## Show health monitoring automation status
	@bash $(DOTFILES)/scripts/automation/show-agent-status.sh \
		"Health Monitoring" "com.user.dotfiles-doctor" \
		"Recent Health Checks" "~/.local/log/dotfiles-doctor-summary.log" "dotfiles-doctor*.log" 10

repo-update-setup: ## Setup scheduled repository updates via LaunchD
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh repo-update

repo-update-status: ## Show scheduled repository update automation status
	@bash $(DOTFILES)/scripts/automation/show-agent-status.sh \
		"Repository Update Automation" "com.user.repo-update" \
		"Recent summary" "~/.local/log/repo-update-summary.log" "repo-update*.log" 12

keychain-check: ## Validate required keychain entries configured in local/keychain-required.txt
	@bash $(DOTFILES)/scripts/bootstrap/check-keychain.sh

backup-verify: ## Verify backup recency and health status
	@bash $(DOTFILES)/scripts/health/doctor.sh --section backup --no-color

ops-status: ## Show consolidated automation and ops health status
	@bash $(DOTFILES)/scripts/automation/ops-status.sh

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

doctor-ci: ## Run deterministic CI health checks
	@bash $(DOTFILES)/scripts/health/doctor-ci.sh

docs-generate: ## Regenerate generated documentation artifacts
	@bash $(DOTFILES)/scripts/docs/generate-cli-reference.sh

docs-sync: ## Verify generated documentation is up to date
	@bash $(DOTFILES)/scripts/docs/generate-cli-reference.sh --check

launchd-install-all: ## Install and load all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh install-all

launchd-uninstall-all: ## Unload and remove all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh uninstall-all

launchd-status: ## Show status of all LaunchD agents
	@bash $(DOTFILES)/scripts/automation/launchd-manager.sh status

launchd-check: ## Validate launchd template contracts
	@bash $(DOTFILES)/scripts/health/check-launchd-contracts.sh

maint-check: lint-shell test-scripts launchd-check ## Run maintenance validation checks (local-safe)

maint-check-ci: maint-check docs-sync ## Run maintenance checks including docs staleness (CI)

maint-sync: update brew-sync brew-audit update-repos ## Run maintenance sync/update workflow

maint-automation: backup-setup doctor-setup ## Setup all built-in automations

maint-full: maint-check maint-sync ## Run checks plus sync/update maintenance workflow
