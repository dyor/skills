---
name: import-skill
description: Consumer-side. Imports a remote skill (single or collection) into the local `.skills/imported-skills` folder using a Python script. Can also refresh all skills using version-first, SHA-fallback drift detection. Pairs with the author-side skill `update-importable-skill`. Full lifecycle doc is bundled at `./references/IMPORTING-SKILLS-DOCUMENTATION.md`.
---

# Skill: Import Remote Skill

## Overview
This skill fetches a remote skill (or collection) from a URL and installs it. Single items go to `.skills/imported-skills`, and planning skills go to `.skills/planning-skills/`. Everything imported is tracked inside `.skills/IMPORTED-SKILLS.md`.

## Execution Protocol

### To Import a New Skill:
1. Identify the URL (required) and optional name.
2. Run the command:
   ```bash
   python3 .skills/import-skill/scripts/import_skill.py --url "<URL>" [--name "<NAME>"]
   ```
3. **If it returns ALREADY_EXISTS**:
   - The script will abort.
   - Ask the User: "This skill already exists locally. Do you want me to overwrite it or would you like to merge it manually?"
   - If User says "overwrite", run the command again with `--overwrite`.
4. Report success, including the commit hash documented in `IMPORTED-SKILLS.md`.
5. **If the imported skill is a planning-skill**:
   - Immediately read the `README.md` file located at the root of the imported planning-skill directory (e.g. `.skills/planning-skills/<name>/README.md`).
   - Tell the User: "I have successfully imported the planning skill. I am now reading its README.md to understand the kickoff instructions."
   - Do NOT attempt to execute, prompt, or run any blueprint skills or guides until you have read the `README.md` first and followed its onboarding steps.

### To Refresh Existing Skills:
1. When the user asks to "refresh imported skills" or "update skills", first run a dry check:
   ```bash
   python3 .skills/import-skill/scripts/import_skill.py --refresh --check
   ```
   This prints a per-skill status (`SKIP`, `UPDATE`, or `FORCE`) using the version-detection ladder below and writes nothing.
2. Then apply the changes:
   ```bash
   python3 .skills/import-skill/scripts/import_skill.py --refresh
   ```
   Each `UPDATE`/`FORCE` row is re-imported with `--overwrite`. Skills that are already up-to-date are skipped.
3. To re-import everything regardless of detected state, add `--force`.

### Version Detection (how `--refresh` decides what to update)
For each tracked skill, the script picks one of three actions using this precedence:

1. **Declared version (preferred).** If the local `SKILL.md` *and* the remote `SKILL.md` both have a `version:` field in their YAML front-matter, compare the strings. Equal → `SKIP`. Different → `UPDATE` (reported as `v1.2.0 -> v1.3.0`). This is the canonical signal; skill authors should bump it via the `update-importable-skill` skill on every meaningful change.
2. **Commit SHA (fallback).** If either side is missing `version:`, compare the locally stored `import_commit` against the current remote HEAD SHA (looked up via the GitHub commits API, scoped to the sub-path of the import URL). Equal → `SKIP`. Different → `UPDATE` (reported as `sha abc1234 -> def5678 (no version)`).
3. **Force re-import (last resort).** If neither signal is available (e.g. an arbitrary raw URL with no SHA in the path and no `version:` on either side), report `FORCE` and re-import. This preserves the old always-overwrite behavior for unversioned third-party skills.

Remote `version:` and SHA lookups are cached per run, so refreshing many skills from the same repository does not hammer the GitHub API. If `GITHUB_TOKEN` is set in the environment, it is sent with API requests to lift the unauthenticated rate limit.

### Proactive Update Checks:
1. When you (the agent) are initialized or asked to perform a task involving skills, look at the `.skills/IMPORTED-SKILLS.md` file.
2. Check the "Last Updated" column for the skills listed.
3. If the current date is more than **7 days** later than the date in the "Last Updated" column for any skill, output a message to the user:
   > **Tip**: It looks like your imported skills haven't been refreshed in over a week. Run a quick drift check:
   > `python3 .skills/import-skill/scripts/import_skill.py --refresh --check`
   > Then apply any pending updates with `--refresh`.

## Tracking File Schema
`IMPORTED-SKILLS.md` uses this 6-column shape:

| Name | Destination | URL | Version | Commit | Last Updated |

The `Version` column holds the upstream `version:` declared in the skill's `SKILL.md` front-matter at import time, or `-` if the skill does not declare one. The script transparently upgrades older 5-column tracking files (`| Commit / Version |`) to this layout the first time it writes them.

## Related Skills & Documentation
- **Partner skill (author-side)**: `update-importable-skill` is the companion utility for skill *authors* — it edits `version:` in a `SKILL.md`'s front-matter before publishing. The `version:` it sets is the primary signal this skill reads during `--refresh`. If the user is asking you to "bump a skill's version" or "update a skill's front-matter", pivot to that skill instead of this one.
- **Full lifecycle documentation**: For the end-to-end story — authoring, versioning, importing, refreshing, and how the version-first / SHA-fallback drift detection works — read the bundled lifecycle doc at `./references/IMPORTING-SKILLS-DOCUMENTATION.md`. The bootstrap step below downloads it as part of installing `import-skill`. Read it whenever the user asks broader questions about how skill versioning, refresh decisions, or the author/consumer split work.

## ADDING THIS SKILL TO YOUR CODEBASE (Bootstrap)

Since you need this skill in order to cleanly import *other* skills, you first have to bootstrap it into a new project manually. Provide this exact prompt to your AI Agent in the new codebase to install it natively:

> Please bootstrap the 'import-skill' into this codebase. Download three files:
> 1. The SKILL.md from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/SKILL.md` → save to `.skills/import-skill/SKILL.md`.
> 2. The python script from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/scripts/import_skill.py` → save to `.skills/import-skill/scripts/import_skill.py`.
> 3. The lifecycle documentation from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md` → save to `.skills/import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md`. This is the reference doc agents should read when answering broader questions about skill versioning, refresh, or the author/consumer workflow.
