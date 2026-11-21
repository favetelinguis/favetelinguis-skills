---
name: setup-llm-wiki
description: Set up a persistent LLM-maintained wiki and its agent instructions.
disable-model-invocation: true
argument-hint: "[wiki location or subject]"
---

# Setup LLM Wiki

Set up [Karpathy's LLM wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): immutable raw sources, a persistent agent-maintained wiki, and an agent instruction file encoding ingest, query, and lint. The installed wiki must work without this skill or any other skill.

## 1. Explore

Identify the wiki root from the argument or conversation; default to the current directory. Inspect that root, its existing `AGENTS.md` and `CLAUDE.md`, and any `raw/`, `wiki/`, or existing knowledge-base instructions. Identify which instruction files the current harness loads for the wiki root and the directory where sessions normally start, including any existing pointer between those files. Inspect git status, tracked files under the proposed paths, and remotes if the root is in a git repo.

If a knowledge base or its instructions already exist, show what overlaps. Do not migrate it or layer a conflicting workflow over it: ask whether to choose another root or make a specific, approved integration. Preserve existing sources, pages, instructions, and unrelated changes.

Done when the root, active instruction file, existing content, and conflicts are known.

## 2. Agree the setup

Propose the defaults: `raw/` and `wiki/` at the wiki root; source, entity, concept, and comparison pages under `wiki/`; an `index.md` and append-only `log.md`; one source at a time with the user involved. Ask the user to confirm:

- The wiki's subject and purpose, and any page types or naming conventions the subject needs.
- The root, where sessions will start, and the active instruction file. If `CLAUDE.md` already points to `AGENTS.md`, put the workflow in `AGENTS.md`. Otherwise put it in the file the harness loads; if both files need to serve agents, put the workflow in one and add a pointer from the other. For a nested wiki, ensure an instruction file loaded where sessions start points to the workflow, or agree that sessions must start in the wiki root.
- How source files will be added and whether any existing files should be copied into `raw/` now. Ingesting them is a separate operation.
- Whether sensitive raw sources, generated pages, and log entries may be stored in this location or tracked by git, and the rule future operations should follow. Inspect the remote's visibility if possible; an unknown or private remote is not proof that publishing is safe. Ignore rules do not protect files already tracked or remove their history: report any such files and agree on a safe path before writing. Do not copy sensitive sources, change ignore rules, commit, or push without approval.

Show the intended paths and any changes to existing instructions. Ask for the user's choice where paths or instructions conflict; do not overwrite existing files. If an approved integration would require reconciling incompatible workflows, agree the reconciliation before writing.

Done when the user has confirmed the subject, paths, instruction file, privacy choices, and any integration.

## 3. Scaffold

1. Adapt [AGENTS-TEMPLATE.md](AGENTS-TEMPLATE.md) to the agreed subject, paths, page types, and privacy policy, preserving all three layers and the ingest, query, and lint workflows. State the wiki root and make every path unambiguous from the instruction file, including when the wiki is nested. Write the workflow into the active instruction file, adding or updating only the approved wiki section when the file already exists. Add any agreed pointers from other instruction files. The resulting instructions must be self-contained, not point back to this skill.
2. Create `raw/`, `wiki/sources/`, `wiki/entities/`, `wiki/concepts/`, and `wiki/comparisons/`, or the agreed equivalents. Put a `.gitkeep` in an otherwise empty directory if it needs to be tracked. Create `wiki/index.md` with a title and empty categories, and `wiki/log.md` with a title and an `init` entry. Preserve existing files; merge only the changes the user approved.
3. Copy only approved sources into `raw/` without altering the originals or overwriting files there. Preserve file metadata where possible and record each source's original location and known date in the init log, subject to the agreed privacy policy. Apply any approved ignore rules. Leave sources uningested until the user asks.

Done when every agreed path exists, the instruction file contains the complete workflow with correct paths, the index and log are usable, and existing content is preserved.

## 4. Verify and hand off

Read the resulting instruction section, pointers, index, and log back. Check that the workflow is discoverable from the agreed session start, each path resolves to the intended location, and a fresh agent can ingest a source, answer with citations, review and verify an answer before filing, and lint without this skill. Report any incomplete or conflicting part and fix it before finishing.

Show the user the files created or changed and any sources copied. Explain how to ask the agent to ingest a source, query the wiki, and lint it. Git, Obsidian, and a search tool such as `qmd` are optional; install or configure none without the user's request. Commit or push only if the user explicitly asks.
