#!/usr/bin/env bash
# Read-only checks, not a complete security audit. Never prompt or install updates.

check_security() {
  [[ "$(uname -s)" == Darwin ]] || return 0
  local disabled sockets udp service version major minor patch updates issues=0
  if ! disabled=$(launchctl print-disabled system 2>/dev/null); then
    record_result "Remote access" 1 "Cannot inspect launchd; remote-access state is unverified"
  else
    for service in com.apple.screensharing com.openssh.sshd; do
      if ! grep -F "\"$service\" => disabled" <<< "$disabled" >/dev/null; then
        issues=$((issues + 1))
      fi
    done
    # A stopped daemon can still have a listening socket owned by root launchd.
    if sockets=$(netstat -an -p tcp 2>/dev/null) && udp=$(netstat -an -p udp 2>/dev/null); then
      if awk '$6 == "LISTEN" && $4 ~ /[.:](22|5900|3283)$/ {found=1} END {exit !found}' <<< "$sockets" ||
        awk '$4 ~ /[.:](5900|3283)$/ {found=1} END {exit !found}' <<< "$udp"; then
        issues=$((issues + 1))
      fi
      if [[ "$issues" == 0 ]]; then
        record_result "Remote access" 0 "Screen Sharing and SSH disabled; no TCP 22/5900/3283 or UDP 5900/3283 listeners"
      else
        record_result "Remote access" 2 "Remote-access service enabled or remote-access port listening"
        add_suggestion "Review General > Sharing (including Remote Management), then apply make nix-switch"
      fi
    else
      record_result "Remote access" 1 "Cannot inspect network sockets; port closure is unverified ($issues service-policy issues)"
    fi
  fi

  if ! version=$(sw_vers -productVersion 2>/dev/null); then
    record_result "macOS updates" 1 "Installed version unavailable"
    return 0
  fi
  IFS=. read -r major minor patch <<< "$version"
  # Known Tahoe Screen Sharing fix, CVE-2026-65400 (Apple advisory 148170).
  # This minimum is not a claim that later releases have no outstanding fixes.
  if [[ "$major" == 26 ]] && (( minor < 6 || (minor == 6 && ${patch:-0} < 1) )); then
    record_result "macOS updates" 2 "macOS $version predates the Screen Sharing fix in 26.6.1"
    add_suggestion "Install the current macOS security update in General > Software Update and restart"
    return 0
  fi
  # Use Apple's cached catalog to keep routine doctor runs offline and fast.
  # Ignore optional major upgrades and Safari's independent version number.
  if updates=$(plutil -extract RecommendedUpdates json -o - /Library/Preferences/com.apple.SoftwareUpdate.plist 2>/dev/null) &&
    updates=$(jq -r --arg version "$version" '
      .[] | select(."Display Name" | startswith("macOS")) |
      ."Display Version" |
      select((split(".")[0] == ($version | split(".")[0])) and
        ((split(".") | map(tonumber)) > ($version | split(".") | map(tonumber))))
    ' <<< "$updates" 2>/dev/null); then
    if [[ -n "$updates" ]]; then
      record_result "macOS updates" 1 "Installed $version; Apple cached catalog offers $updates (not a live scan)"
      add_suggestion "Check General > Software Update and install pending security updates"
    else
      record_result "macOS updates" 0 "Installed $version; no newer same-major macOS in cached catalog (not a live scan or security audit)"
    fi
  else
    record_result "macOS updates" 1 "Installed $version; update catalog unavailable, check Software Update manually"
  fi
}
