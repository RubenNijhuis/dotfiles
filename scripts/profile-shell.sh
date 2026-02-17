#!/usr/bin/env bash
# Profile zsh startup time to identify bottlenecks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/output.sh" "$@"

ANALYZE=false

usage() {
  cat <<EOF2
Usage: $0 [--help] [--no-color] [--analyze]

Without flags, generates shell profile data.
With --analyze, reads /tmp/zsh-profile.log and prints analysis.
EOF2
}

parse_args() {
  show_help_if_requested usage "$@"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --analyze)
        ANALYZE=true
        shift
        ;;
      --no-color)
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

analyze_profile() {
  if [[ ! -f /tmp/zsh-profile.log ]]; then
    print_error "No profile data found"
    print_info "Run without --analyze flag first to generate profile data"
    exit 1
  fi

  print_section "Top 10 Slowest Operations:"
  printf '\n'

  awk '/^[[:space:]]*[0-9]+\)/ {
    calls = $2
    time = $3
    percent = $6
    name = ""
    for(i=8; i<=NF; i++) name = name $i " "
    printf "  %.0fms\t%s\t%s\n", time, percent, name
  }' /tmp/zsh-profile.log | head -10 | while IFS=$'\t' read -r time percent name; do
    local time_num
    time_num=$(echo "$time" | sed 's/ms//')
    if [[ $time_num -gt 50 ]]; then
      printf "  "
      print_error "${time} (${percent}) - $name"
    elif [[ $time_num -gt 20 ]]; then
      printf "  "
      print_warning "${time} (${percent}) - $name"
    else
      printf "  "
      print_dim "${time} (${percent}) - $name"
    fi
  done

  printf '\n'
  print_section "Analysis:"

  local compinit_time
  compinit_time=$(awk '/compinit/ {print $3; exit}' /tmp/zsh-profile.log)
  if [[ -n "$compinit_time" ]] && (( $(echo "$compinit_time > 100" | bc -l) )); then
    print_error "compinit is slow (${compinit_time}ms)"
    print_bullet "Solution: Cache compinit to run once per day"
  fi

  print_info "eval() calls are not shown in zprof but can be slow"
  print_bullet "fnm env, zoxide init, fzf --zsh all use eval()"
  print_bullet "Solution: Cache eval outputs or lazy-load"

  printf '\n'
  print_section "Recommendations:"
  print_bullet "1. Cache compinit (run once per day instead of every session)"
  print_bullet "2. Cache brew --prefix calls (avoid subprocess on every startup)"
  print_bullet "3. Lazy-load tool completions (defer fnm, zoxide until first use)"
  print_bullet "4. Background load syntax highlighting (non-critical for startup)"

  printf '\n'
  print_info "Profile data: /tmp/zsh-profile.log"
}

generate_profile() {
  print_section "Generating profile data..."
  print_dim "Starting zsh with profiling enabled..."
  printf '\n'

  local start end elapsed_ms
  start=$(date +%s%N)
  zsh -i -c "exit" 2>/dev/null
  end=$(date +%s%N)
  elapsed_ms=$(( (end - start) / 1000000 ))

  printf '  '
  print_key_value "Actual startup time" "${elapsed_ms}ms"
  printf '\n'

  cat > /tmp/.zshrc-profile << 'EOF2'
# Profiling wrapper
zmodload zsh/zprof

# Source the actual zshrc
source ~/.zshrc

# Print profiling results
zprof
EOF2

  zsh -c "source /tmp/.zshrc-profile" > /tmp/zsh-profile.log 2>&1

  if [[ -f /tmp/zsh-profile.log ]]; then
    print_success "Profile data generated"
    print_info "Run with --analyze flag to see detailed breakdown:"
    print_dim "  bash $0 --analyze"
  else
    print_error "Failed to generate profile data"
    rm -f /tmp/.zshrc-profile
    exit 1
  fi

  rm -f /tmp/.zshrc-profile
}

main() {
  parse_args "$@"

  print_header "Shell Startup Performance Analysis"

  if $ANALYZE; then
    analyze_profile
  else
    generate_profile
  fi
}

main "$@"
