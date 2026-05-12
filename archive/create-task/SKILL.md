---
name: create-task
description: Scaffolds a complete 6-part Task Bundle (Prompt, Agent, Guide, Calculator, Validation, Hints) inside the remote `.skills/tasks/` directory for authoring a new chunk of orchestrated work.
---

# Skill: Create Task Bundle

## Overview
A "Task" is a set of orchestrated skills that help a developer execute a massive chunk of work. This skill scaffolds the 6 essential blueprints required for a standard Task, mimicking the robust architecture of [`kmp-baseline`](https://github.com/dyor/skills/tree/main/tasks/kmp-baseline).

## Execution Protocol

### Step 1: Solicit Task Name
Ask the developer for a new task name. It must be formatted in kabab-case (e.g., `feature-auth`, `database-migration`).

### Step 2: Scaffold Directories
Once the developer provides the name (referred to below as `<task-name>`), create the following directory structure inside `.skills/tasks/<task-name>/`:

- `<task-name>-prompt-blueprint/`
- `<task-name>-agent-blueprint/`
- `<task-name>-guide-blueprint/`
- `<task-name>-calculator-blueprint/`
- `<task-name>-validation-blueprint/`
- `<task-name>-hints-blueprint/`
- `<task-name>-hints-blueprint/examples/`

### Step 3: Scaffold Blueprint SKILL.md Files
Create a `SKILL.md` file inside each of the 6 directories you just created. Use the following specifications to generate their content dynamically:

#### 1. `<task-name>-prompt-blueprint`
**Purpose**: The entry point skill that tells the agent how to localize the blueprints into the developer's local `.skills/` directory.
**Content Requirements**:
- Write a prompt instructing the agent to sequentially read the sibling blueprints using relative paths (e.g., `../<task-name>-guide-blueprint/SKILL.md`) and generate their local, codebase-specific `-task` equivalents (e.g., `.skills/<task-name>-guide-task/SKILL.md`).
- It must instruct the agent to prompt the host developer for specific variables needed to populate the local guides/hints (similar to soliciting the "App Name" and "Target Audience" in `kmp-baseline`).

#### 2. `<task-name>-agent-blueprint`
**Purpose**: Specific agent instructions used to create/update an `AGENTS.md` file in the root of the project.
**Content Requirements**:
- Write instructions that teach the AI agent how to properly use this task *without* requiring the developer to directly steer it. 
- It should tell the agent to strictly follow the current Phase/Step in the `guide-task` and heavily reference the `hints-task` for technical execution guardrails.

#### 3. `<task-name>-guide-blueprint`
**Purpose**: The step-by-step set of instructions mapping out the work.
**Content Requirements**:
- Create markdown placeholders for `## Phase 1`, `## Phase 2`, etc., containing `- [ ]` checklist items.
- Provide a comment indicating that the developer and the agent will flesh out these specific steps together after the scaffolding is complete.

#### 4. `<task-name>-calculator-blueprint`
**Purpose**: Built to measure task completion relative to the guide.
**Content Requirements**:
- Write a skill script that parses the `guide-task` file, counts the total number of `- [ ]` markdown checkboxes versus the checked `- [x]` boxes, and outputs a formatted progress report so the developer knows how close the task is to being done.

#### 5. `<task-name>-validation-blueprint`
**Purpose**: Validations that must pass before the task is considered done.
**Content Requirements**:
- Scaffold two sections: **Agent Validations** (e.g., "Does it compile?", "Do the unit tests pass?", "Is linting clean?") and **User Validations** (e.g., "Confirm UI layout matches Figma", "Confirm UX feels correct").
- Explicitly state that once all items in both lists are verified, the overarching task is complete.

#### 6. `<task-name>-hints-blueprint`
**Purpose**: A massive collection of custom workarounds, internal intelligence, and AI guardrails.
**Content Requirements**:
- Write instructions indicating that the author should populate this file with specific fixes for outdated LLM training data (for example, bridging the gap for frameworks that released major updates recently like AGP 9+, Room, or Navigation 3).
- Also instruct the author to place private contexts here, such as internal style guides, undocumented APIs, or codebase-specific architectural rules.
- Remind the author that real-world code snippets should be placed in the adjacent `examples/` directory for the agent to ingest.

### Step 4: Finalize
After generating all 6 files, inform the user that the task bundle has been successfully scaffolded at `.skills/tasks/<task-name>/` and ask them which blueprint they would like to start fleshing out first.
