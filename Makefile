.PHONY: help help-all install update stow unstow macos ssh-info gpg-info ssh-setup gpg-setup \
	migrate-ssh backup restore brew-sync brew-audit validate-repos migrate-dev-dryrun migrate-dev \
	complete-migration openclaw-setup openclaw-info ai-on doctor doctor-quick update-repos \
	hooks profile-shell format vscode-setup backup-setup backup-status doctor-setup doctor-status stow-report \
	check-scripts test-scripts maint-check maint-sync maint-automation maint maint-full

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
	@printf "\033[36m%-15s\033[0m %s\n" "maint" "Run maintenance validation checks"
	@printf "\033[36m%-15s\033[0m %s\n" "maint-full" "Run checks plus sync/update maintenance workflow"
	@printf "\nRun \033[36mmake help-all\033[0m to see every target.\n"

help-all: ## Show all commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Full install (bootstrap + brew + stow + macos)
	@bash $(DOTFILES)/install.sh

update: ## Update brew packages and re-stow configs
	@bash $(DOTFILES)/scripts/update.sh

stow: ## Stow all config packages
	@bash $(DOTFILES)/scripts/stow-all.sh

stow-report: ## Preview stow conflicts without changing files
	@bash $(DOTFILES)/scripts/stow-report.sh

unstow: ## Unstow all config packages
	@bash $(DOTFILES)/scripts/unstow-all.sh

macos: ## Apply macOS defaults
	@bash $(DOTFILES)/macos/defaults.sh

ssh-info: ## Display SSH key information and status
	@bash $(DOTFILES)/scripts/ssh-info.sh

gpg-info: ## Display GPG key information and Git signing config
	@bash $(DOTFILES)/scripts/gpg-info.sh

ssh-setup: ## Generate SSH keys for current profile
	@bash $(DOTFILES)/templates/ssh/generate-keys.sh

gpg-setup: ## Generate GPG key and configure Git signing
	@bash $(DOTFILES)/templates/gpg/generate-keys.sh

migrate-ssh: ## Migrate existing SSH keys to new naming
	@bash $(DOTFILES)/scripts/migrate-ssh-keys.sh

backup: ## Backup current dotfiles before modifications
	@bash $(DOTFILES)/scripts/backup-dotfiles.sh

restore: ## Restore from latest backup
	@bash $(DOTFILES)/scripts/restore-backup.sh

brew-sync: ## Sync manually installed packages to Brewfiles
	@bash $(DOTFILES)/scripts/sync-brew.sh

brew-audit: ## Audit Brewfiles for missing or undeclared packages
	@bash $(DOTFILES)/scripts/brew-audit.sh

validate-repos: ## Check repos are safe to migrate
	@bash $(DOTFILES)/scripts/validate-repos.sh

migrate-dev-dryrun: ## Preview Developer migration
	@bash $(DOTFILES)/scripts/migrate-developer-structure.sh --dry-run

migrate-dev: ## Migrate ~/Developer to new structure
	@bash $(DOTFILES)/scripts/migrate-developer-structure.sh

complete-migration: ## Complete the Developer directory migration
	@bash $(DOTFILES)/scripts/migrate-developer-structure.sh --complete

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
	@bash $(DOTFILES)/scripts/doctor.sh

doctor-quick: ## Run quick health check (skip optional checks)
	@bash $(DOTFILES)/scripts/doctor.sh --quick

update-repos: ## Update all git repositories in ~/Developer
	@bash $(DOTFILES)/scripts/update-repos.sh

hooks: ## Install git hooks for code quality checks
	@bash $(DOTFILES)/git-hooks/install-hooks.sh

profile-shell: ## Profile shell startup performance
	@bash $(DOTFILES)/scripts/profile-shell.sh && echo "" && bash $(DOTFILES)/scripts/profile-shell.sh --analyze

format: ## Format all files according to EditorConfig
	@bash $(DOTFILES)/scripts/format-all.sh

vscode-setup: ## Install VS Code extensions from extensions.txt
	@echo "Installing VS Code extensions..."
	@cat "$(DOTFILES)/stow/vscode/Library/Application Support/Code/User/extensions.txt" | \
		grep -v '^#' | grep -v '^$$' | cut -d' ' -f1 | \
		xargs -L 1 code --install-extension
	@echo "✓ Extensions installed"

backup-setup: ## Setup automated daily backups via LaunchD
	@bash $(DOTFILES)/scripts/setup-automation.sh backup

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
	@bash $(DOTFILES)/scripts/setup-automation.sh doctor

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

check-scripts: ## Run syntax and shellcheck on all scripts
	@echo "Checking shell script syntax..."
	@find $(DOTFILES)/scripts -type f -name "*.sh" -print0 | xargs -0 bash -n
	@echo "Running shellcheck..."
	@find $(DOTFILES)/scripts -type f -name "*.sh" -print0 | xargs -0 shellcheck
	@echo "✓ Script checks passed"

test-scripts: ## Run lightweight script behavior tests
	@bash $(DOTFILES)/scripts/tests/smoke-help.sh
	@bash $(DOTFILES)/scripts/tests/test-cli-parsing.sh
	@bash $(DOTFILES)/scripts/tests/test-install-checkpoint.sh
	@echo "✓ Script tests passed"

maint-check: check-scripts test-scripts ## Run all maintenance validation checks

maint-sync: update brew-sync brew-audit update-repos ## Run maintenance sync/update workflow

maint-automation: backup-setup doctor-setup ## Setup all built-in automations

maint: maint-check ## Run maintenance validation checks

maint-full: maint-check maint-sync ## Run checks plus sync/update maintenance workflow
