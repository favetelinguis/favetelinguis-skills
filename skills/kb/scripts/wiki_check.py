#!/usr/bin/env python3
"""Mechanical health check of a knowledge base folder (default kb/).

Usage:
  wiki_check.py [KB_DIR] [--max-words 2000] [--index-words 3000]

Reports, one section each, only what it finds:
  broken-link      a relative link in kb/wiki/ whose target does not exist
  orphan           a wiki page no other wiki page (index.md included) links to
  not-in-index     a wiki page index.md does not list
  oversized        a page over --max-words (split it into child pages)
  index-size       index.md over --index-words (time to add a search tool)
  uncited-claim    a dated claim bullet with no link into raw/
  undated-claim    a bullet citing raw/ that is not written as a claim
  date-mismatch    a claim not dated with the newest recorded date of its cited sources
  bare-bullet      a bullet with no link at all (a fact with no citation)
  ledger           relevant or maybe rows not extracted, extracted rows not reduced,
                   extracts with no ledger row

A claim bullet starts with "On YYYY-MM-DD," or "Undated:", optionally after a
bold label ("- **Rollback**: On 2024-01-15, ..."). Exit status is 0 when
clean and 1 when anything was reported.
"""
import argparse
import os
import re
import sys
from pathlib import Path

LINK = re.compile(r"\]\(([^)\s]+)\)")
CLAIM = re.compile(r"^\s*(?:[-*]|\d+\.)\s+(?:\*\*[^*]+\*\*:?\s+)?(?:On (\d{4}-\d{2}-\d{2}),|Undated:)")
BULLET = re.compile(r"^\s*(?:[-*]|\d+\.)\s+")
SPECIAL = {"index.md", "log.md", "open-questions.md"}


def words(text):
    return len(text.split())


def links(text):
    for target in LINK.findall(text):
        if re.match(r"^[a-z]+:", target) or target.startswith("#"):
            continue
        yield target.split("#", 1)[0]


def ledger_rows(path):
    rows = []
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.startswith("| raw/"):
                cells = [c.strip() for c in line.strip().strip("|").split("|")]
                rows.append(cells + [""] * (7 - len(cells)))
    return rows


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("kb", nargs="?", default="kb")
    parser.add_argument("--max-words", type=int, default=2000)
    parser.add_argument("--index-words", type=int, default=3000)
    args = parser.parse_args(argv)

    kb = Path(args.kb)
    wiki = kb / "wiki"
    if not wiki.is_dir():
        sys.exit(f"error: no wiki folder at {wiki}")
    pages = sorted(wiki.rglob("*.md"))
    rows = ledger_rows(kb / "ledger.md")
    recorded = {(kb / row[0]).resolve(): row[1] for row in rows}
    findings = {}

    def report(kind, message):
        findings.setdefault(kind, []).append(message)

    inbound = {page.resolve(): 0 for page in pages}
    for page in pages:
        for target in links(page.read_text(encoding="utf-8")):
            resolved = (page.parent / target).resolve()
            if not resolved.exists():
                report("broken-link", f"{page.relative_to(kb)} -> {target}")
            elif resolved in inbound and resolved != page.resolve():
                inbound[resolved] += 1

    index = wiki / "index.md"
    indexed = set()
    if index.exists():
        indexed = {(wiki / t).resolve() for t in links(index.read_text(encoding="utf-8"))}
    for page in pages:
        name = page.relative_to(wiki).as_posix()
        text = page.read_text(encoding="utf-8")
        if name in SPECIAL:
            continue
        if inbound[page.resolve()] == 0:
            report("orphan", name)
        if page.resolve() not in indexed:
            report("not-in-index", name)
        count = words(text)
        if count > args.max_words:
            report("oversized", f"{name} ({count} words)")
        for number, line in enumerate(text.splitlines(), 1):
            cited = [(page.parent / t).resolve() for t in links(line) if "raw/" in t]
            claim = CLAIM.match(line)
            if claim and not cited:
                report("uncited-claim", f"{name}:{number}")
            elif BULLET.match(line) and cited and not claim:
                report("undated-claim", f"{name}:{number}")
            elif claim and claim.group(1) and rows:
                dates = {recorded.get(c) for c in cited} - {None, "undated"}
                if dates and claim.group(1) != max(dates):
                    report("date-mismatch", f"{name}:{number} ({claim.group(1)}; sources {', '.join(sorted(dates))})")
            elif BULLET.match(line) and not LINK.search(line):
                report("bare-bullet", f"{name}:{number}")

    if index.exists():
        count = words(index.read_text(encoding="utf-8"))
        if count > args.index_words:
            report("index-size", f"index.md is {count} words; add a search tool such as qmd")

    sources = {row[0] for row in rows}
    waiting = [r[0] for r in rows if r[2] in ("relevant", "maybe") and not r[5]]
    unreduced = [r[0] for r in rows if r[5] and not r[6]]
    if waiting:
        report("ledger", f"{len(waiting)} relevant or maybe rows not extracted")
    if unreduced:
        report("ledger", f"{len(unreduced)} extracted rows not reduced")
    extracts = kb / "extracts"
    if extracts.is_dir():
        for extract in sorted(extracts.rglob("*.md")):
            match = re.search(r"^source:\s*(\S+)", extract.read_text(encoding="utf-8"), re.MULTILINE)
            source = match.group(1) if match else ""
            if os.path.normpath(source) not in sources and source.removeprefix("kb/") not in sources:
                report("ledger", f"{extract.relative_to(kb)} has no ledger row")

    for kind, messages in findings.items():
        print(f"## {kind}")
        for message in messages:
            print(f"- {message}")
        print()
    if not findings:
        print("clean")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
