# KMP Video Studio — Technical Hints

These are architectural guardrails, not frozen dependency snippets. Kotlin Multiplatform and media APIs evolve quickly; check official docs and compatibility at implementation time and record the date/version choice in the project.

## Kotlin Toolchain first

- Start with the official Kotlin Toolchain Compose Multiplatform application template and Android+iOS targets. The official guide currently identifies Kotlin Toolchain as Alpha.
- Invoke modules by declared module names (`androidApp`, `iosApp`), not directory paths. With Toolchain 0.13, Android uses `-p android`; iOS uses a concrete target such as `-p iosSimulatorArm64` on Apple Silicon. The shorthand `-p ios` is rejected. Confirm options with `kotlin run --help` for the installed CLI.
- Capture `kotlin --version`, IDE and Toolchain plugin versions, JDK, Android SDK, Xcode, and the generated project tree. Preserve generated `project.yaml`, module YAML, wrappers, and run instructions as source of truth.
- Inspect module names and source layout before editing. The documented Toolchain layout uses `src@android`-style directories and YAML module declarations; legacy `shared/src/androidMain` assumptions may be wrong.
- Use Toolchain CLI commands documented for the installed version. Do not guess commands from Gradle projects.
- Fallback only after a reproducible blocker in generation, dependency resolution, build, or run. Write down the blocker, migrate in a documented sequence, and verify clean Android and iOS builds after transition.

## Shared versus native ownership

- Share domain types, script/project workflows, timeline math, edit intent, and most workflow UI.
- Native platform layer owns camera sessions, media surfaces/players, codecs, export jobs, file/photo-library access, permissions, and share sheets.
- Define narrow interfaces with typed state/events. Keep native framework objects and lifecycle owners out of shared domain state.
- Native camera and playback hosts must have explicit lifecycle disposal, interruption, orientation, and error behavior. Do not start/stop capture as an incidental composable recomposition side effect.

## Media pipeline

- Android recording: CameraX VideoCapture is the standard candidate; bind/unbind use cases to the correct lifecycle and handle device capability combinations.
- iOS recording: use AVFoundation capture sessions and an appropriate movie output. Configure camera/microphone inputs, session lifecycle, orientation, interruption, and audio session behavior deliberately.
- Android editing/export: evaluate Media3 Transformer for trimming, effects, and output conversion. Check supported input/output formats and device codec capabilities at runtime.
- iOS editing/export: use AVFoundation composition/export APIs and check preset/output compatibility before starting work.
- Common edit model should express intent (source asset, trim ranges, timed overlays, output profile). Platform adapters execute it. Cross-platform tests assert semantics; do not compare output byte-for-byte or assume identical codec output.
- Specify export job states and cancellation, progress, failure mapping, output validation, temporary output cleanup, and relaunch reconciliation. Preserve source until output is validated.
- For captions/title cards, establish whether rendered into exported pixels, the font/fallback policy, safe areas, coordinate space, text wrapping, timing, opacity/background, orientation, and preview/export parity before choosing implementation details.
- Probe each input asset for duration, dimensions, rotation, tracks, codec/container, and audio. Unsupported files should fail with an actionable message before destructive work.
- Test camera switching, backgrounding, audio route changes, low storage, cancellation, interrupted exports, and repeated sessions on real devices.

## Project and media persistence

- Keep project/script/edit metadata separate from large media blobs.
- Give each managed asset a stable app-generated ID and record ownership, media kind, relative managed location or platform-specific durable reference, and verification metadata. The resolver should report unavailable/moved assets instead of silently constructing stale absolute paths.
- Decide whether external clip import is supported. If it is, define security-scoped/platform URI handling and copying/bookmark lifetime; do not assume picker URLs remain accessible forever.
- Define cleanup ownership so removing a project cannot delete an asset still referenced elsewhere. Preserve originals when exporting edits.
- Choose Room KMP, SQLite, or a small file catalog based on actual archive/recovery needs, migrations, transaction requirements, and iOS target support. Check current official status before pinning versions; the Room and SQLite documentation may describe alpha artifacts.
- Include schema migrations and interrupted write/relaunch tests. For files, use versioned serialization and explicit atomic-replacement guarantees per platform.

## Permissions and publishing

- Request camera and microphone only when the user starts the recording flow. Explain purpose before the system prompt where useful and provide a clear denied/retry path.
- Use a save-only photo-library API when the app only exports to Photos; avoid broad library read permission unless browsing is a product requirement.
- Keep add-to-library and share-sheet calls on native sides, returning typed success/cancel/failure results to shared UI.
- Check Android manifest features/permissions and iOS usage descriptions against the exact APIs used. Do not request unused permissions.

## Social-platform uploader

- Direct upload to selected social platforms is an eventual Factory requirement. An OS share sheet or saving to Photos/Gallery is an additional route, not an uploader substitute.
- Before each integration, check that platform's current official API: developer enrollment and approval, account eligibility, auth/OAuth flow, supported upload types and limits, caption/title/privacy metadata, rate limits, processing state, resumability, and error semantics.
- Keep a shared upload job contract for destination/account identity, media reference, user-reviewed metadata, progress, cancellation, retry/resume capability, remote processing, success confirmation, and actionable failures. Adapters must reflect each platform's actual behavior.
- Use secure native token storage and never bundle client secrets or long-lived credentials. Add a backend only if a chosen provider requires server-held secrets or upload coordination; record which content and metadata cross it.
- Make the user confirm the platform, account, video, caption/metadata, and visibility before sending. Only show success after a platform-confirmed result; protect retries from accidental duplicate publishing.
- Validate with platform test/sandbox, private/unlisted settings, or designated test accounts when available. Do not publish test content to a real audience without explicit approval.

## Beginner project workflow

- Keep one small runnable increment per phase and build/run both targets regularly. Diagnose iOS build issues using Xcode output and toolchain diagnostics rather than blanket cache invalidation.
- Separate IDE sync, compile, simulator runtime, physical hardware, and signing failures in reports.
- Do not add AI credentials to app resources, build config, or source control. The initial plan is manual-first; an AI feature needs a provider/service and privacy design before implementation.

## Official starting references

- [Kotlin Toolchain KMP setup](https://kotlinlang.org/docs/multiplatform/kotlin-toolchain.html)
- [Kotlin Multiplatform quickstart](https://kotlinlang.org/docs/multiplatform/quickstart.html)
- [Compose Multiplatform compatibility](https://kotlinlang.org/docs/multiplatform/compose-compatibility-and-versioning.html)
- [Room KMP](https://developer.android.com/kotlin/multiplatform/room) and [SQLite KMP](https://developer.android.com/kotlin/multiplatform/sqlite)
- [CameraX video capture](https://developer.android.com/media/camera/camerax/video-capture)
- [Media3 Transformer](https://developer.android.com/media/media3/transformer), [transformations](https://developer.android.com/media/media3/transformer/transformations), and [supported formats](https://developer.android.com/media/media3/transformer/supported-formats)
- [AVFoundation capture setup](https://developer.apple.com/documentation/avfoundation/setting-up-a-capture-session), [AVVideoComposition](https://developer.apple.com/documentation/avfoundation/avvideocomposition), and [AVAssetExportSession](https://developer.apple.com/documentation/avfoundation/avassetexportsession)
- [Apple Photos save APIs](https://developer.apple.com/documentation/avfoundation/saving-captured-photos)
