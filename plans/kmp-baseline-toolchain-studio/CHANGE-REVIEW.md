# Independent Change Review: Factory Video Studio

## Review context

This review began in a fresh agent context after inspecting the proposed plan and the reusable `kmp-baseline` prompt, guide, agent, hints, validation, and journey skills. The initial reviewer checked current official Kotlin, Android, and Apple documentation and did not edit files. The following work materialized the project plan, renamed the six active skill directories, corrected their guidance, and test-drove the result with a generated Android+iOS project. This review now records both the original rationale and the observed outcomes; open product choices remain documented as gates.

## What changed in the proposal

The reusable templates live in `planning-skills/kmp-baseline/`; project-specific plans live in `plans/kmp-baseline-toolchain-studio/`, outside the reusable skills. Template maintenance was explicitly part of this task, so the six active directories were renamed to remove `-blueprint` and their content updated in place.

- Replaces the old joke-app/Gemini/Film Noir example with a Factory rebuild scope: scripts, teleprompter, capture, simple single-track editing, overlays, export, direct social-platform uploads, and archive/recovery.
- Makes Kotlin Toolchain the preferred project bootstrap and build workflow, including its project/module YAML model, while explicitly treating its documented Alpha status as a risk and requiring a recorded fallback route.
- Recommends Compose Multiplatform for shared workflow UI and Kotlin logic, with native Android/iOS camera, playback, media processing, permissions, and share boundaries.
- Replaces CameraK as a default with CameraX VideoCapture on Android and AVFoundation capture on iOS; recommends Media3 Transformer on Android and AVFoundation composition/export APIs on iOS.
- Sets local-first media/project handling, non-destructive edits, source preservation, cancellation/progress/error states, and native save/share as design principles.
- Adds a library decision gate rather than freezing dependency versions copied from the old examples.
- Adds a list of execution-blocking decisions covering media profiles, overlay rendering, durable asset identity, persistence choice, platform UI boundaries, phase evidence, export recovery, AI deployment/privacy, and beginner usability.
- Adds a Toolchain setup/fallback gate and additional official references for Room/SQLite, Compose compatibility, Media3 format limits, AVVideoComposition, export compatibility, and save-only photo access.
- Materializes `prompt.md`, `guide.md`, `hints.md`, `validation.md`, `AGENTS.md`, and `progress.md` so the proposal can guide a project rather than remain only a brief. The five legacy XML journeys were not copied because their fixed UI/timing assumptions conflict with this product; their intent is replaced by the validation journeys in `validation.md`.
- Test-drive findings are documented in the execution section below. The corrected project was generated at `/private/tmp/kmp-video-studio-android-ios-v2` and its plan copied under the project’s own `plans/kmp-baseline-toolchain-studio/` directory.

## Reusable skill template changes now made

The reusable collection itself has now been updated, as requested. These are template changes in `planning-skills/kmp-baseline/`; generated project-specific plan artifacts remain under `plans/`.

- `planning-skills/kmp-baseline/README.md`: changes collection positioning and startup instructions to Kotlin Toolchain and the video studio; explains the template/project-plan separation rule.
- `kmp-baseline-prompt/SKILL.md`: replaces joke/Gemini/Film Noir defaults with studio scope, Toolchain Alpha guidance, artifact materialization, explicit target selection, and a consistency gate.
- `kmp-baseline-guide/SKILL.md`: replaces the legacy fixed workflow with seven executable phases and adds target/module audits and concrete CLI run guidance.
- `kmp-baseline-agent/SKILL.md`: removes fixed module paths, secret-in-BuildConfig instructions, and Android-only validation; adds generated-layout inspection, native media boundaries, storage safeguards, and platform evidence rules.
- `kmp-baseline-hints/SKILL.md`: replaces stale dependency recipes and API claims with official-source decision gates for Toolchain, CameraX, Media3, AVFoundation, persistence, permissions, and recovery; records concrete Toolchain module/target CLI syntax.
- `kmp-baseline-validation/SKILL.md`: replaces joke app and hard-coded UI/duration journeys with product journey requirements and simulator/physical-device distinctions.
- Removed the old copied dependency/build and Kotlin examples that hard-coded obsolete versions, CameraK, Gemini, Room setup, and legacy layouts; removed the five fixed XML journeys that contradicted the new plan.
- `kmp-baseline-calculator/SKILL.md` remains generic progress tracking; its warning text now says “reusable skill template” instead of “blueprint”.

## Initial review findings (before materialization)

### High severity

1. **The brief still is not an executable plan.** It does not yet generate the full artifact set expected by the collection: `guide.md`, `hints.md` and examples, `validation.md` and journeys, `progress.md`, and root `AGENTS.md`. The rest of the existing templates still tell agents to build a Gemini joke app and use old media assumptions. Until the six artifacts are generated and checked together, instructions conflict.

   **Required next change:** Materialize these artifacts from this proposal outside `.skills/`. Add a migration checklist naming each stale template section/example/journey and require a final cross-artifact consistency pass. Update reusable templates only in a separate authorized template-edit task.

2. **Media editing is underspecified.** Captions/title cards are promised, but the proposal does not decide whether they are burned into exported pixels or are app-only metadata. Preview/export parity, text rendering, timing, orientation, safe areas, font availability, and expected visual tolerances are undefined.

   **Required next change:** Make overlay rendering a blocking decision; define a shared edit fixture set and platform-specific acceptance criteria. Verify preview and export outputs independently on Android and iOS.

3. **The shared media job contract is only a name.** It lacks operation signatures, lifecycle/cancellation/progress semantics, error mapping, temporary-file policy, output validation, and a launch capability profile. Cross-platform conformance could be misread as identical behavior despite different hardware codecs and native APIs.

   **Required next change:** Define supported input/output formats, container/codec, resolution, frame rate, orientation and audio behavior, minimum OS/device support, unsupported-media response, job states, and cancellation/failure cleanup. Define conformance as shared semantic fixtures plus native capability tests, not identical output bytes.

4. **Durable media storage is not specified.** Rejecting absolute sandbox paths is correct, but “relocatable identifiers” does not define how the ID resolves to a file or how imports, moves, deletion, missing assets, interrupted exports, and project recovery work. The existing `VideoPathResolver.kt` suggests filename-based path reconstruction and conflicts with the intended stronger asset model.

   **Required next change:** Define stable asset IDs, managed-file location or platform URL/bookmark strategy, asset ownership and cleanup, import scope, project references, and repair/reconciliation behavior. Cover relaunch, app update, low storage, and interrupted export in validation.

### Medium severity

5. **Toolchain fallback needs a beginner procedure.** The proposal flags Alpha and names a fallback, but does not set objective fallback triggers, identify authoritative files after generation, or give reproducible migration/build steps. Physical iOS device validation also needs explicit Xcode, signing, provisioning, and device-trust prerequisites.

   **Required next change:** Add first-run prerequisite checks, expected generated files, captured CLI/plugin versions, fallback triggers, exact fallback procedure, and separate simulator versus signed physical-device validation.

6. **Persistence remains open despite archive/recovery being in scope.** “Use Room only after checking compatibility” and “add a database only when archive/recovery needs justify it” conflict with archive/restore already being core requirements. Current Android docs provide KMP Room and SQLite setup guidance, but version maturity must be checked when initializing.

   **Required next change:** Choose Room KMP, SQLite, or a deliberately small file catalog in the materialized plan. Compare migrations, transactions, iOS support, testability, and beginner effort; define schema/migration policy and pin checked versions.

7. **Compose/native ownership boundaries need a screen contract.** The proposal says most UI is shared and media surfaces are native but does not define native host lifecycle ownership, event/state flow, or accessibility treatment for recording controls and timeline.

   **Required next change:** Add a platform/screen matrix and interface contracts for shared workflow screens, native camera preview, playback, permissions, and share flows. Include TalkBack and VoiceOver validation.

8. **Phases need owners and observable gates.** Current phases are broad outcomes, without numbered tasks, runnable increments, dependencies, ownership, or completion evidence. Existing journeys contain assumptions (generated script, five-second countdown, fixed duration/layout) that need to be reconciled with manual-first workflows.

   **Required next change:** For every phase specify user/agent action, deliverable, Android/iOS test evidence, and clear acceptance. Replace all old journeys and distinguish simulator tests from physical camera/microphone tests.

### Low severity

9. **The “atomic promote” wording can overpromise.** File atomicity across platform locations and volumes is not specified.

   **Required next change:** Define the user-visible guarantee: source remains intact and incomplete exports are never marked complete. Specify platform promotion operations and startup reconciliation of orphaned temporary files.

10. **AI key/privacy guidance lacks a deployable model.** “Provider-independent,” optional, and consented does not explain how credentials avoid being embedded in the app or what user content leaves the device.

   **Required next change:** Keep AI out of the first increment. If introduced later, require a provider and backend or user-supplied credentials, data-flow/retention disclosure, explicit consent, and manual script authoring.

11. **Beginner usability needs product decisions.** Empty states, autosave, undo, destructive actions, export presets, progress/cancel feedback, and how originals differ from exports are missing.

   **Required next change:** Add a first-run-to-export journey and decisions for these product behaviors, including accessible controls.

12. **Research list must remain tied to concrete choices.** Added sources broaden coverage, but actual Room, Compose, Toolchain, Media3, and Apple API versions and maturity should be rechecked at plan materialization. A starting link is not proof the selected version is compatible.

   **Required next change:** Record source check date, exact selected versions, compatibility constraints, and rationale in the generated hints/build section.

## Verified facts and judgment

**Verified from official documentation checked for this review:**

- Kotlin Toolchain is documented as Alpha, creates `project.yaml` and module YAML files, and uses a project layout that differs from the legacy source-set paths used in the old examples. [Kotlin Toolchain setup](https://kotlinlang.org/docs/multiplatform/kotlin-toolchain.html)
- CameraX `VideoCapture` is a lifecycle-bound use case, and supported use-case combinations depend on device hardware. [CameraX video capture](https://developer.android.com/media/camera/camerax/video-capture)
- Media3 Transformer supports trims/effects/conversion and documents supported formats and device capability constraints. [Transformer](https://developer.android.com/media/media3/transformer), [supported formats](https://developer.android.com/media/media3/transformer/supported-formats)
- Apple documents native capture sessions and movie file output; Apple export APIs expose compatibility checks. [Capture setup](https://developer.apple.com/documentation/avfoundation/setting-up-a-capture-session), [AVCaptureMovieFileOutput](https://developer.apple.com/documentation/avfoundation/avcapturemoviefileoutput), [AVAssetExportSession](https://developer.apple.com/documentation/avfoundation/avassetexportsession)
- Android publishes KMP setup guidance for Room and SQLite; Compose Multiplatform compatibility depends on Kotlin, Gradle, AGP, and Xcode compatibility. [Room KMP](https://developer.android.com/kotlin/multiplatform/room), [SQLite KMP](https://developer.android.com/kotlin/multiplatform/sqlite), [Compose compatibility](https://kotlinlang.org/docs/multiplatform/compose-compatibility-and-versioning.html)
- Apple Photos save APIs can request add-only access, avoiding broad library read access when browsing is not required. [Saving captured photos](https://developer.apple.com/documentation/avfoundation/saving-captured-photos)

**Reviewer judgment:** The proposal is directionally sound, especially around native media boundaries and avoiding absolute-path persistence. Its current completeness is insufficient for a beginner to execute safely without making major architecture decisions midstream. The severity assignments reflect likely implementation and integration impact, not claims made by platform vendors.

## Template alignment follow-up

The source areas flagged by the reviewer were addressed in the current active skills: `kmp-baseline-prompt`, `kmp-baseline-guide`, `kmp-baseline-agent`, `kmp-baseline-hints`, `kmp-baseline-validation`, `kmp-baseline-calculator`, and the collection README. Stale copied examples and fixed XML journeys were removed. The archived snapshots under `archive/tasks/kmp-baseline/` remain as historical records and are not active templates.

## Test-drive findings and evidence

- The first generated project at `/private/tmp/kmp-video-studio` included a Server selection, yielding `core` and `server`. Its `project.yaml` listed `app/androidApp`, `app/iosApp`, `app/shared`, `core`, and `server`.
- Re-running the wizard correctly produced `/private/tmp/kmp-video-studio-android-ios-v2` with exactly `androidApp`, `iosApp`, and `shared`. The observed defaults selected Android, iOS, Desktop (JVM), and Web (Wasm); Server was off. Pressing Enter while Server was highlighted toggled it on, so the prompt now gives row-by-row selection guidance and requires a generated-module audit.
- The Toolchain wizard takes project ID after the target picker. Sending target confirmation and ID text in the same input sequence caused a stray space to be read as the project ID; the prompt now explicitly separates those interactions.
- The generated app README uses module names such as `androidApp`; passing the filesystem path as `-m` is wrong. Kotlin Toolchain 0.13 accepts `-p android` and `-p iosSimulatorArm64`, while `-p ios` is rejected. The prompt, guide, and hints now call for module names and concrete target names, checked against `kotlin run --help`.
- The unchanged Android starter compiled and launched on `emulator-5554`. An Android CLI journey tapped “Click me!” and verified `Compose: Hello, Android 37!`.
- The shared script home/editor increment compiled and ran on Android; the journey created a title/body draft and returned to the draft card. Evidence is stored in the test app plan under `resources/` and `evidence/`.
- The shared UI compiled for `iosSimulatorArm64`, Xcode reported `Build Succeeded`, and Kotlin Toolchain launched it on an iPhone 17 Pro simulator (iOS 26.5). The first screenshot surfaced a status-bar safe-area collision; the app now applies Compose `safeContentPadding()` at the root, and the final screenshot confirms the header clears the status bar.
- An aggregate `./kotlin build` printed successful shared Android/iOS and Android app compilations but did not terminate; it was stopped and is not recorded as a successful aggregate build. Module-specific runs provide the verified build/run evidence. Android CLI and Xcode required access to their user cache/device-set files, so those commands were run with the environment’s authorized escalation.

The first generated project and the corrected project are both retained under `/private/tmp`; the failed first attempt was not pruned or overwritten.

## Product scope correction

The owner clarified that the intended app is a rebuild of Factory and explicitly selected social platforms as the uploader destination class. The earlier plan's “automatic social publishing out of scope” wording was too broad and contradicted the desired product. The reusable prompt, guide, hints, agent instructions, validation rules, README, and project-specific artifacts now require a direct, user-confirmed uploader to selected social platforms. A simple editor is explicitly single-track (arrange/reorder clips, trim, preview, timed titles/captions, export). The exact social platform list and associated account/API enrollment remain a User Action. An OS share sheet is documented as supplemental, never as a substitute.

## Review status

The active reusable skill templates use their renamed paths, and the plan is maintained both in the skills workspace and within the corrected test app repo under `plans/kmp-baseline-toolchain-studio/`. The implementation now includes a shared script draft editor, Android/iOS local single-draft persistence, and a teleprompter with adjustable type size and speed plus start/pause/rewind. Android and iOS simulator journeys confirmed saved title/body, process restart, and reopen. Multi-project/media storage, capture integration, the simple editor, direct uploader integrations, and physical-device checks remain future phases. The owner selected social platforms as the uploader destination class; the first platform list, account/auth flow, API enrollment, and any backend needs remain user decisions. Minimum OS versions and the media profile are also open. Android script, teleprompter, and persistence journeys pass; iOS persistence passed on simulator.

## Test-drive correction: teleprompter scrolling

The first short-script try showed that the effect immediately reset `isScrolling` when `maxValue` was zero. The scrolling loop now remains in its started state when no overflow exists and auto-stops only after a nonzero scroll range reaches its end. A long-script Android run verified Start/Pause state changes, text-size adjustment, and rewind. Android journey XML is a step specification, not an `android journey` CLI command; the installed Android CLI requires sequential agent execution and per-action JSON. Its screenshot resolver uses `--screenshot`, while some installed journey-skill examples still say `--screen`.

## Test-drive increment: local draft persistence

The previous editor held its only draft in Compose memory, so app process death lost the user's writing. The app now injects a small `ScriptDraftStore` boundary: Android uses app-scoped preferences and iOS uses app-scoped `NSUserDefaults`; shared UI loads on launch, debounces saves while typing, and saves before leaving the editor. Android and iOS simulator journeys created a title/body, terminated and relaunched the app, verified the draft card, and reopened the editor with the same text. This is a single-draft prototype, not the final project/media catalog decision. Preference stores are not encrypted; do not store credentials or treat this prototype as a privacy/security decision. Multiple projects, script sections, media records, backup, and at-rest protection still need a durable model selected for the full Factory workflow.
