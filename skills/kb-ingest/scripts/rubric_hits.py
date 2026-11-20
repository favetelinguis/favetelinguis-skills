#!/usr/bin/env python3
"""Count rubric term hits per source file, for triage and snowballing.

Usage:
  rubric_hits.py RUBRIC FILE...           every Signal and Anti-signal in the rubric
  rubric_hits.py --terms "a,b,c" FILE...  ad hoc terms (snowball); prints only files with hits

A FILE that does not exist as given is looked up under kb/, so the output of
`ledger.py list` can be passed straight in.

Rubric entries are bullets under `## Signals` and `## Anti-signals` that
name the entry in bold and list its terms in backticks after `Terms:`:

  - **Deploy pipeline**: ... Terms: `argo`, `helm chart`, `rollback`.

Output is TSV: source, signal hits, anti-signal hits, then name:count pairs,
most hits first. Matching ignores case and respects word edges, and skips the
speaker labels vtt_to_text.py writes (`[00:01:00] Erik Lund: `).
"""
import argparse
import re
import sys
from pathlib import Path

ENTRY = re.compile(r"^\s*[-*]\s+\*\*(.+?)\*\*(.*)$")
SPEAKER = re.compile(r"^(\[\d{2}:\d{2}:\d{2}\] )[^:\n]{1,60}: ", re.MULTILINE)


def parse(rubric_text):
    """Return [(kind, name, [terms])] with kind 'signal' or 'anti'."""
    entries = []
    kind = None
    for line in rubric_text.splitlines():
        heading = re.match(r"^##\s+(.*)", line)
        if heading:
            title = heading.group(1).strip().lower()
            kind = "anti" if title.startswith("anti") else "signal" if title.startswith("signal") else None
            continue
        match = ENTRY.match(line)
        if kind and match and "Terms:" in match.group(2):
            terms = re.findall(r"`([^`]+)`", match.group(2).split("Terms:", 1)[1])
            if terms:
                entries.append((kind, match.group(1).strip(), terms))
    return entries


def pattern(term):
    return re.compile(r"(?<!\w)" + re.escape(term) + r"(?!\w)", re.IGNORECASE)


def locate(name):
    path = Path(name)
    if not path.exists() and (Path("kb") / name).exists():
        path = Path("kb") / name
    return path


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--terms")
    parser.add_argument("paths", nargs="+")
    args = parser.parse_args(argv)

    if args.terms:
        entries = [("signal", t.strip(), [t.strip()]) for t in args.terms.split(",") if t.strip()]
        files = args.paths
    else:
        rubric, files = args.paths[0], args.paths[1:]
        entries = parse(Path(rubric).read_text(encoding="utf-8"))
        if not entries:
            sys.exit(f"error: no entries with Terms: under ## Signals or ## Anti-signals in {rubric}")
    compiled = [(kind, name, [pattern(t) for t in terms]) for kind, name, terms in entries]

    for name in files:
        text = SPEAKER.sub(r"\1", locate(name).read_text(encoding="utf-8", errors="replace"))
        totals = {"signal": 0, "anti": 0}
        hits = []
        for kind, entry, patterns in compiled:
            count = sum(len(p.findall(text)) for p in patterns)
            if count:
                totals[kind] += count
                hits.append((count, ("!" if kind == "anti" else "") + entry))
        if args.terms and not hits:
            continue
        hits.sort(key=lambda h: (-h[0], h[1]))
        pairs = ",".join(f"{entry}:{count}" for count, entry in hits)
        print(f"{name}\t{totals['signal']}\t{totals['anti']}\t{pairs}")


if __name__ == "__main__":
    main()
