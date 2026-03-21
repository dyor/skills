---
name: project-guide-blueprint
description: The central source of truth for planning, tracking progress, and orchestrating work between the AI Agent and the User in this codebase.
---

# Project Guide

## When to use this skill
- Use this when determining the next step in the development process.
- This is helpful for understanding the overall goals, phases, and status of the project.

## How to use it
- Scan sequentially to identify the first incomplete `- [ ]` task.
- Follow the instructions based on whether it is an `**Agent Action**`, `**User Action**`, or `**Validation**`.
- Once a task is complete, mark it as `- [x]`.

---

## Project Overview
Factory-9 is a Kotlin Multiplatform (Android, iOS) application. It helps KMP App Builders accomplish Streamlining the creation and publication of YouTube Short educational videos about the app.
Aesthetic: Film noir-classic old school movie theme.
Core Architecture: Kotlin Multiplatform (Android, iOS), Jetpack Compose / Compose Multiplatform, Room, Ktor, Koin, Coil, Jetpack Navigation 3, Calf permissions.

## Phase 1: Foundation & Infrastructure
Goal: Initialize the stack and establish core dependencies.

### Step 1: Project Setup
- [ ] **Agent Action**: Update `CALCULATOR.md` by executing `.skills/project-calculator/SKILL.md` before starting to track baseline progress.
- [x] **User Action**: Change the Android Studio project view from "Android View" to "Project View" using the dropdown in the top-left of the Project tool window. This is required to see all KMP directories like `shared` and `iosApp`.
- [x] **User Action**: Run `git init`.
- [x] **Agent Action**: Purge extraneous targets. Remove `desktopApp`, `jvm`, `webApp`, `js`, and `wasmJs` references from `settings.gradle.kts` and the `kotlin { }` block in `shared/build.gradle.kts`. Delete their respective directories (`desktopApp/`, `webApp/`, `shared/src/jsMain/`, etc.). Clean up extraneous run configurations from `.idea/workspace.xml` and `.idea/runConfigurations/`. This project ONLY targets Android and iOS.
- [x] **User Action**: Open `iosApp/iosApp.xcodeproj` in Xcode. Navigate to the `iosApp` target -> 'Signing & Capabilities' tab and configure the development 'Team'. This prevents obscure iOS compiler linkage errors later.
- [x] **Validation**: Ensure project builds and runs on Android and iOS then run `git add . && git commit -m "Extraneous targets removed and iOS signing configured"`.
- [x] **Agent Action**: Configure `build.gradle.kts` with required dependencies (Room, Ktor, Koin, Coil, Compose Navigation 3, Calf permissions). Only do this AFTER targets have been purged.
    *   **Note**: If facing `Unresolved reference 'androidx.savedstate:savedstate-compose-serialization'` during dependency resolution, ensure this dependency is *removed* from `libs.versions.toml` and `build.gradle.kts`. Navigation 3 in KMP handles `NavKey` serialization via `SavedStateConfiguration` and `kotlinx.serialization.modules` directly, as documented in `.skills/project-skill/SKILL.md`.
- [x] **Validation**: Ensure project builds and runs on Android and iOS then run `git add . && git commit -m "Phase 1 started"`.
- [x] **User Action**: Add `film_noir.png` to codebase at `shared/src/commonMain/composeResources/drawable/film_noir.png`.
- [x] **Agent Action**: Set `film_noir.png` as background image in `App.kt` immediately to verify resource loading.
- [x] **Agent Action**: Adjust application style and theme based on `film_noir.png` aesthetic. Ensure text legibility on dark backgrounds by explicitly setting `contentColor = MaterialTheme.colorScheme.onSurface` on Cards and other containers.
- [x] **Validation**: Validate that the app builds and runs with the background image then run `git add . && git commit -m "Phase 1 complete"`.
- [ ] **Agent Action**: Update `CALCULATOR.md` by executing `.skills/project-calculator/SKILL.md` to reflect Phase 1 completion.

## Phase 2: Core Features & Logic
Goal: Implement the primary business logic, integrations (e.g., AI interop), and local database.

### Step 1: Data Models & Persistence
- [x] **Agent Action**: Implement base Entities, DAOs, and Database config with Room.
    *   **Note on Room KMP Migrations**: During development, *always* append `.fallbackToDestructiveMigration(dropAllTables = true)` to your `Room.databaseBuilder` inside your platform-specific `getDatabaseBuilder()` functions (in both `androidMain` and `iosMain`). Do NOT attempt to use old Android `SupportSQLiteDatabase` manual migrations as they will crash the iOS build or fail at runtime when using `BundledSQLiteDriver`.
- [x] **Agent Action**: Create unit tests for Data Layer (Note: For Room KMP, implement these as Android Instrumented tests and iOS simulator tests, avoid Robolectric).
- [x] **Validation**: Run unit tests for Data layer.

### Step 2: Main User Interface
- [x] **Agent Action**: Implement Compose Navigation 3 with 6 navigation nodes: Home, Writers Room, Recording Studio, Editing Studio, Publishing Studio, and Archives.
- [x] **Agent Action**: Create core UI screens and ViewModels for each of these screens. Start by just having 5 buttons on the Home screen (one for each of the other pages) and then a Home button on the other screens. 
- [x] **Validation**: Manual testing of UI states.
- [x] **Agent Action**: Update `progress-calculator` by executing the `.skills/project-calculator/SKILL.md` to reflect Phase 2 completion.

## Phase 3: Hardware / Native Integrations (Production)
Goal: Implement device-specific features (Camera, Audio, Location, etc.).

### Step 1: Permissions
- [x] **Agent Action**: Configure cross-platform permission requests using `calf-permissions` (com.mohamedrejeb.calf:calf-permissions).
- [x] **Validation**: User grants permissions on Android and iOS.

### Step 2: Native Implementations
### Step 2.1: Gemini/Network and Room Implementation
- [x] **Agent Action**: Implement `expect`/`actual` when needed for native capabilities.
- [x] **Agent Action**: Ensure network permissions and Ktor engines are configured. Specifically, verify `<uses-permission android:name="android.permission.INTERNET" />` is in `AndroidManifest.xml` and Ktor platform engines (`ktor-client-okhttp` for Android, `ktor-client-darwin` for iOS) are added to respective source sets in `build.gradle.kts`.
- [x] **User Action**: Add `GEMINI_API_KEY=your_api_key_here` to `local.properties` to keep it out of version control.
- [x] **Agent Action**: For the Writer's Room, implement a Gemini client using Ktor. Ensure you configure the `HttpTimeout` plugin (e.g., 60 seconds) to prevent socket timeouts during long LLM generations. Inject the API key securely (e.g., via Gradle property injection or `buildConfigField`) to prevent hardcoding. Include a default prompt of "Write a script for YouTube short that is designed to teach people how to create compelling YouTube shorts."
- [x] **Agent Action**: Present the script on the screen and allow the user to edit and save it in the local Room database.
- [x] **Agent Action**: Implement "Active Script" logic: Update `Script` entity with `isActive` field, add `clearActiveScript()` and `setActiveScript()` to `ScriptDao`, and modify `WritersRoomViewModel.saveScript()` to set the newly saved script as active.
- [ ] **Validation**: Ensure that the described functionality works on Android and iOS and `git commit -m "Phase 3: Writer's Room complete"`
- [ ] **Agent Action**: Allow the user to navigate to the Recording Studio after they save a script.
- [ ] **Agent Action**: For the Recording Studio, show a front-facing camera view with a start button on the bottom half of the screen, and on the top half of the screen show the active script. Implement `CameraPreview` as an `expect/actual` function. Ensure the `CameraPreview` is not consuming touch events by adding `Modifier.clickable(enabled = false, onClick = {})` to it.
- [ ] **Agent Action**: Implement `RecordingStudioViewModel` to manage a 5-second countdown and teleprompter logic that displays 3 lines at a time and advances them to finish the script in 60 seconds. The `RecordingStudioScreen` should observe the active script from the ViewModel.
- [ ] **Agent Action**: When the recording is done, allow user to re-record. Also include navigation to go back (to Writer's Room) and forward (to Editing Studio).
- [ ] **Validation**: Ensure that the described functionality works on Android and iOS and `git commit -m "Phase 3: Recording Studio complete"`
- [ ] **Agent Action**: For the Editing Studio, allow the user to mark sections of the video for removal (e.g., where there was white space or where they made a mistake). Include a Save button that stares the modified video and a Restore button that returns the original video.
- [ ] **Agent Action**: Include navigation for returning to the Editing Studio and advancing to the Publishing room.
- [ ] **Validation**: Ensure that the described functionality works on Android and iOS and `git commit -m "Phase 3: Editing Studio complete"`
### Step 2.2: YouTube Integration
- [ ] **Agent Action**: Provide an option to publish the video on YouTube shorts. It is ok to use simple shortcuts - like saving this video to the native Photo app and opening YouTube (where the user can upload the video from their native Photo app). 
- [ ] **Validation**: Ensure that the described functionality works on Android and iOS and `git commit -m "Phase 3: Publishing Studio complete"`
- [ ] **Agent Action**: Update `CALCULATOR.md` by executing `.skills/project-calculator/SKILL.md` to reflect Phase 3 completion.

## Phase 4: The Final Cut (Cleanup & Optimization)
Goal: Polish, optimize, and prepare for production.

- [ ] **Agent Action**: Remove hardcoded values and mock data.
- [ ] **Agent Action**: Enforce naming conventions and clean up resources.
- [ ] **Agent Action**: Remove or minimize debug logging.
- [ ] **User Action**: Full regression test of the application.
- [ ] **Validation**: `git add . && git commit -m "Phase 4: Final Cut"`
- [ ] **Agent Action**: Update `CALCULATOR.md` by executing `.skills/project-calculator/SKILL.md` to reflect 100% completion.

## Phase 5: Factory-Specific Polish
Goal: Refine the user experience with precise video editing, dynamic durations, and finalized branding.

- [ ] **Agent Action**: Implement a Target Duration slider (5s to 60s) in the Writer's Room and update the Gemini prompt to strictly adhere to the selected duration. Update `Script` entity to store this duration.
- [ ] **Agent Action**: Upgrade the VideoPlayer to support precise seeking (`seekRequest`) and playback state (`isPlaying`) across Android (`VideoView`) and iOS (`AVPlayerViewController`). Add `onTimeUpdate` and `onCompletion` callbacks.
- [ ] **Agent Action**: Implement `resolveVideoPath` expect/actual to handle iOS Simulator UUID changes across rebuilds (searching `NSDocumentDirectory` and `NSTemporaryDirectory`).
- [ ] **Agent Action**: Refactor the Editing Studio timeline to dynamically generate exactly one block per second of the recorded video using `MediaMetadataRetriever` (Android) and `AVURLAsset` (iOS) to fetch the actual video duration.
- [ ] **Agent Action**: Implement a "Fine-tune" modal in the Editing Studio allowing tenth-of-a-second skipping granularity (0.0s to 0.9s). Ensure it overlays cleanly at the bottom, auto-pauses the video when open, and seeks directly to the tapped tenth.
- [ ] **Agent Action**: Add a "Preview without Skipped Frames" button that instantly seeks to the first unskipped tenth of a second and plays through, auto-skipping removed segments and reverting state upon completion.
- [ ] **Agent Action**: Implement native `VideoTrimmer` (expect/actual) using Android `MediaExtractor`/`MediaMuxer` and iOS `AVMutableComposition` to trim and stitch unskipped tenths of a second into a final `_trimmed.mp4` file without heavy re-encoding. Ensure video rotation/transform metadata is preserved.
- [ ] **Agent Action**: Standardize bottom navigation across all studio screens to have a consistent "Go Back" and "Go Home" row. Ensure correct back-stack popping logic.
- [ ] **Agent Action**: Rebrand the app from "KotlinProject" to "The Factory" in Android (`strings.xml`) and iOS (`Info.plist`).
- [ ] **Agent Action**: Update the iOS and Android app icons using the `film_noir.png` asset (e.g., using `sips` for macOS to generate `app-icon-1024.png`).
- [ ] **Agent Action**: Update `CALCULATOR.md` by executing `.skills/project-calculator/SKILL.md` to reflect Phase 5 completion.
