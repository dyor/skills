---
name: kmp-baseline-calculator-blueprint
description: Blueprint for estimating and reporting how much of the project described in `<plan_dir>/guide.md` has been completed, writing the summary to `<plan_dir>/progress.md` outside of `.skills/`.
version: 2.0.0
---

> [!WARNING] This is an immutable blueprint template used to build the active project plans. Do not execute or edit this file directly while writing code for this codebase. Active project plans must be materialized OUTSIDE of `.skills/` (default: `plans/kmp-baseline/progress.md`, or a custom directory chosen by the user).

# Blueprint Calculator Skill

## When to use this skill
- Use this when generating or updating the progress report for a project at `<plan_dir>/progress.md` (default `plans/kmp-baseline/progress.md`).
- Keeps progress reports alongside your project plan outside `.skills/`.

## How to use it
- Execute the instructions for the AI Assistant below to read `<plan_dir>/guide.md` and create or update `<plan_dir>/progress.md`.

---

# Skill: KMP Project Progress Calculator

## Description
This document provides predefined instructions for an AI assistant to estimate and report how much of the project described in `<plan_dir>/guide.md` (default `plans/kmp-baseline/guide.md`) has been completed.

## Materialization Instructions / Usage
To materialize or update this report in a project, parse `<plan_dir>/guide.md` and write the output to `<plan_dir>/progress.md` (never inside `.skills/`).

---

## Instructions for the AI Assistant

When the trigger prompt is received, please perform the following steps:

### 1. Parse the `<plan_dir>/guide.md` File
Locate `<plan_dir>/guide.md` (default `plans/kmp-baseline/guide.md`). Read its contents to understand the project phases, steps, and associated tasks.

### 2. Calculate Task Metrics
Scan through all the actionable checkboxes (`- [ ]` for incomplete, `- [x]` or `- [X]` for complete) within `guide.md`.
Categorize the tasks by Phase and calculate:
*   **Total Tasks**: The total number of checkbox items in each phase.
*   **Completed Tasks**: The number of tasks marked as `- [x]`.
*   **Pending Tasks**: The number of tasks marked as `- [ ]`.
*   *Action Breakdown*: Count how many pending tasks are assigned to `**User Action**`, `**Agent Action**`, and `**Validation**`.

### 3. Generate `<plan_dir>/progress.md`
Create or update `<plan_dir>/progress.md` with a comprehensive progress report:

*   **Methodology:** A brief explanation that progress is calculated based on the completion of actionable tasks (`- [x]` vs `- [ ]`) outlined in `<plan_dir>/guide.md`.
*   **Phase Breakdown:** A markdown table detailing the progress of each phase (`Phase`, `Total Tasks`, `Completed`, `Pending`, `Completion %`).
*   **Actionable Insights:** A brief list of the immediate next steps (the first 1–3 pending tasks) and who is responsible (`User Action` or `Agent Action`).
*   **Overall Project Progress:** The absolute sum of all completed tasks divided by the total tasks, displayed prominently as a percentage.

### Example Output Structure (`<plan_dir>/progress.md`)
```markdown
# Project Progress Calculation

## Methodology
Progress is calculated by evaluating the completed (`- [x]`) versus pending (`- [ ]`) tasks defined across all phases in `plans/kmp-baseline/guide.md`.

## Phase Breakdown

| Phase | Total Tasks | Completed | Pending | Completion % |
|-------|-------------|-----------|---------|--------------|
| Phase 1: Foundation & Infrastructure | 3 | 3 | 0 | 100% |
| Phase 2: Core Features & Logic | 5 | 2 | 3 | 40% |
| Phase 3: Hardware / Native Integrations | 4 | 0 | 4 | 0% |
| Phase 4: Data Processing & Editing | 2 | 0 | 2 | 0% |
| Phase 5: Distribution & Cloud Sync | 2 | 0 | 2 | 0% |
| Phase 6: The Final Cut | 5 | 0 | 5 | 0% |

## Actionable Insights
*   **Current Phase:** Phase 2: Core Features & Logic
*   **Next Task:** `- [ ] **Agent Action**: Create core UI screens and ViewModels.`
*   **Pending Breakdown:** 1 User Action, 12 Agent Actions, 3 Validations remaining.

---

## Overall Project Progress
*   **Total Tasks**: 21
*   **Completed Tasks**: 5
*   **Pending Tasks**: 16
*   **Overall Completion**: 23.8%
```
