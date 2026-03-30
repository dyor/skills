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

## Journey 1: Home Screen
Goal: Verify that the application boots into a correctly themed environment that dynamically routes the user based on their active project state.

- [ ] **Agent Validation**: Ensure the app renders with a background image (`film_noir.png`) and the theme is consistent with this aesthetic (e.g., overriding standard material purple with high-contrast, readable text colors).
- [ ] **User Validation**: Launch the app. Confirm the background image is present and text is clearly readable. Verify that if there is an active script, the user is presented with a button to continue in the appropriate room (Writer's Room, Recording Studio, Editing Studio, Publishing Studio). Verify that if there is NO active script, the user is presented with an option to "Start New Video". Confirm that the "Archives" button is always an available option on the Home screen.

## Journey 2: Writer's Room
Goal: Verify that the user can generate, fine-tune, edit, and persist a strictly formatted script using Gemini.

- [ ] **Agent Validation**: Ensure that the Gemini prompt strictly requests a response formatted as `0s-5s: Spoken words` and programmatically verify that the output strips out conversational filler or background information. Ensure Room DB successfully persists `Script` entities.
- [ ] **User Validation**: Navigate to the Writer's Room. Select a target duration (5s to 60s) using the slider. Click generate and ensure a valid script appears within 60 seconds. Verify the text *only* contains the time duration and the words for the teleprompter (e.g., "0s-5s: Hello YouTube Creators..."), with no background info. Edit a portion of the script text, tap 'Save', and verify it persists correctly. Confirm that saving automatically enables navigation to the Recording Studio.

## Journey 3: Recording Studio
Goal: Verify that the user can record video using the front-facing camera while following the teleprompter.

- [ ] **Agent Validation**: Verify ViewModel logic accurately manages the 5-second countdown timer and synchronizes the active script with the teleprompter advancement based on the target duration. Ensure the recording screen correctly observes variables mapping to "Time left in current caption" and "Time left in whole video".
- [ ] **User Validation**: Navigate to the Recording Studio. Confirm the top half displays the previously saved script and the bottom half shows the live front-facing camera view (with touch events disabled). Tap the Start button. Wait for the 5-second countdown, and verify the teleprompter advances correctly until the target duration is met (e.g., 0s-5s shows up for 5 seconds, then transitions to the 5s-11s caption for 6 seconds). Verify that two counters exist (one for time remaining in current caption, one for time remaining in video) and count down accurately. When recording completes, confirm that navigation to go back (to Writer's Room) and forward (to Editing Studio) works.

## Journey 4: Editing Studio
Goal: Verify that the user can precisely define sections of the recorded video to trim and recover, utilizing fine-tune controls.

- [ ] **Agent Validation**: Verify timeline scaling and metadata generation correctly load the local file path. Run tests validating the native video extraction logic and verify tenth-of-a-second granularity constraints.
- [ ] **User Validation**: Navigate to the Editing Studio. Verify the video player controls. Open the Fine-tune modal and verify you can adjust playback blocks in tenth-of-a-second increments (0.0s to 0.9s). Select sections of the video to skip/remove; verify that the video seeks to the selected segment and visually indicates the segment as skipped (e.g., showing red). Tap "Preview without Skipped Frames" and confirm that playback accurately and seamlessly skips all marked/red sections. Select 'Save' to process the complex native trimming and confirm navigation logic to proceed to the Publishing Studio.

## Journey 5: Publishing Studio
Goal: Verify that the user can seamlessly share the generated and edited video to external channels.

- [ ] **Agent Validation**: Ensure external share URI intents (on Android) and corresponding Activity View Controllers (on iOS) are properly structured and permissioned for external apps. Verify app branding shows as 'The Factory' with proper visual icons.
- [ ] **User Validation**: Navigate to the Publishing Studio. Ensure the video preview displayed on screen plays cleanly without any of the sections marked 'skipped/red' from the Editing Studio. Select the option to export the video. Confirm it successfully saves to the native Photo App or directly opens into YouTube Shorts if installed.

## Journey 6: Archives
Goal: Verify that users can see past projects and restore an archived project to active status.

- [ ] **Agent Validation**: Ensure that the database query for the Archives correctly fetches scripts where `scriptState == 'ARCHIVES'` or `isActive == false` and populates a list.
- [ ] **User Validation**: Navigate to the Archives screen from the Home Screen. Confirm that previously archived videos (or scripts) appear in a list. Tap on an archived video, select a "Restore" or "Make Active" option, and verify you are immediately routed to the Home Screen or appropriate studio, and the project is now the Active Project.
