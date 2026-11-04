---
name: kmp-baseline-hints
description: Kotlin Toolchain-first architecture and native media guidance for Android/iOS video production apps; consult before build, persistence, capture, edit, or export work.
version: 3.0.0
---

> [!WARNING] Reusable template only. Materialize project-specific guidance at `<plan_dir>/hints.md` and examples under `<plan_dir>/examples/`, outside `.skills/`.

# Factory Video Studio Technical Hints

Use these principles while generating project-specific hints. Inspect actual generated files and current official documentation. Do not copy fixed versions or assume a legacy Gradle layout.

## Kotlin Toolchain

- Prefer the Kotlin Toolchain project creator and its Compose Multiplatform application template for Android+iOS.
- The official Kotlin guide currently labels Kotlin Toolchain Alpha. Record CLI/plugin version, generated tree, and command line. Preserve `project.yaml`, module YAML, wrappers, and generated run/build configuration.
- Inspect module definitions and source layout. Toolchain's documented layout differs from traditional `commonMain`/`androidMain` filesystem assumptions. Use the build workflow supported by the generated project; do not silently rewrite it to Gradle.
- Invoke modules by their declared module name, not their directory path. In Kotlin Toolchain 0.13, `kotlin run -m androidApp -p android -d <adb-serial>` is valid; iOS uses the concrete target name such as `-p iosSimulatorArm64` with an Xcode simulator UDID (`-p ios` is invalid).
- Define an explicit fallback trigger for reproducible blockers. Document migration steps and validate both Android and iOS after transition.
- Check current compatibility for Kotlin, Compose Multiplatform, Android Gradle Plugin, Gradle, Xcode, and target SDK together when applicable.

## Architecture boundary

- Share domain models, script/project logic, edit intent, timeline calculations, and most workflow UI.
- Keep capture sessions, media playback surfaces, codecs, export APIs, permission prompts, photo-library calls, and share sheets native.
- Expose native capabilities through small interfaces and typed events/results. Keep native framework objects out of common models. Give native views clear lifecycle ownership and cleanup.
- Prefer platform-specific implementations where hardware/API behavior differs. Shared code does not imply identical encodes or device capabilities.

## Capture, edit, export

- Android recording candidate: CameraX `VideoCapture`; bind use cases to lifecycle, check supported combinations, and handle camera/microphone interruptions.
- iOS recording candidate: AVFoundation capture session and movie output; handle session lifecycle, orientation, microphone/audio session, interruption, and file completion.
- Android edit/export candidate: Media3 Transformer. Check input/output support, effects, and device codec capabilities.
- iOS edit/export candidate: AVFoundation composition/export. Check preset/container compatibility and export status before beginning.
- Store edit intent (trim ranges, overlay timing/placement, output profile) separately from the source file. Preserve the original until the new output is validated.
- Define a supported media profile: containers/codecs, resolution, frame rate, rotation/orientation, audio behavior, minimum OS/device requirements, and unsupported-input response.
- Define job states, progress, cancellation, typed errors, temporary output handling, validation, and relaunch recovery. Avoid asserting filesystem atomicity unless verified for the specific operation.
- Decide whether captions/title cards are burned into output. Define safe areas, fonts/fallbacks, coordinate system, wrapping, opacity/background, timing, and preview/export parity before implementation.
- Probe media metadata and reject unsupported cases before work. Test cancel, low storage, interruption, repeated exports, audio route change, and physical devices.

## Project and media persistence

- Keep large media files separate from structured project/script/edit metadata.
- Use stable app-generated asset IDs and an explicit resolver to app-managed relative paths or durable platform references. Do not persist absolute sandbox paths or assume a filename alone is durable.
- Specify import scope. Imported external URLs may require platform-specific access persistence or copying into app-managed storage.
- Define asset ownership, project references, deduplication if needed, cleanup, missing-file repair, and export-history behavior.
- Select Room KMP, SQLite, or a file catalog based on transaction, migration, iOS, testing, and complexity needs. Check current official status before choosing/pinning; current docs may describe alpha artifacts.
- Test schema/file-format migrations and recovery after interrupted writes.

## Permissions and privacy

- Ask for camera/microphone at the moment the user begins capture and explain purpose. Handle denied/restricted states with a useful retry/settings path.
- Request only permissions needed by selected APIs. Prefer save-only photo access when browsing the library is not required.
- No API secret embedded in source, resources, generated BuildConfig, or a mobile binary. Keep AI generation out of initial scope; if later added, require a backend or user credential design plus consent/data-retention decisions.

## Social upload

- The eventual Factory product requires direct uploads to user-selected social platforms. Export/share/save remains useful but does not satisfy the uploader feature.
- Select platforms before choosing libraries or designing auth. Check each platform's current official API for app enrollment/approval, OAuth flow, upload sessions, media limits, metadata, visibility, rate limits, resumability, and account eligibility.
- Keep upload orchestration behind a shared typed contract and platform/service adapters. Model destination/account, prepared media, metadata, progress, cancellation, retry/resume capability, remote processing, completion, and actionable failures. Do not assume every platform supports the same states or resumability.
- Use supported user authorization and secure native token storage. Never ship client secrets or long-lived credentials. Add a backend only when a chosen platform's documented flow requires server-held secrets or upload coordination; document what media/metadata passes through it.
- Make upload explicitly user initiated. Show the destination account, video, caption/metadata, visibility, and consent before transfer. Report success only after platform confirmation; prevent accidental duplicate submissions when retrying.
- Validate with official sandbox/test modes, private/unlisted destinations, or designated test accounts where available. Do not publish test media to a real audience without the user's explicit approval.

## Troubleshooting and validation

- Separate generation/configuration, dependency resolution, build, simulator, physical hardware, and signing errors. Use the generated tool's diagnostics and Xcode output; avoid blanket cache invalidation as a default fix.
- Validate both targets continuously. A successful Android build does not prove iOS linkage or runtime behavior.
- Keep unit tests for shared deterministic logic and platform tests for native capability. Use common edit fixtures to assert semantics, not byte-identical outputs.
- Check release notes and official docs immediately before pinning versions or copying APIs; include date, selected version, compatibility rationale, and source links in generated hints.
- Android CLI workflow: use `android docs search "<topic>"` for Android API/library guidance; `android skills find <topic>` and `android skills add <skill>` for relevant Android implementation expertise; `android emulator list/create/start` for AVD operations; and `android layout` or `android screen capture` for UI inspection. Build and launch Kotlin Toolchain modules with `kotlin run`; `android run --apks=<path>` deploys an already-built APK. Follow the Android CLI skill's journey instructions and report each journey step as specified. Avoid requiring Android Studio for emulator launch/UI inspection when CLI support suffices.

## Official references to consult

- Kotlin Toolchain: https://kotlinlang.org/docs/multiplatform/kotlin-toolchain.html
- KMP compatibility: https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html
- Compose compatibility: https://kotlinlang.org/docs/multiplatform/compose-compatibility-and-versioning.html
- Room KMP: https://developer.android.com/kotlin/multiplatform/room
- SQLite KMP: https://developer.android.com/kotlin/multiplatform/sqlite
- CameraX video: https://developer.android.com/media/camera/camerax/video-capture
- Media3 Transformer: https://developer.android.com/media/media3/transformer
- Apple capture: https://developer.apple.com/documentation/avfoundation/setting-up-a-capture-session
- Apple export: https://developer.apple.com/documentation/avfoundation/avassetexportsession
- Apple photo save: https://developer.apple.com/documentation/avfoundation/saving-captured-photos
