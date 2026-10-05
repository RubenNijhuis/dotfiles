#!/usr/bin/env bash
# Exercise the hook in an isolated repository, never the real index or keys.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/output.sh" "$@"
source "$ROOT_DIR/lib/test-helpers.sh"

fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
mkdir -p "$fixture/lib" "$fixture/bin"
cp "$ROOT_DIR/lib/output.sh" "$fixture/lib/output.sh"
git -C "$fixture" init --quiet
git -C "$fixture" config user.name Fixture
git -C "$fixture" config user.email fixture@example.invalid
git -C "$fixture" config commit.gpgsign false
git -C "$fixture" config core.hooksPath /dev/null

# An old placeholder can be removed, but an added assignment still blocks.
printf '%s%s\n' 'api_' 'key=placeholder' > "$fixture/old.txt"
git -C "$fixture" add old.txt
git -C "$fixture" commit --quiet -m fixture
printf 'retired\n' > "$fixture/old.txt"
git -C "$fixture" add old.txt
cd "$fixture"
assert_exit "removed-placeholder-allowed" 0 bash "$ROOT_DIR/hooks/pre-commit"
printf '%s%s\n' 'api_' 'key=placeholder' > added.txt
git add added.txt
assert_exit "added-placeholder-blocked" 1 bash "$ROOT_DIR/hooks/pre-commit"
printf 'safe\n' > added.txt
git add added.txt

# A formatter that fails both validation and repair must block, not restage.
printf '#!/usr/bin/env bash\nexit 7\n' > bin/biome
chmod +x bin/biome
printf '{}\n' > fixture.json
git add fixture.json
assert_exit "formatter-failure-blocked" 1 env PATH="$fixture/bin:$PATH" bash "$ROOT_DIR/hooks/pre-commit"

test_summary "git-hooks"
