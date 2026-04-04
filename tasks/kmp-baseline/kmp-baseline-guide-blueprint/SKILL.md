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
[App Name: default: Factory] is a [Architecture: default=MVVM] application. It helps [Target Audience: default=App Builders] accomplish [Core Problem: create YouTube shorts for their apps].
Aesthetic: [Visual Theme: default=based off film_noir.png]
Core Architecture: [default=Kotlin Multiplatform (Android, iOS), Compose, Room, Compose Navigation 3, Calf Permissions, Material 3]

## Phase 1: Foundation & Infrastructure
Goal: Initialize the stack and establish core dependencies.

### Step 1: Project Setup
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` before starting to track baseline progress.
- [ ] **User Action**: Change the Android Studio project view from "Android View" to "Project View" using the dropdown in the top-left of the Project tool window. This is required to see all KMP directories like `shared` and `iosApp`.
- [ ] **User Action**: Run `git init`.
- [ ] **Agent Action**: Purge extraneous targets. Remove `desktopApp`, `jvm`, `webApp`, `js`, and `wasmJs` references from `settings.gradle.kts` and the `kotlin { }` block in `shared/build.gradle.kts`. Delete their respective directories (`desktopApp/`, `webApp/`, `shared/src/jsMain/`, etc.). Clean up extraneous run configurations from `.idea/workspace.xml` and `.idea/runConfigurations/`. This project ONLY targets Android and iOS.
- [ ] **User Action**: Open `iosApp/iosApp.xcodeproj` in Xcode. Navigate to the `iosApp` target -> 'Signing & Capabilities' tab and configure the development 'Team'. This prevents obscure iOS compiler linkage errors later.
- [ ] **User Action**: Confirm that the project builds and runs on Android and iOS.
- [ ] **Agent Action**: Run `git add . && git commit -m "Extraneous targets removed and iOS signing configured"`.
- [ ] **Agent Action**: Configure `build.gradle.kts` with required dependencies (Room, Ktor, Koin, Coil, Compose Navigation 3, Calf permissions). Only do this AFTER targets have been purged.
    *   **Note**: If facing `Unresolved reference 'androidx.savedstate:savedstate-compose-serialization'` during dependency resolution, ensure this dependency is *removed* from `libs.versions.toml` and `build.gradle.kts`. Navigation 3 in KMP handles `NavKey` serialization via `SavedStateConfiguration` and `kotlinx.serialization.modules` directly, as documented in `.skills/tasks/kmp-baseline/kmp-baseline-hints-task/SKILL.md`.
- [ ] **User Action**: Confirm that the project builds and runs on Android and iOS.
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 1 started"`.
- [ ] **Agent Action**: Copy `film_noir.png` from `.skills/tasks/kmp-baseline/kmp-baseline-guide-task/resources/film_noir.png` to `shared/src/commonMain/composeResources/drawable/film_noir.png` to verify resource loading. (If the task directory doesn't have it, retrieve it from the blueprint's `resources`).
- [ ] **Agent Action**: Set `film_noir.png` as background image in `App.kt` immediately to verify resource loading.
- [ ] **Agent Action**: Adjust application style and theme based on `film_noir.png` aesthetic. Ensure text legibility on dark backgrounds by explicitly setting `contentColor = MaterialTheme.colorScheme.onSurface` on Cards and other containers.
- [ ] **User Action**: Confirm that the app builds and runs with the background image.
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 1 complete"`.
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to reflect Phase 1 completion.

## Phase 2: Core Features & Logic
Goal: Implement the primary business logic, integrations (e.g., AI interop), and local database.

### Step 1: Data Models & Persistence
- [ ] **Agent Action**: Implement base Entities, DAOs, and Database config with Room.
    *   **Note on Room KMP Migrations**: During development, *always* append `.fallbackToDestructiveMigration(dropAllTables = true)` to your `Room.databaseBuilder` inside your platform-specific `getDatabaseBuilder()` functions (in both `androidMain` and `iosMain`). Do NOT attempt to use old Android `SupportSQLiteDatabase` manual migrations as they will crash the iOS build or fail at runtime when using `BundledSQLiteDriver`.
- [ ] **Agent Action**: Create unit tests for Data Layer (Note: For Room KMP, implement these as Android Instrumented tests and iOS simulator tests, avoid Robolectric).
- [ ] **Agent Action**: Run unit tests for Data layer.

### Step 2: Main User Interface
- [ ] **Agent Action**: Implement Compose Navigation 3 with 6 navigation nodes: Home, Writers Room, Recording Studio, Editing Studio, Publishing Studio, and Archives.
- [ ] **Agent Action**: Create core UI screens and ViewModels for each of these screens. Start by just having 5 buttons on the Home screen (one for each of the other pages) and then a Home button on the other screens. 
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 2 complete: Core Navigation"`.
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to reflect Phase 2 completion.

## Phase 3: Hardware / Native Integrations (Production)
Goal: Implement device-specific features (Camera, Audio, Location, etc.).

### Step 1: Permissions
- [ ] **Agent Action**: Configure cross-platform permission requests using `calf-permissions` (com.mohamedrejeb.calf:calf-permissions).
- [ ] **User Action**: Confirm that permissions can be successfully requested and granted on Android and iOS.

### Step 2: Native Implementations
### Step 2.1: Gemini/Network and Room Implementation
- [ ] **Agent Action**: Implement `expect`/`actual` when needed for native capabilities.
- [ ] **Agent Action**: Ensure network permissions and Ktor engines are configured. Specifically, verify `<uses-permission android:name="android.permission.INTERNET" />` is in `AndroidManifest.xml` and Ktor platform engines (`ktor-client-okhttp` for Android, `ktor-client-darwin` for iOS) are added to respective source sets in `build.gradle.kts`.
- [ ] **User Action**: Add `GEMINI_API_KEY=your_api_key_here` to `local.properties` to keep it out of version control.
- [ ] **Agent Action**: Implement a Target Duration slider (5s to 60s) in the Writer's Room and update the Gemini prompt to strictly adhere to the selected duration. Update `Script` entity to store this duration.
- [ ] **Agent Action**: For the Writer's Room, implement a Gemini client using Ktor. Ensure you configure the `HttpTimeout` plugin (e.g., 60 seconds) to prevent socket timeouts during long LLM generations. Inject the API key securely (e.g., via Gradle property injection or `buildConfigField`) to prevent hardcoding. Include a default prompt that explicitly commands: "Write a script for a YouTube short that takes exactly {targetDuration} seconds to read aloud. ONLY return the text to be spoken and the timestamp range it is spoken in, using the strict format `0s-5s: Hello...`. Do not include any conversational filler, markdown formatting, explanations, or background info. These timestamps will directly control how long the caption remains on screen."
- [ ] **Agent Action**: Present the script on the screen and allow the user to edit and save it in the local Room database.
- [ ] **Agent Action**: Implement "Active Script" logic: Update `Script` entity with `isActive` field, add `clearActiveScript()` and `setActiveScript()` to `ScriptDao`, and modify `WritersRoomViewModel.saveScript()` to set the newly saved script as active.
- [ ] **Validation**: Execute `.skills/tasks/kmp-baseline/kmp-baseline-validation-task/SKILL.md` to validate Journey 2: Writer's Room.
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 3: Writer's Room complete"`.
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to track Phase 3 progress.
- [ ] **Agent Action**: Allow the user to navigate to the Recording Studio after they save a script.
- [ ] **Agent Action**: For the Recording Studio, show a front-facing camera view with a start button on the bottom half of the screen, and on the top half of the screen show the active script. Use `CameraKScreen` from the `io.github.kashif-mehmood-km:camerak` library for a robust multiplatform camera implementation. Ensure the camera preview is not consuming touch events by adding `Modifier.clickable(enabled = false, onClick = {})` to it.
- [ ] **Agent Action**: Implement `RecordingStudioViewModel` to parse the `0s-5s:` timestamps from the generated script. The teleprompter must advance based strictly on these parsed durations (e.g., showing a caption for exactly 5 seconds if marked `0s-5s`). Include a 5-second initial countdown. During recording, display two counters: one showing time remaining for the current caption, and one showing time remaining for the entire video. The `RecordingStudioScreen` should observe the active script from the ViewModel.
- [ ] **Agent Action**: When the recording is done, allow user to re-record. Also include navigation to go back (to Writer's Room) and forward (to Editing Studio).
- [ ] **Validation**: Execute `.skills/tasks/kmp-baseline/kmp-baseline-validation-task/SKILL.md` to validate Journey 3: Recording Studio.
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 3: Recording Studio complete"`.
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to track Phase 3 progress.
- [ ] **Agent Action**: For the Editing Studio, allow the user to mark sections of the video for removal. Implement visual indicators on the timeline so skipped frames show a red overlay instead of actually skipping them during standard playback. Include a Save button that explicitly triggers the `VideoTrimmer` to reconstruct the original footage without the red sections, and a Restore button.
- [ ] **Agent Action**: Upgrade the VideoPlayer to support precise seeking (`seekRequest`) and playback state (`isPlaying`) across Android (`VideoView`) and iOS (`AVPlayerViewController`). Add `onTimeUpdate` and `onCompletion` callbacks.
- [ ] **Agent Action**: Implement `resolveVideoPath` expect/actual to handle iOS Simulator UUID changes across rebuilds (searching `NSDocumentDirectory` and `NSTemporaryDirectory`).
- [ ] **Agent Action**: Refactor the Editing Studio timeline to dynamically generate exactly one block per second of the recorded video using `MediaMetadataRetriever` (Android) and `AVURLAsset` (iOS) to fetch the actual video duration.
- [ ] **Agent Action**: Implement a "Fine-tune" modal in the Editing Studio allowing tenth-of-a-second skipping granularity (0.0s to 0.9s). Ensure it overlays cleanly at the bottom, auto-pauses the video when open, and seeks directly to the tapped tenth.
- [ ] **Agent Action**: Add a "Preview without Skipped Frames" button that instantly seeks to the first unskipped tenth of a second and plays through, auto-skipping removed segments and reverting state upon completion.
- [ ] **Agent Action**: Implement native `VideoTrimmer` (expect/actual) using Android `MediaExtractor`/`MediaMuxer` and iOS `AVMutableComposition` to trim and stitch unskipped tenths of a second into a final `_trimmed.mp4` file without heavy re-encoding. Ensure video rotation/transform metadata is preserved.
- [ ] **Agent Action**: Include navigation for returning to the Editing Studio and advancing to the Publishing room.
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 3: Editing Studio complete"`.
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to track Phase 3 progress.
- [ ] **Agent Action**: Implement Active Script state management and dynamic Home screen navigation. Update the `Script` entity to store the `scriptState` (e.g. `WRITERS_ROOM`, `RECORDING_STUDIO`, etc.).
- [ ] **Agent Action**: Implement archiving functionality for any script (marking `isActive` to false, `scriptState` to `ARCHIVES`).
- [ ] **Agent Action**: Implement "Go Back" functionality to revert an active script to a previous stage dynamically.
- [ ] **Agent Action**: Standardize bottom navigation across all studio screens to have a consistent "Go Back" and "Go Home" row. Ensure correct back-stack popping logic.
- [ ] **Agent Action**: Create an Archives screen that lists all of the archived videos and allows a user to make an archived video active so that they can work on it some more.
- [ ] **Validation**: Execute `.skills/tasks/kmp-baseline/kmp-baseline-validation-task/SKILL.md` to validate Journey 6: Archives.
### Step 2.2: YouTube Integration
- [ ] **Agent Action**: In the Publishing Studio, display a `VideoPlayer` that acts as a final preview of the trimmed video (where the skipped/red frames from the Editing Studio are physically removed).
- [ ] **Agent Action**: Provide an option to publish the video on YouTube shorts. Implement `expect`/`actual` logic in a `VideoPublisher` class to handle exporting the recorded video to the native Photo Gallery (using Android's `MediaStore` and iOS's `PHPhotoLibrary`) and launching the native YouTube application via Intent/URL scheme. Refer to `.skills/tasks/kmp-baseline/kmp-baseline-hints-task/examples/VideoPublisher.kt` for the exact implementations.
- [ ] **Validation**: Execute `.skills/tasks/kmp-baseline/kmp-baseline-validation-task/SKILL.md` to validate Journey 5: Publishing Studio.
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 3: Publishing Studio complete"`.
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to reflect Phase 3 completion.

## Phase 4: The Final Cut (Cleanup & Optimization)
Goal: Polish, optimize, and prepare for production.

- [ ] **Agent Action**: Remove hardcoded values and mock data.
- [ ] **Agent Action**: Enforce naming conventions and clean up resources.
- [ ] **Agent Action**: Remove or minimize debug logging.
- [ ] **User Action**: Final review of the application state.
- [ ] **Validation**: Execute `.skills/tasks/kmp-baseline/kmp-baseline-validation-task/SKILL.md` to perform a full end-to-end regression validation.
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 4: Final Cut"`.
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to track Phase 4 completion.

## Phase 5: Factory-Specific Polish
Goal: Refine the user experience with precise video editing, dynamic durations, and finalized branding.

- [ ] **Agent Action**: Implement a Target Duration slider (5s to 60s) in the Writer's Room and update the Gemini prompt to strictly adhere to the selected duration. Update `Script` entity to store this duration.
- [ ] **Agent Action**: Upgrade the VideoPlayer to support precise seeking (`seekRequest`) and playback state (`isPlaying`) across Android (`VideoView`) and iOS (`AVPlayerViewController`). Add `onTimeUpdate` and `onCompletion` callbacks.
- [ ] **Agent Action**: Implement `ModalBottomSheet` for Recording Studio controls to overlay transparently on top of the native camera view.
- [ ] **Agent Action**: Ensure `EditingStudioViewModel` correctly updates the active script state to `EDITING_STUDIO` upon load, maintaining the navigation step tracking.
- [ ] **Agent Action**: Implement `resolveVideoPath` expect/actual to handle iOS Simulator UUID changes across rebuilds (searching `NSDocumentDirectory` and `NSTemporaryDirectory`).
- [ ] **Agent Action**: Refactor the Editing Studio timeline to dynamically generate exactly one block per second of the recorded video using `MediaMetadataRetriever` (Android) and `AVURLAsset` (iOS) to fetch the actual video duration.
- [ ] **Agent Action**: Implement a "Fine-tune" modal in the Editing Studio allowing tenth-of-a-second skipping granularity (0.0s to 0.9s). Ensure it overlays cleanly at the bottom, auto-pauses the video when open, and seeks directly to the tapped tenth.
- [ ] **Agent Action**: Add a "Preview without Skipped Frames" button that instantly seeks to the first unskipped tenth of a second and plays through, auto-skipping removed segments and reverting state upon completion.
- [ ] **Agent Action**: Implement native `VideoTrimmer` (expect/actual) using Android `MediaExtractor`/`MediaMuxer` and iOS `AVMutableComposition` to trim and stitch unskipped tenths of a second into a final `_trimmed.mp4` file without heavy re-encoding. Ensure video rotation/transform metadata is preserved.
- [ ] **Agent Action**: Implement caption rendering on iOS using `AVMutableVideoComposition` and `CATextLayer`. Create a parent container layer bounded by `renderWidth` with precise text offset calculations to ensure captions are vertically centered and horizontally bounded to prevent clipping.
- [ ] **Agent Action**: Standardize bottom navigation across all studio screens to have a consistent "Go Back" and "Go Home" row. Ensure correct back-stack popping logic.
- [ ] **Agent Action**: Rebrand the app from "KotlinProject" to "The Factory" in Android (`strings.xml`) and iOS (`Info.plist`).
- [ ] **Agent Action**: Update the iOS and Android app icons using the `film_noir.png` asset (e.g., using `sips` for macOS to generate `app-icon-1024.png`).
- [ ] **Validation**: Execute `.skills/tasks/kmp-baseline/kmp-baseline-validation-task/SKILL.md` to validate Journey 4: Editing Studio.
- [ ] **Agent Action**: Run `git add . && git commit -m "Phase 5: Polish complete"`.
- [ ] **Agent Action**: Update progress tracking by executing `.skills/tasks/kmp-baseline/kmp-baseline-calculator-task/SKILL.md` to reflect Phase 5 completion.
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