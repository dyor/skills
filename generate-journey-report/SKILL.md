---
name: generate-journey-report
description: Automates the execution of an Agent Journey test and generates a persistent Markdown change review document with screenshots.
import_commit: raw
import_date: 2026-04-18 23:51:21
import_url: https://github.com/dyor/skills/raw/main/changereview-from-journey/SKILL.md
---

# `generate-journey-report` Skill

When a user invokes you with **"run generate-journey-report on <journey_name>"** or a similar request to execute a journey and generate a report, execute the following steps exactly as described. This is typically run at the end of a long-running phase of work to generate verifiable proof of progress for the developer.

## Step 1: Locate and Parse the Journey File
1. The journey name is provided by the user (e.g., `sample_journey`, `home_screen`).
2. Use the `find_files` or `code_search` tool to locate the `<journey_name>.journey.xml` file within the project (typically under `app/src/journeysTest/`).
3. Read the file to extract the list of `<action>` steps that you need to perform.

## Step 2: Setup Persistent Output Directory
1. Execute a shell command to create a persistent directory and images subfolder for this specific journey:
   `mkdir -p .journey_reports/<journey_name>/latest/images`

## Step 3: Execute the Journey Directly & Capture Screenshots
1. Launch the app using the `deploy` tool.
2. **CRITICAL:** For *each* action/step extracted from the journey XML, act as the user testing the application:
   * Use `ui_state` to understand the current screen.
   * Use `adb_shell_input` to perform the required UI interactions to achieve the step.
   * Once the step is successfully completed, capture a screenshot of the resulting device screen. Save it directly to the persistent directory using:
     `adb -s <device-id> exec-out screencap -p > .journey_reports/<journey_name>/latest/images/step_<step_number>.png`
   * Keep a log in your memory of the Step Action/Goal and the pass/fail result so you can write the report later.

### If a Step Fails:
* Do **NOT** change the journey test to force it to pass.
* You must attempt to repair the *application code* to fix the bug.
* After applying the code fix, redeploy the app and restart the journey.
* If the journey still fails after multiple repair attempts (e.g., 3 tries), you must **stop work completely** (even if operating continuously) and ask the user for manual intervention. Do not proceed to generate a "passing" report.

## Step 4: Downscale Screenshots (Crucial for IDE Rendering)
1. Android Studio's Markdown renderer often ignores HTML image width attributes, making raw screenshots appear huge. Therefore, physically resizing the images is highly recommended.
2. **OS Dependency Check:** The provided bash script uses `sips`, which is a **macOS-exclusive** command line tool.
   * Before resizing, check the host OS (e.g., using `uname -s`).
   * **If macOS:** Run the script (using the `images` folder as both source and destination):
     `bash .skills/imported-skills/generate-journey-report/scripts/copy_and_resize_images.sh .journey_reports/<journey_name>/latest/images .journey_reports/<journey_name>/latest/images 200`
   * **If Linux/Windows:** Do *not* run the script. You may attempt to resize using `mogrify -resize 200x` if ImageMagick is installed, or otherwise skip the resizing step.

## Step 5: Generate the Change Review Report
1. Synthesize your logged execution steps and the captured images into a clean, business-level Markdown document. Do **NOT** include internal agent mechanics (like "adb shell commands" or "agent reasoning/jargon"). The report should solely document the outcome.
2. Determine the overall Pass/Fail status. If any step failed, the overall status is **FAIL**. Otherwise, it is **PASS**.
3. Retrieve the current date and time (e.g., by running the `date` shell command).
4. Use the `write_file` tool to save the report to: `.journey_reports/<journey_name>/latest/report.md`
5. Structure the Markdown exactly as follows:
   * Document Title: `# <Journey Name> Execution Report`
   * Metadata & Status:
     * `* **Date/Time:** <Current Date and Time>`
     * `* **Overall Status:** **[PASS]** (or **[FAIL]**)`
     * `* **Device Tested:** <Device ID>`
   * A sequential breakdown of every step attempted. For each step, include:
     * **Step Action/Goal**
     * **Result** (e.g., Goal Complete / Failed)
     * **Screenshot**: Embed the corresponding screenshot that was captured in Step 3. 
       * **CRITICAL**: Use the absolute path so Android Studio renders it correctly.
       * **CRITICAL**: Do NOT use a table format for the output document as standard Markdown tables cannot enforce column widths in all parsers, leading to squished images. Use standard Markdown headers and paragraphs.
       * *Format*:
         ```markdown
         ### Step 1
         **Goal:** [Insert Action From XML]
         **Result:** ✅ Complete
         
         ![Step 1 Screenshot](file://<absolute_project_path>/.journey_reports/<journey_name>/latest/images/step_1.png)
         ---
         ```

## Step 6: Notify User
1. Notify the user that the `.journey_reports/<journey_name>/latest/report.md` document has been generated successfully. If operating in Guided Migration mode, pause and await their review before continuing to the next phase. If operating in Autonomous Migration mode, proceed immediately to the next phase.