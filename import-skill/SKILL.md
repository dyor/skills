---
name: import-skill
description: Imports a remote skill (single or collection) into the local `.skills/imported-skills` folder using a Python script. Can also refresh all skills.
---

# Skill: Import Remote Skill

## Overview
This skill fetches a remote skill (or collection) from a URL and installs it. Single items go to `.skills/imported-skills`, and tasks bundles go to `.skills/tasks/`. Everything imported is tracked inside `.skills/IMPORTED-SKILLS.md`.

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

### To Refresh Existing Skills:
1. When the user asks to "refresh imported skills" or "update skills", run:
   ```bash
   python3 .skills/import-skill/scripts/import_skill.py --refresh
   ```
2. This will read through `IMPORTED-SKILLS.md` and attempt to individually `--overwrite` the directories with their latest source commits.
