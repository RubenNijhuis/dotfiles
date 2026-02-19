#!/usr/bin/env bash
# Migrate repositories from a legacy layout into a structured Developer tree.
# Supports:
#   --dry-run       Preview the planned migration
#   --complete      Interactive categorization mode for existing setups
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/output.sh" "$@"

SOURCE_DIR="$HOME/Developer/repositories"
TARGET_DIR="$HOME/Developer"
RULES_FILE="$ROOT_DIR/local/migration-rules.txt"
DEFAULT_DESTINATION="personal/projects"
DRY_RUN=false
COMPLETE_MODE=false
NON_INTERACTIVE=false
BACKUP_DIR=""

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --dry-run                          Preview planned moves without changing files
  --complete                         Interactive categorization mode for existing setups
  --source <path>                    Source root containing repositories
                                     (default: $HOME/Developer/repositories)
  --target <path>                    Target developer root
                                     (default: $HOME/Developer)
  --rules <path>                     Optional pattern rules file
                                     (default: local/migration-rules.txt if present)
  --default-destination <subpath>    Fallback target subpath for unmapped repos
                                     (default: personal/projects)
  --non-interactive                  Disable prompts (auto/rules only)
  --help                             Show this help message
  --no-color                         Disable color output

Rules file format:
  pattern|destination-subpath

Example:
  # Move all repos in a legacy Work folder under work/projects
  Work/*|work/projects
EOF
}

to_kebab_case() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

is_valid_destination() {
  local destination="$1"
  [[ -n "$destination" ]] || return 1
  [[ "$destination" != /* ]] || return 1
  [[ "$destination" != *".."* ]] || return 1
  [[ "$destination" =~ ^[a-zA-Z0-9._/-]+$ ]] || return 1
}

normalize_path() {
  local path="$1"
  cd "$path" && pwd
}

log_move() {
  local source="$1"
  local target="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    print_indent "Would move: $source -> $target"
  else
    print_indent "Moved: $(basename "$source") -> $target"
  fi
}

move_repo() {
  local source="$1"
  local target="$2"

  if [[ -d "$target" ]]; then
    print_warning "Target already exists, skipping: $target"
    return 1
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_move "$source" "$target"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  mv "$source" "$target"
  log_move "$source" "$target"
  return 0
}

infer_destination() {
  local rel="$1"
  local repo_name="$2"
  local probe
  probe="$(printf '%s/%s' "$rel" "$repo_name" | tr '[:upper:]' '[:lower:]')"

  case "$probe" in
    *experiment*|*sandbox*|*spike*)
      echo "personal/experiments"
      ;;
    *learn*|*course*|*tutorial*|*katas*|*advent*)
      echo "personal/learning"
      ;;
    *work*|*client*|*company*|*corp*|*business*)
      echo "work/projects"
      ;;
    *archive*|*legacy*|*old*)
      echo "archive"
      ;;
    *)
      echo "$DEFAULT_DESTINATION"
      ;;
  esac
}

rule_patterns=()
rule_destinations=()

load_rules() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 0
  fi

  while IFS='|' read -r raw_pattern raw_destination; do
    [[ -n "${raw_pattern// /}" ]] || continue
    [[ "${raw_pattern#\#}" != "$raw_pattern" ]] && continue
    [[ -n "${raw_destination// /}" ]] || continue

    local pattern destination
    pattern="$(echo "$raw_pattern" | sed 's/[[:space:]]*$//')"
    destination="$(echo "$raw_destination" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    if ! is_valid_destination "$destination"; then
      print_error "Invalid destination in rules file: $destination"
      exit 1
    fi

    rule_patterns+=("$pattern")
    rule_destinations+=("$destination")
  done < "$file"

  print_info "Loaded ${#rule_patterns[@]} migration rule(s) from $file"
}

resolve_by_rules() {
  local rel="$1"
  local repo_name="$2"
  local probe
  probe="${rel%/}/$repo_name"

  local i
  for ((i = 0; i < ${#rule_patterns[@]}; i++)); do
    # shellcheck disable=SC2053 # Intentional glob match against user-provided pattern.
    if [[ "$probe" == ${rule_patterns[$i]} ]]; then
      echo "${rule_destinations[$i]}"
      return 0
    fi
  done

  return 1
}

prompt_destination() {
  local rel="$1"
  local repo_name="$2"
  local suggested="$3"
  local choice=""

  print_warning "Unmapped repo: ${rel%/}/$repo_name"
  printf '  Suggested: %s\n' "$suggested"
  echo "  1) personal/projects"
  echo "  2) personal/experiments"
  echo "  3) personal/learning"
  echo "  4) work/projects"
  echo "  5) work/clients"
  echo "  6) archive"
  echo "  7) custom subpath"

  read -rp "Choice [1-7, Enter=suggested]: " choice
  case "${choice:-}" in
    "") echo "$suggested" ;;
    1) echo "personal/projects" ;;
    2) echo "personal/experiments" ;;
    3) echo "personal/learning" ;;
    4) echo "work/projects" ;;
    5) echo "work/clients" ;;
    6) echo "archive" ;;
    7)
      read -rp "Custom subpath (relative to target): " custom
      echo "$custom"
      ;;
    *)
      print_warning "Invalid choice; using suggested destination"
      echo "$suggested"
      ;;
  esac
}

resolve_destination() {
  local rel="$1"
  local repo_name="$2"

  local by_rule=""
  if by_rule="$(resolve_by_rules "$rel" "$repo_name")"; then
    echo "$by_rule"
    return 0
  fi

  local suggested
  suggested="$(infer_destination "$rel" "$repo_name")"

  if [[ "$COMPLETE_MODE" == "true" && "$NON_INTERACTIVE" != "true" ]]; then
    local selected
    selected="$(prompt_destination "$rel" "$repo_name" "$suggested")"
    if ! is_valid_destination "$selected"; then
      print_warning "Invalid destination '$selected'; using suggested '$suggested'"
      echo "$suggested"
      return 0
    fi
    echo "$selected"
    return 0
  fi

  echo "$suggested"
}

create_backup() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return
  fi

  BACKUP_DIR="${SOURCE_DIR%/}-backup-$(date +%Y%m%d-%H%M%S)"
  print_section "Creating migration backup"
  cp -R "$SOURCE_DIR" "$BACKUP_DIR"
  print_success "Backup created: $BACKUP_DIR"
}

prepare_target_layout() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return
  fi

  mkdir -p "$TARGET_DIR/personal/projects"
  mkdir -p "$TARGET_DIR/personal/experiments"
  mkdir -p "$TARGET_DIR/personal/learning"
  mkdir -p "$TARGET_DIR/work/projects"
  mkdir -p "$TARGET_DIR/work/clients"
  mkdir -p "$TARGET_DIR/archive"
}

cleanup_source_if_empty() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return
  fi

  find "$SOURCE_DIR" -type d -empty -delete 2>/dev/null || true
  if [[ -d "$SOURCE_DIR" ]] && [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
    rmdir "$SOURCE_DIR"
    print_success "Removed empty source directory: $SOURCE_DIR"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --complete)
        COMPLETE_MODE=true
        shift
        ;;
      --source)
        SOURCE_DIR="${2:-}"
        [[ -n "$SOURCE_DIR" ]] || { print_error "--source requires a value"; exit 1; }
        shift 2
        ;;
      --target)
        TARGET_DIR="${2:-}"
        [[ -n "$TARGET_DIR" ]] || { print_error "--target requires a value"; exit 1; }
        shift 2
        ;;
      --rules)
        RULES_FILE="${2:-}"
        [[ -n "$RULES_FILE" ]] || { print_error "--rules requires a value"; exit 1; }
        shift 2
        ;;
      --default-destination)
        DEFAULT_DESTINATION="${2:-}"
        [[ -n "$DEFAULT_DESTINATION" ]] || { print_error "--default-destination requires a value"; exit 1; }
        shift 2
        ;;
      --non-interactive)
        NON_INTERACTIVE=true
        shift
        ;;
      --no-color)
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [[ "$DRY_RUN" == "true" && "$COMPLETE_MODE" == "true" ]]; then
    print_error "Cannot combine --dry-run with --complete"
    usage
    exit 1
  fi

  if ! is_valid_destination "$DEFAULT_DESTINATION"; then
    print_error "Invalid --default-destination: $DEFAULT_DESTINATION"
    exit 1
  fi

  if [[ -d "$SOURCE_DIR" ]]; then
    SOURCE_DIR="$(normalize_path "$SOURCE_DIR")"
  fi

  if [[ -d "$TARGET_DIR" ]]; then
    TARGET_DIR="$(normalize_path "$TARGET_DIR")"
  fi
}

run_migration() {
  if [[ ! -d "$SOURCE_DIR" ]]; then
    print_success "No source directory found at $SOURCE_DIR"
    print_info "Nothing to migrate on this machine."
    return 0
  fi

  local repo_count
  repo_count=$(find "$SOURCE_DIR" -type d -name '.git' | wc -l | tr -d ' ')
  if [[ "$repo_count" -eq 0 ]]; then
    print_success "No git repositories found under $SOURCE_DIR"
    return 0
  fi

  print_header "Developer Repository Migration"
  print_key_value "Source" "$SOURCE_DIR"
  print_key_value "Target" "$TARGET_DIR"
  print_key_value "Mode" "$([ "$COMPLETE_MODE" == "true" ] && echo "interactive" || echo "auto")"
  print_key_value "Dry run" "$DRY_RUN"
  print_key_value "Repositories found" "$repo_count"
  echo ""

  load_rules "$RULES_FILE"
  create_backup
  prepare_target_layout

  local moved=0
  local skipped=0
  local failed=0

  while IFS= read -r -d '' gitdir; do
    local source_repo rel repo_name destination target_repo
    source_repo="$(dirname "$gitdir")"
    rel="${source_repo#"$SOURCE_DIR"/}"
    repo_name="$(basename "$source_repo")"

    if [[ "$source_repo" == "$TARGET_DIR"* ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    destination="$(resolve_destination "$rel" "$repo_name")"
    target_repo="$TARGET_DIR/$destination/$(to_kebab_case "$repo_name")"

    if [[ "$source_repo" == "$target_repo" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    if move_repo "$source_repo" "$target_repo"; then
      moved=$((moved + 1))
    else
      failed=$((failed + 1))
    fi
  done < <(find "$SOURCE_DIR" -type d -name '.git' -print0)

  cleanup_source_if_empty

  echo ""
  print_section "Migration Summary"
  print_key_value "Moved" "$moved"
  print_key_value "Skipped" "$skipped"
  print_key_value "Failed" "$failed"

  if [[ "$DRY_RUN" == "true" ]]; then
    print_warning "Dry run complete. Re-run without --dry-run to execute."
  else
    [[ -n "$BACKUP_DIR" ]] && print_key_value "Backup" "$BACKUP_DIR"
    if [[ "$failed" -gt 0 ]]; then
      print_warning "Migration finished with failures. Review warnings above."
      return 1
    fi
    print_success "Migration finished successfully"
  fi
}

main() {
  parse_args "$@"
  run_migration
}

main "$@"
