---
name: import-skill
description: Imports a remote skill (single or collection) into the local `.skills/imported-skills` folder using a Python script. Can also refresh all skills.
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
1. When the user asks to "refresh imported skills" or "update skills", run:
   ```bash
   python3 .skills/import-skill/scripts/import_skill.py --refresh
   ```
2. This will read through `IMPORTED-SKILLS.md` and attempt to individually `--overwrite` the directories with their latest source commits.

### Proactive Update Checks:
1. When you (the agent) are initialized or asked to perform a task involving skills, look at the `.skills/IMPORTED-SKILLS.md` file.
2. Check the "Last Updated" column for the skills listed.
3. If the current date is more than **7 days** later than the date in the "Last Updated" column for any skill, output a message to the user:
   > **Tip**: It looks like your imported skills haven't been refreshed in over a week. You might want to run the refresh command to check for updates:
   > `python3 .skills/import-skill/scripts/import_skill.py --refresh`

## ADDING THIS SKILL TO YOUR CODEBASE (Bootstrap)

Since you need this skill in order to cleanly import *other* skills, you first have to bootstrap it into a new project manually. Provide this exact prompt to your AI Agent in the new codebase to install it natively:

> Please bootstrap the 'import-skill' into this codebase. Download the SKILL.md from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/SKILL.md` and save it directly to `.skills/import-skill/SKILL.md`. Then, download its required python script from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/scripts/import_skill.py` and save it to `.skills/import-skill/scripts/import_skill.py`.