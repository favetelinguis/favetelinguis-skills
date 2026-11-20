# Extract

An **extract** is the claims one relevant source offers the Purpose, pulled out once so reduce never rereads the raw text. It lives at `kb/extracts/<kind>/<stem>.md`, outside the wiki and outside the index.

Read the whole cleaned source. Keep what the Purpose's **Signal** covers and the rubric's signals point at; drop what its **Noise** names, however true. Prefer the concrete: names, commands, thresholds, owners, sequences, failure modes, the reason behind a choice, and every "watch out for".

```
---
source: raw/<kind>/<file>
recorded: <date from the ledger>
---

# <stem>

<One or two sentences: what this source is and what it offers the Purpose.>

## <Candidate topic>

- <claim, self-contained, in the wiki's language> @<locator>
- "<quote in its original language>" (<speaker>) @<locator>

## New terms

- `<term>`: <what it names>. Signal: <rubric entry it belongs to, or "new">.

## Questions

- <something the source raises and leaves unresolved, or contradicts> @<locator>
```

- Claims carry the locator only; reduce adds the date and the link.
- A candidate topic is a short noun phrase (Services, Deploys, On-call). Reuse the topics in `SCHEMA.md` when it has them, and the headings of other extracts when you have seen them.
- **New terms** are names the rubric does not yet list (a service, a tool, a team, an acronym) that point at Signal. They feed the rubric's snowball.

Done when every passage of the source that bears on the Signal has a claim, and every claim has a locator.
