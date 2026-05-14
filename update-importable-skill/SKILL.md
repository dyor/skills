---
name: update-importable-skill
description: Author-side. A utility skill to programmatically update or bump YAML front-matter metadata (notably `version:`) on existing SKILL.md files before `git push`. Pairs with the consumer-side skill `import-skill`, which reads the `version:` this skill sets to decide whether downstream copies are stale. Full lifecycle doc ships with `import-skill`: `./import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md` in the source repo, or `https://raw.githubusercontent.com/dyor/skills/main/import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md`.
---

# Skill: Update Importable Skill Metadata

## Overview
This standalone skill is used by Skill Authors to add or update custom YAML front-matter on their `.skills/` files before committing and pushing to GitHub. The most important field to maintain is `version:` — `import-skill` uses it as the canonical signal when deciding whether a downstream copy of the skill is stale (with commit-SHA comparison as a fallback for skills that have not adopted versioning). `import_commit`, `import_date`, and `import_url` are managed automatically by `import-skill` on the importer side, so authors should not set or edit those.

## The `version:` Contract
- Declare `version:` in the YAML front-matter of every `SKILL.md` you publish (e.g. `version: 1.2.0`). Use any string scheme you like — `import-skill` only checks string equality, not semver order — but pick one and stick with it.
- Bump the version on every meaningful change: new behavior, fixed bug, breaking change, updated script. Cosmetic edits to documentation can stay on the same version.
- Do not write `import_commit`, `import_date`, or `import_url`; the importer strips and rewrites those on every import.

## Execution Protocol
When the user asks you to "update the importable skill" or "bump the skill version":

1. Identify which `SKILL.md` (or collection of `SKILL.md` files in a planning skill bundle) they want to update.
2. Ask the user what keys and values they want to change or add to the YAML front-matter (e.g., `version`, `author`, `description`). If the user only says "bump", default to incrementing the rightmost numeric component of the existing `version:` string and confirm before writing.
3. Using your file-editing tools (e.g., `replace_file_content`), parse the top YAML block bounded by `---` and insert or update the requested fields. Preserve unrelated keys exactly as they were.
4. If multiple files (like in a task bundle) need updating, do this iteratively or use `run_command` with a custom shell or python script to batch update them.
5. Remind the user to commit and push their newly updated skills to GitHub so downstream importers can pick up the new version on their next `--refresh`.

## Related Skills & Documentation
- **Partner skill (consumer-side)**: `import-skill` is what downstream developers run to install and later refresh a published skill. It reads the `version:` this skill sets to decide whether a local copy is stale. If the user is asking you to "install a skill" or "refresh imported skills" in *their* project (not edit a skill they author), pivot to `import-skill` instead.
- **Full lifecycle documentation**: For the end-to-end story — when authors should bump `version:`, how downstream refresh decides whether a skill is stale, and where front-matter ownership is split between author and importer — read [`IMPORTING-SKILLS-DOCUMENTATION.md`](https://raw.githubusercontent.com/dyor/skills/main/import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md). The doc ships in the sibling skill's `references/` folder; the URL above points to it in the source repo. Read when the user asks broader questions about the versioning contract or the author/consumer split.
