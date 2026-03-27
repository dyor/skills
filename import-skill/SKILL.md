---
name: import-skill
description: Imports a remote skill (single or collection) into the local `.skills/imported-skills` folder using a Python script.
---

# Skill: Import Remote Skill

## Overview
This skill uses a Python script to fetch a remote skill (or collection of skills) from a URL (e.g. GitHub or Raw link) and installs it locally in the `.skills/imported-skills` directory.

## Execution Protocol
When the user asks to import a skill:
1. Identify the `--url` (required) and optional `--name` (local folder name).
2. Execute the Python script:
   ```bash
   python3 .skills/import-skill/scripts/import_skill.py --url "<URL>" [--name "<NAME>"]
   ```
3. Report success and the local path `.skills/imported-skills/<NAME>`.
