---
name: kmp-baseline-prompt-blueprint
description: Blueprint outlining the initial prompt steps for materializing the KMP baseline plan outside of `.skills/` (default `plans/kmp-baseline/`).
version: 2.0.0
---

> [!WARNING] This is an immutable blueprint template used to build the active project plans. Do not execute or edit this file directly while writing code for this codebase. Active project plans must be materialized OUTSIDE of `.skills/` (default: `plans/kmp-baseline/`, or a custom directory chosen by the user).

# Initial Prompt Skill

## When to use this skill
- Use this when initializing a brand new KMP project that requires setting up the core planning and tracking structure.
- Standardizes how projects are kicked off while keeping `.skills/` clean and upstream-refreshable.

## How to use it
- Send the following prompt as the very first instruction in a new environment.

---

I want you to initialize this new KMP project by reading the blueprint skills in `.skills/imported-skills/planning-skills/kmp-baseline/` (or the active `kmp-baseline` skill directory).

**CRITICAL ARCHITECTURAL RULE — DO NOT WRITE PLANS INTO `.skills/`:**
The `.skills/` directory is reserved for upstream-synced skills and must not be polluted with project-specific plans. You must materialize all codebase-specific plan files into a dedicated project directory **outside** of `.skills/`, referred to below as `<plan_dir>`.
- **Default `<plan_dir>`**: `plans/kmp-baseline` (at the project root).
- Before generating files, ask the user if they want to use the default `plans/kmp-baseline/` directory or specify a custom directory (e.g., `SPECS/kmp-baseline/`).

Please follow these exact steps sequentially. Do not start executing the actual development tasks yet; your goal is purely to generate the management and tracking files in `<plan_dir>/`.

1. **Read the Blueprint Skills:**
   Read the sibling directories located adjacent to this prompt (inside the `kmp-baseline/` blueprint folder) to understand the templates available.
   *CRITICAL RULE:* For any blueprint that contains an `examples/` or `resources/` folder (e.g., `../[blueprint-name]/examples/` or `../[blueprint-name]/resources/`), you MUST copy those folders into `<plan_dir>/` (i.e., `<plan_dir>/examples/` and `<plan_dir>/resources/`).

2. **Generate `<plan_dir>/hints.md`:**
   Execute the instructions in `../kmp-baseline-hints-blueprint/SKILL.md` to create the codebase-specific `<plan_dir>/hints.md` file, which will act as the baseline for architecture rules and library versions. Don't forget to copy the `examples/` folder into `<plan_dir>/examples/` if it exists.

3. **Generate `<plan_dir>/guide.md`:**
   Execute the instructions in `../kmp-baseline-guide-blueprint/SKILL.md` to create `<plan_dir>/guide.md`. Copy `resources/` into `<plan_dir>/resources/` if present.
   *Here are the default details for the project you should use to populate the guide (or ask the user to override them):*
   - **App Name:** Factory
   - **Target Audience:** KMP App Builders
   - **Core Problem:** Streamlining the creation and publication of YouTube Short educational videos about the app.
   - **Visual Style/Theme:** Film noir-classic old school movie theme.
   - **Core Architecture:** Kotlin Multiplatform (Android, iOS), Jetpack Compose / Compose Multiplatform, Room, Ktor, Koin, Coil, Jetpack Navigation 3, Calf permissions.
   *Ensure the output strictly follows the Phased Execution structure and uses the `**User Action**`, `**Agent Action**`, and `**Validation**` prefixes for all tasks.*
   **Validation**: Before moving on to step 4, ask the user to verify the contents of `<plan_dir>/guide.md` and say 'Proceed' when the review is complete.

4. **Generate `<plan_dir>/validation.md`:**
   Once `<plan_dir>/guide.md` is created, use the instructions in `../kmp-baseline-validation-blueprint/SKILL.md` to generate `<plan_dir>/validation.md`. Tailor the multi-layered testing plan specifically to the phases and features you just outlined in `<plan_dir>/guide.md`. Ask the user for any information needed to create a robust validation plan.

5. **Generate `<plan_dir>/progress.md`:**
   Next, use the instructions in `../kmp-baseline-calculator-blueprint/SKILL.md` to parse the newly created `<plan_dir>/guide.md` and generate the initial `<plan_dir>/progress.md` file to give us our starting baseline progress report. As we work through `<plan_dir>/guide.md`, we will periodically update `<plan_dir>/progress.md` to estimate how much of the work we have completed.

6. **Generate Root `AGENTS.md`:**
   Finally, use the instructions in `../kmp-baseline-agent-blueprint/SKILL.md` to create or update an `AGENTS.md` file in the root directory that points to `<plan_dir>/` (`guide.md`, `hints.md`, `validation.md`, `progress.md`) and prevents the agent from making mistakes.

## Execution & Validation Rules
When we begin executing `<plan_dir>/guide.md`, you must strictly adhere to the following rules:
* **CRITICAL Validation Rule**: You are strictly forbidden from checking off a `**Validation**` task in the guide unless you have physically run the `execute-and-report-journey` skill, captured the screenshots, and verified the generated `report.md` exists on disk. Never simulate or assume a validation step.
