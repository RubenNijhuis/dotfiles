.PHONY: help install update ssh-setup gpg-setup gpg-check \
	backup brew-audit app-audit \
	doctor spicetify-status spicetify-apply spicetify-restore \
	hooks format vscode-setup keychain-check automation-setup \
	lint-shell test-scripts maint-check bootstrap-verify \
	automation-list launchd-install-all launchd-uninstall-all launchd-status \
	clean restore launchd-check \
	help-setup help-brew help-launchd help-test cheat \
	profile-list profile-show profile-set nix-check nix-check-all nix-build nix-switch nix-home-switch \
	nix-fmt nix-adopt files-init

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

install: ## Install the Nix-first macOS configuration
	@bash $(DOTFILES)/install.sh

update: ## Refresh Nix inputs and verify the configuration
	@bash $(DOTFILES)/ops/update.sh $(ARGS)

# ── Health & Status ──────────────────────────────────────────────────

doctor: ## Quick health + automation dashboard (use --full for deep checks)
	@bash $(DOTFILES)/health/doctor.sh $(ARGS)

app-audit: ## Read installed app versions and detect duplicate bundles (ARGS=--check)
	@bash $(DOTFILES)/ops/app-audit.sh $(ARGS)

# ── Setup (one-time) ────────────────────────────────────────────────

ssh-setup: ## Generate SSH keys
	@bash $(DOTFILES)/setup/generate-ssh-keys.sh

gpg-setup: ## Generate GPG key and configure Git signing
	@bash $(DOTFILES)/setup/generate-gpg-keys.sh

gpg-check: ## Test GPG signing/encryption in a disposable keyring (never real keys)
	@bash $(DOTFILES)/tests/test-gpg-roundtrip.sh

vscode-setup: ## Install VS Code extensions from extensions.txt
	@bash $(DOTFILES)/setup/vscode-setup.sh $(ARGS)

hooks: ## Enable the repository's native Git hooks
	@git -C $(DOTFILES) config core.hooksPath hooks
	@find $(DOTFILES)/hooks -type f -exec chmod +x {} +

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

files-init: ## Create the portable personal file structure (never moves files)
	@bash $(DOTFILES)/setup/create-files-root.sh

# ── Backup ───────────────────────────────────────────────────────────

backup: ## Backup current dotfiles before modifications
	@bash $(DOTFILES)/ops/backup-dotfiles.sh

restore: ## Restore from latest backup
	@bash $(DOTFILES)/ops/restore-backup.sh

# ── Brew ─────────────────────────────────────────────────────────────

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

maint-check: ## Run maintenance validation checks in parallel
	@bash $(DOTFILES)/ops/maint-check.sh

# ── Nix (cross-platform foundation) ─────────────────────────────────

NIX_DARWIN_HOST ?= Rubens-MacBook-Pro
NIX ?= $(or $(shell command -v nix 2>/dev/null),/nix/var/nix/profiles/default/bin/nix)
PROFILE ?=
NIX_HOME_HOST ?=

nix-check: ## Evaluate the cross-platform Nix flake
	@$(NIX) flake check --no-build

nix-check-all: ## Evaluate the Nix flake on every declared platform
	@$(NIX) flake check --all-systems --no-build

nix-build: ## Build the current macOS Nix configuration without switching
	@$(NIX) build .#darwinConfigurations.$(NIX_DARWIN_HOST).system --no-link

nix-fmt: ## Format the Nix source using the pinned formatter
	@$(NIX) fmt

nix-adopt: ## Back up one named configuration profile before its Nix handoff
	@bash $(DOTFILES)/setup/adopt-nix-configs.sh "$(PROFILE)" $(ARGS)

nix-switch: ## Apply the current macOS Nix configuration
	@rebuild=$$($(NIX) build .#darwinConfigurations.$(NIX_DARWIN_HOST).config.system.build.darwin-rebuild --no-link --print-out-paths --no-write-lock-file) && \
		sudo -H "$$rebuild/bin/darwin-rebuild" switch --flake .#$(NIX_DARWIN_HOST) --no-write-lock-file

nix-home-switch: ## Apply a Linux/WSL Home Manager target (NIX_HOME_HOST=<name>)
	@test -n "$(NIX_HOME_HOST)" || { echo "Usage: make nix-home-switch NIX_HOME_HOST=rubennijhuis-windows-wsl" >&2; exit 2; }
	@home-manager switch --flake .#$(NIX_HOME_HOST)

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
