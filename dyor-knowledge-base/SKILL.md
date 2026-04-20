---
name: dyor-knowledge-base
description: A summary of all names and descriptions of skills in the dyor/skills repository, used to guide importing relevant skills.
---

# Skill: dyor-knowledge-base

## Overview
This skill acts as a repository of knowledge about available skills in the `dyor/skills` ecosystem. It helps identify which skills are available and how to import them when needed.

## Available Skills

### Standalone Skills

- **`create-task`**
  - **Description**: Scaffolds a complete 6-part Task Bundle (Prompt, Agent, Guide, Calculator, Validation, Hints) inside the remote `.skills/tasks/` directory for authoring a new chunk of orchestrated work.
  - **URL**: `https://github.com/dyor/skills/tree/main/create-task`

- **`generate-journey-report`**
  - **Description**: Automates the execution of an Agent Journey test and generates a persistent Markdown change review document with screenshots.
  - **URL**: `https://github.com/dyor/skills/tree/main/generate-journey-report`

- **`import-skill`**
  - **Description**: Imports a remote skill (single or collection) into the local `.skills/imported-skills` folder using a Python script. Can also refresh all skills.
  - **URL**: `https://github.com/dyor/skills/tree/main/import-skill`

- **`journey-writing-skill`**
  - **Description**: Use this skill when you need to test or validate app behavior, write an Android Studio Journey, automate UI testing, or define user flow validation requirements.
  - **URL**: `https://github.com/dyor/skills/tree/main/journey-writing-skill`

- **`update-importable-skill`**
  - **Description**: A utility skill to programmatically update or bump the front-matter metadata (like version numbers) of existing SKILL.md files.
  - **URL**: `https://github.com/dyor/skills/tree/main/update-importable-skill`

- **`dyor-knowledge-base`**
  - **Description**: A summary of all names and descriptions of skills in the dyor/skills repository, used to guide importing relevant skills.
  - **URL**: `https://github.com/dyor/skills/tree/main/dyor-knowledge-base`

### Tasks (Bundles)

- **`kmp-baseline`**
  - **Description**: A complex bundle of interconnected reusable blueprints to get from a template to a full-featured baseline app.
  - **URL**: `https://github.com/dyor/skills/tree/main/tasks/kmp-baseline`
  - **Constraint**: Skills associated with this task are not to be installed individually - only install the entire task's collection of skills.

## Execution Protocol

1. **Search & Suggestion**:
   - If a skill has not been imported and it may be relevant to the current prompt, or if the user explicitly asks to search `dyor-knowledge-base`, refer to this skill.
   - Check if the required skill is already present in the local codebase (e.g., in `.skills/imported-skills/` or `.skills/tasks/`).

2. **Import Prompt**:
   - If a relevant skill is found here but is not imported, ask the user if they want to import the skill.

3. **Importing**:
   - If the user says yes, proceed to import it using `import-skill`.
   - **Bootstrap Check**: If `import-skill` is not already bootstrapped in the target codebase, you must first tell the user to bootstrap the `import-skill` skill as described in the README of the repo.
     - The bootstrap instructions are:
       > Please bootstrap the 'import-skill' into this codebase. Download the main skill blueprint from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/SKILL.md` and save it directly to `.skills/import-skill/SKILL.md`. Then, download its required python script from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/scripts/import_skill.py` and save it to `.skills/import-skill/scripts/import_skill.py`.
   - If `import-skill` is bootstrapped, use it to fetch the skill using the URLs listed above.

4. **Task Constraint**:
   - Remember that skills associated with a task in the tasks/ directory such as the `kmp-baseline` skills must only be installed as a complete collection, not individually.
