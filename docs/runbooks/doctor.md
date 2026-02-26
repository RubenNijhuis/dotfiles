# Runbook: Doctor

## Commands

```bash
make doctor
make doctor-quick
bash scripts/health/doctor.sh --section backup --no-color
```

## Expected Result

- Exit `0`: all checks passed
- Exit `1`: warnings
- Exit `2`: errors

## Triage Flow

1. Run `make doctor-quick` for fast signal.
2. Run failing section directly with `--section`.
3. Apply fixes from `docs/doctor-guide.md`.
4. Re-run `make doctor`.
