## LLM wiki

Purpose: <subject and purpose>

Wiki root: <path to the wiki root, resolved relative to this instruction file>. All paths below are relative to the wiki root, regardless of the session's current directory.

Privacy: <agreed rules for storing, tracking, and sharing raw sources, generated pages, and log entries>. Apply these rules before ingesting, filing, or recording an operation; ask the user when the status of a source is unclear.

This wiki is a persistent synthesis of the sources, maintained by the agent and read by the user. The user curates sources, guides emphasis, and asks questions; the agent maintains the pages and their connections. For any request to ingest a source, query this subject, file an answer, or lint the wiki, follow the corresponding operation below.

### Layers

- `raw/`: curated source documents, the evidence behind the wiki. Read them and leave them unchanged. Copy new sources here without overwriting an existing source. Sources can be mistaken or disagree.
- `wiki/`: agent-maintained Markdown: source summaries in `sources/`, entity pages in `entities/`, concepts in `concepts/`, and comparisons or other synthesis in `comparisons/`. Update existing pages and their cross-references as knowledge changes.
- This section: the schema and workflows for maintaining the wiki. Adapt it with the user as the wiki evolves.

Use readable Markdown links between pages and back to sources, with a heading or other locator where possible. Attribute claims to their sources; distinguish source claims, inference, uncertainty, and open questions. Preserve disagreements and their provenance instead of silently choosing a winner. Use the source date when relevant, rather than treating ingestion order as evidence of recency.

### Index and log

`wiki/index.md` is the content catalog: list each content page by category with a link and a one-line summary. Update it when pages are added or changed. Read it first when navigating the wiki.

`wiki/log.md` is the chronological, append-only record of ingests, queries, and lint passes. Add entries at the end with a heading `## [YYYY-MM-DD] <operation> | <title>` and brief notes about what happened and which pages changed. Use `ingest`, `query`, or `lint` as the operation.

### Ingest

1. If the user-selected source is already in `raw/`, use it in place; otherwise copy it there without overwriting another source. Preserve its content and retain its origin and date when available in the source summary or log, subject to the privacy rules. Distinguish file timestamps from a source's actual date. Read it; if it cannot be read fully, report the limitation rather than pretending it was processed. Discuss key takeaways and emphasis with the user.
2. Write a source summary in `wiki/sources/`, linked to the raw source. Find existing relevant pages via the index and search. Create or update entity and concept pages, add cross-links, and integrate the evidence into any affected summaries and synthesis. Cite the source at the relevant claims.
3. Flag contradictions, stale claims, and unresolved questions with their sources. Retain meaningful earlier evidence when later evidence changes the synthesis. Update the index and append an ingest entry to the log listing the source and pages touched.

Ingest one source at a time with the user by default; batch only when requested. Done when the source is represented in the wiki, affected existing pages and links are updated, and the index and log reflect the ingest.

### Query

1. Read the index, then the relevant wiki pages. Consult raw sources when needed to verify claims or fill gaps. Answer the user's question with citations to the supporting pages and sources, distinguishing gaps and uncertainty from supported conclusions.
2. Append a query entry to the log. If the answer contains a useful comparison, analysis, or connection, offer to file it as a page or an update to an existing page.
3. Before filing, trace every factual claim in the proposed page to its raw sources and verify that they support it. Cite those sources at the claims and distinguish inferences, disagreements, and gaps. When a source cannot be checked or a claim is unsupported, tell the user and label it unverified or leave it out.
4. Show the proposed page or update to the user and ask whether it is correct. Incorporate their corrections, verify any changed claims against the raw sources, and show the revised proposal for approval. If a correction lacks supporting evidence, ask for a source or label it as the user's unverified observation; do not present it as a verified source claim. Write only the approved version, update its links and the index, and append a query entry recording the filing. If the user declines, leave the content pages unchanged.

Done when the answer is traceable to evidence, gaps are named, and any filing has been checked, reviewed, approved, and integrated.

### Lint

Inspect the index and wiki for contradictions, stale or superseded claims, orphan pages, missing or broken cross-references, important concepts without pages, and gaps worth investigating. Check claims against their sources where needed. Report findings with affected pages and propose repairs or sources to investigate. Make agreed repairs, preserve the provenance of changes, update the index as needed, and append a lint entry to the log.

Done when the findings and any agreed repairs are recorded, with unresolved gaps made visible to the user.
