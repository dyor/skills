# Planning Skill: Kotlin Multiplatform (KMP) Baseline Blueprint

Welcome to the **KMP Baseline** Planning Skill collection! This repository contains a highly orchestrated set of AI-agent blueprints designed to bootstrap, manage, track, and validate the migration or creation of a premium Kotlin Multiplatform mobile application (targeting Android and iOS).

## Overview of the Collection

A Planning Skill is not a single standalone utility, but rather a structured package of interconnected blueprints. Together, they establish a rigorous Test-Driven Development (TDD) loop, codebase-specific architectural guardrails, and automated progress metrics.

This collection includes the following blueprints:

1. **`kmp-baseline-prompt-blueprint`**: The initial orchestrator that boots up the planning skill, solicits configuration parameters (including the target `<plan_dir>` outside of `.skills/`) from the developer, and generates the codebase-specific plan files.
2. **`kmp-baseline-agent-blueprint`**: Generates specific agent directives for the project's root `AGENTS.md` to prevent execution errors, resource leaks, or hallucinated APIs.
3. **`kmp-baseline-guide-blueprint`**: A phased, step-by-step playbook outlining all user/agent actions and validations required to complete the baseline.
4. **`kmp-baseline-hints-blueprint`**: Holds custom workarounds, library configurations (e.g., Compose, Room, Koin), style guides, and real-world code examples.
5. **`kmp-baseline-calculator-blueprint`**: A utility to parse the progress of your guide and output real-time completion percentages.
6. **`kmp-baseline-validation-blueprint`**: The final quality-assurance suite that must pass (unit tests, UI flow validation journeys, visual layout checks) before the plan is considered done.

---

## Core Principle: Skills Stay Clean, Plans Live Outside `.skills/`

To ensure that your `.skills/` directory can be periodically refreshed from upstream (`github.com/dyor/skills`) without overwriting your project's custom plan:
- **The Blueprints** remain read-only inside `.skills/imported-skills/planning-skills/kmp-baseline/`.
- **Your Active Project Plan** (the customized guide, hints, validation suite, and progress tracker) is materialized **outside** of `.skills/` in a project directory `<plan_dir>` — defaulting to `plans/kmp-baseline/` (or any custom directory you choose, such as `SPECS/kmp-baseline/`).

---

## How to Kick Off This Planning Skill

To begin using this collection of skills in your project, follow these steps:

### Step 1: Import the Collection
Ensure the `kmp-baseline` directory containing these files is imported into your project under `.skills/imported-skills/planning-skills/`:
```text
.skills/imported-skills/planning-skills/kmp-baseline/
```

### Step 2: Execute the Prompt Blueprint
Provide the following command/instruction to your AI agent as the very first prompt in your workspace:

> Please read the orchestrator instructions in `.skills/imported-skills/planning-skills/kmp-baseline/kmp-baseline-prompt-blueprint/SKILL.md` and initialize the KMP baseline setup process.

### Step 3: Configure and Materialize Outside `.skills/`
1. The agent will parse the blueprints and ask you to confirm or customize project parameters (App Name, Architecture, Visual Style) and the target plan directory `<plan_dir>` (default: `plans/kmp-baseline/`).
2. It will then generate your customized project plan files inside `<plan_dir>/`:
   - `<plan_dir>/guide.md`
   - `<plan_dir>/hints.md` (plus `<plan_dir>/examples/` and `<plan_dir>/resources/`)
   - `<plan_dir>/validation.md`
   - `<plan_dir>/progress.md`
   - Root `AGENTS.md`
3. The immutable blueprint templates remain safely in `.skills/imported-skills/planning-skills/kmp-baseline/`, while your active plan lives cleanly in `<plan_dir>/` ready for development and version control.
