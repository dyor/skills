---
name: kmp-baseline-validation-blueprint
description: Tracks the validation of explicitly defined end-to-end user journeys in the application.
---

# User Journey Validation

This document contains a rigorous, multi-layered testing plan tailored precisely to the actual end-state functionality of the application. Journeys represent the final shipping product, not intermediate development steps (e.g., validating a navigation graph with empty placeholder screens).

## Execution Protocol
1.  **Agent Validations**: The AI agent will first execute any programmatically verifiable tests, scripts, or inspection to confirm the behavior.
2.  **User Validations**: The AI agent will then prompt the User to manually navigate the application UI to functionally experience the journey. 
3.  **Bug Tracking**: If a journey fails validation, the AI agent must abort the validation process, update the appropriate phase in `kmp-baseline-guide-task` with a new `**Agent Action**: Fix bug [...]`, and resolve the issue before re-attempting validation.

---

## Journey 0: KMP Baseline (Joke App)
Goal: Verify that the core KMP stack (Calf, Room, Nav 3, Ktor, Gemini, Material 3) is working together correctly before adding app-specific features.

- [ ] **Agent Validation**: Verify that Ktor can reach Gemini, Room can persist data, and Compose Navigation 3 handles backstack. Verify that the UI uses Material 3 tokens (colors/spacing) and no hardcoded values are found in the baseline code.
- [ ] **User Validation**: Launch the app. You should see a clean Material 3 screen with a "Tell me a joke" button. Tap it. Verify a truncated list of jokes appears. Tap a joke to see the full text. Use the back button to return. Confirm no Film Noir styling or video features are present yet.

---

## Journey 1: Writer's Room
Description: Verify that the user can generate, fine-tune, edit, and persist a strictly formatted script.
Actions:
- [ ] Tap 'Start New Video' or 'Continue' to navigate to the Writer's Room.
- [ ] Keep the slider at the default 15 second duration.
- [ ] Enter "Teach people to do pushups" in the prompt idea box.
- [ ] Tap 'Generate Script' and wait for the generated script to appear on screen - this should only be done once and may take 20 seconds.
- [ ] Check that the generated text contains duration timestamps like '0s-5s' without conversational filler.
- [ ] Edit a portion of the generated script text.
- [ ] Tap 'Record' to go to the recording studio.

---

## Journey 2: Recording Studio
Description: Verify that the user can record video using the front-facing camera while following the teleprompter.
Actions:
- [ ] Tap the "Writer's Room" button.
- [ ] Type the following EXACTLY into the Generated Script Content text box: "0s-5s: Master the perfect push-up right now!\n5s-15s: Hands shoulder-width, body straight from head to heels. Engage your core."
- [ ] Tap the "Record" button to proceed to the Recording Studio.
- [ ] Check that the bottom half of the screen shows the live front-facing camera view.
- [ ] Tap the wide button labeled 'Start' on the right side of the bottom navigation bar to begin recording.
- [ ] Wait for the 5-second countdown to finish.
- [ ] Wait for 20 seconds while the teleprompter recording finishes.
- [ ] Verify that the teleprompter advances correctly based on the target duration timestamps and finishes at about 19 seconds (given the 2 second buffer after each segment).
- [ ] Check that the visual timeline advances automatically counting down the remaining time for the entire video (the script duration + 2 second buffers after each).
- [ ] When recording completes, verify that navigation option 'Edit' appears.
- [ ] Tap 'Edit' to advance to the next screen.
- [ ] Verify that the screen title is now "Editing Studio".

---

## Journey 3: Editing Studio
Description: Verify that the user can precisely define sections of the recorded video to trim and recover.
Actions:
- [ ] Tap the "Writer's Room" button.
- [ ] Type the following EXACTLY into the Generated Script Content text box: "0s-5s: Master the perfect push-up right now!\n5s-15s: Hands shoulder-width, body straight from head to heels. Engage your core."
- [ ] Tap the "Record" button to proceed to the Recording Studio.
- [ ] Check that the bottom half of the screen shows the live front-facing camera view.
- [ ] Tap the wide button labeled 'Start' on the right side of the bottom navigation bar to begin recording.
- [ ] Wait for the 5-second countdown to finish.
- [ ] Wait for 20 seconds while the teleprompter recording finishes.
- [ ] Verify that the teleprompter advances correctly based on the target duration timestamps and finishes at about 19 seconds (given the 2-second buffer after each segment).
- [ ] When recording completes, verify that navigation option 'Edit' appears.
- [ ] Tap 'Edit' to advance to the next screen.
- [ ] Verify that the screen title is now "Editing Studio".
- [ ] Verify that the timeline of seconds blocks roughly matches the length of the recorded video - approximately 19 seconds.
- [ ] Click on the 0-second block to open the 'Fine-tune' modal and click skip all.
- [ ] Click the "Done" button to close the modal.
- [ ] Click on the 1-second block to open the Fine-tune modal and skip the first .1 second (the first block on the left).
- [ ] Click the "Done" button to close the modal.
- [ ] Verify that the 0s block is red (fully skipped) and the 1s block is orange (partially skipped).
- [ ] Click play and ensure that the skipped segments are shown with a red overlay indicated that they will be cut when published.
- [ ] Ensure that the active second block is highlighted with a yellow border on the seconds button.
- [ ] Tap 'Publish' to advance to the next screen.
- [ ] Verify that the screen title is now "Publishing Studio".

---

## Journey 4: Publishing Studio
Description: Verify that the user can seamlessly share the generated and edited video to external channels.
Actions:
- [ ] Tap the "Writer's Room" button.
- [ ] Type the following EXACTLY into the Generated Script Content text box: "0s-5s: Master the perfect push-up right now!\n5s-15s: Hands shoulder-width, body straight from head to heels. Engage your core."
- [ ] Tap the "Record" button to proceed to the Recording Studio.
- [ ] Check that the bottom half of the screen shows the live front-facing camera view.
- [ ] Tap the wide button labeled 'Start' on the right side of the bottom navigation bar to begin recording.
- [ ] Wait for the 5-second countdown to finish.
- [ ] Wait for 20 seconds while the teleprompter recording finishes.
- [ ] Verify that the teleprompter advances correctly based on the target duration timestamps and finishes at about 19 seconds (given the 2-second buffer after each segment).
- [ ] When recording completes, verify that navigation option 'Edit' appears.
- [ ] Tap the "Edit" button to advance to the Editing Studio.
- [ ] Verify that the screen title is now "Editing Studio".
- [ ] Verify that the timeline of seconds blocks roughly matches the length of the recorded video - approximately 19 seconds.
- [ ] Click on the 0-second block to open the 'Fine-tune' modal and click skip all.
- [ ] Click the "Done" button to close the modal.
- [ ] Click on the 1-second block to open the Fine-tune modal and skip the first .1 second (the first block on the left).
- [ ] Click the "Done" button to close the modal.
- [ ] Verify that the 0s block is red (fully skipped) and the 1s block is orange (partially skipped).
- [ ] Click play and ensure that the skipped segments are shown with a red overlay indicated that they will be cut when published.
- [ ] Ensure that the active second block is highlighted with a yellow border on the seconds button.
- [ ] Tap 'Publish' to advance to the next screen.
- [ ] Verify that the screen title is now "Publishing Studio".
- [ ] Click the play ▶ button to preview the video.
- [ ] Ensure the video preview plays cleanly without any of the sections marked 'skipped' from the Editing Studio - the first 1.1 seconds.
- [ ] Select the option to 'Export' the video.
- [ ] Confirm that the action successfully triggers the native Photo App save or external share sheet (like YouTube Shorts).

---

## Journey 5: Archives
Description: Verify that users can see past projects and restore an archived project to active status.
Actions:
- [ ] First we have to create a script so we can archive it, so click on Writers Room - Tap the "Writer's Room" button.
- [ ] Type the following two lines EXACTLY into the Generated Script Content text box. Do NOT type these instructions into the box. ONLY type these two lines:
"0s-5s: Master the perfect push-up right now!"
"5s-15s: Hands shoulder-width, body straight from head to heels. Engage your core."
- [ ] Tap the "Record" button to proceed to the Recording Studio.
- [ ] Archive this script by clicking on the ↓ archive button and confirm the Archive Video prompt (click Yes).
- [ ] On the home screen tap 'The Archives'.
- [ ] Confirm that previously archived script appears in the list.
- [ ] Tap on an archived video card and confirm Restore Project.
- [ ] Verify that the selected project becomes the Active Project and the app shows the Recording Studio as the active step.

---

## Notes for Blueprint
*   **Philosophy Shift**: Validation tasks must focus exclusively on end-state functionality representing the final shipping product, not intermediate development steps (e.g., "Phase 1: Core Navigation" with empty screens). 
*   **Journey 1 (Home Screen)**: Focus on thematic consistency (background images, readable text contrast, non-default colors) and dynamic state routing (Active project routing vs. "Start New Video"). Remove intermediate placeholder UI tests. Ensure "Archives" is always accessible.
*   **Writer's Room**: Added strict formatting validation requirements for the LLM output. The script must ONLY contain teleprompter words and timestamps (e.g., "0s-5s: Hello..."), stripping conversational filler or background context.
*   **Editing Studio**: Collapsed "Phase 5 (Polish)" requirements into the core Editing Studio journey. The validation must explicitly check for 0.1s granularity seeking, visual indicators of skipped segments (red blocks), the "Preview without Skipped Frames" feature, and accurate native trimming logic.
*   **Archives**: Explicitly added an Archives journey to ensure the user can see past projects and restore an archived project to active status.