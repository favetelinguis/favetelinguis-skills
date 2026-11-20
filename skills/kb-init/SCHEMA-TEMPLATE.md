# Knowledge base schema

The Purpose is the Knowledge base section of the Home Repo's `AGENTS.md`. Conventions for claims, pages, and layout come from the `kb` skill. This file holds the settings particular to this knowledge base; `kb-ingest` adds to Topics and nothing else.

## Sources

| kind | raw folder | cleaning | recorded date |
|---|---|---|---|
| transcripts | `raw/transcripts/` | vtt | filename regex `<regex>`, else `<mtime or undated>` |

## Raw in git

<committed | gitignored>, because <reason>.

## Language

Wiki in <language>. Quotes keep their original language (<source languages>).

## Models

- Triage: <cheap model, as the harness names it>
- Capable (calibration, audit, map, reduce): <model, or "session default">

## Page types

Core: topic hubs and their child pages, `index.md`, `log.md`, `open-questions.md`.

Domain types:

- **<type>**: <what one page of this type covers>. Lives under the hub `<topic>/`.

## External sources

- <name>: <what it holds>, reached by <tool or URL>.

## Topics

Filled by `kb-ingest` once the user approves the topics, one entry each in this form: `- **<Topic>** (<topic>.md): <scope>. Gathers: <extract headings>.`
