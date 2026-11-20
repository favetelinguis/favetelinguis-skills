#!/usr/bin/env python3
"""Read and write kb/ledger.md, the one-row-per-source progress table.

Usage:
  ledger.py [--ledger kb/ledger.md] register FILE... [--date-pattern RE] [--fallback mtime|undated]
  ledger.py set SOURCE... --verdict V --reason TEXT
  ledger.py set --from TSV            (lines: source<TAB>verdict<TAB>reason; '-' reads stdin)
  ledger.py mark SOURCE... (--extracted | --reduced)
  ledger.py list [--verdict V[,V]] [--extracted | --not-extracted] [--not-reduced] [--sample N] [--seed S]
  ledger.py counts

Sources are stored relative to the ledger's folder (kb/); `list` prints them
joined to the ledger's folder (kb/raw/...), and every command accepts either
form. Verdicts are
pending, relevant, maybe, skip. Dates are YYYY-MM-DD; `set` stamps
`triaged` and `mark` stamps `extracted` or `reduced` with today's date.
"""
import argparse
import datetime
import os
import random
import re
import sys
from pathlib import Path

COLUMNS = ["source", "recorded", "verdict", "reason", "triaged", "extracted", "reduced"]
VERDICTS = {"pending", "relevant", "maybe", "skip"}
HEADER = """# Ledger

One row per raw source, in the order sources arrived. Written by
`ledger.py` (in the `kb-ingest` skill); read it with `rg` or `ledger.py list`.
"""
DEFAULT_DATE = r"(\d{4})[-_.]?(\d{2})[-_.]?(\d{2})"


def today():
    return datetime.date.today().isoformat()


def load(path):
    rows = []
    if not path.exists():
        return rows
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|") or line.startswith("|---") or line.startswith("| source "):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        cells += [""] * (len(COLUMNS) - len(cells))
        rows.append(dict(zip(COLUMNS, cells)))
    return rows


def save(path, rows):
    lines = [HEADER, "| " + " | ".join(COLUMNS) + " |", "|" + "---|" * len(COLUMNS)]
    for row in rows:
        lines.append("| " + " | ".join(row[c].replace("|", "/") for c in COLUMNS) + " |")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def rel(root, source):
    p = Path(source)
    if p.is_absolute() or p.exists():
        try:
            return os.path.relpath(p.resolve(), root.resolve())
        except ValueError:
            pass
    prefix = root.as_posix().rstrip("/") + "/"
    return source[len(prefix):] if source.startswith(prefix) else source


def recorded(path, pattern, fallback):
    """Date from the filename by pattern, else the fallback.

    The pattern may capture year, month, day as three groups, or the whole
    date as one group (or none): the digits of the match are read as YYYYMMDD.
    """
    match = re.search(pattern, path.name)
    if match:
        groups = [g for g in match.groups() if g]
        digits = groups if len(groups) >= 3 else re.findall(r"\d+", groups[0] if groups else match.group(0))
        if len(digits) == 1 and len(digits[0]) == 8:
            digits = [digits[0][:4], digits[0][4:6], digits[0][6:]]
        try:
            return datetime.date(*map(int, digits[:3])).isoformat()
        except (TypeError, ValueError):
            print(f"warning: '{match.group(0)}' in {path.name} is not a date; using {fallback}", file=sys.stderr)
    if fallback == "mtime":
        siblings = [s for s in path.parent.glob(path.stem + ".*") if s.is_file()] or [path]
        oldest = min(s.stat().st_mtime for s in siblings)
        return datetime.date.fromtimestamp(oldest).isoformat()
    return "undated"


def index(rows):
    return {row["source"]: row for row in rows}


def find(rows, root, source):
    key = rel(root, source)
    row = index(rows).get(key)
    if row is None:
        sys.exit(f"error: {key} is not in the ledger")
    return row


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--ledger", default="kb/ledger.md")
    sub = parser.add_subparsers(dest="command", required=True)

    reg = sub.add_parser("register")
    reg.add_argument("files", nargs="+")
    reg.add_argument("--date-pattern", default=DEFAULT_DATE)
    reg.add_argument("--fallback", choices=["mtime", "undated"], default="mtime")

    st = sub.add_parser("set")
    st.add_argument("sources", nargs="*")
    st.add_argument("--verdict")
    st.add_argument("--reason", default="")
    st.add_argument("--from", dest="from_file")

    mk = sub.add_parser("mark")
    mk.add_argument("sources", nargs="+")
    group = mk.add_mutually_exclusive_group(required=True)
    group.add_argument("--extracted", action="store_true")
    group.add_argument("--reduced", action="store_true")

    ls = sub.add_parser("list")
    ls.add_argument("--verdict")
    done = ls.add_mutually_exclusive_group()
    done.add_argument("--extracted", action="store_true")
    done.add_argument("--not-extracted", action="store_true")
    ls.add_argument("--not-reduced", action="store_true")
    ls.add_argument("--sample", type=int)
    ls.add_argument("--seed", type=int, default=0)

    sub.add_parser("counts")

    args = parser.parse_args(argv)
    path = Path(args.ledger)
    root = path.parent
    rows = load(path)

    if args.command == "register":
        known = index(rows)
        added = 0
        for name in args.files:
            key = rel(root, name)
            if key in known:
                continue
            row = dict.fromkeys(COLUMNS, "")
            row.update(source=key, verdict="pending",
                       recorded=recorded(Path(name), args.date_pattern, args.fallback))
            rows.append(row)
            known[key] = row
            added += 1
        save(path, rows)
        print(f"registered {added}, already known {len(args.files) - added}", file=sys.stderr)
        dated = [r for r in rows if r["recorded"] != "undated"]
        if rows and not dated:
            print("warning: every row is undated; check --date-pattern", file=sys.stderr)

    elif args.command == "set":
        updates = []
        if args.from_file:
            stream = sys.stdin if args.from_file == "-" else open(args.from_file, encoding="utf-8")
            for line in stream:
                if not line.strip():
                    continue
                parts = line.rstrip("\n").split("\t")
                if len(parts) < 2:
                    sys.exit(f"error: want source<TAB>verdict<TAB>reason, got: {line.strip()}")
                updates.append((parts[0], parts[1].strip(), parts[2].strip() if len(parts) > 2 else ""))
        else:
            if not args.verdict:
                sys.exit("error: set needs --verdict or --from")
            updates = [(s, args.verdict, args.reason) for s in args.sources]
        for source, verdict, reason in updates:
            if verdict not in VERDICTS:
                sys.exit(f"error: verdict '{verdict}' is not one of {sorted(VERDICTS)}")
            row = find(rows, root, source)
            row.update(verdict=verdict, reason=reason, triaged=today() if verdict != "pending" else "")
        save(path, rows)
        print(f"set {len(updates)}", file=sys.stderr)

    elif args.command == "mark":
        column = "extracted" if args.extracted else "reduced"
        for source in args.sources:
            find(rows, root, source)[column] = today()
        save(path, rows)

    elif args.command == "list":
        picked = rows
        if args.verdict:
            wanted = set(args.verdict.split(","))
            picked = [r for r in picked if r["verdict"] in wanted]
        if args.extracted:
            picked = [r for r in picked if r["extracted"]]
        if args.not_extracted:
            picked = [r for r in picked if not r["extracted"]]
        if args.not_reduced:
            picked = [r for r in picked if not r["reduced"]]
        if args.sample is not None and args.sample < len(picked):
            picked = random.Random(args.seed).sample(picked, args.sample)
        for row in picked:
            print((root / row["source"]).as_posix())

    elif args.command == "counts":
        tally = {}
        for row in rows:
            tally[row["verdict"]] = tally.get(row["verdict"], 0) + 1
        print("total", len(rows))
        for verdict in ["pending", "relevant", "maybe", "skip"]:
            print(verdict, tally.get(verdict, 0))
        print("extracted", sum(1 for r in rows if r["extracted"]))
        print("reduced", sum(1 for r in rows if r["reduced"]))


if __name__ == "__main__":
    main()
