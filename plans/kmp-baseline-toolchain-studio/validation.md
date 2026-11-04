# Validation Plan

Validation is evidence-based. Record device/OS, app revision, command or journey, result, and report/screenshot location. Simulator and physical-device results are separate; simulator success does not prove camera, microphone, codec, or thermal behavior on hardware.

## Build gates

- [x] Kotlin Toolchain version and generated structure recorded; Android module build and launch succeed through Kotlin Toolchain on `emulator-5554`.
- [x] iOS simulator module build and launch succeed through the generated Kotlin Toolchain/Xcode integration on iPhone 17 Pro simulator (iOS 26.5).
- [x] Journey `shared/src/journeys/01_script_draft_android.journey.xml` passed; per-action JSON is in `plans/kmp-baseline-toolchain-studio/resources/01_script_draft_android-results.json`; screenshot is in `plans/kmp-baseline-toolchain-studio/evidence/android-script-draft.png`.
- [x] Journey `shared/src/journeys/02_teleprompter_android.journey.xml` passed on `emulator-5554`; the test verified a long script is scrollable, text-size adjustment changes 36sp to 40sp, Start changes to Pause, Pause returns to Start, and rewind restores the beginning. Per-action JSON is in `plans/kmp-baseline-toolchain-studio/resources/02_teleprompter_android-results.json`.
- [x] Journey `shared/src/journeys/03_draft_persistence_android.journey.xml` passed on `emulator-5554`; a saved title/body survived force-stop/relaunch and the Continue writing action restored the editor contents. Per-action JSON is in `plans/kmp-baseline-toolchain-studio/resources/03_draft_persistence_android-results.json`.
- [x] Rebuilt and launched Android and iOS modules after the teleprompter scroll-state fix; iOS simulator home capture is in `evidence/ios-teleprompter-build-home.png`.
- [x] Journey `shared/src/journeys/04_draft_persistence_ios.journey.xml` passed on iPhone 17 Pro simulator (iOS 26.5); title/body survived process termination/relaunch and reopened in the editor. Result JSON is in `plans/kmp-baseline-toolchain-studio/resources/04_draft_persistence_ios-results.json`; screenshot is `plans/kmp-baseline-toolchain-studio/evidence/ios-draft-persistence.png`.
- [x] Rebuilt Android and iOS after adding platform draft stores; both app targets compiled and launched. Android and iOS process-restart journeys verified stored title/body and reopen flow.
- [x] iOS home-screen launch and safe-area visual check captured in `evidence/ios-studio-home.png`.
- [ ] Aggregate `./kotlin build` terminates successfully. It compiled the Android/iOS modules but stalled without returning; this result is not counted as a pass.
- [ ] Physical-device signing/provisioning is documented; signed Android and iOS device builds are tested before release claims.
- [ ] Selected persistence and media dependency versions are checked against official compatibility docs.
- [ ] Each selected social platform's authorization and direct-upload API is verified from official documentation; the app's uploader is tested without relying only on a share sheet.

## Journey 1: New project and script

1. Launch with no projects and inspect the empty state.
2. Create a project, write a multi-section script and shot note, leave the screen, and reopen it.
3. Force-close and relaunch; confirm project and script remain intact and no network is needed.
4. Check text scaling, screen-reader labels, focus order, and narrow-screen layout.

## Journey 2: Recording and recovery

1. Deny camera permission; verify explanation and a recoverable retry route.
2. Grant camera, then microphone; verify requests are contextual and independent.
3. Record front-camera video while advancing the teleprompter; confirm playable audio/video and metadata.
4. Stop, cancel, background/interruption, and simulate low storage where practical; verify state recovery and no corrupt file marked complete.
5. Repeat camera/audio checks on physical devices for Android and iOS.

## Journey 3: Editing and export

1. Open source clip and inspect duration, orientation, audio, and supported profile.
2. Apply trim ranges and timed title/caption fixtures; verify edits are non-destructive.
3. Compare preview with exported output for timing, orientation, text placement, audio, and trim boundaries.
4. Cancel an export and force-quit during an export; confirm source remains available and incomplete output is reconciled.
5. Try unsupported media and insufficient storage; verify actionable errors and no false success.

## Journey 4: Social upload and archive

1. Choose a supported social platform/account and review the video, caption/metadata, and visibility before upload.
2. Confirm the upload explicitly; inspect progress and verify remote completion before the app reports success.
3. Exercise cancellation, retry/resume where supported, expired authorization, network/API failure, rejected media, and duplicate protection.
4. Save locally and share as additional routes; verify the saved export plays independently of the app.
5. Archive, restore, relaunch, and verify project/asset associations; make an asset unavailable and verify repair guidance and safe cleanup.

## Journey 5: Full creator workflow

Starting from a new install, create a project and script, use the teleprompter, record a short video, arrange/trim clips, add a timed overlay, export, upload to each selected social platform after user confirmation, verify remote completion, save/share locally, archive the project, and restore it after relaunch. Complete on Android and iOS; note platform-specific differences and physical-device coverage.

## Non-functional checks

- [ ] TalkBack and VoiceOver can operate core navigation, recording controls, timeline, progress, and errors.
- [ ] Large text, reduced motion where applicable, rotation, backgrounding, audio route change, and repeated capture/export are checked.
- [ ] Storage usage and cleanup are understandable; originals are not deleted by edit/export cleanup.
- [ ] No secrets, media contents, or sensitive script text are written to logs unintentionally.
