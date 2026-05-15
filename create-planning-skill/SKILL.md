---
name: create-planning-skill
description: Scaffolds a complete 6-part Planning Skill (Prompt, Agent, Guide, Calculator, Validation, Hints) inside the remote `.skills/planning-skills/` directory for authoring a new chunk of orchestrated work.
---

# Skill: Create Planning Skill

## Overview
A "Planning Skill" is a set of orchestrated skills that help a developer execute a massive chunk of work. This skill scaffolds the 6 essential blueprints required for a standard Planning Skill, mimicking the robust architecture of [`kmp-baseline`](https://github.com/dyor/skills/tree/main/planning-skills/kmp-baseline).

## Execution Protocol

### Step 1: Solicit Planning Skill Name
Ask the developer for a new planning skill name. It must be formatted in kabab-case (e.g., `feature-auth`, `database-migration`).

### Step 2: Scaffold Directories
Once the developer provides the name (referred to below as `<planning-skill-name>`), create the following directory structure inside `.skills/planning-skills/<planning-skill-name>/`:

- `<planning-skill-name>-prompt-blueprint/`
- `<planning-skill-name>-agent-blueprint/`
- `<planning-skill-name>-guide-blueprint/`
- `<planning-skill-name>-calculator-blueprint/`
- `<planning-skill-name>-validation-blueprint/`
- `<planning-skill-name>-hints-blueprint/`
- `<planning-skill-name>-hints-blueprint/examples/`

### Step 3: Scaffold Blueprint SKILL.md Files
Create a `SKILL.md` file inside each of the 6 directories you just created. Ensure that every scaffolded blueprint `SKILL.md` file begins with the following warning banner directly below the YAML front-matter:

> [!WARNING] This is an immutable blueprint template that is used to build the active plans. Do not execute or edit this file directly while writing code for this codebase - only for building the active plans. For active execution, use .skills/planning-skills/

Use the following specifications to generate their content dynamically:

#### 1. `<planning-skill-name>-prompt-blueprint`
**Purpose**: The entry point skill that tells the agent how to localize the blueprints into the developer's local `.skills/planning-skills/<planning-skill-name>-local/` directory.
**Content Requirements**:
- Write a prompt instructing the agent to sequentially read the sibling blueprints using relative paths (e.g., `../<planning-skill-name>-guide-blueprint/SKILL.md`) and generate their local, codebase-specific `-local` equivalents inside a completely new directory called `.skills/planning-skills/<planning-skill-name>-local/` (e.g., `.skills/planning-skills/<planning-skill-name>-local/<planning-skill-name>-guide-local/SKILL.md`).
- It must instruct the agent to prompt the host developer for specific variables needed to populate the local guides/hints (similar to soliciting the "App Name" and "Target Audience" in `kmp-baseline`).

#### 2. `<planning-skill-name>-agent-blueprint`
**Purpose**: Specific agent instructions used to create/update an `AGENTS.md` file in the root of the project.
**Content Requirements**:
- Write instructions that teach the AI agent how to properly use this planning skill *without* requiring the developer to directly steer it. 
- It should tell the agent to strictly follow the current Phase/Step in the `guide-local` and heavily reference the `hints-local` for technical execution guardrails.

#### 3. `<planning-skill-name>-guide-blueprint`
**Purpose**: The step-by-step set of instructions mapping out the work.
**Content Requirements**:
- Create markdown placeholders for `## Phase 1`, `## Phase 2`, etc., containing `- [ ]` checklist items.
- Provide a comment indicating that the developer and the agent will flesh out these specific steps together after the scaffolding is complete.

#### 4. `<planning-skill-name>-calculator-blueprint`
**Purpose**: Built to measure planning skill completion relative to the guide.
**Content Requirements**:
- Write a skill script that parses the `guide-local` file, counts the total number of `- [ ]` markdown checkboxes versus the checked `- [x]` boxes, and outputs a formatted progress report so the developer knows how close the planning skill is to being done.

#### 5. `<planning-skill-name>-validation-blueprint`
**Purpose**: Validations that must pass before the planning skill is considered done.
**Content Requirements**:
- Scaffold two sections: **Agent Validations** (e.g., "Does it compile?", "Do the unit tests pass?", "Is linting clean?") and **User Validations** (e.g., "Confirm UI layout matches Figma", "Confirm UX feels correct").
- Explicitly state that once all items in both lists are verified, the overarching planning skill is complete.

#### 6. `<planning-skill-name>-hints-blueprint`
**Purpose**: A massive collection of custom workarounds, internal intelligence, and AI guardrails.
**Content Requirements**:
- Write instructions indicating that the author should populate this file with specific fixes for outdated LLM training data (for example, bridging the gap for frameworks that released major updates recently like AGP 9+, Room, or Navigation 3).
- Also instruct the author to place private contexts here, such as internal style guides, undocumented APIs, or codebase-specific architectural rules.
- Remind the author that real-world code snippets should be placed in the adjacent `examples/` directory for the agent to ingest.

---

### Step 4: Scaffold Parent README.md File
Create a `README.md` file inside the root of `.skills/planning-skills/<planning-skill-name>/`.
**Purpose**: Provide clear documentation to developers and agents on what this planning skill is all about and how to kick it off.
**Content Requirements**:
- **Overview of the Collection**: Explain that this is a highly orchestrated planning skill composed of multiple blueprints (Prompt, Agent, Guide, Calculator, Validation, Hints).
- **Kick-Off Instructions**: Explicitly instruct developers or agents on how to kick off the planning skill using the prompt blueprint (e.g. running the orchestrator instructions inside `.skills/imported-skills/planning-skills/<planning-skill-name>/<planning-skill-name>-prompt-blueprint/SKILL.md`).
- **Workflow Components**: Outline and describe each blueprint included in the collection so that developers understand what is scaffolded.

---

### Step 5: Finalize
After generating all 7 files (6 blueprint SKILL.md files + 1 parent README.md), inform the user that the planning skill has been successfully scaffolded at `.skills/planning-skills/<planning-skill-name>/` and ask them which blueprint they would like to start fleshing out first.
