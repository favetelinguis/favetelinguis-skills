---
name: kb-lint
description: Health-check the Home Repo knowledge base against its Purpose and fix what the user picks.
disable-model-invocation: true
---

Health-check the knowledge base: the mechanical faults a script finds, and the semantic ones only reading finds, all measured against the **Purpose**. Call the Skill tool with "kb" first, then read `kb/SCHEMA.md`, the Purpose in `AGENTS.md`, and `kb/wiki/open-questions.md`.

## 1. Mechanical check

Run `wiki_check.py` from the `kb` skill. It reports broken links, orphans, pages missing from the index, oversized pages, an index too large for one read, claims missing a date or citation or dated off the ledger, and ledger rows stuck between stages.

Done when you hold its report.

## 2. Semantic check

Dispatch one capable subagent per hub, as the `kb` skill says. Brief: "Call the Skill tool with "kb". Read `kb/wiki/<topic>.md` and its children; open other pages only to check a claim against them. The Purpose is: <Purpose>. Write nothing. Report, each with page and line:
- **contradictions**: claims that disagree with no `Superseded on` to settle them;
- **overstatements**: a summary or lead sentence claiming more than its cited claims say, or stating a fact with no citation;
- **stale claims**: an older claim a newer one overtakes, left unmarked;
- **missing pages**: a thing of a `SCHEMA.md` page type that the claims of three or more pages name, with no page of its own;
- **missing links**: pages that discuss each other with no link;
- **gaps**: parts of the Purpose's Signal this topic should cover and does not, worded as questions someone could answer."

Done when every hub has a report.

## 3. Report and fix

Merge the reports: one finding per fault, however many hubs saw it (a missing link counts once per page pair). Drop gaps `open-questions.md` already asks; a gap that partly overlaps a question widens that question. For a missing page whose thing fits no page type, propose a section on the page that covers it most. Show the user one list, grouped by kind, mechanical and semantic together, each finding with a proposed fix. Add two recommendations when they apply: when `index-size` fires, adding a local search tool such as [qmd](https://github.com/tobi/qmd) over `kb/`; when `open-questions.md` holds questions an outside source could answer, running `/kb-ingest resolve`.

Apply the fixes the user picks. Contradictions and gaps the sources cannot settle go into `open-questions.md` with an `Ask:` line naming who would know. A page you create gets the step 2 check, with the brief narrowed to that page, before you finish. Add a `lint` entry to `log.md` with the number of findings per kind and how many were fixed, filed, or declined, and commit.

Done when every finding is fixed, filed in `open-questions.md`, or declined by the user, and `wiki_check.py` reports nothing the user chose to fix.
