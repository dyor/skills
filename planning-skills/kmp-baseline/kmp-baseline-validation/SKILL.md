---
name: kmp-baseline-validation
description: Creates Android and iOS end-to-end journeys for a Kotlin Toolchain-first local video production studio.
version: 3.0.0
---

> [!WARNING] Template only. Materialize `<plan_dir>/validation.md` and journey resources outside `.skills/`, normally under `plans/kmp-baseline/`.

# Factory Video Studio User Journey Validation

Generate validation journeys for the actual project scope and UI. Do not preserve stale labels, fixed screen layouts, network calls, script content, durations, or controls from examples unless the implemented product explicitly uses them. Copy this skill's `resources/` only after confirming it matches the generated journeys; revise or replace incompatible journeys.

## Protocol

1. Run available unit/integration/build checks first and record commands/results.
2. Run Android and iOS journeys with platform and OS noted. Separate simulator evidence from physical camera/microphone/device evidence.
3. If a journey fails, stop that journey, add a focused fix task to `<plan_dir>/guide.md`, fix it, then rerun. Do not mark validation complete based on assumed behavior.
4. Retain report/screenshots at an agreed path in the app repository, outside `.skills/`.

For Android journeys, follow the installed Android CLI skill exactly. Store each XML file in the Android app module at `src/journeys/` (for this Kotlin Toolchain KMP template, normally `shared/src/journeys/`). Use its journey XML format, inspect actions with `android layout` first and screenshots as needed, execute each action in order, and report per-action JSON results with the project plan. The XML is a step specification; do not assume Android CLI provides a journey runner. Use Android CLI emulator management/deployment rather than requiring Android Studio. iOS journey execution remains a separate native simulator/device validation lane.

## Required gates

- Toolchain-generated project: recorded CLI/tool versions; clean Android and iOS simulator build/run.
- Project persistence: create, relaunch, reopen, and verify metadata and script.
- Permissions: camera/microphone denial and grant paths; no unused permission requests.
- Recording: front-camera preview, audio/video capture, stop, interruption, partial output cleanup; physical-device coverage.
- Editing/export: supported/unsupported media, trim semantics, caption/title behavior, preview/export parity, cancellation, low storage, output validation, interrupted-export recovery.
- Social uploader: select destination/account, review video and metadata, confirm user-initiated upload, observe progress/processing/completion, and exercise cancellation, retry/resume where supported, auth expiry, network failure, duplicate protection, and platform rejection. Use test/private destinations where available.
- Local outputs/archive: save/share, external playback, archive/restore, missing-media repair, cleanup ownership.
- Accessibility and resilience: screen reader, larger text, orientation, background/resume, repeated sessions.

## Journey generation

Create project-specific end-to-end journeys for (1) new user to script/teleprompter, (2) record and recover, (3) edit and export, (4) upload to each selected social platform then archive/restore, and (5) full creator regression including a confirmed upload. Include observable expected results, auth/network/API error cases, and any physical-device-only steps. Do not require a cloud AI account or fixed video length for baseline acceptance. Never publish test media to a real audience without explicit user approval.
