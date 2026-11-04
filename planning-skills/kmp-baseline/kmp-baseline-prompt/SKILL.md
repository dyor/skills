---
name: kmp-baseline-prompt
description: Initializes a Kotlin Toolchain-first KMP video production studio plan for Android and iOS, materialized outside the skills directory.
version: 3.0.0
---

> [!WARNING] This is a reusable skill template. Generated project plans and codebase-specific checklists belong outside `.skills/` (default `plans/kmp-baseline/`). Edit this template only when maintaining the reusable skill itself.

# Factory Video Studio Plan Initializer

Use this skill to plan and build the Factory mobile video-production app for Android and iOS. Its eventual scope includes a teleprompter, a simple single-track video editor, and a first-class uploader to selected social platforms. A generated skeleton or the first script-editor increment is only the beginning; retain all later product phases in the project plan.

## First prompt for a new project

Read the sibling `kmp-baseline-*` skill templates and their examples/resources, then materialize a project-specific plan outside `.skills/` (default `plans/kmp-baseline/`). Never create project plans, TODO lists, or copied resources inside the skills directory. Ask the user for a different plan directory only when needed; the default is acceptable without confirmation.

Use these defaults unless the user overrides them:

- Product: rebuild Factory as a local-first creator workflow: author scripts, record with a teleprompter, arrange and trim clips in a simple editor, add timed titles/captions, export, upload to selected social platforms, and archive projects locally.
- Platforms: Android and iOS.
- Build/project workflow: Kotlin Toolchain CLI and its generated Compose Multiplatform template. Kotlin Toolchain is documented as Alpha; record the installed version, generated structure, and a concrete fallback trigger/procedure.
- UI: Compose Multiplatform for shared workflows; native platform integrations for camera, playback, media processing, permissions, photo save, and sharing.
- Media: Android CameraX VideoCapture and Media3 Transformer; iOS AVFoundation capture/composition/export. These are candidates to verify against current docs and target-device capabilities, not promises of identical behavior.
- Initial milestone: manual script authoring and local project persistence. AI generation, cloud sync, and nonlinear multi-track editing are outside the initial scope. A user-triggered social-platform uploader is required in the eventual product; it is not replaced by export, share sheets, or photo-library save.

## Factory feature contract

Keep these eventual capabilities visible in every generated guide, validation plan, and progress tracker. Implement them in runnable phases; do not mark the product complete after the Toolchain skeleton or script editor.

- **Teleprompter**: read the saved script during capture with adjustable text size and scrolling behavior, a clear start/stop state, and usable camera framing.
- **Simple editor**: provide a single linear track that can arrange/reorder clips, trim clip boundaries, preview the sequence, add timed title/caption overlays, and export a validated video. Preserve originals. Multi-track compositing and advanced effects remain out of scope unless requested.
- **Social uploader**: upload a validated export to user-selected social platforms through their supported upload APIs. The platform list, account flow, required metadata, visibility controls, API access/approval, and whether a small backend is required must be resolved before each integration. Upload is user initiated, shows progress and terminal status, supports cancel/retry where the platform permits, and never reports success before confirmation. Sharing an exported file through an OS share sheet alone does not satisfy this requirement.
- **Account/security boundary**: use the platform's supported authorization flow and secure native token storage; never embed client secrets or long-lived credentials in the app. Use a backend only when a platform's documented flow requires server-held secrets or resumable upload coordination. Disclose the destination and content before upload.

For Android work, use the Android CLI for `android docs search`, `android skills find`/`add`, emulator management, UI inspection (`android layout`/`android screen capture`), and the journey workflow in the Android CLI skill. Build and run Kotlin Toolchain modules with `kotlin run`; `android run --apks=<path>` is for deploying an already-built APK directly. Do not require Android Studio to launch or inspect the emulator when the CLI can do it.

## Kotlin Toolchain target selection (required)

Run `kotlin new` interactively. Choose **Compose Multiplatform application**. In the observed wizard, Android, iOS, Desktop (JVM), and Web (Wasm) start selected while Server (Ktor) starts off. Keep Android and iOS selected; move to Desktop and Web and press Space on each to deselect them. Leave Server off: when it is highlighted, Enter may toggle it instead of confirming, so move to Web (or another row) and confirm with Enter. Wait for the separate project ID prompt, then enter the ID. Do not combine target confirmation and project ID input. If the installed wizard differs, inspect its current selection indicators and choose only Android+iOS; do not accept an ambiguous default selection.

Immediately audit `project.yaml`, every generated `module.yaml`, and the generated README. For this app the application modules must be Android and iOS, backed by a shared module. A Server target adds `core` and `server`; Desktop/JVM or Web can add their own application modules or shared-platform entries. The exact Android+iOS generation observed here lists `androidApp`, `iosApp`, and `shared` in `project.yaml`, and its README says it targets Android and iOS. If any unwanted target appears, correct the wizard selection and regenerate in a new empty output directory rather than pruning generated modules by guesswork. Keep the original output until the corrected project builds.

The generated module names may be path-independent names such as `androidApp` even when the module is located at `app/androidApp`. Use the module name shown by Toolchain in commands, for example `kotlin run -m androidApp -p android -d <device-serial>`; do not pass its filesystem path as the module name. For iOS, pass the concrete target accepted by the installed CLI, commonly `-p iosSimulatorArm64` for Apple Silicon simulator or `-p iosArm64` for a physical device; `-p ios` is not accepted by Kotlin Toolchain 0.13. Confirm options with the generated wrapper's `run --help` or Toolchain CLI help before use.

## Materialize these artifacts

1. `<plan_dir>/guide.md` from `kmp-baseline-guide`. Convert phases into ordered, executable tasks with `**User Action**`, `**Agent Action**`, and `**Validation**` labels, deliverables, and Android/iOS evidence.
2. `<plan_dir>/hints.md` and `<plan_dir>/examples/` from `kmp-baseline-hints`. Copy only reusable examples that remain technically valid; remove stale examples rather than blindly copying them.
3. `<plan_dir>/validation.md` and `<plan_dir>/resources/` from `kmp-baseline-validation`. Replace fixed legacy journeys with journeys for this product and copy only current, relevant resources.
4. `<plan_dir>/progress.md` from `kmp-baseline-calculator`, initialized against the generated guide.
5. Root `AGENTS.md` using `kmp-baseline-agent`. It must point to `<plan_dir>/` and recognize the actual generated Toolchain layout.

Before implementation, resolve or explicitly track: app/project ID, minimum OS versions, media import scope, output profile, caption rendering behavior, asset storage model, and persistence choice. Record assumptions; do not invent user credentials or embed service keys.

## Consistency gate

Cross-check all generated artifacts. The guide, hints, validation, journeys, examples, and AGENTS.md must agree on module layout, dependencies, teleprompter behavior, simple editor scope, uploader destinations/authentication/status, permissions, storage identity, supported media, and evidence requirements. Remove inherited joke-app/Gemini/Film Noir assumptions, stale camera wrapper claims, absolute sandbox path persistence, fixed-duration UI assumptions, and unverified version pins.

## Execution rule

Do not begin app implementation while initializing the plan. When the user later says to execute, follow the generated guide sequentially, stop for genuine user-owned actions, consult hints before platform/media/build changes, update progress from completed tasks only, and record separate simulator and physical-device validation evidence.
