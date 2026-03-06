.PHONY: help help-all install update stow unstow macos ssh-info gpg-info ssh-setup gpg-setup \
	migrate-ssh backup restore brew-sync brew-audit validate-repos migrate-dev-dryrun migrate-dev \
	complete-migration doctor doctor-quick update-repos \
	hooks profile-shell format vscode-setup backup-setup backup-status doctor-setup doctor-status stow-report \
	lint-shell test-scripts maint-check maint-check-ci maint-sync maint-automation maint-full \
	bootstrap-verify docs-generate docs-sync ops-status repo-update-setup repo-update-status \
	keychain-check backup-verify launchd-check brew-sync-dry doctor-ci \
	cleanup-dotfiles-backups

DOTFILES := $(shell pwd)

help: ## Show common commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk -F':.*?## ' '$$1 ~ /^(install|update|stow|stow-report|doctor|doctor-quick|format|backup|cleanup-dotfiles-backups|backup-status|doctor-status|ops-status|bootstrap-verify|doctor-ci|docs-sync|launchd-check|brew-sync-dry|maint-check|maint-full)$$/ \
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
	@echo "Backup Automation Status:"
	@echo ""
	@echo "LaunchD Agent:"
	@launchctl print gui/$$(id -u)/com.user.dotfiles-backup >/dev/null 2>&1 && \
		echo "  com.user.dotfiles-backup (loaded)" || echo "  Not loaded"
	@echo ""
	@echo "Recent Backups:"
	@ls -lth ~/.dotfiles-backup/ 2>/dev/null | head -8 || echo "  No backups found"
	@echo ""
	@echo "Log files:"
	@ls -lh ~/.local/log/dotfiles-backup.* 2>/dev/null || echo "  No logs yet"

doctor-setup: ## Setup automated daily health checks via LaunchD
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh doctor

doctor-status: ## Show health monitoring automation status
	@echo "Health Monitoring Status:"
	@echo ""
	@echo "LaunchD Agent:"
	@launchctl print gui/$$(id -u)/com.user.dotfiles-doctor >/dev/null 2>&1 && \
		echo "  com.user.dotfiles-doctor (loaded)" || echo "  Not loaded"
	@echo ""
	@echo "Recent Health Checks:"
	@tail -10 ~/.local/log/dotfiles-doctor-summary.log 2>/dev/null || echo "  No checks yet"
	@echo ""
	@echo "Log files:"
	@ls -lh ~/.local/log/dotfiles-doctor*.log 2>/dev/null || echo "  No logs yet"

repo-update-setup: ## Setup scheduled repository updates via LaunchD
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh repo-update

repo-update-status: ## Show scheduled repository update automation status
	@echo "Repository Update Automation Status:"
	@echo ""
	@echo "LaunchD Agent:"
	@launchctl print gui/$$(id -u)/com.user.repo-update >/dev/null 2>&1 && \
		echo "  com.user.repo-update (loaded)" || echo "  Not loaded"
	@echo ""
	@echo "Recent summary:"
	@tail -12 ~/.local/log/repo-update-summary.log 2>/dev/null || echo "  No runs yet"
	@echo ""
	@echo "Log files:"
	@ls -lh ~/.local/log/repo-update*.log 2>/dev/null || echo "  No logs yet"

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

launchd-check: ## Validate launchd template contracts
	@bash $(DOTFILES)/scripts/health/check-launchd-contracts.sh

maint-check: lint-shell test-scripts launchd-check ## Run maintenance validation checks (local-safe)

maint-check-ci: maint-check docs-sync ## Run maintenance checks including docs staleness (CI)

maint-sync: update brew-sync brew-audit update-repos ## Run maintenance sync/update workflow

maint-automation: backup-setup doctor-setup ## Setup all built-in automations

maint-full: maint-check maint-sync ## Run checks plus sync/update maintenance workflow
