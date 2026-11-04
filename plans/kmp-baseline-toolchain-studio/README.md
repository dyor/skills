# Factory Video Studio — KMP Toolchain Plan

This is a project-specific plan derived from `planning-skills/kmp-baseline`. It lives outside the reusable skill templates; the templates have since been updated in place as part of the test drive.

## Product outcome

Rebuild Factory as a beginner-friendly Android and iOS creator app that takes a user from an idea to a published short video: script and teleprompter, native camera and microphone capture, a simple single-track editor, captions/title cards, export, direct upload to selected social platforms, and project archive. This is a coherent local-first production workflow with an in-app uploader; it does not promise a full nonlinear multi-track editor or cloud rendering.

## Opinionated stack

- Start with **Kotlin Toolchain** (`kotlin new`, Compose Multiplatform template, Android and iOS targets) and its `project.yaml` / module YAML configuration. Toolchain is currently documented as Alpha; record its exact CLI version, preserve generated wrapper/configuration, and provide a documented Gradle/Xcode fallback. Do not assume a Toolchain project has the legacy `shared/` + `androidApp/` layout.
- Share product logic, persistence-facing interfaces, workflow state, and most UI with Kotlin/Compose Multiplatform. Keep camera capture, playback surfaces, media processing, photo-library access, and platform permission prompts native behind small `expect/actual` or injected interfaces.
- Use AndroidX **CameraX VideoCapture** for Android recording, **AVFoundation** capture APIs for iOS, **Media3 Transformer** for Android edits/exports, and AVFoundation composition/export APIs for iOS. Define a small common media-job contract and a cross-platform conformance suite; do not promise bit-identical encodes.
- Implement an actual uploader to the social platforms selected by the owner. Review and confirm the destination, account, video, caption/metadata, and visibility before upload; show progress and only report success after the platform confirms completion. An OS share sheet is an additional route, not a replacement.
- Store projects, scripts, clip metadata, and edit decisions locally. Use a KMP-supported Room version only after checking current official Android/KMP compatibility; keep media bytes in app-managed files and persist relocatable identifiers, not absolute sandbox paths. Add database only when archive/recovery needs justify it.
- Use Kotlin serialization for project interchange and Ktor only if a real remote service is selected. Script generation must be provider-independent, optional, consented, and have a useful local/manual path. Never put API secrets in the mobile binary or commit them.
- Use version catalogs only if the generated build uses Gradle; let generated Toolchain configuration remain authoritative. Pin versions from official compatibility matrices at initialization time instead of copying old numbers from this repository.

## Delivery phases

1. Environment and generated skeleton: verify Kotlin Toolchain, JDK, Android SDK, Xcode, simulators, and physical-device path; generate Android+iOS targets; run the untouched app on both platforms.
2. Shared product foundation: theme, navigation, domain model, project lifecycle, local persistence, permissions rationale, accessible states; verify Android and iOS after each vertical slice.
3. Writers’ room: create/edit scripts and shot lists manually; optional AI adapter only after provider, privacy, and key management are chosen.
4. Recording studio: native preview, front/back selection, audio, countdown, teleprompter, interruption handling, storage limits, recording lifecycle, and recoverable failed/partial capture.
5. Simple editing studio: single-track clip arrangement/reordering, non-destructive trim ranges, preview, timed caption/title overlays, cancellation/progress, output validation, and export on each platform.
6. Social uploader and archive: integrate selected platform upload APIs, account authorization, metadata/visibility review, progress, cancellation/retry/resume where supported, auth/network/API failures, duplicate protection, local save/share, and project archive/restore.
7. Release readiness: accessibility, device matrix, performance/thermal/storage checks, privacy disclosures, signing, and end-to-end journeys on Android and iOS.

Every phase must create runnable increments. No phase is complete based only on compilation: require Android and iOS runtime evidence, and label simulator-only checks separately from physical camera/audio and real platform-upload checks.

## Architecture rules

- Model media pipeline operations and failures explicitly (`permissionDenied`, `unsupportedFormat`, `insufficientStorage`, `cancelled`, `interrupted`, `exportFailed`). Preserve the original source until an export is validated.
- Treat edit decisions as non-destructive project data. Export to a new temporary destination, validate duration/tracks/playability, then atomically promote it; clean temporary output on cancel/failure.
- Keep editing linear and single-track for the initial editor: arrange/reorder clips, trim boundaries, preview, and timed title/caption overlays. Advanced multi-track editing is outside this scope.
- Social uploads are user initiated. Use official platform APIs and authorization; store tokens securely; add a backend only if a chosen platform requires one. Never include client secrets in a mobile binary, and never claim an upload succeeded before the platform confirms it.
- Define platform capability and minimum OS/device requirements up front. Test orientation, lifecycle/backgrounding, audio route changes, camera switching, low storage, and thermal/performance constraints.
- Keep UI state and timeline math common; keep codec, capture-session, native player, and photo-library objects out of `commonMain`.
- Use least-privilege, just-in-time permission requests. Explain denied/restricted states and provide a user-triggered settings route when appropriate. Do not request photo-library read access if using a save-only API.
- No Gemini assumptions, network access before a user starts an upload, joke-app milestones, deprecated Navigation 3 snippets, blanket “all usage-description keys” requirements, or routine IDE-cache invalidation advice. Direct upload requires network access when the user starts that flow.

## Library decision gate

Before adopting any third-party KMP camera/editor abstraction, verify current maintenance, release cadence, Android+iOS feature parity, audio recording, lifecycle behavior, supported formats, licensing, sample buildability, and issue history. Prefer official native media frameworks for capture/edit primitives and share the business rules around them. A wrapper may be adopted only when it passes the same device-level acceptance matrix on both platforms. The stale CameraK examples from the former templates were removed and are not an assumed production choice.

## Template integration proposal

The reusable templates have now been revised together: prompt defaults, guide, hints, agent instructions, validation journeys, and README use the Factory scope, Kotlin Toolchain-first setup, Android CLI workflow, durable media IDs, simple editor, and required social uploader. Project-specific plans and journeys are kept under `plans/kmp-baseline-toolchain-studio/` in the test app repository.

## Current official references checked

- [Kotlin Toolchain KMP setup](https://kotlinlang.org/docs/multiplatform/kotlin-toolchain.html) — describes CLI/project YAML and calls Toolchain Alpha.
- [Kotlin Multiplatform quickstart](https://kotlinlang.org/docs/multiplatform/quickstart.html) — supported IDE/wizard setup and environment checks.
- [Android CameraX video capture](https://developer.android.com/media/camera/camerax/video-capture) — official recording API.
- [Android Media3 Transformer](https://developer.android.com/media/media3/transformer) — official Android editing/export API.
- [Apple AVFoundation capture setup](https://developer.apple.com/documentation/avfoundation/setting-up-a-capture-session) — native capture session model.
- [Apple AVAssetExportSession](https://developer.apple.com/documentation/avfoundation/avassetexportsession) — native export API.

Versions and API signatures are intentionally not frozen here. Recheck the official docs and compatibility information when materializing in an actual app.

## Decisions required before execution

This proposal is a product/architecture brief, not yet a runnable phase-by-phase guide. Before implementation, materialize the full plan artifacts and resolve these gates:

- Define an explicit supported capture/export profile: containers, codecs, resolution, frame rate, orientation, audio, minimum OS/device capability, and unsupported-media behavior.
- Specify the media job contract: inspect, preview, trim, compose overlays, export, cancel, progress, errors, temporary-file recovery, and output validation. Shared conformance means common semantic fixtures plus platform capability tests; it does not promise identical encodes.
- Decide whether titles/captions are burned into the exported video; define safe areas, typography, timing, preview/export agreement, and test fixtures.
- Choose a durable asset catalog: stable asset IDs, app-managed relative storage or platform URL/bookmark handling, imported-media scope, ownership, deletion, and repair after missing files or interrupted exports. Never treat a filename alone as durable identity.
- Make persistence concrete against archive/recovery needs. Evaluate Room KMP, SQLite, and a small file catalog for migrations, transactions, iOS support, and beginner complexity; pin versions only after checking current official compatibility and release status.
- Define the UI/platform boundary per screen: shared Compose workflow UI; native capture preview; playback; permission and share flows; and the state/event contract between native hosts and common logic. Include TalkBack and VoiceOver acceptance checks.
- Add task owners, runnable increments, completion evidence, and Android/iOS validation for every phase. Rewrite the five supplied journeys, including checks that need physical cameras/audio versus simulator-only checks.
- Replace “atomic promote” with a user-visible invariant: originals survive, incomplete exports are never marked complete, and relaunch reconciles interrupted work using each platform’s actual file-operation guarantees.
- Keep AI out of the initial build. If added later, choose a provider and backend or user-credential model, disclose data flow/retention, request consent, and retain a manual authoring path.
- Define first-run, autosave/recovery, undo scope, export presets, progress/cancel feedback, destructive-action confirmation, and accessibility behavior.

## Toolchain adoption gate

On a fresh machine, capture CLI and IDE/plugin versions, generated file tree, Android and iOS run commands, and a clean build/run on both platforms. The Toolchain guide currently labels the feature Alpha, so fall back only when a documented blocker prevents generation, sync, build, or run; preserve the generated project and document the exact reproducible migration to the supported Gradle/KMP setup. For iOS, include Xcode installation/SDK selection, simulator launch, and a separate signing/provisioning/device trust path for physical-device validation.

## Additional primary references

- [Room for Kotlin Multiplatform](https://developer.android.com/kotlin/multiplatform/room) and [SQLite for Kotlin Multiplatform](https://developer.android.com/kotlin/multiplatform/sqlite) — compare current stable/alpha status and persistence choices before pinning.
- [Compose Multiplatform compatibility](https://kotlinlang.org/docs/multiplatform/compose-compatibility-and-versioning.html) — verify Compose/Kotlin/Gradle/AGP/Xcode compatibility together.
- [Media3 transformations](https://developer.android.com/media/media3/transformer/transformations) and [supported formats](https://developer.android.com/media/media3/transformer/supported-formats) — effects and device-format limits.
- [AVVideoComposition](https://developer.apple.com/documentation/avfoundation/avvideocomposition) and [AVAssetExportSession compatibility](https://developer.apple.com/documentation/avfoundation/avassetexportsession) — composition and supported export checks.
- [Photos library save APIs](https://developer.apple.com/documentation/avfoundation/saving-captured-photos) — use save-only access when the workflow does not need to browse the photo library.
