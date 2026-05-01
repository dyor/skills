---
name: execute-and-report-journey
description: Executes a Journey test, validates UI, captures screenshots, and maintains a live Markdown report of its progress with Before/After image comparisons.
version: 1.0.0
author: dyor
---

# `execute-and-report-journey` Skill

When a user invokes you with **"run execute-and-report-journey on <journey_name>"** or a similar request, this skill executes the journey test and generates a persistent Markdown change review document with Before/After screenshots. It minimizes IDE permission interruptions by batching file writes and image processing.

## Workflow

1.  **Initialize Directories & Report:** 
    *   Ensure the base directory structure exists for the current journey.
    *   Clear out any previous run data in the `latest` folder: `rm -rf .journey_reports/<journey_name>/latest/`
    *   Create the necessary directories: `mkdir -p .journey_reports/<journey_name>/latest/images/`

2.  **Execute Step & Capture Screenshots:** For each action in the journey:
    *   Determine the current UI state using `ui_state`.
    *   Perform necessary UI actions using `adb_shell_input` or other tools.
    *   Verify the outcome using `ui_state`.
    *   **Capture Screenshot:** Take a screenshot of the resulting screen by running `adb shell screencap -p > .journey_reports/<journey_name>/latest/images/step_<step_number>.png`.

3.  **Judge Action & Failure Loop:**
    *   Keep track of the pass/fail status and detailed grading for each step in your memory to build the report.
    *   **If a step fails:** 
        *   Do **NOT** change the journey test to force it to pass.
        *   You must attempt to repair the *application code* to fix the bug with **at least one retry**.
        *   After applying the code fix, redeploy the app and restart the journey.
        *   **If the journey passes after a fix**: When generating the final report, the screenshots from the failed/previous run will act as the "Before" images, and the screenshots from the newly successful run will act as the "After" images.
        *   **If the journey still fails** after multiple repair attempts (e.g., 2-3 tries), you must **stop work completely** and ask the user for manual intervention. Do not proceed to generate a "passing" report.

4.  **Repeat:** Continue to the next action and repeat steps 2 and 3 until all actions are completed. *To avoid IDE prompt interruptions, do NOT write to the report file piecemeal or use shell commands for formatting.*

5.  **Batch Resize Images & Finalize Report:**
    *   **Resize all captured screenshots at once** using the provided bash script to prevent constant IDE permission prompts:
        `bash .skills/imported-skills/execute-and-report-journey/scripts/copy_and_resize_images.sh .journey_reports/<journey_name>/latest/images .journey_reports/<journey_name>/latest/images 300`
    *   **Find Previous Archive:** Use `ls -td .journey_reports/<journey_name>/archive/* 2>/dev/null | head -1` to find the most recent previous run (if any).
    *   **Construct Markdown Report:** Build the entire final markdown report in memory. For each step's screenshot, if a previous run exists, embed the images in a Before/After table:
        ```markdown
        | Before | After |
        |---|---|
        | ![Before](file://<absolute_path_to_archived_step_image>) | ![After](file://<absolute_path_to_latest_step_image>) |
        ```
        If no previous run exists, just use a standard image tag: `![Step <step_number>](file://<absolute_path_to_latest_step_image>)`
    *   Use the **native `write_file` tool** to save the complete `report.md` file *once*. Do NOT use `echo` via `run_shell_command` as this breaks formatting and prompts the user repeatedly.
    *   Generate a timestamp (e.g., `yyyy-MM-dd-HH-mm`).
    *   Copy the entire `latest/` directory to the archive: `mkdir -p .journey_reports/<journey_name>/archive/<timestamp> && cp -R .journey_reports/<journey_name>/latest/* .journey_reports/<journey_name>/archive/<timestamp>/`

## Example Report Format

```markdown
# Journey Report: 04_lines_directory.journey.xml

## Execution Summary

| Action | Status |
| :--- | :--- |
| Verify the list of transit lines is visible. | ✅ Passed |

## Detailed Grading

### 1. Verify the list of transit lines is visible.
*   **Result:** ✅ Passed
*   **Grading:** Verified list is visible and styled properly.

| Before | After |
|---|---|
| ![Before](file:///Users/mattdyor/metropolist8/.journey_reports/04_lines_directory/archive/2026-04-30-10-37/images/step_1.png) | ![After](file:///Users/mattdyor/metropolist8/.journey_reports/04_lines_directory/latest/images/step_1.png) |
```