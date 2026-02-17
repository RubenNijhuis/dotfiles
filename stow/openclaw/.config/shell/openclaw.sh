# shellcheck shell=bash disable=SC1090
# OpenClaw Configuration
# Sourced by ~/.zshrc

# Completions
if [ -f ~/.openclaw/completions/openclaw.zsh ]; then
  source ~/.openclaw/completions/openclaw.zsh
fi

# Environment
export OPENCLAW_HOME="$HOME/.openclaw"

# Aliases
alias oc='openclaw'
alias ocagent='openclaw agent'
alias ocmsg='openclaw message send --channel whatsapp --target'
alias ocremind='~/.openclaw/workspace/reminder-helper.sh'
alias occron='openclaw cron list'
alias ocstatus='openclaw models status && openclaw doctor'

# Quick reminder function
remind() {
  if [ $# -lt 2 ]; then
    echo "Usage: remind <time> <message>"
    echo "Examples: remind 16:00 'Check cables' | remind +30m 'Take break'"
    return 1
  fi
  ~/.openclaw/workspace/reminder-helper.sh "$1" "$2"
}
