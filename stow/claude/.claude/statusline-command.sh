#!/usr/bin/env bash
# Claude Code status line — Tokyo Night + emojis, compact
input=$(cat)

# -- Tokyo Night palette --
SKY=$'\033[38;2;122;162;247m'
LAV=$'\033[38;2;187;154;247m'
GRN=$'\033[38;2;158;206;106m'
AMB=$'\033[38;2;224;175;104m'
RED=$'\033[38;2;247;118;142m'
MUT=$'\033[38;2;86;95;137m'
RST=$'\033[0m'
S="${MUT}│${RST}"

# -- Parse JSON --
eval "$(echo "$input" | jq -r '
  @sh "cwd=\(.workspace.current_dir // .cwd // "")",
  @sh "used_pct=\(.context_window.used_percentage // "")",
  @sh "lines_add=\(.cost.total_lines_added // "")",
  @sh "lines_rm=\(.cost.total_lines_removed // "")",
  @sh "model_name=\(.model.display_name // "")",
  @sh "agent_name=\(.agent.name // "")",
  @sh "wt_name=\(.worktree.name // "")",
  @sh "cost_usd=\(.cost.total_cost_usd // "")",
  @sh "duration_ms=\(.cost.total_duration_ms // "")"
')"

# -- Directory: basename only --
dir=""
[[ -n "$cwd" ]] && dir="${cwd##*/}"

# -- Git --
git_seg=""
if [[ -n "$cwd" ]] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    porcelain=$(git -C "$cwd" status --porcelain 2>/dev/null)
    staged=0 modified=0 untracked=0
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      x=${line:0:1} y=${line:1:1}
      [[ "$x" == "?" ]] && (( untracked++ )) && continue
      [[ "$x" != " " && "$x" != "?" ]] && (( staged++ ))
      [[ "$y" != " " && "$y" != "?" ]] && (( modified++ ))
    done <<< "$porcelain"

    st=""
    (( staged > 0 ))    && st="${st}${GRN}+${staged}"
    (( modified > 0 ))  && st="${st}${AMB}~${modified}"
    (( untracked > 0 )) && st="${st}${RED}?${untracked}"

    git_seg="🌿 ${LAV}${branch}${RST}"
    [[ -n "$st" ]] && git_seg="${git_seg} ${MUT}[${RST}${st}${MUT}]${RST}"
  fi
fi

# -- Lines changed (inline, no emoji) --
lines_seg=""
if [[ -n "$lines_add" && "$lines_add" != "0" ]] || [[ -n "$lines_rm" && "$lines_rm" != "0" ]]; then
  [[ -n "$lines_add" && "$lines_add" != "0" ]] && lines_seg="${GRN}+${lines_add}${RST}"
  [[ -n "$lines_rm" && "$lines_rm" != "0" ]] && lines_seg="${lines_seg}${RED}-${lines_rm}${RST}"
  lines_seg="✏️ ${lines_seg}"
fi

# -- Active: agent or worktree --
active=""
if [[ -n "$agent_name" ]]; then
  active="🕹️ ${AMB}${agent_name}${RST}"
elif [[ -n "$wt_name" ]]; then
  active="🌳 ${AMB}${wt_name}${RST}"
fi

# -- Cost --
cost=""
if [[ -n "$cost_usd" && "$cost_usd" != "0" ]]; then
  cost="💰 ${MUT}\$$(printf '%.2f' "$cost_usd")${RST}"
fi

# -- Duration --
dur=""
if [[ -n "$duration_ms" && "$duration_ms" != "0" ]]; then
  secs=$(( duration_ms / 1000 ))
  if (( secs >= 60 )); then
    dur="⏱️ ${MUT}$(( secs / 60 ))m$(( secs % 60 ))s${RST}"
  else
    dur="⏱️ ${MUT}${secs}s${RST}"
  fi
fi

# -- Context bar (6 chars) --
ctx=""
if [[ -n "$used_pct" ]]; then
  pct=${used_pct%.*}
  (( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
  filled=$(( pct * 6 / 100 )); empty=$(( 6 - filled ))
  if (( pct >= 90 )); then bar_c="$RED"; icon="🔴"
  elif (( pct >= 70 )); then bar_c="$AMB"; icon="🟡"
  else bar_c="$GRN"; icon="🟢"; fi
  bar="${bar_c}"; for (( i=0; i<filled; i++ )); do bar+="█"; done
  bar+="${MUT}"; for (( i=0; i<empty; i++ )); do bar+="░"; done
  ctx="${icon} ${bar}${RST} ${bar_c}${pct}%${RST}"
fi

# -- Line 1: agent/worktree | git | lines | dir --
p1=()
[[ -n "$active" ]]     && p1+=("$active")
[[ -n "$git_seg" ]]    && p1+=("$git_seg")
[[ -n "$lines_seg" ]]  && p1+=("$lines_seg")
[[ -n "$dir" ]]        && p1+=("📂 ${SKY}${dir}${RST}")

line1=""
for (( i=0; i<${#p1[@]}; i++ )); do
  (( i > 0 )) && line1+=" $S "
  line1+="${p1[$i]}"
done

# -- Line 2: context | cost | duration | model --
p2=()
[[ -n "$ctx" ]]        && p2+=("$ctx")
[[ -n "$cost" ]]       && p2+=("$cost")
[[ -n "$dur" ]]        && p2+=("$dur")
[[ -n "$model_name" ]] && p2+=("🤖 ${SKY}${model_name}${RST}")

line2=""
for (( i=0; i<${#p2[@]}; i++ )); do
  (( i > 0 )) && line2+=" $S "
  line2+="${p2[$i]}"
done

if [[ -n "$line2" ]]; then
  printf '%b\n%b' "$line1" "$line2"
else
  printf '%b' "$line1"
fi
