# Shell Performance Optimization

Documentation for shell startup performance improvements.

## Current Performance

**Optimized startup time target:** ~40-60ms on Starship (measured with `time zsh -i -c exit`)

### Before Optimization
- **Total:** ~250ms
- **compinit:** 239ms (95% of time)
- **compdef calls:** 57ms
- **compdump:** 50ms

### After Optimization
- **Total:** ~50ms (**5x faster**)
- **compinit:** 10ms (cached)
- All other operations combined: 40ms

## Optimizations Applied

### 1. Completion System Caching
**Problem:** `compinit` runs on every shell startup, regenerating completion cache.

**Solution:** Only regenerate cache once per 20 hours
```zsh
autoload -Uz compinit
setopt EXTENDEDGLOB
local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n ${zcompdump}(#qNmh-20) ]]; then
  # Cached: use existing dump
  compinit -C -d "$zcompdump"
else
  # Expired: regenerate dump
  compinit -d "$zcompdump"
fi
unsetopt EXTENDEDGLOB
```

**Impact:** Reduced compinit from 239ms to 10ms

### 2. Cache Homebrew Prefix
**Problem:** `$(brew --prefix)` spawns a subprocess on every startup.

**Solution:** Cache the prefix in a variable
```zsh
export HOMEBREW_PREFIX="${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}"
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
```

**Impact:** Saves ~20-30ms per call (3 calls = 60-90ms saved)

### 3. Background Load Syntax Highlighting
**Problem:** Syntax highlighting loads synchronously but isn't critical for startup.

**Solution:** Load in background job
```zsh
{
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
} &!
```

**Impact:** Removes ~20ms from critical path

### 4. Lazy-Load fnm and zoxide
**Problem:** `fnm env` and `zoxide init` run eagerly on every startup even when not needed in that session.

**Solution:** Stub the commands and defer real init until first use
```zsh
_zsh_lazy_load_fnm() {
  unfunction fnm node npm npx corepack 2>/dev/null
  _zsh_eval_cache fnm env --use-on-cd --shell zsh
}
for cmd in fnm node npm npx corepack; do
  eval "${cmd}() { _zsh_lazy_load_fnm; ${cmd} \"\$@\" }"
done
```

**Impact:** Removes ~30-50ms from startup when node/zoxide not used in that session. First-use delay is negligible (cache hit via `_zsh_eval_cache`).

### 5. Starship Prompt
**Goal:** Keep prompt rendering fast and stable with a single backend.

```zsh
eval "$(starship init zsh)"
```

## Profiling Tools

### Profile Current Shell
```bash
bash health/profile-shell.sh --full
```

This generates timing data and measures actual startup time.

### Analyze Profile Data
```bash
bash health/profile-shell.sh --full
```

Shows breakdown of where time is spent during startup.

### Manual Profiling
Add to top of `.zshrc`:
```zsh
zmodload zsh/zprof
```

Add to bottom:
```zsh
zprof
```

## Future Optimizations

### Parallel Loading
Could load multiple slow operations in parallel:
```zsh
{
  eval "$(fnm env)"
} &
{
  eval "$(zoxide init zsh)"
} &
wait
```

**Trade-off:** Complex, may cause race conditions with prompt.

## Best Practices

1. **Profile regularly** - Performance degrades over time as plugins accumulate
2. **Cache when possible** - Avoid subprocess calls during startup
3. **Defer non-critical loads** - Not everything needs to load immediately
4. **Measure impact** - Always profile before and after changes

## Benchmarking

### Quick Test
```bash
time zsh -i -c exit
```

### Detailed Profiling
```bash
zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof'
```

### Comparison
```bash
# Starship
for i in {1..10}; do time zsh -i -c exit; done 2>&1 | grep real
```

## Cache Management

### Clear Completion Cache
```bash
rm -f ~/.zcompdump*
# Completions will regenerate on next shell start
```

### Force Regeneration
```bash
autoload -Uz compinit
compinit -f
```

## Troubleshooting

### Completions Not Working
If completions stop working after optimization:
```bash
# Clear cache
rm -f ~/.zcompdump*

# Open new shell (will regenerate)
zsh
```

### Syntax Highlighting Not Loading
Background loading may fail if there are errors. Check manually:
```bash
source "${DOTFILES_HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
```

### Slow Startup After System Update
Homebrew prefix may have changed. Update `HOMEBREW_PREFIX` in `.zshrc`:
```bash
brew --prefix  # Check actual path
```

### Starship Warning Under TERM=dumb
If your command runner sets `TERM=dumb`, Starship may print a warning in non-interactive checks.
This does not affect normal Ghostty sessions (`TERM=xterm-256color`).
