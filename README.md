# favetelinguis skills

Personal skills, plus the upstream skills they build on, installed into `~/.agents/skills` from one checkout. Upstreams are git submodules under `vendor/`:

- **[matt](https://github.com/mattpocock/skills)** (`vendor/matt`): Matt Pocock's `engineering/` and `productivity/` skills.
- **[pstack](https://github.com/backnotprop/pstack)** (`vendor/pstack`): standalone mirror of [cursor/plugins/pstack](https://github.com/cursor/plugins/tree/main/pstack). Only `unslop` is linked.

[AGENTS.md](./AGENTS.md) covers the layout, how to write personal skills, and how to update or add submodules.

Matt's upstream skills own the core development loop (`grill-with-docs` -> `to-spec` -> `to-tickets` -> `implement` / `tdd` -> `code-review` -> `retro`). The personal skills in [skills/](./skills) fill in personal tooling around it. Installed:

- **[explain-diff](./skills/explain-diff/SKILL.md)**: Explain a diff or PR in your own words, get grilled until your model matches the code, and leave with review comments. Its blind reviewer runs `code-review` (complements `code-review` and `grilling`).
- **[setup-matt-skills-with-beads](./skills/setup-matt-skills-with-beads/SKILL.md)**: Configure a repo for the engineering skills with a personal beads_rust (`br`) tracker kept out of git, wired through one block in the global `AGENTS.md` (replaces `setup-matt-pocock-skills`).

Parked (kept in the repo, commented out in `skills.conf`, not installed). They were a production check that `explain-diff` used to run; nothing calls them now, and their descriptions still assume that wiring, so update the descriptions before linking any of them again:

- **[production-readiness-check](./skills/production-readiness-check/SKILL.md)**: An independent copy of upstream `code-review` with Production and Integration axes: documented standards, the originating spec, production readiness (via `infra-and-deploy` and `observability`), and, when the diff touches an external integration, integration resilience (via `external-integration-design`).
- **[external-integration-design](./skills/external-integration-design/SKILL.md)**: Design resilient integrations with external systems and providers.
- **[infra-and-deploy](./skills/infra-and-deploy/SKILL.md)**: Trace app-to-infrastructure chains across Helm, Kubernetes, AWS, Azure, Terraform, Bicep, Docker, and CI/CD, and surface what only a live deploy can verify.
- **[observability](./skills/observability/SKILL.md)**: Instrument production code with structured logging, RED and USE metrics, OpenTelemetry tracing, symptom-based alerts, and runbooks.

## How they fit into Matt's flow

| Upstream stage | Matt's skills | How `favetelinguis` complements it |
|---|---|---|
| **Setup & Tracker** | `setup-matt-pocock-skills`, `triage`, `wayfinder` | `setup-matt-skills-with-beads` replaces upstream setup: a personal `.beads/` excluded through `.git/info/exclude`, and a beads tracker doc adding `discovered-from`, `--external-ref`, native acceptance criteria, priority, and defer |
| **Spec & Slices** | `grill-with-docs`, `to-spec`, `to-tickets` | Unchanged: specs and tickets stay focused on behaviour |
| **Build** | `implement`, `tdd`, `codebase-design`, `wizard` | Unchanged: the implementer stays lean and focused on code |
| **Review & Diagnose** | `code-review`, `diagnosing-bugs` | `code-review` stays the per-change code review; `explain-diff` runs it once more over the whole change, blind, and grills you until your model of the change matches the code |

## Linking skills

```bash
git clone --recurse-submodules git@github.com:favetelinguis/favetelinguis-skills.git
cd favetelinguis-skills
./link-skills.sh
```

[link-skills.sh](./link-skills.sh) links every entry in [skills.conf](./skills.conf) into `~/.agents/skills`. Entries are `<source>:<path>`, for example `matt:skills/engineering/tdd`, `pstack:skills/unslop`, or `self:skills/explain-diff`. Remove or comment out an entry and rerun to unlink it. New skills must be added to the list explicitly.

Running the script repeatedly is safe. It replaces selected symlinks, refuses to overwrite real files or directories, refuses two entries that would link under the same name, and only removes deselected links pointing to this checkout. Unrelated skills stay installed.

Upstreams only change when you bump them: run [update-vendor.sh](./update-vendor.sh), review what changed, and commit the new submodule commits. See [AGENTS.md](./AGENTS.md#submodules).

The same script links the executables listed in its `scripts` array from [scripts/](./scripts) into `~/.local/bin`. On macOS, add `~/.local/bin` to `PATH`; the script prints a note when it is missing.

- **[wt-review](./scripts/wt-review)**: `wt review <pr-number|branch>` opens a throwaway worktree where the whole change shows as unstaged edits, so any editor's gutter and diff view drive the review. Needs `wt` and, for PR numbers, `gh`. Finish with `wt remove --force review/<target>`.

## Mise install setup

Tools are installed with [mise](https://mise.jdx.dev). The personal config lives at `~/.config/mise/config.toml`, outside this repository. Every tool is set to `"latest"`, so `mise install` fetches the newest release.

Two tools in that config come from GitHub releases:

- **[beads_rust](https://github.com/Dicklesworthstone/beads_rust)** (`"github:Dicklesworthstone/beads_rust"`) installs the `br` binary. It is the Rust port of Beads, and it is the Beads backend these skills use in place of `bd`.
- **[abacus](https://github.com/chrisedwards/abacus)** (`"github:chrisedwards/abacus"`) installs the `abacus` terminal UI. It shows a Beads database as a tree. It reads both `bd` and `br` projects.

Common commands:

```bash
mise install   # install every tool in the config that is missing
mise ls        # show installed versions and where each one is set
mise prune     # remove installed versions that the config no longer uses
```

`mise prune` removes every installed tool that is not in the config. Run `mise prune --dry-run` first to see what it would remove.

The Herdr shortcut `prefix+f` (cmd 9) opens an `abacus` tab in the active pane's folder. If the tab already exists, it focuses that tab instead.

## License

[MIT](./LICENSE). Some personal skills are adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (`production-readiness-check` from `code-review`, `setup-matt-skills-with-beads` from `setup-matt-pocock-skills`), so the license carries Matt Pocock's copyright notice too. The submodules under `vendor/` are not part of this repo and keep their own licenses: `vendor/matt` (MIT, Matt Pocock) and `vendor/pstack` (MIT, Lauren Tan).
