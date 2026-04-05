---
name: kmp-baseline-guide-blueprint
description: The central source of truth for planning, tracking progress, and orchestrating work between the AI Agent and the User in this codebase.
---

# Skill: Project Orchestration via kmp-baseline-guide-task/SKILL.md

## Overview
This re-usable skill provides the structure and instructions for an AI Agent to generate, maintain, and execute a `kmp-baseline-guide-task/SKILL.md` file specific to the user's codebase. The `kmp-baseline-guide-task/SKILL.md` is the central source of truth for planning, tracking progress, and orchestrating work between the AI Agent and the User in a codebase during a buildout of a baseline KMP project (e.g., adding baseline KMP cababilities to a KMP template).

## Materialization Instructions for Generating a New `kmp-baseline-guide-task`
When placed in a new codebase and asked to create a `kmp-baseline-guide-task/SKILL.md`, create the file at `.skills/tasks/kmp-baseline/kmp-baseline-guide-task/SKILL.md`. Ask for details on the project requirements and generate the document following this exact structure.

Also, copy the contents of the blueprint's `resources/` folder to the materialized task's `resources/` folder to make assets available to the task runner (this is done automatically during materialization by the agent).

### 1. Project Overview
Define the high-level intent, core architecture, and stylistic guidelines of the project. When information is needed from the user, such as [App Name] or [Architecture]

### 2. Phased Execution
Break the project down into logical, sequential phases (e.g., Phase 1: Foundation, Phase 2: Core UI, Phase 3: Features, Phase 4: Polish).
Each Phase must have a clear `Goal:`.

### 3. Actionable Task Lists
Within each phase, define numbered steps with specific checklist items.
Prefix each task with the responsible party to ensure clear separation of duties:
*   `**User Action**:` For manual steps the human must take (e.g., running `git init`, testing on a physical device, adding visual assets, creating external accounts).
*   `**Agent Action**:` For code generation, refactoring, build configuration, and file modifications the AI will perform.
*   `**Validation**:` A reserved step explicitly triggering the execution of specific user journeys defined in `.skills/tasks/kmp-baseline/kmp-baseline-validation-task/SKILL.md`. This represents an important end-to-end journey that the agent and the user are going to confirm is working and track.

### 4. Tracking State
Use Markdown checkboxes as bulleted lists to track state, which ensures they render on separate lines. All new tasks should start as `- [ ]`. When completed, update the document to `- [x]`.

## `kmp-baseline-guide-task/SKILL.md` Template for New KMP Project
```markdown
---
name: kmp-baseline-guide-task
description: The central source of truth for planning, tracking progress, and orchestrating work between the AI Agent and the User in this codebase.
---

## Project Overview
[App Name: default: Baseline Joke App / The Factory] is a [Architecture: default=MVVM] application.
Aesthetic: Default Material 3 (clean baseline) -> Overridden by Film Noir branding later in The Factory phase.
Core Architecture: Kotlin Multiplatform (Android, iOS), Compose, Room, Compose Navigation 3, Calf Permissions, Material 3, Ktor, Gemini Interop.

## Phase 1: Foundation & Baseline Infrastructure
Goal: Initialize the stack, clean targets, and establish core dependencies and theming.

### Step 1: Project Setup & Cleanup
- [ ] **Agent Action**: Purge extraneous targets (Only keep Android and iOS).
- [ ] **User Action**: Configure iOS signing in Xcode.
- [ ] **User Action**: Confirm that the project builds and runs on Android and iOS.

### Step 2: Theming System (No Hardcoded Values)
- [ ] **Agent Action**: Setup Material 3 theming. Create `Theme.kt`, `Color.kt`, and a `Spacing` system (e.g., via `CompositionLocal`) in `shared/src/commonMain/kotlin/.../ui/theme`. Ensure no hardcoded colors or padding values are used in UI components; all must reference the theme or spacing system.

### Step 3: Dependencies
- [ ] **Agent Action**: Configure `build.gradle.kts` with Room, Ktor, Compose Navigation 3, Calf permissions, and Gemini dependencies.
- [ ] **User Action**: Confirm that the project builds and runs.

## Phase 2: Baseline Validation (The Joke App)
Goal: Implement a minimal feature set to validate all core libraries working together.

### Step 1: Feature Implementation
- [ ] **Agent Action**: Implement a button that, when pressed, makes a Ktor call to Gemini for "tell me a new joke".
- [ ] **Agent Action**: Store the joke response in the Room database.
- [ ] **Agent Action**: Render the stored jokes as a list on the screen, showing the first few words of each joke.
- [ ] **Agent Action**: Allow the user to drill into the joke detail view (showing the full joke) with a back button supported by Compose Navigation 3.
- [ ] **Agent Action**: Ensure all these UI elements use the established Material 3 theme and spacing system (no hardcoded colors or padding).
- [ ] **Agent Action**: Create basic unit tests for the data layer and repository.
- [ ] *Validation*: App boots, joke button pulls data, saves to Room, list updates, navigation works. Baseline is complete.

## Phase 3: The Factory - Foundation & Aesthetics
Goal: Transition from the baseline app to the product, applying styles and branding.

### Step 1: Aesthetic & Branding
- [ ] **Agent Action**: Copy `film_noir.png` to resources.
- [ ] **Agent Action**: Set `film_noir.png` as background image.
- [ ] **Agent Action**: Override the clean baseline Material theme with the high-contrast Film Noir colors (e.g., overriding purple/greys with cinematic darks and golds as seen in reference codebase).
- [ ] **Agent Action**: Rebrand the app (string resources, icons).

## Phase 4: The Factory - Core Workflows
Goal: Implement the specific features of the video production application.

### Step 1: Writer's Room & Gemini Scripts
- [ ] **Agent Action**: Implement the teleprompter script generation with Gemini. Prompt should request timestamps (e.g. `0s-5s`) and no conversational filler.
- [ ] **Agent Action**: Implement teleprompter logic adding a **2-second buffer** after each segment for calculated read time.

### Step 2: Recording Studio
- [ ] **Agent Action**: Implement front-facing camera view (bottom half) and teleprompter overlay (top half).
- [ ] **Agent Action**: Implement a **5-second countdown** before recording starts.
- [ ] **Agent Action**: Implement a visual timeline counting down remaining time for the entire video (including buffers).
- [ ] **Agent Action**: Add an **Archive button** (↓) in this screen to archive the active script.

### Step 3: Editing Studio
- [ ] **Agent Action**: Implement a timeline of seconds blocks matching the recorded video length.
- [ ] **Agent Action**: Implement a **Fine-tune modal** (opened by tapping a second block) supporting "Skip all" and tenth-of-a-second skipping granularity.
- [ ] **Agent Action**: Implement visual states: color blocks red (fully skipped) and orange (partially), and show a red overlay during playback for skipped stretches. Highlight the active second block with a yellow border.

### Step 4: Publishing
- [ ] **Agent Action**: Implement video preview that plays without skipped sections.
- [ ] **Agent Action**: Implement export triggering native Photo App save or external share sheet.

### Step 5: Archives
- [ ] **Agent Action**: Create an Archives screen listing archived scripts.
- [ ] **Agent Action**: Implement a Restore operation setting the restored project as active and routing the user to the appropriate studio step (e.g. Recording Studio).

## Phase 5: The Final Cut
Goal: Cleanup, polish, and optimization.

- [ ] **Agent Action**: Final check for hardcoded values.
- [ ] **Agent Action**: Remove debug logs.
- [ ] **Validation**: Full end-to-end regression validation.
```

## Execution Protocol
When the User says "Execute" or "Continue with the guide":
1.  Open and read the generated `SKILL.md` file.
2.  Scan sequentially to identify the first incomplete `- [ ]` task.
3.  If the next task is an `**Agent Action**`:
    -   Perform the necessary code changes to complete the action.
    -   **Debugging Dependency Resolution**: If "Could not resolve" errors occur after Gradle sync:
        *   Verify artifact group ID and name (e.g., `org.jetbrains.androidx` vs `androidx`).
        *   Verify artifact existence on Maven repositories (e.g., by web searching the full Maven coordinate).
        *   Ensure all necessary Maven repositories (e.g., `mavenCentral()`, `google()`, `maven("https://maven.pkg.jetbrains.space/public/p/compose/dev")`) are correctly declared **globally** in `settings.gradle.kts` (under both `pluginManagement { repositories { ... } }` and `dependencyResolutionManagement { repositories { ... } }`). Avoid adding repositories to module-level `build.gradle.kts` as this can override global settings and cause other dependencies to fail.
        *   Meticulously match dependency declarations (group ID, artifact ID, version) and API usage (imports, component names, parameters) when adapting from sample implementations.
        *   Always perform a Gradle sync (`gradle_sync()`) after modifying build scripts (`libs.versions.toml`, `build.gradle.kts`).
        *   Always run `analyze_file()` after significant code changes to catch new errors.
    -   Validate the changes (e.g., run local unit tests or build commands if applicable).
    -   Update the guide file, changing the `- [ ]` to `- [x]` for the completed task.
    -   Move on to the next task or pause if the next task requires the User.
4.  **STOP ON USER ACTIONS**: You must process the `kmp-baseline-guide-task` strictly sequentially. If the next unchecked item in the guide is a User Action, you MUST STOP execution, explicitly prompt the user to complete that action, and wait for their confirmation. Do NOT proceed to subsequent Agent Actions or Validations until the user confirms the step is done.
5.  Periodically, at the end of a session or after major milestones, run the instructions in `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to update the progress tracking and keep it up to date.