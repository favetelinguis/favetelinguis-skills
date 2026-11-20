---
name: kb-init
description: Set up a knowledge base in the current Home Repo, focused on a fixed Purpose.
disable-model-invocation: true
argument-hint: "[what you are working on and the goal, if not already in AGENTS.md]"
---

Set up a knowledge base in the current Home Repo: a fixed **Purpose** in its `AGENTS.md`, settings in `kb/SCHEMA.md`, and an empty `kb/` ready for `/kb-ingest`. Call the Skill tool with "kb" first: it defines the layout, claims, and pages this skill sets up.

## 1. Find the Home Repo

The Home Repo is the git repo the session runs in. Find the file the harness loads at session start (`AGENTS.md`, or `CLAUDE.md` for Claude Code; when `CLAUDE.md` only points at `AGENTS.md`, use `AGENTS.md`). Create `AGENTS.md` if there is none.

If that file already has a **Knowledge base** section with a Purpose, stop. The Purpose is fixed: tell the user that a different goal gets its own Home Repo, where the same raw sources can be copied and triaged against that Purpose. If the section exists but `kb/SCHEMA.md` does not, resume at step 3 with the Purpose as written.

Done when you know the file to write, and that it holds no Purpose yet.

## 2. Settle the Purpose

The Purpose has five fields:

- **Role**: who the user is in this work.
- **Goal**: what they must be able to do, phrased as an outcome ("run on-call for the platform alone").
- **Horizon**: by when, and for how long the knowledge base must serve.
- **Signal**: the kinds of knowledge that move them toward the goal.
- **Noise**: what to drop, even when it is true and interesting.

Draft every field from what is already known: the argument, the conversation, `AGENTS.md` and those repos it points at that are on disk. When every field is clear, show the draft and ask the user to confirm it as the Purpose. When any field is unclear, call the Skill tool with "grilling" and grill only the unclear fields.

Done when the user has confirmed all five fields, worded as they will be written.

## 3. Settle the settings

Look up what you can first: where the user's sources sit now and a sample of their filenames (does a date sit in them?) and modification times, the Home Repo's remote and its visibility (`git remote -v`, then the forge's CLI), and the models the harness can dispatch subagents on. Then put the remaining decisions to the user in grilling-style rounds, each with your recommendation:

- **Source kinds** and their raw folders under `kb/raw/` (`transcripts` for VTT, `pages` for Confluence or wiki exports, `conversations`), and which of the user's sources to copy in now.
- **Recorded date rule**: the regex that finds a date in a filename (three groups for year, month, day, or one group for the whole date); the fallback, `mtime` when file times look like recording times, `undated` when they look like an export or copy (most files share one time, or the times postdate the dates in filenames).
- **Raw in git**: committed when the remote is private or there is no remote, gitignored when the remote is public.
- **Models**: a cheap one for triage, a capable one for calibration, audit, map, and reduce, named as the harness's subagent dispatch accepts them.
- **Language** of the wiki (recommend English, quotes kept in the original).
- **Domain page types** beyond the core, proposed from the Purpose (for a platform handover: services, runbooks, decisions, people).
- **External sources** that `/kb-ingest` may search to resolve open questions (Confluence spaces, wiki URLs, and how the agent reaches them).

Done when every setting has a decided value.

## 4. Scaffold

1. Append the Knowledge base section to the file from step 1:

   ```
   ## Knowledge base

   Purpose (fixed):
   - Role: ...
   - Goal: ...
   - Horizon: ...
   - Signal: ...
   - Noise: ...

   The knowledge base lives in `kb/`, set up by `kb/SCHEMA.md`. For any question about <a short phrase naming the Goal's domain>, call the Skill tool with "kb" and read `kb/wiki/index.md` first.
   ```

2. Write `kb/SCHEMA.md` from [SCHEMA-TEMPLATE.md](SCHEMA-TEMPLATE.md) with the decided settings, leaving the Topics section with its one line of explanation.
3. Create `kb/raw/<kind>/` and `kb/extracts/<kind>/` for each source kind, each holding a `.gitkeep`, and `kb/wiki/` holding `index.md` (`# Index`), `open-questions.md` (`# Open questions`), and `log.md` (`# Log`, then an `init` entry). Copy in the sources the user chose with `cp -p`, so modification times survive. When raw stays out of git, add `kb/raw/` to `.gitignore` (the cleaned text beside each source stays out with it).
4. Commit in the Home Repo. Pushing is the user's call.

Done when the section, `SCHEMA.md`, and every folder and file above exist and are committed. Tell the user to add any further sources to `kb/raw/<kind>/` and run `/kb-ingest bulk`.
