# Factory KMP Video Studio Planning Skill

This reusable planning skill helps a KMP beginner rebuild Factory as an Android+iOS video-production app using Kotlin Toolchain and Compose Multiplatform. The eventual product includes a teleprompter, simple single-track editor, and direct uploader to selected social platforms, with native media and platform integrations behind explicit boundaries.

## Contents

- `kmp-baseline-prompt/`: initialization and artifact-generation sequence.
- `kmp-baseline-guide/`: phased implementation guide template.
- `kmp-baseline-agent/`: instructions for generating the application repository's `AGENTS.md`.
- `kmp-baseline-hints/`: Kotlin Toolchain, KMP, persistence, camera, and media architecture guidance.
- `kmp-baseline-validation/`: end-to-end validation requirements and journey-generation rules.
- `kmp-baseline-calculator/`: progress tracking instructions.

## Separation rule

These files are reusable templates. When applying the skill to an app, put the generated `guide.md`, `hints.md`, `validation.md`, `progress.md`, examples/resources, and root `AGENTS.md` in the app repository, outside `.skills/` (default plan directory: `plans/kmp-baseline/`). Never create app-specific plans or TODOs in this skill directory.

## Start

Ask the coding agent to read `kmp-baseline-prompt/SKILL.md` and initialize the plan in the target application repository. Use the Android CLI (`android docs`, `android skills`, `android emulator`, layout/screen inspection, and journey execution) for Android documentation, Android-specific skills, emulator management, and Android journeys. Build and run Kotlin Toolchain modules with `kotlin run`; use `android run --apks=<path>` only for an already-built APK. The agent should inspect Kotlin Toolchain's current documentation and generated project structure, record its version (currently documented as Alpha), and verify current dependency compatibility before pinning libraries.

## Stack intent

Use Kotlin Toolchain as the preferred project/build workflow; Compose Multiplatform for shared workflow UI and business logic; CameraX VideoCapture and Media3 Transformer as Android candidates; AVFoundation capture/composition/export on iOS. Keep hardware/media and social upload APIs behind small interfaces. Treat library choices, social destinations, authorization flows, and versions as gates to validate against current official documentation and the app's supported device profile. Direct upload is a required product capability; share-sheet export alone is insufficient.
