---
name: ask-about-kb
description: Ask how to do something with the knowledge base skills, or how they work. A router over the kb-* skills.
disable-model-invocation: true
argument-hint: "[your question]"
---

# Ask about the knowledge base

You don't remember how every part of the knowledge base works, so ask.

Before stating what a skill does or how a step behaves, read that skill's `SKILL.md`, and the file it points at for the branch in question (`BULK.md`, `RESOLVE.md`, `EXTRACT.md`, `REDUCE.md`, `cleaning/<kind>.md`, `SCHEMA-TEMPLATE.md`): the summaries here are for orientation only. When the question is about this knowledge base's state (where a bulk ingest stands, why a source was skipped, what a topic covers), read the Home Repo's own files and answer from them: `AGENTS.md`, `kb/SCHEMA.md`, `kb/rubric.md`, `kb/ledger.md`, `kb/wiki/log.md`. Answer with the command or skill to run next, and the file that shows it.

A **flow** is a path through the skills. The knowledge base has one **main flow** from an empty Home Repo to a working wiki, then **upkeep** loops that keep it growing and healthy. `kb` runs underneath all of them.

## The model

Based on [Karpathy's LLM wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f), inside a **Home Repo** (the repo every session starts in, whose `AGENTS.md` points at your other repos).

- **Purpose**: role, goal, horizon, signal, noise, in the Home Repo's `AGENTS.md`. **Fixed**: a different goal gets a different Home Repo. Every decision about what to keep is made against it.
- **Three layers**: `kb/raw/` holds sources exactly as they arrived (immutable, the source of truth); `kb/extracts/` holds the claims each relevant source offers (intermediate, outside the wiki); `kb/wiki/` holds the pages the agent writes and you read.
- **Claims**: every fact is a bullet dated by its source's recording date and citing the cleaned raw text with a locator (`042@00:13:20`). The wiki records history: a newer claim supersedes an older one rather than overwriting it.
- **Four stages** every source passes through: **clean**, **triage**, **extract**, **reduce**. Most sources stop at triage and never reach the wiki, but stay in `raw/` and the ledger.
- **Rubric** (`kb/rubric.md`): what the Purpose sounds like in these sources (signals, anti-signals, session kinds), reverse-engineered from a sample and sharpened as extraction finds new names.
- **Ledger** (`kb/ledger.md`): one row per source with verdict, reason, and progress dates. It is how any session knows what is done and what is left.
- **Settings** (`kb/SCHEMA.md`): source kinds, date rule, language, models, page types, external sources, and the approved topics.

## The main flow: empty Home Repo → working wiki

1. **`/kb-init`** sets up the knowledge base in the current Home Repo. It confirms the Purpose with you (grilling only what is unclear), settles the settings, copies your sources into `kb/raw/<kind>/`, and commits the scaffold. It stops if a Purpose already exists.
2. **`/kb-ingest bulk`** takes the corpus through the four stages, resuming wherever the files say it stopped. Three **gates** wait for you:
   - **Rubric**: after calibration on a sample, you approve what counts as signal before a cheap model triages everything.
   - **Maybes**: after the skip audit, you decide whether borderline sources get extracted, re-triaged, or left.
   - **Topics**: after extraction, you approve the handful of topic hubs before reduce writes the pages.
3. **`/kb-lint`** right after the first bulk ingest, to catch what reduce left rough.

### Context hygiene

A bulk ingest of hundreds of sources spans sessions. The coordinating session reads only subagent reports, counts, and the files above, never the transcripts, so its window stays small. Start a fresh session at any gate or stage boundary and rerun `/kb-ingest bulk`: the Resume table in `BULK.md` picks the stage back up from the files.

## Using it

- **Asking the knowledge base something** needs no command: in the Home Repo, ask. The model-invoked **`kb`** skill answers from `index.md`, the hubs, then extracts and raw text, with citations, and names what it cannot answer as a gap. A good answer can be filed back as a page, only when you say yes.

## Upkeep

- **A new source** (a Confluence page, a conversation, one more recording) → **`/kb-ingest <path or URL>`**. Same four stages for one source, integrated into the existing topics.
- **Questions the sources leave open** collect in `kb/wiki/open-questions.md`, from reduce and lint. Ask the people the `Ask:` lines name, or run **`/kb-ingest resolve`** to have the agent search the external sources in `SCHEMA.md`, save what it uses into `raw/`, and close or narrow each question.
- **Health** → **`/kb-lint`** every so often: the mechanical check (links, orphans, uncited or misdated claims, stuck ledger rows) and a read per hub (contradictions, overstatements, stale claims, missing pages, gaps against the Purpose). It suggests adding a search tool such as qmd once `index.md` outgrows one read.

## Underneath

- **`kb`** is the single source of truth for the conventions (layout, claims, pages, index, log, open questions), the query steps, how subagents are dispatched (with a headless fallback when the harness has none), and `scripts/wiki_check.py`. Every `kb-*` skill loads it first.

## Common questions

Orientation only; confirm in the file named before answering. `ledger.py` and the other ingest scripts live in `kb-ingest/scripts/`, `wiki_check.py` in `kb/scripts/`.

- **Where is my bulk ingest?** The Resume table in `BULK.md`, checked against `ledger.py counts` and the last entries of `log.md` (`grep '^## \[' kb/wiki/log.md | tail -5`).
- **Why was this source skipped?** Its ledger row's reason, which names the rubric entries it rests on.
- **A skip was wrong.** If the rubric missed a signal, add it to `kb/rubric.md` with a Log line; then set the row back with `ledger.py set <source> --verdict pending --reason "<why>"` and rerun `/kb-ingest bulk`, which resumes at triage (the Resume table in `BULK.md`). For one source, `/kb-ingest <path>` re-triages it directly.
- **My goal changed.** The Purpose is fixed: set up a new Home Repo with `/kb-init` and copy the raw sources there to triage against the new Purpose.
- **A new kind of source** (an export format not yet covered): add a cleaning note under `kb-ingest/cleaning/`, then a row in `SCHEMA.md` Sources. See `cleaning/pages.md` for the shape.
- **The cleaned transcripts look wrong** (repeated phrases, lost words): `cleaning/vtt.md`; fix `vtt_to_text.py` and its tests before cleaning the rest.
- **Which model runs what?** `SCHEMA.md` Models: cheap for triage, capable for calibration, audit, map, and reduce.
- **Should raw sources be in git?** `SCHEMA.md` Raw in git, decided at init: committed for a private remote or none.
- **How is a claim dated?** The `kb` skill's Claims section: the source's `recorded` date in the ledger, set at registration by the date rule in `SCHEMA.md`, or `Undated:` when the rule finds none; reduce adds it (`REDUCE.md`); a claim several sources support takes the newest.
- **Taking the skills to another machine** (work): clone this skills repo there and run `./link-skills.sh`, or copy the `kb`, `kb-init`, `kb-ingest`, `kb-lint`, and `ask-about-kb` folders into the Home Repo's skills folder. The scripts need only Python 3.
