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
1. Execute a shell command to create a persistent directory for this specific journey:
   `mkdir -p .changereview/<journey_name>`

## Step 3: Copy Assets
1. Execute a shell command to copy all `.png` screenshots from the ephemeral build folder into the persistent folder:
   `cp <source_device_journey_path>/*.png .changereview/<journey_name>/`

## Step 4: Extract Reasoning and Actions
1. Execute a shell command to extract readable text from the protobuf results file:
   `strings <source_device_journey_path>/journey_results.pb`
2. Parse the output in your context window. It will contain strings detailing the steps ("Verify that..."), the Agent's reasoning ("The current screen clearly shows..."), the actions performed ("Tap 'Archives' button"), and the result state ("Goal Complete").

## Step 5: Generate the Change Review Report
1. Synthesize the parsed text and the copied images into a highly readable Markdown document.
2. Use the `write_file` tool to save the report to: `.changereview/<journey_name>-changereview.md`
3. Structure the Markdown as follows:
   * Document Title: `# <Journey Name> Change Review`
   * Metadata: Journey File, Device Tested.
   * A sequential breakdown of every step attempted. For each step, include:
     * **Step Action/Goal**
     * **Result** (e.g., Goal Complete / Failed)
     * **Agent Reasoning**
     * **Command Executed** (if applicable, e.g., ADB tap command)
     * **Verification Statement**
     * **Screenshot**: Embed the corresponding screenshot that was copied in Step 3. 
       * **CRITICAL**: Use the absolute path so Android Studio renders it correctly.
       * **CRITICAL**: Wrap the image in a link to itself so the user can pop it out. Constrain the width so it isn't massive.
       * *Format*: `[<img src="file://<absolute_project_path>/.changereview/<journey_name>/displayStateX.png" width="150" />](file://<absolute_project_path>/.changereview/<journey_name>/displayStateX.png)`

## Step 6: Notify User
1. Notify the user that the `<journey_name>-changereview.md` document has been generated successfully and is ready for inspection.