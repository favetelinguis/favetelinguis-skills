# Goal brief format

A goal brief is the output of `goal`: one issue on the tracker, titled `Goal: <short goal title>`, with the body below. It is read by the human, by the requester, and by the next skill in the flow, so write it in the domain language from `GLOSSARY.md` and leave out implementation detail.

Keep each section short. A section with nothing in it says "None". Refer to other issues by name, with the id inside the link.

## Body template

```markdown
## Ask

> <the ask, verbatim>

**Source:** <issue reference, message, or "own idea">. **Requester:** <person or role>.

## Goal

**<Achieve | Maintain | Avoid | Cease> [<condition>]**, so that <the rung above>.

**Success measure:** <the observation that shows the goal is met; a quality attribute scenario where it is a quality>.

**5 Whys:** <ask> → <rung> → <rung> → <goal>.

## Existing work

- <what already exists or was tried, with file:line or issue reference, and what it means for this goal>

## Routes considered (OR-refinement)

| Route | Helps (softgoals) | Hurts (softgoals) | Decision |
| --- | --- | --- | --- |
| <the ask as it came in> | <concerns> | <concerns> | <chosen, or rejected: one-line reason> |
| <reuse> | | | |
| <non-software route> | | | |
| <do nothing> | | | |

Research: <link to the research findings, the asset linked from this brief>.

## Chosen route

<one or two sentences: what will be done, at the level of the goal, not the design>

## Obstacles

| Obstacle | Resolution | Note |
| --- | --- | --- |
| <what could stop the goal> | <requirement / expectation / accepted risk / out of scope> | <the reason; for an expectation, see Expectations> |

## Expectations

What the world outside the system must ensure for the route to work.

- <expectation>. **Accountable:** <who confirms>. **Status:** <confirmed / unconfirmed>.

## Open questions

| Question | Accountable | Working assumption |
| --- | --- | --- |
| <question, including design questions for the next skill> | <mine / theirs: name or role> | <the human's assumption, or "None"> |

## Out of scope

- <what was ruled out, and why>

## Next step

<the recommended next skill or action, and why>
```
