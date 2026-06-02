#!/usr/bin/env bash
# One-page personal cheatsheet — the tools you have but might forget to use.
# Print with `make cheat` or `dotc` from anywhere.
set -euo pipefail

bold()  { printf "\033[1m%s\033[0m" "$1"; }
dim()   { printf "\033[2m%s\033[0m" "$1"; }
cyan()  { printf "\033[36m%s\033[0m" "$1"; }
green() { printf "\033[32m%s\033[0m" "$1"; }

row() {
  printf "  %-18s  %s\n" "$(cyan "$1")" "$2"
}

section() {
  printf "\n%s\n" "$(bold "$1")"
}

clear
printf "%s  %s\n" "$(bold "Cheatsheet")" "$(dim "— the tools you forget you have")"

section "Shadowed defaults"
row "cd <dir>"        "really runs z — fuzzy directory jump after first visit"
row "du"              "really runs dust — colored, sorted by size"
row "cat"             "really runs bat — syntax highlighted, paged"
row "grep"            "really runs rg — fast, ignores .gitignore"
row "top"             "really runs btop — live resource TUI"
row "vim / vi / v"    "really runs nvim (LazyVim)"

section "Keybindings (zsh)"
row "Ctrl-R"          "atuin — search shell history (per-dir bias)"
row "Ctrl-G"          "lazygit in current repo"
row "Ctrl-O"          "yazi file manager"
row "Ctrl-S"          "sesh — switch tmux session"
row "Ctrl-T"          "fzf — pick a file path into the command line"
row "Alt-C"           "fzf — pick a directory and cd into it"

section "Single-key launchers"
row "y"               "yazi (cd's into exit dir)"
row "s"               "sesh — fzf session picker"
row "lg"              "lazygit"
row "g / gs / gd"     "git / git status / git diff"
row "fe"              "fzf-pick a file, open in \$EDITOR"
row "proj"            "fzf-pick a project under ~/Developer, open in \$EDITOR"

section "Dotfiles shortcuts (from anywhere)"
row "dot"             "cd into ~/dotfiles"
row "dots"            "make status — quick health snapshot"
row "dotd"            "make doctor — full health check"
row "dotu"            "make update — sync repos / brew / runtimes / stow"
row "doth"            "make help"
row "dotc"            "make cheat — this page"

section "Useful but easy to forget"
row "mkcd <dir>"      "mkdir + cd"
row "z -"             "back to previous directory"
row "tldr <cmd>"      "tealdeer — example-driven help"
row "hyperfine <cmd>" "benchmark a command"
row "difft <a> <b>"   "syntax-aware diff"
row "gh dash"         "TUI for GitHub PRs/issues"
row "jj"              "git-compatible VCS — try alongside git"
row "uv"              "Python venv/package/script runner"
row "FORCE=1 clean-*" "override the 20-match safety cap"

section "Conflict / safety"
row "(deny list)"     "rm -*r/-*R, git push --force*, git reset --hard, branch -D"
row "FORCE=1"         "needed to override clean-* 20-match guard"

printf "\n%s %s\n" "$(dim "Edit:")" "$(dim "ops/cheat.sh")"
