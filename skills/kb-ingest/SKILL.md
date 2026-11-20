---
name: kb-ingest
description: Ingest sources into the Home Repo knowledge base, in bulk or one at a time, or resolve open questions from outside sources.
disable-model-invocation: true
argument-hint: "[bulk | a source path or URL | resolve]"
---

Turn raw sources into knowledge that serves the **Purpose**. Every source flows through the same four stages, in order: **clean** it to plain text, **triage** it against the rubric, **extract** its claims, **reduce** the claims into wiki pages. Most sources stop at triage: they stay in `kb/raw/` and the ledger, and nothing of them reaches the wiki.

Call the Skill tool with "kb" first: it defines the layout, claims, pages, and log entries everything here writes. Then read `kb/SCHEMA.md` and the Purpose in `AGENTS.md`. If `kb/SCHEMA.md` does not exist, tell the user to run `/kb-init` and stop.

## Tools

The scripts sit in this skill's `scripts/` folder; steps name them bare. Run each as `python3 <this skill's folder>/scripts/<script>` from the Home Repo root; each has `--help`.

- `vtt_to_text.py`: VTT to timestamped paragraphs, beside the raw file.
- `ledger.py`: every read and write of `kb/ledger.md` (`register`, `set`, `mark`, `list`, `counts`).
- `rubric_hits.py`: rubric term hits per file, or ad hoc `--terms` for snowballing.

Dispatch subagents as the `kb` skill says, on the model `SCHEMA.md` names for each job. Subagents return their results to you and write only the files their brief names; you alone write the ledger, the rubric, `SCHEMA.md`, `index.md`, `log.md`, and `open-questions.md`, so parallel subagents never collide.

## Pick the mode

- **Bulk** (the argument is `bulk`, or a raw folder holds many unregistered sources): read [BULK.md](BULK.md) and follow it.
- **Resolve** (the argument is `resolve`): read [RESOLVE.md](RESOLVE.md) and follow it.
- **Single** (a path or URL to one source): the steps below.

## Single source

1. **Clean.** Copy the source into `kb/raw/<kind>/` (fetch a URL first) and clean it as `cleaning/<kind>.md` says. Register it: `ledger.py register <cleaned file>` with the date rule from `SCHEMA.md`.
2. **Triage.** Read the cleaned text against the Purpose and `kb/rubric.md` (no rubric yet: judge against the Purpose alone). Set the verdict with a reason that names the rubric entries it rests on. On `skip`, stop here and report why.
3. **Extract.** Write `kb/extracts/<kind>/<stem>.md` as [EXTRACT.md](EXTRACT.md) says, then `ledger.py mark <source> --extracted`. Append its new terms to the rubric's matching entries.
4. **Reduce.** Integrate the extract into the wiki as [REDUCE.md](REDUCE.md) says, within the topics in `SCHEMA.md`. A claim that fits no topic gets a proposed new topic, written only after the user approves it into `SCHEMA.md`. Check whether the source answers anything in `open-questions.md`.
5. **Record.** `ledger.py mark <source> --reduced`, update `index.md`, and add an `ingest` entry to `log.md` naming the pages touched. Run `wiki_check.py` from the `kb` skill and fix what it reports on the pages you touched.

Done when the ledger row is complete for its verdict, every claim in the extract is in a page, superseding an older claim, or listed in `open-questions.md`, and `wiki_check.py` reports nothing on the touched pages.
