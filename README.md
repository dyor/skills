# Skills Repository

Welcome to the Skills Repository! This collection contains skills and "tasks" (tasks are a collection of skills designed to help get through a large chunk of work - like standing up a baseline KMP app, or migrating from an old library to a new one). These skills are hosted remotely (here or some other github repo) and intended to be localized or imported into your codebase. 

> **New here?** Read [import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md](./import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md) for the end-to-end story: how authors publish and version skills, how developers import them, and how version-aware refresh detects drift. The two skills below — `import-skill` and `update-importable-skill` — are two halves of that one lifecycle.

## 1. Importing Standalone Skills

A standalone skill provides your AI agent with a specific new capability. Because you need the `import-skill` tool to fetch other tools dynamically, you must first bootstrap it. 

### Step 1: Bootstrap the `import-skill`
To get started in a fresh project, tell your AI Agent to execute this exact prompt:
> Please bootstrap the 'import-skill' into this codebase. Download three files:
> 1. The SKILL.md from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/SKILL.md` → save to `.skills/import-skill/SKILL.md`.
> 2. The python script from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/scripts/import_skill.py` → save to `.skills/import-skill/scripts/import_skill.py`.
> 3. The lifecycle documentation from `https://raw.githubusercontent.com/dyor/skills/main/import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md` → save to `.skills/import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md`. This is the reference doc agents should read when answering broader questions about skill versioning, refresh, or the author/consumer workflow.

### Step 2: Import Other Skills
Once the `import-skill` is in your codebase, you can prompt your AI agent to download and install any other standalone skill simply by feeding it the remote GitHub URL. 

**Example: Importing the Journey Writing Skill**
Ask your agent:
> "Please import the skill located at `https://github.com/dyor/skills/tree/main/journey-writing-skill`."

The agent will automatically pull down the repository code and unpack it into your project exactly at `.skills/imported-skills/journey-writing-skill/`. Simultaneously, it generates a ledger at `.skills/IMPORTED-SKILLS.md` keeping track of the GitHub commit hash, URL, and timestamp so you always know exactly what version of a skill you downloaded!

## 2. Importing Project Tasks (Bundles)

While standalone skills are singular and targetted, a **Task** is a complex bundle of interconnected reusable blueprints, that the agent can use to create codebase-specific task skills within your codebase. Typically a Task gets you from where you are (e.g., an old library version, an old language, an old framework) to where you want to be (e.g., a new library, a new language, a new framework). It can also be used to get from a template to a full-featured baseline app (e.g., the kmp-baseline skill).  

The `import-skill` logic is sophisticated enough to detect when you are importing a task bundle based on the `/tasks/` URL structure.

**Example: Importing the KMP Baseline Task**
Ask your agent:
> "Please import the task bundle from `https://github.com/dyor/skills/tree/main/tasks/kmp-baseline`."

Instead of flattening the downloaded files into generic folders, the importer carefully re-assembles the entire nested tree structure locally inside your `.skills/tasks/kmp-baseline/` directory. By actively preserving the root folder structures, internal task blueprints can safely use relative paths (e.g., `../kmp-baseline-hints-blueprint/SKILL.md`) to execute their sibling prompts flawlessly. 

## 3. Best Practices for Skill Authors

If you are a developer authoring your own portable skills for distribution via GitHub, you'll want to ensure that other developers can gracefully track, integrate, and verify your tools. See [import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md](./import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md) for the full author-and-consumer lifecycle, including when to bump `version:` and how downstream refresh detects drift.

When an end-user runs `import-skill` on your repository, the script automatically injects `import_commit`, `import_date`, and `import_url` into the user's local `SKILL.md` file. However, for maximum professionalism, you should maintain rich, semantic metadata directly on the raw files you publish.

This is where the **`update-importable-skill`** utility comes into play. 

Before you `git push` a brand new skill (or a massive update) to your GitHub repository, you can prompt your agent to invoke this utility to standardize your files:
> "Run the update-importable-skill against my `journey-writing-skill`. Bump the `version` from 1.0.0 to 1.1.0 and update the `description` to match the revised functionality."

The AI will safely parse the YAML `<--- --->` front-matter block at the top of your `SKILL.md` (or iterate across a massive array of files in a task bundle) and inject or bump the custom fields without disturbing your core markdown instructions. This guarantees your distributed tools will look great, behave cleanly, and be universally readable by any other AI agent working in an imported environment.
