---
name: create-planning-skill
description: Scaffolds a complete 6-part Planning Skill (Prompt, Agent, Guide, Calculator, Validation, Hints) inside the skills repo (`planning-skills/<name>/`) for authoring a new chunk of orchestrated work. Enforces the rule that active project plans are materialized OUTSIDE of `.skills/` (default `plans/<name>/`, user-configurable).
version: 2.0.0
author: dyor
---

# Skill: Create Planning Skill

## Overview
A "Planning Skill" is a set of orchestrated blueprint skills that help a developer execute a massive chunk of work. This skill scaffolds the 6 essential blueprints required for a standard Planning Skill, mimicking the robust architecture of [`kmp-baseline`](https://github.com/dyor/skills/tree/main/planning-skills/kmp-baseline).

### Core Architectural Rule: Keep Active Plans Outside of `.skills/`
The `.skills/` directory (and the upstream `dyor/skills` repo) is strictly for **reusable, upstream-synced skill templates and scripts** so skills can be periodically refreshed via `import-skill` or `skills-repo-sync` without clobbering project work.
- **Blueprint definitions** live in the skills repository under `planning-skills/<planning-skill-name>/` (or when imported into a consumer project, under `.skills/imported-skills/planning-skills/<planning-skill-name>/`).
- **Project-specific materialized plans** (the tailored guide, validation plan, progress report, and local hints generated when running a planning skill in an app repo) **MUST NEVER be written inside `.skills/`**. Instead, they are materialized into a configurable project directory **outside** of `.skills/` — defaulting to `<plan_dir>` = `plans/<planning-skill-name>/` (or another directory chosen by the developer, such as `SPECS/plans/<planning-skill-name>/`).

## Execution Protocol

### Step 1: Solicit Planning Skill Name & Authoring Location
1. Ask the developer for a new planning skill name in kebab-case (e.g., `feature-auth`, `database-migration`).
2. Determine where the blueprint collection itself is being authored:
   - If authoring inside the `dyor/skills` repository, create it at `planning-skills/<planning-skill-name>/`.
   - If scaffolding locally inside an app repo, ask where to place the blueprint definition (defaulting to `planning-skills/<planning-skill-name>/` or `.skills/planning-skills/<planning-skill-name>/` only if explicitly authoring a skill).

### Step 2: Scaffold Blueprint Directories
Once the developer provides `<planning-skill-name>`, create the following directory structure inside the blueprint root (`planning-skills/<planning-skill-name>/`):

- `<planning-skill-name>-prompt-blueprint/`
- `<planning-skill-name>-agent-blueprint/`
- `<planning-skill-name>-guide-blueprint/`
- `<planning-skill-name>-calculator-blueprint/`
- `<planning-skill-name>-validation-blueprint/`
- `<planning-skill-name>-hints-blueprint/`
- `<planning-skill-name>-hints-blueprint/examples/`

### Step 3: Scaffold Blueprint `SKILL.md` Files
Create a `SKILL.md` file inside each of the 6 directories you just created. Ensure that every scaffolded blueprint `SKILL.md` file begins with the following warning banner directly below the YAML front-matter:

> [!WARNING] This is an immutable blueprint template used to materialize active project plans. Do not execute or edit this file directly while writing application code. Active project plans must be materialized OUTSIDE of `.skills/` (default: `plans/<planning-skill-name>/`, or a custom directory chosen by the user).

Use the following specifications to generate their content dynamically:

#### 1. `<planning-skill-name>-prompt-blueprint`
**Purpose**: The entry-point skill that tells the agent how to materialize the blueprints into the developer's project directory **outside** of `.skills/`.
**Content Requirements**:
- Instruct the agent to first ask the developer to confirm or customize the target plan directory `<plan_dir>` (defaulting to `plans/<planning-skill-name>/` at the project root — **never** inside `.skills/`) as well as project-specific variables (e.g., App Name, Target Audience, Architecture).
- Instruct the agent to sequentially read the sibling blueprints using relative paths (e.g., `../<planning-skill-name>-guide-blueprint/SKILL.md`) and generate their codebase-specific markdown files inside `<plan_dir>/`:
  - `<plan_dir>/guide.md` (from `<planning-skill-name>-guide-blueprint`)
  - `<plan_dir>/hints.md` + `<plan_dir>/examples/` (from `<planning-skill-name>-hints-blueprint`)
  - `<plan_dir>/validation.md` (from `<planning-skill-name>-validation-blueprint`)
  - `<plan_dir>/progress.md` (from `<planning-skill-name>-calculator-blueprint`)
  - Root `AGENTS.md` (from `<planning-skill-name>-agent-blueprint`, pointing to `<plan_dir>/`).

#### 2. `<planning-skill-name>-agent-blueprint`
**Purpose**: Specific agent instructions used to create/update an `AGENTS.md` file in the root of the project.
**Content Requirements**:
- Write instructions that teach the AI agent how to properly execute the plan in `<plan_dir>/guide.md` *without* requiring the developer to micro-manage it.
- Tell the agent to strictly follow the current Phase/Step in `<plan_dir>/guide.md` and heavily reference `<plan_dir>/hints.md` for technical execution guardrails.

#### 3. `<planning-skill-name>-guide-blueprint`
**Purpose**: The step-by-step set of instructions mapping out the work, materialized to `<plan_dir>/guide.md`.
**Content Requirements**:
- Create markdown placeholders for `## Phase 1`, `## Phase 2`, etc., containing `- [ ]` checklist items prefixed with `**User Action**:`, `**Agent Action**:`, or `**Validation**:`.
- Provide a comment indicating that the developer and the agent will flesh out these specific steps together after the scaffolding is complete.

#### 4. `<planning-skill-name>-calculator-blueprint`
**Purpose**: Built to measure plan completion relative to `<plan_dir>/guide.md` and write the report to `<plan_dir>/progress.md`.
**Content Requirements**:
- Write instructions that parse `<plan_dir>/guide.md`, count the total number of `- [ ]` markdown checkboxes versus checked `- [x]` boxes per phase, and output a formatted progress table to `<plan_dir>/progress.md`.

#### 5. `<planning-skill-name>-validation-blueprint`
**Purpose**: Validations that must pass before the plan is considered done, materialized to `<plan_dir>/validation.md`.
**Content Requirements**:
- Scaffold two sections: **Agent Validations** (e.g., "Does it compile?", "Do the unit tests pass?", "Is linting clean?") and **User Validations** (e.g., "Confirm UI layout matches Figma", "Confirm UX feels correct").
- Explicitly state that once all items in both lists are verified, the overarching plan is complete.

#### 6. `<planning-skill-name>-hints-blueprint`
**Purpose**: A collection of custom workarounds, internal intelligence, and AI guardrails, materialized to `<plan_dir>/hints.md`.
**Content Requirements**:
- Write instructions indicating that the author should populate this file with specific fixes for outdated LLM training data (for example, bridging the gap for frameworks that released major updates recently like AGP 9+, Room, or Navigation 3).
- Instruct the author to place private contexts here, such as internal style guides, undocumented APIs, or codebase-specific architectural rules.
- Remind the author that real-world code snippets should be placed in the adjacent `examples/` directory for the agent to copy into `<plan_dir>/examples/`.

---

### Step 4: Scaffold Parent `README.md` File
Create a `README.md` file inside the root of `planning-skills/<planning-skill-name>/`.
**Purpose**: Provide clear documentation to developers and agents on what this planning skill is all about and how to kick it off.
**Content Requirements**:
- **Overview of the Collection**: Explain that this is an orchestrated planning skill composed of 6 blueprints (Prompt, Agent, Guide, Calculator, Validation, Hints).
- **Separation of Skills vs. Project Plans**: Explicitly explain that the blueprints stay untouched inside `.skills/imported-skills/planning-skills/<planning-skill-name>/` (so upstream skill updates work cleanly), while the customized project plan is materialized outside `.skills/` into `<plan_dir>` (default `plans/<planning-skill-name>/`, or any folder the developer chooses).
- **Kick-Off Instructions**: Show the exact prompt to run `<planning-skill-name>-prompt-blueprint/SKILL.md`.

---

### Step 5: Finalize
After generating all 7 files (6 blueprint `SKILL.md` files + 1 parent `README.md`), inform the user that the planning skill has been scaffolded and ask which blueprint they would like to flesh out first.
