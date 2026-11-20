---
name: kb
description: Conventions of the Home Repo knowledge base in `kb/`, and how to answer from it. Use when a question touches the domain of the Home Repo's Purpose, or before reading or writing anything under `kb/`.
---

The **knowledge base** is a persistent, compounding wiki an agent writes and keeps current, inside a **Home Repo**: the repo the agent runs in, whose `AGENTS.md` holds a **Knowledge base** section with the **Purpose** (role, goal, horizon, signal, noise) and pointers into `kb/`. The Purpose is fixed for the life of the knowledge base, and every page exists to serve it. `kb/SCHEMA.md` holds this knowledge base's settings (source kinds, date rule, language, models, page types, topics); read it before writing.

## Layout

```
kb/
  SCHEMA.md            settings for this knowledge base
  rubric.md            what the Purpose looks like in the sources: signals, anti-signals
  ledger.md            one row per raw source: verdict, reason, progress dates
  raw/<kind>/          immutable sources; cleaned text sits beside each one
  extracts/<kind>/     one file of claims per relevant source (intermediate, outside the wiki)
  wiki/
    index.md           every hub and child page, one line each
    log.md             append-only record of operations
    open-questions.md  what the sources leave unresolved
    <topic>.md         a hub page
    <topic>/<page>.md  its child pages
```

Raw sources are the source of truth: read them, cite them, and leave them byte for byte as they arrived. The ledger is written only through `ledger.py` in the `kb-ingest` skill.

## Claims

Every fact in the wiki is a **claim**: one bullet, dated by its source's `recorded` date in the ledger, citing the cleaned raw text with a **locator**.

```
- On 2024-03-12, billing deploys through Argo CD with a manual gate. ([042@00:13:20](../raw/transcripts/042.txt))
- Undated: the on-call rota lives in PagerDuty. ([intro@00:02:10](../raw/transcripts/intro.txt))
```

- The locator is the paragraph timestamp for transcripts, the heading for pages (`page@#Rollback`), the message time for conversations.
- Link paths are relative to the page (`../../raw/...` from a child page).
- A claim several sources support cites each of them and takes the newest of their dates.
- A claim may open with a bold label (`- **Rollback**: On 2024-01-15, ...`); lead sentences and summaries that state facts are claims too, and carry citations.
- The wiki records history. When a newer source changes a claim, add the new claim and append `Superseded on <date>.` after the old one's citation, keeping its text.
- When two sources conflict and dates do not settle it, keep both claims and add the question to `open-questions.md`.
- Write claims in the language `SCHEMA.md` names; a quote keeps its original language, in quotation marks.

## Pages

A page covers one thing: a topic hub, or one thing of a page type `SCHEMA.md` lists. Topics are subject areas (Services, Deploys, On-call); page types are the kinds of child pages inside them (a service, a runbook, a decision). Each claim lives on one page; other pages link to it.

```
# <Title>

<Two or three sentences: what this is, cited like any claim, and why it matters for the Purpose, which needs no citation.>

## <Section>

- <claims>

Related: [<page>](<path>), [<page>](<path>)
```

A hub summarises its topic and links every child. When a page outgrows one comfortable read (about 2000 words), split it into child pages under `<topic>/` and leave the hub as the summary. Links are relative markdown links.

## Index, log, open questions

`index.md` lists hubs as headings, each with its children:

```
## Services
- [Services](services.md): what runs, who owns it, how it ships.
  - [Billing](services/billing.md): invoicing pipeline and its nightly jobs.
```

`log.md` takes one entry per operation, newest last, headed `## [YYYY-MM-DD] <op> | <title>` with `<op>` one of init, ingest, query, lint, resolve, followed by a few bullets of what changed.

`open-questions.md` takes one heading per question, merged with any open question that asks the same thing:

```
## <question>
- Raised: <date>, by <op from the log list>, from [<page>](<path>)
- Ask: <role or person who would know>
- Tried: <sources searched, with dates>
- Status: open | resolved on <date>, see [<page>](<path>)
```

## Checks and subagents

`scripts/wiki_check.py` in this skill's folder checks a knowledge base mechanically: broken links, orphans, the index, page sizes, claims missing a date or citation or dated off the ledger, and ledger rows stuck between stages. Run it as `python3 <this skill's folder>/scripts/wiki_check.py kb` from the Home Repo root after any operation that writes pages; a subagent writing part of a larger run leaves it to the caller, since sibling pages may not exist yet.

Every subagent the `kb-*` skills dispatch starts with a fresh context window. When the harness has no subagent tool, start each as a fresh non-interactive run of the agent CLI with the brief as its prompt (for pi: `pi -p --no-session --model <model> "<brief>"`), as many at once as the machine allows.

## Query

1. Read `kb/wiki/index.md`, then the hubs and children it points to for the question.
2. When the pages run thin, search deeper with `rg` over `kb/extracts/`, then over the cleaned raw text.
3. Answer with claims and their citations. Name any part the knowledge base cannot answer as a gap.
4. When the answer is worth keeping (a comparison, an analysis, a connection across pages), propose where it belongs: a new page, or a section on an existing one. Write it only after the user says yes, then update `index.md`, add a `query` entry to `log.md`, and add any gap the user agrees on to `open-questions.md`.

Done when every statement in the answer carries a citation or is labelled a gap, and any filing the user accepted is written.
