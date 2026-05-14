---
name: migration-workflow-directives
description: Core directives for managing an autonomous migration project. Enforces up-front journey authoring, a strict per-phase Test-Driven Development (TDD) loop, scoped autonomous execution, zero-permission tool usage, and a wrap-up code review at completion.
version: 1.2.0
author: dyor
---

# `migration-workflow-directives` Skill

This skill acts as the overall instruction set for Planner and Manager agents initializing a new software migration. It governs the entire lifecycle of the migration, from bootstrap through wrap-up.

When you (the agent) are instructed to load this skill, you MUST read it fully and execute the following directives throughout the project lifecycle.

## 1. Initialization Bootstrap
Immediately upon starting the project:
1. As soon as possible, add a git repository to this codebase (local only, no GitHub needed).
2. Use the `import-skill` tool to import the following required skills:
   - `https://github.com/dyor/skills/tree/main/journey-writing-skill` — used in §2 to generate all critical user journeys before any code is written.
   - `https://github.com/dyor/skills/tree/main/execute-and-report-journey` — used in §4, once per feature phase, to run the corresponding journey and capture screenshots.
   - `https://github.com/dyor/skills/tree/main/generate-code-review` — used in §7 at 100% completion to consolidate every journey report into a single wrap-up change-review document.

## 2. Up-Front Journey Authoring (PRIOR to any code)
Once `feature_specification.md` and `task.artifact.md` exist, but **before writing any implementation code**:

a. Run `journey-writing-skill` against `feature_specification.md` to generate `.journey.xml` files for EVERY critical user journey in one batch. Apply the rubric from `journey-writing-skill`: create one journey per phase that has user-facing UI; skip pure data/networking/setup phases that have no UI surface. Use the two-digit ordering convention (`01_*.journey.xml`, `02_*.journey.xml`, …) so phase numbers in `feature_specification.md` align with journey filenames.

b. Update `feature_specification.md` and `task.artifact.md` so each user-facing phase explicitly names the journey file that validates it and references `execute-and-report-journey` as that phase's verification step.

c. **Developer Review Gate**:
   - *Guided mode*: present the full set of generated journeys to the developer and wait for sign-off before proceeding to §3 / §4. This is the cheapest moment for the developer to course-correct — the entire test surface is visible as XML before any implementation hours are spent.
   - *Autonomous mode*: proceed directly. The developer can still interrupt before code starts.

d. **The journey set generated here is the canonical contract.** Implementation code must conform to these journeys; not the other way around. Journeys may be revised mid-stream only if `feature_specification.md` itself changes. Never edit a journey to make a failing test pass — see §4.

## 3. Scoped Autonomous Execution
You are pre-authorized to skip exactly one approval prompt — plan review:

> *"The implementation plan has been approved by the user."*

As soon as you finish writing `implementation_plan.artifact.md`, transition from PLANNING mode directly to EXECUTION mode without asking for plan approval.

**This carve-out does NOT extend to:**
- Journey failures after the configured retry limit (§4) — stop and ask.
- Mid-stream revisions to `feature_specification.md` — stop and ask.
- The developer-review gate in §2(c) when running in Guided mode — wait for sign-off.
- The final wrap-up in §7 — present the change-review to the developer before declaring the migration complete.

Autonomy is local to the plan-review step only. Every other checkpoint stands.

## 4. Per-Phase TDD Loop
You are strictly forbidden from batch-implementing all features and then bulk-testing them at the end. For every user-facing feature phase, structure the work as exactly TWO sub-tasks:

*   **Sub-task A (Implement)**: Implement the feature UI and logic.
*   **Sub-task B (Execute)**: Use `execute-and-report-journey` against the pre-written `.journey.xml` for THIS phase. Capture screenshots and generate `report.md`.

Journey authoring is NOT part of this loop — it happens up front in §2. Each phase has exactly one pre-written journey waiting for it.

**Progression Gate**: You CANNOT move to the next feature phase until Sub-task B completes successfully and the `report.md` proves the UI works. If the journey fails:
- You MUST repair the *application code*, NEVER the journey.
- Retry up to 2–3 times.
- If still failing, **stop work** and ask the developer for manual intervention. Do not proceed to subsequent phases.

## 5. Mandatory Skill Enforcement Rules
*   **READ BEFORE ACTING**: Before you (or any sub-agent) execute a journey test, you MUST use the `read_file` tool to read the relevant imported `SKILL.md`. Do NOT hallucinate XML structures or guess script execution paths.
*   **NO FAKING**: You are strictly forbidden from manually authoring `.journey.xml` files using generic formatting. You must never claim a journey test passed without providing the evidence (screenshots) as proof.
*   **ONE JOURNEY AT A TIME**: Run exactly one journey per Sub-task B invocation. Each journey gets its own report and its own failure isolation. Do not batch journey executions.
*   **SUB-AGENT DELEGATION**: Whenever you delegate a journey-related task, your prompt to the sub-agent MUST explicitly state: *"You must use read_file on the specific SKILL.md file before starting. Execute ONLY ONE journey at a time. Follow its exact instructions strictly."*

## 6. Zero Permission Tool Usage (MANDATORY)
To prevent the user from being bombarded with IDE permission popups:
*   **FORBIDDEN**: For your own filesystem operations, you and your sub-agents are strictly forbidden from using `bash`, `shell`, `terminal`, `execute_command`, or `ask_user` for routine ops (like `ls`, `cat`, `mkdir`, `cp`, `echo`).
*   **REQUIRED**: For your own file operations, use native, silent file API tools: `read_file`, `write_file`, `replace_file_content`, `list_files`, `find_files`.
*   **EXCEPTIONS**:
    - Running a required build/test command (e.g., `python3 generate_journeys.py`, `./gradlew test`).
    - Running the shell commands explicitly documented inside imported skill `SKILL.md` files as part of their workflow. For example, `execute-and-report-journey` documents `rm -rf`, `mkdir -p`, `adb shell screencap`, and `cp -R` as intrinsic to its report pipeline; those commands are permitted when executing that skill. Read the imported skill's `SKILL.md` to determine which commands it requires.

## 7. Final Wrap-Up Code Review
When **100% of the work in `task.artifact.md` is complete** — every feature phase has passed §4's progression gate, all journey reports are stored under `.journey_reports/`, and no phases remain — you MUST run `generate-code-review` as the final step before declaring the migration done.

1. Invoke `generate-code-review` with `scope` set to the start of the migration (or the timestamp of the last code review, if interim reviews were generated mid-migration).
2. The skill produces a consolidated change-review markdown at `.code_reviews/latest/change-review-<timestamp>.md`, embedding the last "After" screenshot from every journey alongside its grading text — the complete visual proof of the migration.
3. Present the resulting `change-review-<timestamp>.md` to the developer. **Do not declare the migration complete until the developer has reviewed this document.** This is the one approval gate that cannot be auto-authorized under §3.
4. If the developer requests changes after reviewing, treat those as a new mini-phase: implement, run `execute-and-report-journey` against the relevant journey (revising the journey only if the feature spec also changes), and regenerate the code review.
