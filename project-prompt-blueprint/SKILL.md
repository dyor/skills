---
name: project-prompt-blueprint
description: Blueprint outlining the initial prompt steps for setting up the management and tracking files.
---

# Initial Prompt Skill

## When to use this skill
- Use this when initializing a brand new KMP project that requires setting up the core tracking structure.
- This is helpful for standardizing how projects are kicked off.

## How to use it
- Send the following prompt as the very first instruction in a new environment.

---

I want you to initialize this new KMP project by executing the blueprint skills defined in the `/Users/mattdyor/.skills/` directory to generate their corresponding codebase-speicfic files in the project's `.skills/` directory. 

Please follow these exact steps sequentially. Do not start executing the actual development tasks yet; your goal is purely to generate the management and tracking files.

1. **Read the Blueprint Skills:** 
   Read the following directories located in `/Users/mattdyor/.skills/` to understand the templates available.
   *CRITICAL RULE:* For any skill instantiated in the project's `.skills/` directory, if its corresponding blueprint directory contains an `examples/` folder (e.g., `/Users/mattdyor/.skills/[blueprint-name]/examples/`), you MUST copy that entire `examples/` folder into the newly created local skill directory (e.g., `.skills/[local-skill-name]/examples/`).

2. **Generate the `project-skill`:**
   Execute the instructions in `/Users/mattdyor/.skills/kmp-baseline-skill-blueprint/SKILL.md` to create the codebase-specific `.skills/project-skill/SKILL.md` file, which will act as the baseline for architecture rules and library versions. Don't forget to copy the `examples/` folder if it exists.

3. **Generate the `project-guide`:**
   Execute the instructions in `/Users/mattdyor/.skills/project-guide-blueprint/SKILL.md` to create the `.skills/project-guide/SKILL.md` file.
   *Here are the core details for the project you should use to populate the guide:*
   - **App Name:** Factory
   - **Target Audience:** KMP App Builders
   - **Core Problem:** Streamlining the creation and publication of YouTube Short educational videos about the app. 
   - **Visual Style/Theme:** Film noir-classic old school movie theme. 
   - **Core Architecture:** Kotlin Multiplatform (Android, iOS), Jetpack Compose / Compose Multiplatform, Room, Ktor, Koin, Coil, Jetpack Navigation 3, Calf permissions. 
   *Ensure the output strictly follows the Phased Execution structure and uses the `**User Action**`, `**Agent Action**`, and `**Validation**` prefixes for all tasks.*
   **Validation** before moving on to step 4, ask the user verify the contents of `project-guide` and to say 'Proceed' when the review is complete. 

4. **Generate the `project-validation`:**
   Once `project-guide` is created, use the instructions in `/Users/mattdyor/.skills/project-validation-blueprint/SKILL.md` to generate a `.skills/project-validation/SKILL.md` file. Tailor the multi-layered testing plan specifically to the phases and features you just outlined in the `project-guide`. Ask user for any information needed to create a robust validation plan. 

5. **Generate the `project-calculator`:**
   Next, use the instructions in `/Users/mattdyor/.skills/kmp-baseline-calculator-blueprint/SKILL.md` to parse the newly created `project-guide` and generate the initial `.skills/project-calculator/SKILL.md` file to give us our starting baseline progress report. As we work through the `project-guide`, we will periodically run the `project-calculator` to estimate how much of the work we have completed. 

6. **Generate the `AGENTS.md`:**
   Finally, use the instructions in `/Users/mattdyor/.skills/kmp-baseline-agent-blueprint/SKILL.md` to create or update an `AGENTS.md` file in the root directory that has agent instructions that prevent the agent from making mistakes. As we work with this project, we will continue to add more instructions to `AGENTS.md` to keep the agent working smoothly with this project.

Once you have created all the files, let me know, and we will begin executing Phase 1 from the `project-guide`.