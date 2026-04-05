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

## ADDING THIS SKILL TO YOUR CODEBASE (Bootstrap)

Since you need this skill in order to cleanly import *other* skills, you first have to bootstrap it into a new project manually. Provide this exact prompt to your AI Agent in the new codebase to install it natively:

> Please bootstrap the 'import-skill' into this codebase. Download the SKILL.md from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/SKILL.md` and save it directly to `.skills/import-skill/SKILL.md`. Then, download its required python script from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/scripts/import_skill.py` and save it to `.skills/import-skill/scripts/import_skill.py`.