# Resolve open questions

**Resolve** works `open-questions.md` against the external sources `SCHEMA.md` lists (Confluence spaces, wiki pages, anything the agent can reach), so a gap the corpus left becomes a cited claim.

1. **Pick.** List the open questions and propose the ones worth a search now, those that bear hardest on the Purpose's Goal first. The user confirms the list.
2. **Search.** For each question, dispatch a capable subagent. Brief: "Find what answers this question: <question and its context>. Search <the external sources from SCHEMA.md, with how to reach them>. Return each source that answers it, in part or whole, as a URL with the passage that answers it, or report what you searched and that nothing answered it."
3. **Save.** Every source used is saved into `kb/raw/<kind>/` before anything cites it, as `cleaning/<kind>.md` says, so each citation can be reread later even after the page changes or disappears.
4. **Ingest.** Run each saved source through the single-source steps in `SKILL.md`, starting at triage.
5. **Update the question.** Answered: set `Status: resolved on <date>` with a link to the page holding the new claim. Partly answered: narrow the question to what is left. Unanswered: add a `Tried:` line naming the sources searched and the date, and leave it open for the person the `Ask:` line names.
6. **Record.** Add a `resolve` entry to `log.md`: questions worked, resolved, narrowed, still open.

Done when every confirmed question is resolved, narrowed, or carries a dated `Tried:` line.
