# Planning Skill: Kotlin Multiplatform (KMP) Baseline Blueprint

Welcome to the **KMP Baseline** Planning Skill collection! This repository contains a highly orchestrated set of AI-agent blueprints designed to bootstrap, manage, track, and validate the migration or creation of a premium Kotlin Multiplatform mobile application (targeting Android and iOS).

## Overview of the Collection

A Planning Skill is not a single standalone utility, but rather a structured package of interconnected blueprints. Together, they establish a rigorous Test-Driven Development (TDD) loop, codebase-specific architectural guardrails, and automated progress metrics.

This collection includes the following blueprints:

1. **`kmp-baseline-prompt-blueprint`**: The initial orchestrator that boots up the planning skill, solicits configuration parameters from the developer, generates the codebase-specific tasks, and cleans up templates.
2. **`kmp-baseline-agent-blueprint`**: Generates specific agent directives for the project's root `AGENTS.md` to prevent execution errors, resource leaks, or hallucinated APIs.
3. **`kmp-baseline-guide-blueprint`**: A phased, step-by-step playbook outlining all user/agent actions and validations required to complete the baseline.
4. **`kmp-baseline-hints-blueprint`**: Holds custom workarounds, library configurations (e.g., Compose, Room, Koin), style guides, and real-world code examples.
5. **`kmp-baseline-calculator-blueprint`**: A script utility to parse the progress of your guide task and output real-time completion percentages.
6. **`kmp-baseline-validation-blueprint`**: The final quality-assurance suite that must pass (unit tests, UI flow validation journeys, visual layout checks) before the planning skill is considered done.

---

## How to Kick Off This Planning Skill

To begin using this collection of skills in your project, follow these steps:

### Step 1: Localize the Collection
Ensure the `kmp-baseline` directory containing these files is copied or imported into your project under the `.skills/planning-skills/` folder:
```
.skills/planning-skills/kmp-baseline/
```

### Step 2: Execute the Prompt Blueprint
Provide the following command/instruction to your AI agent as the very first prompt in your workspace:

> Please read the orchestrator instructions in `.skills/planning-skills/kmp-baseline/kmp-baseline-prompt-blueprint/SKILL.md` and initialize the KMP baseline setup process.

### Step 3: Configure and Validate
1. The agent will parse the blueprints and ask you to confirm or customize project parameters (e.g. App Name, Architecture, Visual Style).
2. It will then generate localized `-local` directories (e.g. `kmp-baseline-guide-local/`) inside the same `kmp-baseline` folder.
3. Finally, it will clean up the `-blueprint` folders, leaving a clean workspace ready for development with this `README.md` remaining as your execution guide.
