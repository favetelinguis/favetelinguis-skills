# Reduce

**Reduce** turns extract claims into wiki pages that follow the `kb` skill's conventions: one topic's hub and its children, or the pages one new source touches.

1. Read the target pages and every extract claim for them. Find claims with `rg -n '^## <Topic>' kb/extracts` and the headings of near synonyms.
2. Write each claim in the `kb` claim form: the source's `recorded` date from the ledger, the claim, and a link to the cleaned raw file with the locator. Merge claims that say the same thing into one bullet citing every source, dated with the newest. A claim that belongs on another topic's page gets a link to that page in place of a copy.
3. Order a page for the reader the Purpose names: what it is, how it works, how to operate it, what goes wrong. A sequence of steps becomes a numbered list with the citations on its steps.
4. When claims change over time, keep both and end the older with `Superseded on <date>.` When they conflict and dates do not settle it, keep both and return the conflict as an open question.
5. Split a page past about 2000 words into child pages under `<topic>/`, keeping the hub as a summary linking every child. Link related pages in `Related:` lines.

Return the pages written, the open questions raised (in the `open-questions.md` form), and any claim that fits no page, so the caller can update `index.md` and `log.md`.

Done when every claim given to you is on a page, merged into another, superseding one, or returned as unplaced.
