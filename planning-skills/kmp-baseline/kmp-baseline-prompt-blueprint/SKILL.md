---
name: kmp-baseline-prompt-blueprint
description: Blueprint outlining the initial prompt steps for setting up the management and tracking files.
---

> [!WARNING] This is an immutable blueprint template that is used to build the active plans. Do not execute or edit this file directly while writing code for this codebase - only for building the active plans. For active execution, use .skills/planning-skills/

# Initial Prompt Skill

## When to use this skill
- Use this when initializing a brand new KMP project that requires setting up the core tracking structure.
- This is helpful for standardizing how projects are kicked off.

## How to use it
- Send the following prompt as the very first instruction in a new environment.

---

I want you to initialize this new KMP project by executing the blueprint skills in the imported `.skills/imported-skills/planning-skills/kmp-baseline/` directory. You must generate their corresponding codebase-specific `-local` files in a completely new, separate directory called `.skills/planning-skills/kmp-baseline-local/`. Do not write any generated files into the imported `kmp-baseline` directory.

Please follow these exact steps sequentially. Do not start executing the actual development tasks yet; your goal is purely to generate the management and tracking files.

1. **Read the Blueprint Skills:** 
    Read the sibling directories located adjacent to this prompt (inside the `.skills/imported-skills/planning-skills/kmp-baseline/` folder) to understand the templates available.
   *CRITICAL RULE:* For any skill instantiated from this `kmp-baseline/` directory, if its corresponding blueprint directory contains an `examples/` or `resources/` folder (e.g., `../[blueprint-name]/examples/` or `../[blueprint-name]/resources/`), you MUST copy those folders into the newly created local directory (e.g., `[local-skill-name]/examples/` and `[local-skill-name]/resources/` under `.skills/planning-skills/kmp-baseline-local/`).

2. **Generate the `kmp-baseline-hints-local`:**
   Execute the instructions in `../kmp-baseline-hints-blueprint/SKILL.md` to create the codebase-specific `kmp-baseline-hints-local/SKILL.md` file (located in `.skills/planning-skills/kmp-baseline-local/kmp-baseline-hints-local/SKILL.md`), which will act as the baseline for architecture rules and library versions. Don't forget to copy the `examples/` folder if it exists.

3. **Generate the `kmp-baseline-guide-local`:**
   Execute the instructions in `../kmp-baseline-guide-blueprint/SKILL.md` to create the `kmp-baseline-guide-local/SKILL.md` file (located in `.skills/planning-skills/kmp-baseline-local/kmp-baseline-guide-local/SKILL.md`).
   *Here are the core details for the project you should use to populate the guide:*
   - **App Name:** Factory
   - **Target Audience:** KMP App Builders
   - **Core Problem:** Streamlining the creation and publication of YouTube Short educational videos about the app. 
   - **Visual Style/Theme:** Film noir-classic old school movie theme. 
   - **Core Architecture:** Kotlin Multiplatform (Android, iOS), Jetpack Compose / Compose Multiplatform, Room, Ktor, Koin, Coil, Jetpack Navigation 3, Calf permissions. 
   *Ensure the output strictly follows the Phased Execution structure and uses the `**User Action**`, `**Agent Action**`, and `**Validation**` prefixes for all tasks.*
   **Validation** before moving on to step 4, ask the user verify the contents of `kmp-baseline-guide-local` and to say 'Proceed' when the review is complete. 

4. **Generate the `kmp-baseline-validation-local`:**
   Once `kmp-baseline-guide-local` is created, use the instructions in `../kmp-baseline-validation-blueprint/SKILL.md` to generate the `kmp-baseline-validation-local/SKILL.md` file (located in `.skills/planning-skills/kmp-baseline-local/kmp-baseline-validation-local/SKILL.md`). Tailor the multi-layered testing plan specifically to the phases and features you just outlined in the `kmp-baseline-guide-local`. Ask user for any information needed to create a robust validation plan. 

5. **Generate the `kmp-baseline-calculator-local`:**
   Next, use the instructions in `../kmp-baseline-calculator-blueprint/SKILL.md` to parse the newly created `kmp-baseline-guide-local` and generate the initial `kmp-baseline-calculator-local/SKILL.md` file (located in `.skills/planning-skills/kmp-baseline-local/kmp-baseline-calculator-local/SKILL.md`) to give us our starting baseline progress report. As we work through the `kmp-baseline-guide-local`, we will periodically run the `kmp-baseline-calculator-local` to estimate how much of the work we have completed. 

6. **Generate the `AGENTS.md`:**
   Finally, use the instructions in `../kmp-baseline-agent-blueprint/SKILL.md` to create or update an `AGENTS.md` file in the root directory that has agent instructions that prevent the agent from making mistakes. As we work with this project, we will continue to add more instructions to `AGENTS.md` to keep the agent working smoothly with this project.

## Execution & Validation Rules
When we begin executing `kmp-baseline-guide-local`, you must strictly adhere to the following rules:
* **CRITICAL Validation Rule**: You are strictly forbidden from checking off a `**Validation**` task in the guide unless you have physically run the `execute-and-report-journey` skill, captured the screenshots, and verified the generated `report.md` exists on disk. Never simulate or assume a validation step.