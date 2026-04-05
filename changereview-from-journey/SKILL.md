---
name: changereview-from-journey
description: Automates the extraction and formatting of Journey test results from the ephemeral build directory into a persistent Markdown change review document.
---

# `changereview-from-journey` Skill

When a user invokes you with **"run changereview on <journey_name>"** or a similar request to extract journey test results, execute the following steps exactly as described:

## Step 1: Locate the Source Directory
1. The journey name is provided by the user (e.g., `home_screen`, `editing_studio`, `recording_studio`).
2. Search the standard Journey framework output directory inside the project: 
   `androidApp/build/intermediates/debug/testJourneysTestDefaultDebugTestSuite/results/`
3. List the contents of this directory to identify the connected device IDs (e.g., `emulator-5554` or `41241FDJG004Q6`).
4. Navigate into the target `<device-id>/<journey_name>/` folder. Verify that files like `journey_results.pb` and `displayStateX.png` exist. If there are multiple device folders, pick the one that contains the `<journey_name>` files.

## Step 2: Setup Persistent Output Directory
1. Execute a shell command to create a persistent directory and images subfolder for this specific journey:
   `mkdir -p .changereview/<journey_name>/images`

## Step 3: Copy and Resize Assets
1. Execute the dedicated bash script to copy all `.png` screenshots from the ephemeral build folder into the persistent folder, resizing them to exactly 200 pixels wide while maintaining their aspect ratio.
2. Run the following shell command, replacing the placeholders with the actual paths:
   `bash .skills/changereview-from-journey/scripts/copy_and_resize_images.sh <source_device_journey_path> .changereview/<journey_name>/images 200`

## Step 4: Extract Reasoning and Actions
1. Execute a shell command to extract readable text from the protobuf results file:
   `strings <source_device_journey_path>/journey_results.pb`
2. Parse the output in your context window. It will contain strings detailing the steps ("Verify that..."), the Agent's reasoning ("The current screen clearly shows..."), the actions performed ("Tap 'Archives' button"), and the result state ("Goal Complete").

## Step 5: Generate the Change Review Report
1. Synthesize the parsed text and the copied images into a highly readable Markdown document.
2. Determine the overall Pass/Fail status by evaluating the result states of the steps (if any step resulted in "Failed" or "Could not successfully complete", the overall status is **FAIL**. Otherwise, it is **PASS**).
3. Retrieve the current date and time (e.g. by running the `date` shell command).
4. Use the `write_file` tool to save the report to: `.changereview/<journey_name>/changereview.md`
5. Structure the Markdown exactly as follows:
   * Document Title: `# <Journey Name> Change Review`
   * Metadata & Status (Prominently displayed right under the title as a bulleted list to prevent markdown line-collapsing):
     * `* **Date/Time:** <Current Date and Time>`
     * `* **Overall Status:** **[PASS]** (or **[FAIL]**)`
     * `* **Device Tested:** <Device ID>`
   * A sequential breakdown of every step attempted. For each step, include:
     * **Step Action/Goal**
     * **Result** (e.g., Goal Complete / Failed)
     * **Agent Reasoning**
     * **Command Executed** (if applicable, e.g., ADB tap command)
     * **Verification Statement**
     * **Screenshot**: Embed the corresponding screenshot that was copied in Step 3. 
       * **CRITICAL**: Use the absolute path so Android Studio renders it correctly.
       * **CRITICAL**: Do NOT use a table format for the output document as standard Markdown tables cannot enforce column widths in all parsers, leading to squished images. Use standard Markdown headers and paragraphs.
       * *Format*:
         ```markdown
         ### Step 1
         **Goal:** ...
         **Result:** ...
         
         [<img src="file://<absolute_project_path>/.changereview/<journey_name>/images/displayStateX.png" width="200" />](file://<absolute_project_path>/.changereview/<journey_name>/images/displayStateX.png)
         ---
         ```

## Step 6: Notify User
1. Notify the user that the `.changereview/<journey_name>/changereview.md` document has been generated successfully and is ready for inspection.