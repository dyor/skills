# Initialize the Factory Video Studio Plan

Read the materialized skill files in this directory before making project changes: `guide.md`, `hints.md`, `validation.md`, `AGENTS.md`, and `progress.md`. These are the project-specific working instructions. The upstream `planning-skills/kmp-baseline` files are reference templates only; do not write plans into `.skills/`.

## Product defaults

- Product: rebuild Factory as a local-first Android/iOS creator app with manual scripts, teleprompter recording, a simple single-track editor, export, direct upload to selected social platforms, and archive.
- Build workflow: Kotlin Toolchain CLI and its generated Compose Multiplatform template, Android and iOS targets. Kotlin Toolchain is Alpha; record version and fallback trigger before creating the app.
- UI: Compose Multiplatform for shared workflow screens. Use native capture, playback, export, permission, social authorization/upload, and share APIs behind small boundaries.
- No AI service is required for the first increment. Users can author scripts manually.
- Direct social-platform upload is part of the eventual product; sharing an exported file through the OS share sheet does not meet this requirement. Keep the first destination list open until the owner confirms platforms and account/API enrollment.

## Required sequence

1. Inspect the target repository and current Toolchain/IDE/Android SDK/Xcode setup. Ask the user only for product choices that materially affect the result. Do not modify files until the target application repository and project ID are known.
2. Generate or adapt the KMP Toolchain project. Preserve generated config and record versions. Validate an untouched Android and iOS run before adding features.
3. Turn every phase in `guide.md` into small runnable increments. Keep checked state truthful; validation requires actual evidence on both platforms, with simulator and physical-device evidence labeled separately.
4. Consult `hints.md` before build, persistence, camera, playback, export, or social upload changes. Check current official docs and compatibility for evolving libraries/platform APIs instead of copying unverified versions.
5. Keep media files in managed storage and persist stable asset IDs and metadata, never stale absolute sandbox paths. Preserve originals through edits and exports.
6. Update `progress.md` after each completed phase. Stop at user-owned prerequisites such as signing, provisioning, or physical-device permission steps.

## Initial questions for the project owner

Confirm the app name/project ID, minimum Android and iOS versions, whether users must import existing clips, and the first social platforms to support. Social upload is required; platform selection, account flows, metadata/visibility controls, and any required backend/API enrollment must be resolved before integration. If unanswered, document these as user actions in the project plan rather than blocking independent setup work.
