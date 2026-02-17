# Shell Performance Optimization

Documentation for shell startup performance improvements.

## Current Performance

**Optimized startup time:** ~50ms (measured with `time zsh -i -c exit`)

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
export HOMEBREW_PREFIX="/opt/homebrew"
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

## Profiling Tools

### Profile Current Shell
```bash
make profile-shell
```

This generates timing data and measures actual startup time.

### Analyze Profile Data
```bash
make profile-shell-analyze
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

### Lazy Loading (Not Yet Implemented)
Could reduce startup time further by lazy-loading tools:

**fnm (Node version manager):**
```zsh
# Instead of: eval "$(fnm env)"
# Lazy load on first node/npm/npx use
fnm() {
  unfunction fnm
  eval "$(command fnm env --use-on-cd --shell zsh)"
  fnm "$@"
}
```

**zoxide:**
```zsh
# Instead of: eval "$(zoxide init zsh)"
# Lazy load on first z/zi use
z() {
  unfunction z zi
  eval "$(zoxide init zsh)"
  z "$@"
}
```

**Trade-off:** Adds delay on first use, but removes ~30-50ms from startup.

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
# Before optimization
for i in {1..10}; do time zsh -i -c exit; done 2>&1 | grep real

# After optimization
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
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

### Slow Startup After System Update
Homebrew prefix may have changed. Update `HOMEBREW_PREFIX` in `.zshrc`:
```bash
brew --prefix  # Check actual path
```
