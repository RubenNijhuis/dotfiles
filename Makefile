.PHONY: install update stow unstow macos help

DOTFILES := $(shell pwd)

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Full install (bootstrap + brew + stow + macos)
	@bash $(DOTFILES)/install.sh

update: ## Update brew packages and re-stow configs
	@bash $(DOTFILES)/scripts/update.sh

stow: ## Stow all config packages
	@bash $(DOTFILES)/scripts/stow-all.sh

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

validate-repos: ## Check repos are safe to migrate
	@bash $(DOTFILES)/scripts/validate-repos.sh

migrate-dev-dryrun: ## Preview Developer migration
	@bash $(DOTFILES)/scripts/migrate-developer-structure.sh --dry-run

migrate-dev: ## Migrate ~/Developer to new structure
	@bash $(DOTFILES)/scripts/migrate-developer-structure.sh

complete-migration: ## Complete the Developer directory migration
	@bash $(DOTFILES)/scripts/complete-migration.sh

openclaw-setup: ## Configure OpenClaw after stowing (requires phone number)
	@bash $(DOTFILES)/templates/openclaw/setup-openclaw.sh

openclaw-info: ## Display OpenClaw status and configuration
	@echo "OpenClaw Status:"
	@openclaw models status 2>/dev/null || echo "  Not configured or not running"
	@echo ""
	@echo "Gateway:"
	@launchctl list | grep openclaw || echo "  Gateway not loaded"
	@echo ""
	@echo "Reminders:"
	@openclaw cron list 2>/dev/null || echo "  No reminders"

doctor: ## Run comprehensive system health check
	@bash $(DOTFILES)/scripts/doctor.sh

doctor-quick: ## Run quick health check (skip optional checks)
	@bash $(DOTFILES)/scripts/doctor.sh --quick
