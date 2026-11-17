---
name: dotfiles
description: Install personal dotfiles on this machine.
disable-model-invocation: true
---

# Dotfiles

## Install Emacs

Install copies of [`resources/emacs/`](resources/emacs/) as `~/.emacs.d/early-init.el` and `~/.emacs.d/init.el`, the default Emacs configuration. Leave `custom.el`, runtime data, packages, credentials, and `local_only/` on the machine untouched.

1. Check for Emacs 31 and Git. Report missing prerequisites and explain that Elpaca needs network access on first startup; ask before installing software or starting a network operation. Inspect the destination and compare each resource with its counterpart. Treat symlinks, non-regular files, and a symlinked destination directory as conflicts, not as files to follow. Check for `~/.emacs.el`, `~/.emacs`, `~/.emacs.elc`, and `~/.emacs.d/{early-init,init}.elc`, which can take precedence over the installed files.
2. Show the user which files are new, identical, or conflicting. Ask before replacing any conflicting file. If an existing destination is a symlink or not a directory, an existing target is a symlink or not a regular file, or a competing init file exists, stop and ask the user to resolve it.
3. Create the destination if needed. Leave identical files alone. Before replacing approved, differing regular files, copy them with their metadata into a new uniquely named backup directory under the home directory. Install new and approved files as copies, using temporary files and renaming them into place so existing hard links are not modified. Leave all other files untouched. If the user declines a replacement, leave that file untouched and report the partial install.
4. Compare every installed file with its resource and report the results and backup path, if any. Tell the user to start Emacs normally with `emacs`; startup may bootstrap Elpaca and download packages. Ghostel may ask to download its native module. The config uses `~/org-agenda`, `~/notes`, optional external tools, and the pi agent's local OpenRouter credentials for gptel; those are not installed by this skill.
