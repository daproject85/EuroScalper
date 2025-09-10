# logdiff.py

A focused diff tool to compare your **EuroScalper** Baseline vs Rewrite semicolon logs and surface the **first differing column** per paired line. Built for fast iterative parity work with **ignore lists** so you can silence noise from not-yet-implemented events or volatile columns.

---

## Install / Run

No dependencies required (YAML optional). Place your logs anywhere and run:

```bash
python3 logdiff.py /path/to/Baseline.log /path/to/Rewrite.log
```

If you want YAML config support (optional), install PyYAML: `pip install pyyaml`

---

## Core usage

### 1) In-order comparison (default)

Compare lines **by index** after filtering ignored events. Reports first differing column per line.

```bash
python3 logdiff.py Baseline.log Rewrite.log   --ignore-config sample_ignore.yml   --ignore-events boot,init   --ignore-columns 1,4,20   --float-tol 1e-6   --csv diffs_index.csv
```

### 2) Keyed comparison

Match lines using **key columns** (default `0,6` → timestamp + event). Good when counts differ or you’re ignoring events to restore alignment.

```bash
python3 logdiff.py Baseline.log Rewrite.log   --mode key --key-cols 0,6   --ignore-config sample_ignore.yml   --report-extra   --csv diffs_key.csv
```

- `--report-extra` also lists lines that exist in only one file.
- You can change keys, e.g. `--key-cols 0,2,3,6` (timestamp, symbol, tf, event).

---

## Ignore lists

You can ignore by **event** and/or by **column index** (0-based). Two ways:

1) CLI flags
2) A YAML/JSON config (example below)

Both merge; CLI values extend/override the config.

### sample_ignore.yml

```yaml
ignore_events:
  - boot
  - init
ignore_columns:
  - 1   # build
  - 4   # magic
  - 20  # volatile metric
```

---

## Output

- **Stdout**: quick summary (first 10 diffs)
- **CSV** (if `--csv`): full rows with baseline/rewrite line numbers, event/key, diff column index, and the baseline/rewrite values.

Columns in CSV:
```
baseline_lineno, rewrite_lineno, event, key, diff_col, baseline_value, rewrite_value, note, baseline_raw, rewrite_raw
```

---

## Tips

- Start with `--mode index` while you stabilize event coverage. As soon as the counts drift, switch to `--mode key` with a solid key (timestamp+event is usually enough, add symbol/timeframe if needed).
- Use `--float-tol` to tolerate tiny numeric jitter.
- Silence early noise by listing not-yet-implemented events in `ignore_events`.

---

## Examples

**Quick scan with tolerance and CSV:**

```bash
python3 logdiff.py baseline.csv rewrite.csv --float-tol 1e-5 --csv diffs.csv
```

**Keyed match on timestamp+event+symbol, report extras:**

```bash
python3 logdiff.py baseline.csv rewrite.csv   --mode key --key-cols 0,2,6 --report-extra --csv diffs_key.csv
```

---

## Notes

- Event detection heuristic: we first try column 6; if empty/non-sensical we also look for a token like `EVENT:...` anywhere later in the row.
- Fields are split by semicolons. Empty cells are preserved; trailing length differences are also detected and reported as `diff_col = -1` with a note.
- This tool reads line-by-line and keeps original line numbers so you can jump back to source quickly.
- Everything is standard library except optional PyYAML for YAML configs. JSON configs also work.
