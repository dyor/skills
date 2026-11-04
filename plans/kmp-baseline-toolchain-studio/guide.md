# KMP Video Studio — Execution Guide

## Product overview

Rebuild Factory as a local-first Android and iOS video-production app: write a script, record with a teleprompter, arrange and trim clips in a simple single-track editor, add timed captions/title cards, export, upload to selected social platforms, and archive the project. Initial script authoring is manual. AI/cloud script generation and multi-track nonlinear editing are out of scope; direct social upload is required.

Use Kotlin Toolchain as the default project creation/build workflow and Compose Multiplatform for shared workflow UI. Keep camera, media playback, encoding/composition, photo-library and share-sheet operations native. Kotlin Toolchain is Alpha; record the version and use the fallback gate in Phase 1 if a reproducible blocker occurs.

## Phase 1: Toolchain and runnable foundation

Goal: A generated project builds and launches on Android and iOS before product code is added.

1. **User Action**: Provide app name/project ID and minimum supported OS versions, or accept documented defaults.
2. **User Action**: Install/configure Kotlin Toolchain, JDK, Android Studio/SDK, Xcode and iOS SDK; provide a simulator. Physical-device signing is a separate later prerequisite.
3. **Agent Action**: Record CLI, IDE plugin, JDK, Android SDK, Xcode, and generated template versions; capture the generated module/file tree and run commands.
4. **Agent Action**: In `kotlin new`, choose Compose Multiplatform application. The observed wizard starts Android, iOS, Desktop (JVM), and Web (Wasm) selected and Server (Ktor) off. Keep Android+iOS, press Space on Desktop and Web to deselect them, leave Server off, and confirm with Enter. Wait for the separate project ID prompt and enter it separately. Preserve generated YAML/wrappers.
5. **Validation**: Audit `project.yaml`, every `module.yaml`, and README. Require exactly the Android/iOS app modules plus shared; reject `server`, `core`, desktop, or web modules. If incorrect, regenerate in a fresh directory instead of pruning modules manually.
6. **Agent Action**: Use declared module names, not folder paths. Use `-p android` for Android and a concrete target such as `-p iosSimulatorArm64` for the Apple Silicon simulator; Kotlin Toolchain 0.13 rejects `-p ios`. Check `kotlin run --help` for the installed CLI's accepted values.
7. **Validation**: Build and launch the unchanged app on Android emulator and iOS simulator; record commands, versions, and evidence.
8. **Agent Action**: If generation/build/run is blocked by a reproducible Toolchain issue, document the failure and exact trigger, then follow the documented Gradle/KMP fallback and repeat both platform runs.

## Phase 2: Shared app foundation

Goal: A navigable, accessible shell can create and reopen an empty video project.

1. **Agent Action**: Map modules/source sets and document boundaries for shared UI/domain versus native platform integrations.
2. **Agent Action**: Implement theme, navigation, project list, create-project flow, draft states, and accessible loading/empty/error states.
3. **Agent Action**: Compare Room KMP, SQLite, and a small file catalog against migrations, iOS support, transactions, media scale, and testing needs. The test-drive currently persists one script draft using app-scoped native key-value storage; keep this prototype boundary explicit and decide the multi-project/media catalog before adding more assets. Record checked versions and migration policy.
4. **Agent Action**: Define stable project and asset IDs, app-managed media locations, ownership/cleanup policy, and missing-file recovery. Persist no absolute sandbox paths.
5. **Validation**: Create/edit the current script draft, force-close/relaunch, reopen it, and verify exact title/body survive on Android and iOS. Repeat when a multi-project catalog is implemented.

## Phase 3: Writers’ room

Goal: The creator can write and manage a script without network access.

1. **Agent Action**: Implement script editor, title, sections, shot notes, save status, and project association.
2. **Agent Action**: Implement teleprompter display settings, adjustable text size/speed, start/pause/rewind controls, and a testable duration estimate; avoid fixed script lengths or required AI generation.
3. **Validation**: Create/edit a script offline, open the teleprompter, adjust text size/speed, start and pause scrolling, rewind, then leave and reopen the project and verify exact text and section ordering.

## Phase 4: Recording studio

Goal: Record video with audio while reading the script, with recoverable lifecycle behavior.

1. **Agent Action**: Define the recording state machine, platform capability checks, supported quality profile, interruption handling, and partial-file cleanup.
2. **Agent Action**: Implement Android camera preview/recording with CameraX VideoCapture and iOS capture with AVFoundation; keep native session ownership in platform code.
3. **Agent Action**: Connect native preview to shared teleprompter/countdown/timer state through a narrow event interface. Request camera/microphone permissions just in time and provide denial/retry guidance.
4. **User Action**: Configure signing/provisioning and trust a physical iOS device if physical capture validation is required.
5. **Validation**: Verify permission grant/denial, front camera, microphone audio, start/stop, interruption/recovery, and relaunch on simulator where possible; repeat camera/audio acceptance on physical Android and iOS devices and label evidence separately.

## Phase 5: Review and editing

Goal: A simple single-track editor produces predictable previews and validated exports.

1. **Agent Action**: Before implementation, decide the supported input/output profile: container, codec, resolution, frame rate, orientation, audio, minimum OS/device capability, and unsupported-input response.
2. **Agent Action**: Specify edit data (trim ranges, timed overlays, safe areas, typography, orientation) independently from source media. Decide whether captions/title cards are burned into exports.
3. **Agent Action**: Keep the first editor linear and single-track: arrange/reorder clips, trim boundaries, preview the sequence, add timed titles/captions, and export. Do not silently expand into multi-track editing.
4. **Agent Action**: Implement native playback and trim preview, then Android Media3 Transformer and iOS AVFoundation composition/export adapters. Share edit semantics and fixtures, not assumptions about identical codecs or bytes.
5. **Agent Action**: Define export job progress/cancel/error states. Write to temporary output, validate duration/tracks/playability, preserve source, and reconcile incomplete jobs after relaunch. Do not claim filesystem atomicity beyond platform guarantees.
6. **Validation**: Run shared edit fixtures and platform capability tests. Compare preview/export frame timing, orientation, audio presence, trim boundaries, and overlays on both platforms.

## Phase 6: Social uploader and archive

Goal: Users can directly upload a validated export to selected social platforms, save/share locally, and recover projects.

1. **User Action**: Select the first social platforms and approve account/authentication setup; identify required developer/API enrollment or backend service.
2. **Agent Action**: Check each selected platform's official upload API, authorization, media/metadata constraints, approval requirements, and upload/resume behavior before implementation.
3. **Agent Action**: Implement user-confirmed upload adapters with secure authorization/token handling, destination and metadata review, progress, cancel/retry where supported, typed failures, and confirmed terminal status. Do not embed client secrets or treat OS sharing as direct upload.
4. **Agent Action**: Implement native share sheets and save-only photo-library flows as additional output routes; request only permissions required by selected APIs.
5. **Agent Action**: Implement archive, restore, missing-media repair, export history, and managed-file cleanup based on the asset catalog policy.
6. **Validation**: Complete a user-confirmed upload on each selected platform; verify progress, cancel/retry or resume where supported, auth expiry, network failure, duplicate protection, and remote completion. Also export/play locally, share/save, archive/restore, and exercise low-storage and missing-file recovery on both platforms.

## Phase 7: Release readiness

Goal: The end-to-end studio is usable, resilient, and ready for store-specific preparation.

1. **Agent Action**: Audit accessibility, privacy disclosures, logs, storage cleanup, performance/thermal behavior, and destructive-action recovery.
2. **Agent Action**: Document build/signing/publishing steps and supported device/media profile; do not claim store readiness without signed platform builds.
3. **Validation**: Complete the new-user-to-upload journey for each selected platform and the full regression journey on Android and iOS; attach reports/screenshots and identify simulator-only coverage.
