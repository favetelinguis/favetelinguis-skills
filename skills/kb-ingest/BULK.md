# Bulk ingest

Bulk ingest takes a corpus of hundreds of sources through clean, triage, extract, and reduce, with three human **gates**: the user approves the rubric before triage, decides the maybes after the audit, and approves the topics before reduce. It spans sessions, so every stage leaves its state in files, and you keep your own context for coordination: subagents read the sources, you read their reports.

## Resume

Find the first stage whose state is unfinished and start there:

| Stage | Finished when |
|---|---|
| 1. Clean | every original source in `kb/raw/` has cleaned text and a ledger row |
| 2. Calibrate | `kb/rubric.md` says `Status: approved` |
| 3. Triage | `ledger.py list --verdict pending` prints nothing |
| 4. Audit | `log.md` has a passing audit entry, recording the maybe decision, after the last triage |
| 5. Map | every `relevant` row (and every maybe the user chose) is extracted, and the last snowball promoted nothing |
| 6. Topics | `SCHEMA.md` Topics lists approved topics |
| 7. Reduce | every extracted row is reduced |

On a fresh start, open one issue for the bulk ingest in the issue tracker the session's instructions name for the Home Repo (its `AGENTS.md`, or the user's global instructions) when that tracker is set up there, and link it from an `ingest` entry in `log.md`. With no tracker named, `log.md` alone is the record.

## 1. Clean

Clean every raw file as `cleaning/<kind>.md` says, then register the cleaned files: `ledger.py register kb/raw/<kind>/*.txt --date-pattern '<regex>' --fallback <mtime|undated>` with the date rule from `SCHEMA.md`.

Done when `ledger.py counts` totals the number of original sources (not their cleaned text).

## 2. Calibrate

The Purpose says what the user needs; the **rubric** says what that sounds like in this corpus. Calibration reverse-engineers it from a sample.

1. Draw the sample: `ledger.py list --sample 25 --seed <today as YYYYMMDD>`.
2. Dispatch five capable subagents, five sources each. Brief: "Read these cleaned sources in full: <paths>. The user's Purpose is: <Purpose>. Report the corpus as it is: the services, tools, teams, and acronyms named; recurring practices; the kinds of session (demo, Q&A, incident walkthrough, admin chatter); the speakers' roles. Then map it to the Purpose: which of these serve the Signal, which are Noise, each with one example as `<stem>@<locator>`. Under 400 words."
3. Draft `kb/rubric.md` from the reports in this form:

   ```
   # Rubric

   Status: draft

   ## Signals

   - **<Name>**: <what it is and why the Purpose needs it>. Terms: `<term>`, `<term>`. Example: <stem>@<locator>.

   ## Anti-signals

   - **<Name>**: <what it is and why it is noise>. Terms: `<term>`. Example: <stem>@<locator>.

   ## Session kinds

   - **<Kind>**: <how to recognise it>; usually <relevant | maybe | skip>.

   ## Log

   - <date>: drafted from a sample of 25.
   ```

   Terms are what `rubric_hits.py` counts: distinctive words and names, not common verbs.
4. **Gate.** Show the user the rubric and ask them to approve it. Revise until they do, then set `Status: approved <date>` and commit.

Done when the user has approved the rubric.

## 3. Triage

1. Get the queue with hit counts: `rubric_hits.py kb/rubric.md $(ledger.py list --verdict pending)`.
2. Split it into batches of about 20 and dispatch a cheap triage subagent per batch, as many at once as the harness allows. Brief: "Triage each source below against the Purpose and the rubric in `kb/rubric.md`. The Purpose is: <Purpose>. For each source read the title, the first 40 lines, and three evenly spaced passages of 20 lines (a source under 100 lines: read it whole); the counts beside each path show which rubric entries the file hits and how often (`!` marks an anti-signal). Return one line per source, tab-separated: `<source>` exactly as given, `relevant | maybe | skip`, a one-line reason naming the rubric entries or session kind it rests on. Sources: <hit count lines>."
3. Save each batch's lines to a file and apply them: `ledger.py set --from <file>`. Re-dispatch any source a batch left out.

Done when no row is pending.

## 4. Audit

A cheap model can quietly drop good material, so a capable one checks the skips before anything is extracted.

1. Draw the audit sample: about 7% of the skips, at least 10 (every skip, when there are fewer), with `ledger.py list --verdict skip --sample <n> --seed <today>`.
2. Dispatch capable subagents in batches of five. Brief: "Read each source in full against the Purpose (<Purpose>) and `kb/rubric.md`. Each was triaged `skip`. Return per source, tab-separated: `<source>`, `agree | disagree`, and for a disagreement what it holds for the Signal and which signal or term the rubric is missing."
3. Set each disagreement's verdict to `relevant` or `maybe` with the auditor's reason.
4. If more than one in ten disagree, the rubric is missing something: add the missing signals and terms with a Log line, reset every remaining skip with `ledger.py set $(ledger.py list --verdict skip) --verdict pending --reason "re-triage: rubric <date>"`, and return to step 3, Triage.
5. **Gate.** Show the user the counts (`ledger.py counts`) and a few `maybe` reasons, and ask them to choose: extract the maybes too, have a capable model re-triage them into relevant or skip, or leave them.
6. Add an `ingest` entry to `log.md`: `audit passed, <k> of <n> disagreed; maybes: <the choice>`.

Done when an audit passes and the user has chosen what happens to the maybes.

## 5. Map

Work in waves of about 50 relevant sources, so each wave's new terms sharpen the triage of the rest.

1. Dispatch capable subagents, about three sources each. Brief: "Read [EXTRACT.md](<absolute path to EXTRACT.md>) and call the Skill tool with "kb". The Purpose is: <Purpose>. Write one extract per source: <paths with their recorded dates>. Write only those extract files. Return the extracts written and their **New terms** sections."
2. Mark the wave: `ledger.py mark <sources> --extracted`.
3. **Snowball.** Add the wave's new terms to the rubric, each under its signal (or as a new signal), with a Log line. Keep only distinctive names (`ledgerd`, `PaymentsLatencyHigh`, `Atlantis`); words common to any session (`main`, `pods`, `app`) match everything and promote noise. Search the skips for them: `rubric_hits.py --terms "<new terms>" $(ledger.py list --verdict skip)`. Promote every hit to `maybe` with the reason `promoted: <terms>`, triage the promoted rows again as in stage 3 with the updated rubric, and add the new `relevant` rows to the next wave.

Done when every relevant row (and every maybe the user chose) is extracted, and the last snowball promoted nothing; with no rows left for a next wave, map is over.

## 6. Topics

1. Dispatch one capable subagent. Brief: "From the extracts in `kb/extracts/`, propose the topics a wiki for this Purpose needs: <Purpose>. Start from the candidate headings (`rg --no-filename '^## ' kb/extracts | sort | uniq -c | sort -rn`) and the summaries. Propose a handful of topics, three to eight. Topics are subject areas; the page types in `kb/SCHEMA.md` are the kinds of child pages inside them, not topics. Give each topic its scope, the candidate headings it gathers, and the child pages it will likely need. Every frequent heading lands in exactly one topic (the one holding most of its claims) or is named as noise."
2. **Gate.** Show the user the topics and ask them to approve them. Revise until they do.
3. Write the approved topics into the Topics section of `SCHEMA.md`, each entry naming the headings it gathers, and commit.

Done when the user has approved the topics and `SCHEMA.md` lists them.

## 7. Reduce

1. Dispatch one capable subagent per topic. Brief: "Read [REDUCE.md](<absolute path to REDUCE.md>) and call the Skill tool with "kb". Build the topic <Topic entry from SCHEMA.md> as `kb/wiki/<topic>.md` and its children under `kb/wiki/<topic>/`, from the extract sections headed <headings>, plus any claim elsewhere in the extracts that falls in this topic's scope. The other topics are <the other Topic entries>: write only claims in your own scope, and link to their hubs for the rest. The reader is: <Role and Goal>. Write only those pages."
2. Write the returned open questions into `open-questions.md`, merging those that ask the same thing. Drop unplaced claims that another topic's pages already hold, and show the user the rest: place them in a topic, or let them go.
3. Rebuild `index.md` from the pages written (each page's title and the first sentence of its lead), run `wiki_check.py` from the `kb` skill and fix what it reports, mark every extracted source `--reduced`, add an `ingest` entry to `log.md` with the counts, and close the bulk ingest issue if there is one.

Done when every extracted row is reduced, `index.md` lists every page, and `wiki_check.py` reports clean. Recommend `/kb-lint` as the next step.
