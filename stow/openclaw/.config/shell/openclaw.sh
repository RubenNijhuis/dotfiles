# shellcheck shell=bash disable=SC1090
# OpenClaw Configuration
# Sourced by ~/.zshrc

# Environment
export OPENCLAW_HOME="${DOTFILES_OPENCLAW_HOME:-$HOME/.openclaw}"

# Completions
if [ -f "$OPENCLAW_HOME/completions/openclaw.zsh" ]; then
  source "$OPENCLAW_HOME/completions/openclaw.zsh"
fi

# Aliases
alias oc='openclaw'
alias ocagent='openclaw agent'
alias ocmsg='openclaw message send --channel whatsapp --target'
alias ocremind='$OPENCLAW_HOME/workspace/reminder-helper.sh'
alias occron='openclaw cron list'
alias ocstatus='openclaw models status && openclaw doctor'

# Quick reminder function
remind() {
  if [ $# -lt 2 ]; then
    echo "Usage: remind <time> <message>"
    echo "Examples: remind 16:00 'Check cables' | remind +30m 'Take break'"
    return 1
  fi
  "$OPENCLAW_HOME/workspace/reminder-helper.sh" "$1" "$2"
}
