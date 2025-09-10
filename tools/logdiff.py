#!/usr/bin/env python3
"""
logdiff.py — Compare two semicolon-separated EuroScalper logs (Baseline vs Rewrite).

- Default is KEYED comparison by timestamp + event (cols 0 and 6).
- Finds the FIRST differing column per matched pair (default) or ALL diffs per pair (--report all).
- Ignore not-yet-implemented EVENTS and/or noisy COLUMNS.
- Numeric tolerance for float jitter.
- CSV export and concise stdout summary.
"""

from __future__ import annotations
import argparse
import csv
import json
import math
import re
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple, Dict, Iterable

try:
    import yaml  # optional
    _HAS_YAML = True
except Exception:
    _HAS_YAML = False

SEMICOLON = ';'
DEFAULT_EVENT_COL = 6
NUM_REGEX = re.compile(r"^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$")

@dataclass
class LogRecord:
    raw: str
    fields: List[str]
    lineno: int
    event: str
    key: Optional[Tuple] = None

def is_number(s: str) -> bool:
    return bool(NUM_REGEX.match(s.strip()))

def approx_equal(a: str, b: str, tol: float) -> bool:
    sa, sb = a.strip(), b.strip()
    if sa == sb:
        return True
    if is_number(sa) and is_number(sb):
        try:
            fa, fb = float(sa), float(sb)
            return math.isclose(fa, fb, rel_tol=tol, abs_tol=tol)
        except Exception:
            return False
    return False

def parse_event(fields: List[str]) -> str:
    # 1) heuristic: column 6 if present and non-numeric
    if len(fields) > DEFAULT_EVENT_COL and fields[DEFAULT_EVENT_COL].strip():
        cand = fields[DEFAULT_EVENT_COL].strip()
        if not is_number(cand):
            return cand
    # 2) fallback: token like "EVENT:kvpairs"
    for f in fields:
        if ':' in f:
            left = f.split(':', 1)[0].strip()
            if left and not is_number(left) and len(left) <= 64:
                return left
    return ""

def load_ignore_config(path: Optional[Path]) -> Tuple[set, set]:
    ignore_events: set = set()
    ignore_columns: set = set()
    if path is None:
        return ignore_events, ignore_columns
    if not path.exists():
        raise FileNotFoundError(f"Ignore config not found: {path}")
    text = path.read_text(encoding='utf-8')
    data = None
    if _HAS_YAML:
        try:
            data = yaml.safe_load(text)
        except Exception:
            data = None
    if data is None:
        try:
            data = json.loads(text)
        except Exception as e:
            raise RuntimeError("Could not parse ignore config as YAML or JSON") from e
    if not isinstance(data, dict):
        raise ValueError("Ignore config must be a mapping with keys like 'ignore_events' and 'ignore_columns'")
    ev = data.get('ignore_events', [])
    cols = data.get('ignore_columns', [])
    if not isinstance(ev, list) or not isinstance(cols, list):
        raise ValueError("'ignore_events' and 'ignore_columns' must both be lists")
    ignore_events = {str(x).strip() for x in ev if str(x).strip()}
    for c in cols:
        try:
            ignore_columns.add(int(c))
        except Exception:
            raise ValueError(f"Invalid column index in ignore_columns: {c}")
    return ignore_events, ignore_columns

def iter_records(path: Path, ignore_events: set) -> Iterable[LogRecord]:
    with path.open('r', encoding='utf-8', errors='replace') as f:
        for i, line in enumerate(f, start=1):
            raw = line.rstrip('\n')
            if not raw.strip():
                continue
            fields = [x.strip() for x in raw.split(SEMICOLON)]
            event = parse_event(fields)
            if event and event in ignore_events:
                continue
            yield LogRecord(raw=raw, fields=fields, lineno=i, event=event)

def build_key(fields: List[str], key_cols: List[int]) -> Tuple:
    key = []
    for idx in key_cols:
        v = fields[idx] if idx < len(fields) else ""
        key.append(v.strip())
    return tuple(key)

def first_diff_column(a: List[str], b: List[str], ignore_cols: set, tol: float) -> Optional[Tuple[int, str, str]]:
    max_i = max(len(a), len(b))
    for idx in range(max_i):
        if idx in ignore_cols:
            continue
        va = a[idx] if idx < len(a) else ""
        vb = b[idx] if idx < len(b) else ""
        if not approx_equal(va, vb, tol):
            return idx, va, vb
    return None

def diff_all_columns(a: List[str], b: List[str], ignore_cols: set, tol: float):
    diffs = []
    max_i = max(len(a), len(b))
    for idx in range(max_i):
        if idx in ignore_cols:
            continue
        va = a[idx] if idx < len(a) else ""
        vb = b[idx] if idx < len(b) else ""
        if not approx_equal(va, vb, tol):
            diffs.append((idx, va, vb))
    return diffs

def compare_index_mode(a_records: List[LogRecord], b_records: List[LogRecord],
                       ignore_cols: set, tol: float, max_rows: Optional[int]) -> List[Dict]:
    out = []
    for i, (ra, rb) in enumerate(zip(a_records, b_records)):
        if max_rows is not None and i >= max_rows:
            break
        diff = first_diff_column(ra.fields, rb.fields, ignore_cols, tol)
        if diff is not None:
            idx, va, vb = diff
            out.append({
                "baseline_lineno": ra.lineno,
                "rewrite_lineno": rb.lineno,
                "event": ra.event or rb.event,
                "diff_col": idx,
                "baseline_value": va,
                "rewrite_value": vb,
                "baseline_raw": ra.raw,
                "rewrite_raw": rb.raw,
            })
    if len(a_records) != len(b_records):
        longer, name = (a_records, "baseline") if len(a_records) > len(b_records) else (b_records, "rewrite")
        start = min(len(a_records), len(b_records))
        for j in range(start, len(longer)):
            r = longer[j]
            out.append({
                f"{name}_lineno": r.lineno,
                "event": r.event,
                "diff_col": -1,
                "baseline_value": "" if name == "rewrite" else r.raw,
                "rewrite_value": r.raw if name == "rewrite" else "",
                "baseline_raw": r.raw if name == "baseline" else "",
                "rewrite_raw": r.raw if name == "rewrite" else "",
                "note": f"extra line present only in {name}",
            })
    return out

def compare_key_mode(a_records: List[LogRecord], b_records: List[LogRecord],
                     key_cols: List[int], ignore_cols: set, tol: float,
                     report_extra: bool, max_rows: Optional[int],
                     report_mode: str = "first") -> List[Dict]:
    """
    Group by key across both files, then compare the nth baseline record to
    the nth rewrite record for each key (stable order). Supports two report modes:
      - "first": emit only the first differing column per paired row
      - "all"  : emit one row per differing column per paired row
    Also reports extras in either file when counts per key differ (if report_extra True).
    """
    from collections import defaultdict
    a_groups: Dict[Tuple, List[LogRecord]] = defaultdict(list)
    b_groups: Dict[Tuple, List[LogRecord]] = defaultdict(list)

    def calc_key(r: LogRecord) -> Optional[Tuple]:
        try:
            return build_key(r.fields, key_cols)
        except Exception:
            return None

    for ra in a_records:
        ra.key = calc_key(ra)
        if ra.key is not None:
            a_groups[ra.key].append(ra)
    for rb in b_records:
        rb.key = calc_key(rb)
        if rb.key is not None:
            b_groups[rb.key].append(rb)

    # stable key order based on baseline appearance
    seen_keys = []
    for ra in a_records:
        if ra.key is not None and (not seen_keys or seen_keys[-1] != ra.key):
            seen_keys.append(ra.key)

    out: List[Dict] = []
    emitted = 0
    def maybe_stop():
        return max_rows is not None and emitted >= max_rows

    for key in seen_keys:
        a_list = a_groups.get(key, [])
        b_list = b_groups.get(key, [])
        pairs = min(len(a_list), len(b_list))

        for i in range(pairs):
            if maybe_stop():
                break
            ra, rb = a_list[i], b_list[i]
            if report_mode == "all":
                diffs = diff_all_columns(ra.fields, rb.fields, ignore_cols, tol)
                for (idx, va, vb) in diffs:
                    if maybe_stop():
                        break
                    out.append({
                        "baseline_lineno": ra.lineno,
                        "rewrite_lineno": rb.lineno,
                        "event": ra.event or rb.event,
                        "key": "|".join(map(str, key)),
                        "diff_col": idx,
                        "baseline_value": va,
                        "rewrite_value": vb,
                        "baseline_raw": ra.raw,
                        "rewrite_raw": rb.raw,
                    })
                    emitted += 1
            else:
                diff = first_diff_column(ra.fields, rb.fields, ignore_cols, tol)
                if diff is not None and not maybe_stop():
                    idx, va, vb = diff
                    out.append({
                        "baseline_lineno": ra.lineno,
                        "rewrite_lineno": rb.lineno,
                        "event": ra.event or rb.event,
                        "key": "|".join(map(str, key)),
                        "diff_col": idx,
                        "baseline_value": va,
                        "rewrite_value": vb,
                        "baseline_raw": ra.raw,
                        "rewrite_raw": rb.raw,
                    })
                    emitted += 1

        if report_extra and not maybe_stop():
            for ra in a_list[pairs:]:
                if maybe_stop():
                    break
                out.append({
                    "baseline_lineno": ra.lineno,
                    "rewrite_lineno": "",
                    "event": ra.event,
                    "key": "|".join(map(str, key)),
                    "diff_col": -1,
                    "baseline_value": ra.raw,
                    "rewrite_value": "",
                    "baseline_raw": ra.raw,
                    "rewrite_raw": "",
                    "note": "no matching rewrite line for key (extra in baseline)",
                })
                emitted += 1
            for rb in b_list[pairs:]:
                if maybe_stop():
                    break
                out.append({
                    "baseline_lineno": "",
                    "rewrite_lineno": rb.lineno,
                    "event": rb.event,
                    "key": "|".join(map(str, key)),
                    "diff_col": -1,
                    "baseline_value": "",
                    "rewrite_value": rb.raw,
                    "baseline_raw": "",
                    "rewrite_raw": rb.raw,
                    "note": "no matching baseline line for key (extra in rewrite)",
                })
                emitted += 1

    return out

def write_csv(rows: List[Dict], path: Path) -> None:
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    cols = ["baseline_lineno","rewrite_lineno","event","key","diff_col",
            "baseline_value","rewrite_value","note","baseline_raw","rewrite_raw"]
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow(r)

def main() -> None:
    p = argparse.ArgumentParser(description="Compare Baseline vs Rewrite logs and report differing columns per matched row.")
    p.add_argument("baseline", type=Path, help="Path to baseline log file")
    p.add_argument("rewrite", type=Path, help="Path to rewrite log file")
    p.add_argument("--mode", choices=["index","key"], default="key",
                   help="Comparison mode: 'index' (in-order) or 'key' (match on columns)")
    p.add_argument("--key-cols", type=str, default="0,6",
                   help="Comma-separated column indices to build key (only in --mode key). Default: 0,6 (timestamp,event)")
    p.add_argument("--ignore-config", type=Path, default=None,
                   help="YAML/JSON file with ignore_events: [..], ignore_columns: [..]")
    p.add_argument("--ignore-events", type=str, default="",
                   help="Comma-separated event names to ignore (overrides/extends config)")
    p.add_argument("--ignore-columns", type=str, default="",
                   help="Comma-separated column indices to ignore during comparison (overrides/extends config)")
    p.add_argument("--float-tol", type=float, default=0.0,
                   help="Numeric tolerance; consider floats equal within this tolerance (rel/abs). Default 0.0")
    p.add_argument("--report-extra", action="store_true",
                   help="In key-mode, also report lines that exist in only one file")
    p.add_argument("--report", choices=["first","all"], default="first",
                   help="Emit only the first differing column per pair (first) or all differing columns (all)")
    p.add_argument("--max-rows", type=int, default=None,
                   help="Stop after reporting this many rows (for quick scans)")
    p.add_argument("--csv", type=Path, default=None,
                   help="Write detailed diff rows to CSV at this path")
    args = p.parse_args()

    cfg_ignore_events, cfg_ignore_cols = load_ignore_config(args.ignore_config)
    cli_ignore_events = {e.strip() for e in args.ignore_events.split(",") if e.strip()}
    cli_ignore_cols = set()
    for tok in [c.strip() for c in args.ignore_columns.split(",") if c.strip()]:
        try:
            cli_ignore_cols.add(int(tok))
        except Exception as e:
            raise SystemExit(f"Invalid --ignore-columns value: {tok}") from e
    ignore_events = cfg_ignore_events.union(cli_ignore_events)
    ignore_cols = cfg_ignore_cols.union(cli_ignore_cols)

    a_records = list(iter_records(args.baseline, ignore_events))
    b_records = list(iter_records(args.rewrite, ignore_events))

    if args.mode == "index":
        rows = compare_index_mode(a_records, b_records, ignore_cols, args.float_tol, args.max_rows)
    else:
        key_cols: List[int] = []
        if args.key_cols.strip():
            for tok in args.key_cols.split(","):
                tok = tok.strip()
                if not tok:
                    continue
                try:
                    key_cols.append(int(tok))
                except Exception as e:
                    raise SystemExit(f"Invalid key column index: {tok}") from e
        if not key_cols:
            raise SystemExit("In key-mode you must provide --key-cols")
        rows = compare_key_mode(a_records, b_records, key_cols, ignore_cols, args.float_tol,
                                args.report_extra, args.max_rows, args.report)

    if not rows:
        print("No differences found under current filters and tolerance.")
    else:
        print(f"Found {len(rows)} difference row(s). Showing first 10:")
        for i, r in enumerate(rows[:10], start=1):
            key = f" key={r.get('key','')}" if r.get('key') else ""
            note = f" [{r['note']}]" if r.get('note') else ""
            print(f"{i:>3}. base#{r.get('baseline_lineno','')}, rew#{r.get('rewrite_lineno','')}, event={r.get('event','?')}{key}, col={r['diff_col']}, base='{r.get('baseline_value','')}', rew='{r.get('rewrite_value','')}'{note}")
    if args.csv:
        write_csv(rows, args.csv)
        print(f"\nCSV written to: {args.csv}")

if __name__ == "__main__":
    main()
