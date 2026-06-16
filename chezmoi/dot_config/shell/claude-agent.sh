# shellcheck shell=bash  # closest to zsh; shellcheck has no zsh mode
# Celebratix Claude agent launcher
# Detects the current repo and starts Claude with the matching agent role.

# Base flags applied to all agent launches.
# Change this single line to toggle permissions, add --model, etc.
CLAUDE_AGENT_FLAGS=(--dangerously-skip-permissions)

# Repo-to-agent mapping loaded from a simple config file if it exists,
# otherwise falls back to the built-in map.
# Config format: one "repo-name=agent-name" per line.
_CLAUDE_AGENT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/claude-agents.conf"

_claude_agent_map() {
  local repo="$1"

  # Try config file first (allows adding repos without editing shell config)
  if [[ -f "$_CLAUDE_AGENT_CONFIG" ]]; then
    local match
    match=$(grep -m1 "^${repo}=" "$_CLAUDE_AGENT_CONFIG" 2>/dev/null)
    if [[ -n "$match" ]]; then
      echo "${match#*=}"
      return
    fi
  fi

  # Built-in defaults
  case "$repo" in
    celebratix-backend)       echo "backend-developer" ;;
    celebratix-dashboard)     echo "frontend-developer" ;;
    celebratix-widget)        echo "frontend-developer" ;;
    celebratix-b2c-app)       echo "frontend-mobile-developer" ;;
    celebratix-insights-app)  echo "frontend-mobile-developer" ;;
    celebratix-ctm)           echo "backend-developer" ;;
    celebratix-jpi)           echo "backend-developer" ;;
    celebratix-img)           echo "backend-developer" ;;
    celebratix-assistant)     echo "backend-developer" ;;
    celebratix-crm)           echo "backend-developer" ;;
    celebratix-infra)         echo "architect" ;;
    celebratix-queue-worker)  echo "backend-developer" ;;
    *)                        return 1 ;;
  esac
}

# Resolve the repo name from the git root directory
_claude_repo_name() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  basename "$root"
}

# Core launcher -- used by all functions below
_claude_run() {
  local agent="$1"; shift
  local args=("${CLAUDE_AGENT_FLAGS[@]}")

  if [[ -n "$agent" ]]; then
    args+=(--agent "$agent")
  fi

  if [[ $# -gt 0 ]]; then
    claude "${args[@]}" "$*"
  else
    claude "${args[@]}"
  fi
}

# Main launcher: auto-detect agent from repo, pass through any initial message
claudex() {
  local repo agent
  repo=$(_claude_repo_name)
  if [[ -n "$repo" ]]; then
    agent=$(_claude_agent_map "$repo")
  fi
  _claude_run "$agent" "$@"
}

# Named functions for explicit agent selection (work from any directory)
claude-ba()        { _claude_run ba "$@"; }
claude-architect() { _claude_run architect "$@"; }
claude-backend()   { _claude_run backend-developer "$@"; }
claude-frontend()  { _claude_run frontend-developer "$@"; }
claude-mobile()    { _claude_run frontend-mobile-developer "$@"; }
claude-review-be() { _claude_run backend-reviewer "$@"; }
claude-review-fe() { _claude_run frontend-reviewer "$@"; }
claude-design()    { _claude_run design-system-engineer "$@"; }
