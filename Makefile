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
