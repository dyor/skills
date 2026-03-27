---
name: update-importable-skill
description: A utility skill to programmatically update or bump the front-matter metadata (like version numbers) of existing SKILL.md files.
---

# Skill: Update Importable Skill Metadata

## Overview
This standalone skill is used by Skill Authors to easily add or update custom YAML front-matter data in their `.skills/` directory before committing and pushing to GitHub. Note that `import_commit` and `import_date` are handled automatically by `import-skill` for end-users, but this tool is useful for author-specific fields (e.g. `version: 1.2.0`, `author: YourName`).

## Execution Protocol
When the user asks you to "update the importable skill" or "bump the skill version":

1. Identify which `SKILL.md` (or collection of `SKILL.md` files in a task bundle) they want to update.
2. Ask the user what keys and values they want to change or add to the YAML front-matter (e.g., `version`, `author`, `description`).
3. Using your file-editing tools (e.g., `replace_file_content`), parse the top YAML block bounded by `---` and insert or update the requested fields.
4. If multiple files (like in a task bundle) need updating, do this iteratively or use `run_command` with a custom shell or python script to batch update them.
5. Remind the user to commit and push their newly updated skills to Github!
