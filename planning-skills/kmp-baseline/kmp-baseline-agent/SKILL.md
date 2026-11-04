---
name: kmp-baseline-agent
description: Generates project-specific KMP video studio agent instructions that follow Kotlin Toolchain structure and point to plans outside the skills directory.
version: 3.0.0
---

> [!WARNING] Template only. Generate the application repository's root `AGENTS.md` from this skill. Project-specific instructions belong in that app repository and its plan directory, never in this skills folder.

# Agent Instructions Template

When initializing a project, inspect its generated Kotlin Toolchain files and materialized `<plan_dir>/guide.md` and `<plan_dir>/hints.md`. Create/update the app repository root `AGENTS.md` with the following adaptable rules. Replace placeholders and examples with observed paths; do not assume `shared/`, `androidApp/`, `iosApp/`, Gradle, or legacy source sets.

## Product and architecture

- This app rebuilds Factory as an Android/iOS video-production app: scripts, teleprompter, camera/audio capture, a simple single-track editor, export, direct upload to selected social platforms, and archive/restore. OS share/save is an additional output route, not a substitute for the uploader.
- Kotlin Toolchain is the preferred project/build workflow. Record the installed version and generated configuration. It is documented as Alpha; follow the project's explicit fallback trigger and prove Android+iOS after fallback.
- Share domain/workflow logic and most UI using the project's selected Compose Multiplatform setup. Keep camera, playback, export/codec, permissions, Photos access, social-platform authorization/upload adapters, and sharing behind narrow interfaces with platform-specific secure token handling.
- Inspect actual modules and source layout before editing. Preserve Toolchain generated YAML, wrappers, and project configuration.

## Media and storage rules

- Android candidates: CameraX VideoCapture and Media3 Transformer. iOS candidates: AVFoundation capture, composition, and export. Check current official documentation, compatibility, supported formats, and device capabilities before implementation.
- Keep edits non-destructive. Preserve originals; never mark an export complete before validating its tracks, duration, and playability.
- Model progress, cancellation, permission denial, unsupported media, storage failure, interruption, and recovery explicitly.
- Treat social uploads as explicit user actions. Confirm platform, account, metadata, and visibility before sending; show progress and only report completion after platform confirmation. Check each selected platform's official API and retry/resume semantics. Never ship client secrets or use a share sheet as the only uploader implementation.
- Test only with private/unlisted/test destinations unless the user explicitly approves public publishing.
- Persist stable project/asset IDs and app-managed locations or platform references. Do not persist absolute sandbox paths as durable identities. Define ownership and cleanup before deleting media.
- Request system permissions just in time and only for APIs actually used. Social upload is a required network flow started by the user; AI and cloud sync remain optional. Never embed provider or OAuth client secrets in the app.

## Workflow and validation

- Read `<plan_dir>/guide.md`, `hints.md`, `validation.md`, and `progress.md` before implementation. Follow the guide sequentially and stop for user-owned credentials, signing, provisioning, or hands-on device actions.
- After build/dependency changes, run the appropriate sync/build. Validate both Android and iOS incrementally; distinguish configuration, compilation, simulator, physical-device, and signing failures.
- Mark a Validation item complete only after the journey ran and its report/evidence is retained. Simulator results do not prove physical camera, microphone, codecs, or thermal behavior.
- Update progress from completed tasks and attach actual evidence. Do not assume API signatures or copy stale snippets; consult official docs and project-generated configuration.

## Materialization output

The generated root `AGENTS.md` must state the real app name, actual module/file locations, build/run commands, plan directory, selected dependencies/versions, native interface boundaries, and any user-specific constraints discovered. Keep it concise and link to the plan files instead of duplicating their full contents.
