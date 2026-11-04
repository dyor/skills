---
name: kmp-baseline-guide
description: Creates an executable Kotlin Toolchain-first Factory rebuild guide for Android and iOS outside the skills directory.
version: 3.0.0
---

> [!WARNING] Reusable template only. Materialize the project-specific guide at `<plan_dir>/guide.md` (default `plans/kmp-baseline/guide.md`), never inside `.skills/`.

# Factory Video Studio Project Guide

## Materialization

Inspect the target repository, the Kotlin Toolchain-generated structure (if present), and sibling skills. Write the actual project guide outside `.skills/`. Do not assume legacy `shared/`, `androidApp/`, Gradle source paths, or file names: Kotlin Toolchain generates declarative project/module configuration and its layout may differ. Preserve generated configuration as authoritative.

For Android development and validation, use the Android CLI to query Android docs with `android docs search`, find/install focused Android skills with `android skills find`/`add`, manage emulators with `android emulator`, and inspect UI with `android layout`/`android screen capture`. Build and run Kotlin Toolchain modules with `kotlin run`; use `android run --apks=<path>` only to deploy an already-built APK directly. Follow the installed Android CLI skill's journey format and reporting rules for Android user journeys; keep iOS simulator/device journeys in the platform-appropriate workflow.

Android journey XML describes the steps; there is no `android journey` subcommand in Android CLI 1.0.15985488. Execute each XML action sequentially, inspect state with `android layout` and screenshots, and retain per-action JSON plus useful screenshots. For UI text entered via `adb shell input text`, encode each space as `%s` exactly. The installed CLI screenshot resolver accepts `--screenshot=<annotated.png>`; verify `android screen resolve --help` because some bundled skill examples use the obsolete `--screen` option.

## Product default

Rebuild Factory as a local-first Android/iOS video-production app: write scripts, read them in a teleprompter while recording, arrange/reorder and trim clips in a simple single-track editor, add timed titles/captions, export, upload directly to selected social platforms, and archive/restore projects. Manual script authoring is the initial path. AI and cloud sync are optional; multi-track editing is outside the initial scope. Social upload is required in the eventual product, not an optional auto-publishing stretch goal.

Use Compose Multiplatform for shared workflow UI and Kotlin logic. Keep camera sessions, playback, media transformation/export, permissions, photo-library operations, social authorization/upload adapters, and share sheets behind explicit interfaces with platform-specific secure token handling. Prefer CameraX VideoCapture and Media3 Transformer on Android; AVFoundation capture and composition/export APIs on iOS. Verify API/library status, social upload authorization, and supported media profiles against official docs before locking versions.

## Phased execution template

Every phase needs a goal, numbered tasks, a runnable increment, and observable completion evidence. Prefix every checkbox with `**User Action**`, `**Agent Action**`, or `**Validation**`. All tasks begin unchecked. Ask the user to confirm consequential product choices, but use documented assumptions for non-blocking details.

### Phase 1: Kotlin Toolchain foundation

Goal: Generate and run the untouched app on Android and iOS.

- [ ] **User Action**: Confirm app name/project ID and minimum Android/iOS versions; configure Kotlin Toolchain, JDK, Android SDK, Xcode, and simulator prerequisites.
- [ ] **Agent Action**: Record CLI/IDE plugin/JDK/SDK/Xcode versions and inspect the generated module/configuration structure.
- [ ] **Agent Action**: In `kotlin new`, choose Compose Multiplatform application. Keep Android/iOS selected; deselect Desktop (JVM) and Web (Wasm) with Space; leave Server (Ktor) off. Confirm the target list with Enter, wait for the project ID prompt, and enter it separately. Preserve generated YAML/wrappers.
- [ ] **Validation**: Audit `project.yaml`, each `module.yaml`, and the generated README. Confirm Android and iOS app modules plus shared only, with no `server`, `core`, desktop, or web modules. If this fails, rerun the wizard in a new empty output directory; do not guess at manual module pruning.
- [ ] **Agent Action**: Use declared module names in Kotlin Toolchain commands, not folder paths. Use `-p android` for Android and the concrete target accepted by the installed CLI (for example `-p iosSimulatorArm64` on Apple Silicon); verify exact `-p` values with `kotlin run --help` rather than assuming `ios`.
- [ ] **Validation**: Build and launch the generated app on Android emulator and iOS simulator; retain commands and evidence.
- [ ] **Agent Action**: If Toolchain blocks generation, dependency resolution, build, or run, record the reproducible blocker and use a documented Gradle/KMP fallback; validate both platforms after fallback.

### Phase 2: Shared project foundation

Goal: Create, save, reopen, and navigate a project on both platforms.

- [ ] **Agent Action**: Document shared/common code and native platform boundaries based on the generated project.
- [ ] **Agent Action**: Build responsive, accessible navigation and project create/list/empty/error states using the shared UI strategy.
- [ ] **Agent Action**: Choose persistence (Room KMP, SQLite, or a small file catalog) against archive, migration, transaction, iOS, and testing needs; verify current support before pinning versions.
- [ ] **Agent Action**: Define stable project/asset IDs, managed-file location or platform reference, ownership, cleanup, and missing-media recovery. Never use persisted absolute sandbox paths as durable IDs.
- [ ] **Validation**: Create a project, force-close/relaunch, reopen, and confirm metadata survives on both platforms.

### Phase 3: Writers’ room

Goal: Compose and persist a script offline.

- [ ] **Agent Action**: Implement project-linked script title, sections, shot notes, edit/save status, and recovery.
- [ ] **Agent Action**: Implement teleprompter settings, adjustable text size/speed, start/pause/rewind, and a testable duration estimate; no network or AI is required.
- [ ] **Validation**: Edit a script offline, open the teleprompter, adjust text size/speed, start and pause scrolling, rewind, then navigate away/relaunch and verify text/order persist.

### Phase 4: Recording studio

Goal: Record camera and microphone media while following the script.

- [ ] **Agent Action**: Define recording lifecycle/state machine, supported capture profile, capability checks, interruptions, and partial-file cleanup.
- [ ] **Agent Action**: Implement native Android CameraX VideoCapture and iOS AVFoundation capture behind a small shared state/event interface.
- [ ] **Agent Action**: Connect native preview to shared teleprompter/countdown/timing state. Request camera and microphone permission just in time and handle denial/retry.
- [ ] **User Action**: Configure signing/provisioning and physical-device trust when hardware validation is required.
- [ ] **Validation**: Test permission denial/grant, front camera, audio, start/stop, interruption, and recovery. Label simulator and physical-device evidence separately.

### Phase 5: Review and editing

Goal: Use a simple single-track editor to make non-destructive edits and produce a validated output.

- [ ] **Agent Action**: Decide input/output containers, codecs, resolution, frame rate, orientation, audio, minimum OS/device support, and unsupported-media behavior.
- [ ] **Agent Action**: Define shared edit intent (trim ranges, timed overlays, coordinate/safe-area behavior) and decide whether titles/captions are burned into output.
- [ ] **Agent Action**: Keep the first editor linear and single-track: arrange/reorder clips, trim boundaries, preview, add timed titles/captions, and export. Do not silently expand into multi-track editing or advanced effects.
- [ ] **Agent Action**: Implement native playback and Android Media3 Transformer / iOS AVFoundation composition/export adapters after compatibility checks.
- [ ] **Agent Action**: Define job progress/cancel/error states and output validation. Preserve source media; reconcile incomplete temporary exports after failure/relaunch without overstating filesystem atomicity.
- [ ] **Validation**: Run shared semantic fixtures and platform capability checks; compare preview/export timing, orientation, trims, captions, and audio on both platforms.

### Phase 6: Social uploader and archives

Goal: Upload a validated export to selected social platforms, provide local save/share, and reliably recover projects.

- [ ] **User Action**: Select the first supported social platforms and approve their account/authentication setup; identify any required developer/API enrollment or backend service.
- [ ] **Agent Action**: Check each selected platform's official upload API, authorization, media/metadata constraints, approval requirements, and upload/resume behavior before implementation.
- [ ] **Agent Action**: Implement platform upload adapters with secure authorization/token handling, destination and metadata confirmation, progress, cancel/retry where supported, typed failures, and confirmed terminal status. Do not ship client secrets or treat OS sharing as direct upload.
- [ ] **Agent Action**: Add native share sheet and save-only photo-library flows as additional output routes; request only permissions required by chosen APIs.
- [ ] **Agent Action**: Implement archive/restore, missing-media repair, export history, and safe managed-file cleanup.
- [ ] **Validation**: Complete a user-confirmed upload on each selected platform; verify progress, cancel/retry or resume behavior where supported, auth expiry, network failure, duplicate protection, and remote completion. Also export/play locally, share/save, archive/restore, and exercise missing media and low storage.

### Phase 7: Quality and release preparation

Goal: Validate the end-to-end creator workflow and prepare platform release documentation.

- [ ] **Agent Action**: Audit accessibility, privacy/data flow, logs, performance/thermal behavior, storage cleanup, and destructive-action recovery.
- [ ] **Agent Action**: Document device/media support, signing, build, and store preparation. Do not claim release readiness without signed platform builds.
- [ ] **Validation**: Complete a new-user-to-upload regression on Android and iOS for each selected platform; attach journey reports and clearly label physical-device coverage.

## Execution protocol

When asked to execute, read `<plan_dir>/guide.md`, locate the first unchecked task, and proceed in order. Stop at a User Action requiring user credentials, signing, provisioning, or device interaction. Before adding/changing build or media dependencies, consult `<plan_dir>/hints.md` and check current official docs. Run targeted checks after changes. Mark tasks complete only after their stated outcome is verified. Update `<plan_dir>/progress.md` after completed work. A validation checkbox requires actual journey execution and retained evidence; never simulate it.
