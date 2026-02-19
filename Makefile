.PHONY: help help-all install update stow unstow macos ssh-info gpg-info ssh-setup gpg-setup \
	migrate-ssh backup restore brew-sync brew-audit validate-repos migrate-dev-dryrun migrate-dev \
	complete-migration openclaw-setup openclaw-info ai-on doctor doctor-quick update-repos \
	hooks profile-shell format vscode-setup backup-setup backup-status doctor-setup doctor-status stow-report \
	check-scripts test-scripts maint-check maint-sync maint-automation maint maint-full \
	bootstrap-verify docs-generate docs-sync ops-status repo-update-setup repo-update-status \
	ai-startup-setup ai-startup-status keychain-check backup-verify launchd-check brew-sync-dry doctor-ci

DOTFILES := $(shell pwd)

help: ## Show common commands
	@printf "\033[36m%-15s\033[0m %s\n" "install" "Full install (bootstrap + brew + stow + macos)"
	@printf "\033[36m%-15s\033[0m %s\n" "update" "Update brew packages and re-stow configs"
	@printf "\033[36m%-15s\033[0m %s\n" "stow" "Stow all config packages"
	@printf "\033[36m%-15s\033[0m %s\n" "stow-report" "Preview stow conflicts without changing files"
	@printf "\033[36m%-15s\033[0m %s\n" "doctor" "Run comprehensive system health check"
	@printf "\033[36m%-15s\033[0m %s\n" "doctor-quick" "Run quick health check (skip optional checks)"
	@printf "\033[36m%-15s\033[0m %s\n" "format" "Format all files according to EditorConfig"
	@printf "\033[36m%-15s\033[0m %s\n" "ai-on" "Start OpenClaw gateway and LM Studio server"
	@printf "\033[36m%-15s\033[0m %s\n" "openclaw-info" "Display OpenClaw status and configuration"
	@printf "\033[36m%-15s\033[0m %s\n" "openclaw-setup" "Configure OpenClaw (requires PHONE_NUMBER=...)"
	@printf "\033[36m%-15s\033[0m %s\n" "backup" "Backup current dotfiles before modifications"
	@printf "\033[36m%-15s\033[0m %s\n" "backup-status" "Show backup automation status"
	@printf "\033[36m%-15s\033[0m %s\n" "doctor-status" "Show health monitoring automation status"
	@printf "\033[36m%-15s\033[0m %s\n" "ops-status" "Show consolidated automation and ops health status"
	@printf "\033[36m%-15s\033[0m %s\n" "bootstrap-verify" "Run strict bootstrap reliability verification suite"
	@printf "\033[36m%-15s\033[0m %s\n" "doctor-ci" "Run deterministic CI health checks"
	@printf "\033[36m%-15s\033[0m %s\n" "docs-sync" "Fail if generated CLI docs are stale"
	@printf "\033[36m%-15s\033[0m %s\n" "launchd-check" "Validate launchd template contracts"
	@printf "\033[36m%-15s\033[0m %s\n" "brew-sync-dry" "Preview brew-sync additions without editing Brewfiles"
	@printf "\033[36m%-15s\033[0m %s\n" "maint" "Run maintenance validation checks"
	@printf "\033[36m%-15s\033[0m %s\n" "maint-full" "Run checks plus sync/update maintenance workflow"
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

migrate-dev-dryrun: ## Preview Developer migration
	@bash $(DOTFILES)/scripts/migration/migrate-developer-structure.sh --dry-run

migrate-dev: ## Migrate ~/Developer to new structure
	@bash $(DOTFILES)/scripts/migration/migrate-developer-structure.sh

complete-migration: ## Complete the Developer directory migration
	@bash $(DOTFILES)/scripts/migration/migrate-developer-structure.sh --complete

openclaw-setup: ## Configure OpenClaw after stowing (use PHONE_NUMBER=+31...)
	@if [ -z "$${PHONE_NUMBER:-}" ]; then \
		echo "Usage: make openclaw-setup PHONE_NUMBER=+31XXXXXXXXX"; \
		exit 1; \
	fi
	@bash $(DOTFILES)/templates/openclaw/setup-openclaw.sh "$$PHONE_NUMBER"

openclaw-info: ## Display OpenClaw status and configuration
	@echo "OpenClaw Status:"
	@openclaw models status 2>/dev/null || echo "  Not configured or not running"
	@echo ""
	@echo "Gateway:"
	@launchctl list | grep openclaw || echo "  Gateway not loaded"
	@echo ""
	@echo "Reminders:"
	@openclaw cron list 2>/dev/null || echo "  No reminders"

ai-on: ## Start OpenClaw gateway and LM Studio server
	@echo "Starting OpenClaw gateway..."
	@openclaw gateway start 2>/dev/null || true
	@echo "Starting LM Studio server..."
	@lms server start
	@echo ""
	@echo "Service status:"
	@openclaw gateway status 2>/dev/null | sed -n '1,24p' || true

doctor: ## Run comprehensive system health check
	@bash $(DOTFILES)/scripts/health/doctor.sh

doctor-quick: ## Run quick health check (skip optional checks)
	@bash $(DOTFILES)/scripts/health/doctor.sh --quick

update-repos: ## Update all git repositories in ~/Developer
	@bash $(DOTFILES)/scripts/maintenance/update-repos.sh

hooks: ## Install git hooks for code quality checks
	@bash $(DOTFILES)/git-hooks/install-hooks.sh

profile-shell: ## Profile shell startup performance
	@bash $(DOTFILES)/scripts/info/profile-shell.sh && echo "" && bash $(DOTFILES)/scripts/info/profile-shell.sh --analyze

format: ## Format all files according to EditorConfig
	@bash $(DOTFILES)/scripts/maintenance/format-all.sh

vscode-setup: ## Install VS Code extensions from extensions.txt
	@echo "Installing VS Code extensions..."
	@cat "$(DOTFILES)/stow/vscode/Library/Application Support/Code/User/extensions.txt" | \
		grep -v '^#' | grep -v '^$$' | cut -d' ' -f1 | \
		xargs -L 1 code --install-extension
	@echo "✓ Extensions installed"

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

ai-startup-setup: ## Setup login AI startup selector via LaunchD
	@bash $(DOTFILES)/scripts/automation/setup-automation.sh ai-startup

ai-startup-status: ## Show AI startup selector automation status
	@echo "AI Startup Selector Status:"
	@echo ""
	@echo "LaunchD Agent:"
	@launchctl print gui/$$(id -u)/com.user.ai-startup-selector >/dev/null 2>&1 && \
		echo "  com.user.ai-startup-selector (loaded)" || echo "  Not loaded"
	@echo ""
	@echo "Recent runs:"
	@tail -12 ~/.local/log/ai-startup-selector.log 2>/dev/null || echo "  No runs yet"
	@echo ""
	@echo "Log files:"
	@ls -lh ~/.local/log/ai-startup-selector*.log 2>/dev/null || echo "  No logs yet"

keychain-check: ## Validate required keychain entries configured in local/keychain-required.txt
	@bash $(DOTFILES)/scripts/bootstrap/check-keychain.sh

backup-verify: ## Verify backup recency and health status
	@bash $(DOTFILES)/scripts/health/doctor.sh --section backup --no-color

ops-status: ## Show consolidated automation and ops health status
	@bash $(DOTFILES)/scripts/automation/ops-status.sh

check-scripts: ## Run syntax and shellcheck on all scripts
	@echo "Checking shell script syntax..."
	@find $(DOTFILES)/scripts -type f -name "*.sh" -print0 | xargs -0 bash -n
	@echo "Running shellcheck..."
	@find $(DOTFILES)/scripts -type f -name "*.sh" -print0 | xargs -0 shellcheck
	@echo "✓ Script checks passed"

test-scripts: ## Run lightweight script behavior tests
	@bash $(DOTFILES)/scripts/tests/smoke-help.sh
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

maint-check: check-scripts test-scripts docs-sync launchd-check ## Run all maintenance validation checks

maint-sync: update brew-sync brew-audit update-repos ## Run maintenance sync/update workflow

maint-automation: backup-setup doctor-setup ## Setup all built-in automations

maint: maint-check ## Run maintenance validation checks

maint-full: maint-check maint-sync ## Run checks plus sync/update maintenance workflow
