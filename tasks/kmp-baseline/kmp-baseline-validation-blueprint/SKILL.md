---
name: kmp-baseline-validation-blueprint
description: The central source of truth for planning and tracking explicitly validated app-specific user journeys.
---

# Skill: Validate User Journeys via kmp-baseline-validation-task/SKILL.md

## Overview
This skill provides the structure and instructions for generating and executing the `kmp-baseline-validation-task/SKILL.md` file, which tracks specific end-to-end user journeys defined by the project.

## Materialization Instructions
When placed in a new codebase and asked to create a `kmp-baseline-validation-task/SKILL.md`, create the file at `.skills/tasks/kmp-baseline/kmp-baseline-validation-task/SKILL.md`. Generate the document following this exact structure:

## `kmp-baseline-validation-task/SKILL.md` Template

```markdown
---
name: kmp-baseline-validation-task
description: Tracks the validation of explicitly defined end-to-end user journeys in the application.
---

# User Journey Validation

This document contains a rigorous, multi-layered testing plan tailored precisely to the actual end-to-end user journeys defined in `kmp-baseline-guide-task/SKILL.md`.

## Execution Protocol
1.  **Agent Validations**: The AI agent will first execute any programmatically verifiable tests, scripts, or inspection to confirm the behavior.
2.  **User Validations**: The AI agent will then prompt the User to manually navigate the application UI to functionally experience the journey. 
3.  **Bug Tracking**: If a journey fails validation, the AI agent must abort the validation process, update the appropriate phase in `kmp-baseline-guide-task` with a new `**Agent Action**: Fix bug [...]`, and resolve the issue before re-attempting validation.

---

## Journey 1: Core Navigation
Goal: Verify that the main UI framework boots and navigation correctly routes between major app destinations.

- [ ] **Agent Validation**: Ensure that UI tests covering the 5 main buttons on the Home screen pass.
- [ ] **User Validation**: Launch the app. Confirm the Home screen displays 5 buttons (Writers Room, Recording Studio, Editing Studio, Publishing Studio, Archives), and that tapping each correctly navigates to its respective empty screen with a functional 'Home' back button.

## Journey 2: Writer's Room
Goal: Verify that the user can generate, fine-tune, edit, and persist a script using Gemini.

- [ ] **Agent Validation**: Ensure that API mock tests for Gemini are passing and the Room Database successfully persists `Script` entities with `Target Duration`.
- [ ] **User Validation**: Navigate to the Writer's Room. Select a target duration (5s to 60s) using the slider. Click generate and ensure a valid script appears within 60 seconds. Edit a portion of the script text, tap 'Save', and verify it persists correctly. Confirm that saving automatically enables navigation to the Recording Studio.

## Journey 3: Recording Studio
Goal: Verify that the user can record video using the front-facing camera while following the teleprompter.

- [ ] **Agent Validation**: Verify ViewModel logic accurately manages the 5-second countdown timer and synchronizes the active script with the teleprompter advancement.
- [ ] **User Validation**: Navigate to the Recording Studio. Confirm the top half displays the previously saved script and the bottom half shows the live front-facing camera view (with touch events disabled). Tap the Start button. Wait for the 5-second countdown, and verify the teleprompter advances 3 lines at a time until the target duration is met. When recording completes, confirm that navigation to go back (to Writer's Room) and forward (to Editing Studio) works.

## Journey 4: Editing Studio
Goal: Verify that the user can precisely define sections of the recorded video to trim and recover.

- [ ] **Agent Validation**: Verify that timeline scaling and metadata generation correctly load the local file path dynamically created in the Recording Studio.
- [ ] **User Validation**: Navigate to the Editing Studio. Verify the video player controls. Mark specific sections of the video for removal. Select a 'Save' equivalent to persist the modified video natively, and select a 'Restore' equivalent to reconstruct the original footage. Confirm navigation logic to proceed to the Publishing Studio.

## Journey 5: Publishing Studio
Goal: Verify that the user can seamlessly share the generated and edited video to external channels.

- [ ] **Agent Validation**: Ensure external share URI intents (on Android) and corresponding Activity View Controllers (on iOS) are properly structured and permissioned for external apps.
- [ ] **User Validation**: Navigate to the Publishing Studio. Select the option to export the video. Confirm it successfully saves to the native Photo App or directly opens into YouTube Shorts if installed.

## Journey 6: Enhanced Editing and Polish (Phase 5)
Goal: Verify Phase 5 precise controls, unskipped previews, and native trimming.

- [ ] **Agent Validation**: Run tests validating the native video extraction logic, verifying tenth-of-a-second granularity constraints. 
- [ ] **User Validation**: Within the Editing Studio, open the Fine-tune modal. Verify you can adjust playback blocks in tenth-of-a-second increments (0.0s to 0.9s). Tap "Preview without Skipped Frames"; confirm that playback accurately skips all marked sections seamlessly. Re-export the video and verify it natively handles the complex trimming natively outside of the test application framework. Ensure app branding shows as 'The Factory' with proper visual icons.
```