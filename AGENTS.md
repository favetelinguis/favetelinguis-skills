# Personal skills

This repo holds personal skills and the selection of upstream skills that get installed into `~/.agents/skills`. Personal skills are mostly **specializations** of upstream workflows (Matt's `engineering/` and `productivity/` skills first of all) for personal repositories and conventions.

## Layout

- `skills/<name>/`: personal skills. This is the only place to write skills.
- `vendor/<source>/`: upstream skill repos as git submodules, each pinned to a commit. Currently `vendor/matt` (`mattpocock/skills`), `vendor/pstack` (`backnotprop/pstack`, the standalone mirror of `cursor/plugins/pstack`), and `vendor/addy` (`addyosmani/agent-skills`).
- `skills.conf`: which skills get linked, one `<source>:<path>` entry per line (`self:skills/explain-diff`, `matt:skills/engineering/tdd`, `pstack:skills/unslop`). `self` is this repo; any other source is `vendor/<source>`.
- `link-skills.sh`: links every `skills.conf` entry into `~/.agents/skills`, and the executables in its `scripts` array from `scripts/` into `~/.local/bin`.
- `update-vendor.sh`: moves submodules to the newest upstream commit and shows what changed.
- `scripts/`: personal executables (`wt-review`).

**Ownership.** Everything under `vendor/` is upstream and read-only: never edit, commit, or stage files inside a submodule. When a personal skill needs an upstream skill to behave differently, carry that change in the personal skill (see below), and leave the upstream file as the submodule delivers it.

## Writing personal skills

Write each one as if it shipped beside its base skill: same structure, same rules as its source repo's `AGENTS.md` (for Matt that is `vendor/matt/AGENTS.md`) except where this file says otherwise, and the voice of the upstream skills nearest to it (read two or three before drafting).

A specialization carries only the **delta** from its base skill: the repositories, tracker, and conventions that make the upstream workflow fit this use case. The base keeps owning everything else, so an upstream bump still improves the personal skill.

Pick the lightest form that carries the delta:

1. **Configuration.** When the base skill already reads personal config (tracker locations, triage vocabulary), put the delta in that configuration, not in a skill.
2. **Wrapper.** When the base is model-invoked, call the Skill tool with it and add only the personal steps before or after.
3. **Fork.** When the base is user-invoked, the Skill tool cannot reach it (see `vendor/matt/.agents/invocation.md`). Copy its steps, change only what the delta demands, and name the base on the first line under the title in `skills.conf` form (`` Specializes `matt:skills/engineering/to-tickets`. ``) so drift against upstream is easy to spot.

Match the base's invocation unless the delta changes who should reach the skill. A skill with no base is fine; it still reaches upstream skills through the Skill tool wherever one fits, as long as that upstream skill is linked in `skills.conf`.

How personal skills differ from Matt's promoted ones:

- **Not promoted.** No `.claude-plugin/plugin.json`, no `docs/` page, no entry in `ask-matt`.
- **README.** List each personal skill in `README.md` as a flat list with a one-line description, the name linked to its `SKILL.md`.
- **Names.** Give each skill a name distinct from every linked skill unless the human explicitly requests otherwise. Links are named after the skill folder, and `link-skills.sh` refuses two entries with the same folder name.
- **Install.** Add `self:skills/<name>` to `skills.conf`, then run `./link-skills.sh`.
- **Prose.** No em-dashes anywhere (skills, README, comments). Rewrite the sentence with a comma, colon, period, parentheses, or a conjunction instead of substituting a character.

## Choosing skills

Edit `skills.conf`, then run `./link-skills.sh`. Removing or commenting out an entry unlinks it on the next run. The script refuses two entries that would link under the same name: pstack and Matt both ship `tdd` and `teach`, so pick one of each. Before linking an upstream skill that calls other skills, check its source's README and link those too (pstack's README has a table of which skills depend on which).

## Submodules

Submodules pin each upstream to an exact commit, so an upstream change reaches the installed skills only when a commit here bumps it.

Clone this repo, or pull it on another machine:

```bash
git clone --recurse-submodules git@github.com:favetelinguis/favetelinguis-skills.git
git pull && git submodule update --init --recursive   # after a pull, move submodules to the pinned commits
git config --global submodule.recurse true            # optional: make plain `git pull` do that too
```

Update an upstream:

```bash
./update-vendor.sh            # every submodule; or ./update-vendor.sh pstack
```

It runs `git submodule update --remote`, prints the incoming upstream commits, a diffstat limited to the skills `skills.conf` links from that source, and a warning for any linked skill that no longer exists upstream. It does not commit. The installed links point into `vendor/`, so the new files are live as soon as it finishes. Then either:

- **Keep it:** read the diff of the linked skills (`git -C vendor/pstack diff <old> <new> -- skills/unslop`), fix `skills.conf` if anything was renamed or removed, check that any personal fork named in a `Specializes` line still matches its base, then `git add vendor && git commit -m "Bump pstack"` and rerun `./link-skills.sh`.
- **Roll back:** `git submodule update vendor/<name>` returns the checkout to the pinned commit.

Add a new upstream:

```bash
git submodule add https://github.com/<owner>/<repo>.git vendor/<name>
git config -f .gitmodules submodule.vendor/<name>.branch main
```

Then add `<name>:<path>` entries to `skills.conf`, list the source under Layout above and in `README.md`, run `./link-skills.sh`, and commit `.gitmodules`, `vendor/<name>`, and `skills.conf` together.

Remove an upstream: delete its entries from `skills.conf`, run `./link-skills.sh` (which unlinks them), then `git rm vendor/<name>` and commit.

In `git status`, `modified: vendor/<name> (new commits)` means the checkout no longer matches the pinned commit: commit it or roll it back, as above. `vendor/<name> (modified content)` means someone edited files inside a submodule; discard that with `git -C vendor/<name> checkout -- .`, since vendor is read-only.
