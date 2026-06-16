#!/usr/bin/env bash
# Loader for ops/automation/agents.manifest — single source of truth
# for launchd agent registration. Source this file; do not execute.
#
# Provides:
#   automation_agent_lines           — all manifest rows as "name|description"
#   automation_default_profile_names — names with in_default_profile=yes
#   automation_resolve_alias <input> — echoes canonical name (or input)
#   automation_setup_targets         — all valid setup-automation.sh targets (names + aliases)

# Resolve manifest path relative to this lib file's parent dir.
_automation_manifest_path() {
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  printf '%s/ops/automation/agents.manifest\n' "$(cd "$lib_dir/.." && pwd)"
}

_automation_read_manifest() {
  local path
  path="$(_automation_manifest_path)"
  [[ -f "$path" ]] || { printf 'automation-registry: manifest not found at %s\n' "$path" >&2; return 1; }
  awk -F'|' '
    /^[[:space:]]*$/ {next}
    /^[[:space:]]*#/ {next}
    {print}
  ' "$path"
}

automation_agent_lines() {
  _automation_read_manifest | awk -F'|' '{printf "%s|%s\n", $1, $2}'
}

automation_default_profile_names() {
  _automation_read_manifest | awk -F'|' '$3 == "yes" {print $1}'
}

automation_resolve_alias() {
  local input="$1" name alias
  while IFS='|' read -r name _desc _default alias; do
    [[ -z "$name" ]] && continue
    if [[ -n "$alias" && "$alias" == "$input" ]]; then
      printf '%s\n' "$name"
      return 0
    fi
  done < <(_automation_read_manifest)
  printf '%s\n' "$input"
}

automation_setup_targets() {
  local name alias
  while IFS='|' read -r name _desc _default alias; do
    [[ -z "$name" ]] && continue
    printf '%s\n' "$name"
    [[ -n "$alias" ]] && printf '%s\n' "$alias"
  done < <(_automation_read_manifest)
}
