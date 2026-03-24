---
name: kmp-baseline-calculator-blueprint
description: Blueprint for estimating and reporting how much of the project described in the kmp-baseline-guide-task has been completed.
---

# Blueprint Calculator Skill

## When to use this skill
- Use this when generating a new progress calculator for a project at `kmp-baseline-calculator-task/SKILL.md`.
- This is helpful for structuring the report correctly.

## How to use it
- Execute the instructions for the AI Assistant below to read a `kmp-baseline-guide-task/SKILL.md` and create a `kmp-baseline-calculator-task/SKILL.md` where the `kmp-baseline-calculator-task` is used to estimate how much of the work covered by the `kmp-baseline-guide-task` has been completed.

---

# Skill: KMP Project Progress Calculator

## Description
This document provides predefined instructions for an AI assistant to estimate and report how much of the project described in the `.skills/kmp-baseline-guide-task/SKILL.md` file has been completed. 

## Materialization Instructions / Usage
To materialize this skill in a new project, copy or generate the contents of this blueprint into a new file located at `.skills/kmp-baseline-calculator-task/SKILL.md` within the user's project codebase. Then, prompt the AI to calculate the project progress in accordance with it.

---

## Instructions for the AI Assistant

When the trigger prompt is received, please perform the following steps:

### 1. Parse the `kmp-baseline-guide-task` File
Locate the `.skills/kmp-baseline-guide-task/SKILL.md` file. Read its contents to understand the project phases, steps, and associated tasks.

### 2. Calculate Task Metrics
Scan through all the actionable checkboxes (e.g. `- [ ]` for incomplete, `- [x]` or `- [X]` for complete) within the `kmp-baseline-guide-task` document.
Categorize the tasks by Phase and calculate:
*   **Total Tasks**: The total number of checkbox items in each phase.
*   **Completed Tasks**: The number of tasks marked as `- [x]`.
*   **Pending Tasks**: The number of tasks marked as `- [ ]`.
*   *Action Breakdown*: Count how many pending tasks are assigned to `**User Action**`, `**Agent Action**`, and `**Validation**`.

### 3. Generate `kmp-baseline-calculator-task`
Create or update `.skills/kmp-baseline-calculator-task/SKILL.md` with a comprehensive progress report. Populate it with the standard YAML frontmatter and the following structure:

*   **Methodology:** A brief explanation that progress is calculated based on the completion of actionable tasks (`- [x]` vs `- [ ]`) outlined in the `kmp-baseline-guide-task` phases.
*   **Phase Breakdown:** A markdown table detailing the progress of each phase. The table must have the following columns:
    *   `Phase`
    *   `Total Tasks`
    *   `Completed`
    *   `Pending`
    *   `Completion %`
*   **Actionable Insights:** A brief list of the immediate next steps (the first 1-3 pending tasks) and who is responsible (`User Action` or `Agent Action`).
*   **Overall Project Progress:** The absolute sum of all completed tasks divided by the total tasks, displayed prominently as a percentage.

### Example Output Structure
```markdown
---
name: kmp-baseline-calculator-blueprint
description: Tracks and calculates the overall completion percentage of the project based on the kmp-baseline-guide-task tasks.
---

# Progress Calculator

## When to use this skill
- Use this when needing to update or view the current completion percentage of the project.
- This is helpful for providing a summary of how many tasks are completed versus pending.

## How to use it
- Reference the latest kmp-baseline-guide-task status.
- Tally the `[x]` vs `[ ]` tasks to output an updated metric.

---

# Project Progress Calculation

## Methodology
Progress is calculated by evaluating the completed (`- [x]`) versus pending (`- [ ]`) tasks defined across all phases in the `.skills/kmp-baseline-guide-task/SKILL.md` file.

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