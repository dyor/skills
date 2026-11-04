# Project Agent Instructions

- Read `guide.md`, `hints.md`, `validation.md`, and `progress.md` before work on this app.
- Kotlin Toolchain is the default generator/workflow. Inspect generated project structure; do not assume legacy `shared/`, `androidApp/`, Gradle, or source-set paths.
- Preserve Toolchain-generated configuration. Record versions and use the explicit fallback gate in `guide.md`; prove both Android and iOS builds after fallback.
- Keep shared workflow/domain code in common Kotlin where supported. Own camera sessions, media players/exporters, system permissions, photo-library access, social authorization/upload adapters, and share sheets behind explicit interfaces and secure platform token storage.
- Direct uploads to owner-selected social platforms are required in the eventual product. OS share/save is supplemental. Check official platform APIs before implementation; uploads must be user-confirmed and report success only after platform confirmation.
- Treat media edits as non-destructive. Keep source assets intact, validate exports before marking complete, and recover interrupted jobs on next launch.
- Store stable asset IDs and managed locations/platform references; never persist sandbox absolute paths as durable identity.
- Check current official documentation and compatibility before selecting versions or copying API examples. Do not reuse stale CameraK, Gemini, joke-app, Navigation 3, or old Gradle snippets from the upstream examples without a new decision and verification.
- Request camera/microphone/photo access only when needed, explain denial, and test denial paths. Social uploads are required in the eventual product, but the first platform list is a user decision. Do not embed OAuth client secrets/provider secrets; do not require cloud AI.
- Follow guide phases in order. Stop at User Actions that require credentials, signing, provisioning, or hands-on device interaction.
- Mark a Validation item complete only after running the corresponding journey and recording actual Android/iOS evidence. Distinguish simulator results from physical-device checks.
- Update `progress.md` only after the guide’s matching tasks are actually complete.
