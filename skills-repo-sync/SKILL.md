---
name: skills-repo-sync
description: Author-side. Sets up a GitHub skills repo (one you write and maintain) for two-way sync across your machines with plain git, by linking every skill in a local clone into your agents' skills folders (~/.agents/skills, ~/.claude/skills, ~/.gemini/config/skills). Use when the user wants their skills repo "live" on a laptop, set up a new machine, sync skills between laptops, retire or rename a skill, or asks how to structure a personal skills repo. Not for using someone else's skills in a project; that's import-skill.
version: 1.0.0
---

# Skill: Skills Repo Sync

## Overview

For authors who keep their skills in a GitHub repo and use them every day. The
pattern is the one dotfiles use:

1. **Clone the repo** anywhere outside the agents' folders (e.g. `~/code/skills`).
2. **Link each skill** into the agents' skills folders with the repo's `install.sh`.
   The clone is then the only copy. An agent that loads `~/.claude/skills/foo` is
   reading `~/code/skills/foo`.
3. **Sync with plain git.** Edit a skill on any machine, commit, push. On the other
   machines, `git pull`, plus `./install.sh` if skills were added, renamed or retired.

**Why not clone into `~/.agents/skills/`?** Agents look for skills exactly one level
down: `<skills folder>/<name>/SKILL.md`. A repo cloned as `~/.agents/skills/my-skills/`
puts every skill two levels down, where no agent finds it, and turns the repo itself
into a broken "skill" with no SKILL.md.

**Two audiences, two mechanisms.** This skill is for the *author*: live links that edit
the source. People who only *use* the skills should import them with `import-skill`,
which copies a pinned version into a project's `.skills/imported-skills/` and can
refresh it later. A repo's README should offer both.

## Repo conventions this relies on

- A **skill** is a top-level folder containing `SKILL.md`. Only these are linked.
- Anything else at the top level (e.g. `archive/`, bundles of nested skills, docs)
  is ignored.
- **Retire** a skill by moving it into `archive/` (or deleting it). The next
  `./install.sh` on each machine removes its links.
- **Rename** = move the folder. The next `./install.sh` removes the old link and adds
  the new one.
- Every installed skill's description is loaded into every agent session. If the repo
  grows unwieldy, split it into smaller, focused repos, each with its own clone and
  `install.sh`. The script only manages links into its own repo, so several repos (and
  hand-made skills) coexist in the same skills folders.

## Workflow: set up a skills repo on this machine

1. **Find or clone the repo.** Ask for the GitHub URL if you don't know it. If there's
   no clone yet, ask where to put it (suggest a folder the user keeps code in, never
   inside a skills folder) and `git clone` it there.
2. **Make the repo self-installing.** If the repo root has no `install.sh`, copy
   `scripts/install.sh` from this skill into the repo root and make it executable.
   This lets any clone install itself without this skill. If the repo already has an
   `install.sh` that differs, show the differences and ask before replacing it.
3. **Check for conflicts first.** List the skill names in the repo and, for each agents'
   skills folder, anything already there under the same name:
   - a link into this repo: fine, it will be refreshed;
   - a link to somewhere else, or a real folder: the script leaves it alone and reports
     it. Tell the user, and offer to move a real folder aside (e.g. rename it
     `<name>.bak`) **only with their OK**, since it may hold edits not in the repo.
     Compare it with the repo's copy first.
4. **Run** `./install.sh` from the repo root. It prints how many skills it found, the
   links it set, links it removed, and anything it skipped.
5. **Confirm** an agent sees the skills, e.g. `ls -l ~/.claude/skills` shows links into
   the clone. Some agents only pick up new skills in a new session.
6. **Document it** in the repo's README if it isn't already: a short "Maintaining these
   skills" section with the clone + `./install.sh` + git sync steps, next to the
   import instructions for people who only use the skills.
7. Commit `install.sh` and the README change, and push **when the user says so**.

## Workflow: day-to-day

- **Pull changes from another machine:** `git pull` in the clone, then `./install.sh`.
- **Edit a skill:** edit it in place (through the link or in the clone; same file),
  commit, push. If the repo versions its skills (a `version:` field in front-matter),
  bump it for meaningful changes.
- **Conflicts** are ordinary git conflicts in the clone; resolve them there.
- **Remove everything from this repo:** `./install.sh --uninstall` removes only the
  links that point into this clone.

## The script

`scripts/install.sh` (copied to the repo root as `install.sh`):

| Run | Does |
|---|---|
| `./install.sh` | Links every top-level skill into each target folder; removes this repo's links to skills that no longer exist. Safe to re-run. |
| `./install.sh --uninstall` | Removes every link into this repo. |
| `./install.sh --repo DIR` | Acts on another clone (default: the folder the script is in). |

Target folders: `$SKILL_DIRS` (colon-separated) if set. Otherwise `~/.agents/skills`,
plus `~/.claude/skills` if `~/.claude` exists and `~/.gemini/config/skills` if
`~/.gemini/config` exists. It never replaces a real folder or a link it didn't make.
Works with macOS's bash 3.2.
