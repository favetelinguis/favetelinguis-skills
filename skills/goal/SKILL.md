---
name: goal
description: Before any design, find the real goal behind an ask, research existing work and routes, sweep for obstacles, and publish a goal brief.
disable-model-invocation: true
argument-hint: "[the ask, a tracker issue reference, or a goal brief to resume]"
---

A raw **ask** has arrived (a vague work ticket, "add a CSV export", a half-formed idea of your own). It names a solution, rarely the **goal** behind it. This skill runs first, before `grill-with-docs` or `wayfinder`, and works in **goal-oriented requirements engineering** (KAOS, i\*): it climbs from the ask to the goal, chooses a route among the alternatives, sweeps that route for obstacles, and publishes a **goal brief** the design flow starts from.

Keep every question at the level of the goal. A design question (module, schema, API) goes straight into the brief's open questions for the next skill.

## Vocabulary

Established techniques, used by name. Each line carries only how this skill applies it.

- **Requirement smells**: check the ask against the ISO/IEC/IEEE 29148 characteristics of a well-formed requirement (necessary, implementation-free, unambiguous, complete, singular, feasible, verifiable). Each failure is a smell.
- **5 Whys**: ladder up from the ask. Stop at the first rung that is solution-free (two or more different routes could meet it) and that the requester would recognise as their reason.
- **KAOS goal patterns**: state the goal as Achieve, Maintain, Avoid, or Cease [condition].
- **Quality attribute scenario** (SEI): the form of a success measure that is a quality, with a number in its response measure.
- **OR-refinement**: the alternative routes to one goal. Always include the ask as it came in, reuse of existing work, a non-software route (process, configuration, policy), and do nothing.
- **Softgoals and contribution links** (i\*, NFR framework): the quality concerns (cost, time, risk, maintenance, the success measure's qualities) and how each route helps or hurts each one.
- **Obstacle analysis** (KAOS): for the goal and each part of the chosen route, what could stop it. Prompt it with the **HAZOP guide words** (no, more, less, as well as, part of, reverse, other than, early, late, before, after), then the three concerns they miss: access, concurrency, and legacy data or callers.
- **Requirement or expectation** (KAOS responsibility assignment): what the system must ensure is a requirement; what the world outside it must ensure is an expectation, and an expectation names who confirms it. An obstacle resolves to one of these, an **accepted risk** (with its reason), or **out of scope**.
- **RACI**: every decision has one **Accountable** owner. **Mine** when the human is accountable (technical calls, their own preferences); **theirs** when someone else is (business rules, priorities, policy, budget, scope). For a theirs decision the human gives a **working assumption**, recorded as unconfirmed under the owner's name.

## The goal brief

The brief is a single issue on this repo's issue tracker, labelled `goal:brief`, titled `Goal: <short goal title>`, with the body in [GOAL-BRIEF-FORMAT.md](GOAL-BRIEF-FORMAT.md). It is the canonical record of the goal: assets made for it (research findings, a questionnaire) are linked from the issue.

**Where the brief, its links, and its assets physically live is tracker-specific.** The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-skills-with-beads`. Consult the tracker doc's "Goal operations" section for how _this_ repo expresses them.

An **open** brief is a goal still being settled: a session is under way, or theirs decisions wait on their owners. A **closed** brief is a settled goal, and the design flow works from it.

In everything the human reads, refer to a brief or issue by its **name** (its title), with the id inside the link.

## Invocation

- **A new ask** (text, or a tracker issue that is not a goal brief): run the process from step 1.
- **A goal brief**: resume it. Load the body and every comment since the last body update, mark each open question that has been answered, and present the updated picture. Re-open the frontier at the layer the answers change (step 3 for the goal, step 4 for the route, step 5 for an obstacle), then finish with step 6.

## Process

### 1. Capture the ask

Take the ask from the argument; for a tracker issue, fetch the body, acceptance criteria, and comments. Record it **verbatim**, with its source and its **requester** (the human, when the ask is their own). Read `GLOSSARY.md` (follow `GLOSSARY-MAP.md` if there is one) and `docs/adr/`.

Dispatch the **existing-work scout** in the background, with a fresh context window, and continue to step 2 while it runs. Its brief:

"Find existing work related to this ask: <ask verbatim>. Search the codebase by domain concept, beyond the ask's own wording; search the issue tracker (open and closed issues, specs, wayfinder maps, goal briefs); read `.out-of-scope/`, `docs/adr/`, and `GLOSSARY.md`. Report what already does this or part of it, what was tried or rejected before and why, and the decisions and constraints that bear on it, each with a file:line or issue reference. Under 400 words."

Done when the ask is recorded verbatim with source and requester, and the scout is running.

### 2. Open the interview

Call the Skill tool twice, for "grilling" and "domain-modeling". On top of grilling:

- **The design tree is a goal tree.** Steps 3 to 5 are its layers, in order: a question joins the frontier once the layer above it is settled.
- **Every question carries its RACI tag**, mine or theirs. When the owner is unclear, the first question is who is accountable.

Seed round 1 with the ask's **requirement smells**.

Done when every smell is a round 1 question or explained by something you looked up.

### 3. Climb to the goal

Run the **5 Whys** from the ask, writing each rung down. State the top rung in a **KAOS goal pattern**, with **so that** [the rung above it] and a **success measure** the requester could observe (a **quality attribute scenario** when it is a quality).

As soon as the goal is stated, call the Skill tool with "research" to find the routes in the background: "Established ways to <goal>: existing libraries, products, services, standard patterns, and prior art, each with its trade-offs and adoption cost."

Done when the goal has one KAOS pattern, a so-that, and a measurable success measure, and the human accepts it as what they actually want (or, for a theirs goal, holds it as a working assumption).

### 4. Choose the route

Build the **OR-refinement** from the scout's findings, the research, and your own analysis. Present it as a table of routes against **softgoals**, each cell a contribution (helps, hurts), with your recommendation. The choice is theirs whenever it changes cost, scope, or what the requester gets.

When **do nothing** or **reuse** wins, skip to step 6.

Done when one route is chosen (or held as a working assumption) and each rejected route has a one-line reason.

### 5. Sweep for obstacles

Run **obstacle analysis** on the chosen route, through every guide word and concern. Resolve each real obstacle as a **requirement**, an **expectation**, an **accepted risk**, or **out of scope**.

Done when every guide word and concern has been applied, every obstacle found has one resolution, and grilling's frontier is empty.

### 6. Publish the goal brief

Write the body following [GOAL-BRIEF-FORMAT.md](GOAL-BRIEF-FORMAT.md) and publish it as the tracker doc's "Goal operations" section describes: create the brief for a new ask, or rewrite the body of a resumed one. Link it to the ask's source issue and link the research findings as its asset. Offer an ADR where `domain-modeling`'s three conditions hold.

Then set the brief's state and recommend the next step:

- **Theirs decisions block the route**: leave the brief open. Tell the human to run `/to-questionnaire` with the brief for the accountable owner, link the questionnaire from the brief, and rerun `/goal` on the brief once the answers are in.
- **The way is clear and fits one session**: close the brief. Tell the human to run `/grill-with-docs` with the brief.
- **The route is large or foggy**: close the brief. Tell the human to run `/wayfinder` with the brief; its goal and route become the map's Destination.
- **Do nothing or reuse won**: close the brief with the reason, and draft the message that explains it to the requester.

Done when the brief exists with every section filled or marked "None", its state matches the branch, and the human has its name and the next step.
