# EuroScalper — Parity Repo

**Generated:** 2025-09-01T00:32:46Z

This repository is organized for a clean parity rewrite of the EuroScalper EA. It separates **source**, **docs**, **tests**, and **deployment**. Use the deploy scripts to copy only build artifacts into your MT4 Data Folder.

## Top-level layout
- `docs/` — Product requirements (PRD), analysis pack, and architecture notes.
- `src/` — EA sources: `baseline/` (original/decompiled, read-only) and `rewrite/` (new clean EA). Shared logging lives under `src/include/logging/`.
- `tests/` — Parity scenarios, log schema, and (optionally) expected logs.
- `tools/deploy/` — Scripts to copy compiled `.ex4` (and optionally `.mq4`) into your MT4 Data Folder.
- `config/` — Paths and local config (never commit secrets).

## Where to host the Git repo
Prefer keeping the Git repo **outside** the MT4 Data Folder. Deploy builds into MT4 via `tools/deploy` scripts or symlinks:
- **Pros:** cleaner Git history, no platform noise (logs, history, cache), easier multi-terminal support.
- **Cons:** one extra copy step.

If you insist on placing the repo **inside** the MT4 Data Folder, use `/.gitignore.in-data-folder` and rename it to `/.gitignore`. This will aggressively ignore logs, history, caches, and `.ex4` outputs.

See `docs/analysis/README.md` for how to integrate the analysis pack.
