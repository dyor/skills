---
name: kmp-baseline-agent-blueprint
description: Blueprint for writing or updating an AGENTS.md file that includes agent instructions for a KMP project.
---

# Blueprint Agents Skill

## When to use this skill
- Use this when generating the root-level AGENTS.md file for a new project.
- This is helpful for setting the ground rules and constraints for the AI Agent in the codebase.

## How to use it
- Execute the instructions for the AI Assistant below to create or update `AGENTS.md`.

---

# Skill: Agent Instructions

## Description
This document provides predefined instructions for an AI assistant to create or update an `AGENTS.md` file in the root directory.

## Trigger / Usage
To use this skill in any project, ensure this file is in the blueprint skills directory and prompt the AI to generate or update `AGENTS.md` in accordance with it.

---

## Instructions for the AI Assistant

When the trigger prompt is received, please write or update the `AGENTS.md` file at the root of the project with the following content:

```markdown
# Project Overview: Film Factory

## Introduction
This is a **Kotlin Multiplatform (KMP)** project called "Factory". It targets **Android** and **iOS**. It uses **Compose Multiplatform** for sharing UI code across these platforms.

## Architecture & Modules

### Root Structure
*   `androidApp`: Android application module.
*   `iosApp`: Xcode project for the iOS application.
*   `shared`: The core shared module containing business logic and shared UI.
*   `gradle`: Contains version catalog (`libs.versions.toml`) and wrapper.

### The `shared` Module
The heart of the application. It is consumed by all other platform-specific modules.
*   **Source Sets:**
    *   `commonMain`: Code shared across all platforms (UI, ViewModels, Domain logic).
    *   `androidMain`: Android-specific implementations.
    *   `iosMain`: iOS-specific implementations.
*   **Key Files:**
    *   `App.kt`: The main Composable entry point for the shared UI.
    *   `Platform.kt`: Example of platform-specific code (expect/actual).
*   **Resources:**
    *   `composeResources`: Shared resources (images, strings, fonts, etc.) are located in `shared/src/commonMain/composeResources`. These are accessed via `Res` generated class.

### Platform Modules
1.  **Android (`:androidApp`)**
    *   Standard Android App structure.
    *   `minSdk`: 24, `compileSdk`: 36.
    *   Dependencies: `androidx.activity`, `compose`, and `:shared`.

2.  **iOS (`iosApp`)**
    *   Native Xcode project.
    *   Embeds the shared code as a framework (`Shared.framework`).
    *   Entry point: `iOSApp.swift` (typically).
    *   **Run:** Open `iosApp/iosApp.xcodeproj` in Xcode and run on a Simulator/Device.

## Dependency Management
*   Dependencies are managed in `gradle/libs.versions.toml`.
*   **Adding a dependency:**
    1.  Add the version and library alias in `libs.versions.toml`.
    2.  Sync Gradle.
    3.  Add implementation in the `build.gradle.kts` of the target module (usually `shared`'s `commonMain` or specific platform source set).

## Development Workflow / "Skill"
To efficiently extend this codebase:
1.  **Shared UI First:** Always try to implement UI in `shared/src/commonMain/kotlin/org/example/project/App.kt` or new composables in that package.
2.  **Platform Divergence:** If you need platform-specific behavior (e.g., Camera, Permissions, SQL Drivers), use the `expect` keyword in `commonMain` and implement `actual` in `androidMain`, `iosMain`, etc.
3.  **Resources:** Put shared resources (images, strings) in `shared/src/commonMain/composeResources` (or similar, check `compose.components.resources` usage). **Use snake_case for filenames.**
4.  **Testing:**
    *   Unit tests go in `commonTest`.
    *   Platform tests go in `androidTest`, `iosTest`, etc.

## Common Tasks
*   **Update Kotlin Version:** Edit `kotlin` version in `libs.versions.toml`.
*   **Add a Screen:** Create a new Composable file in `shared/commonMain` and call it from `App()`.

## Code Style
*   Follow standard Kotlin coding conventions.
*   Use Material3 for UI components where possible.
*   **Responsive UI:** Use `Box(contentAlignment = Alignment.Center)` with `widthIn(max = 600.dp)` for main content to support broader screens if needed.

## Prompting
* When I say "Execute", that means that I have validated the work and I am ready for you to continue with `.agents/skills/project-guide/SKILL.md`.
* Ensure that the `project-guide` periodically invokes the `.agents/skills/project-calculator/SKILL.md` to determine how complete the project is.
* **CRITICAL**: Always begin your response with the current active Phase and Step (if present) from `project-guide` formatted exactly like either `[Phase X - Step Y]` or `[Phase X - Step Y.Z]` or `[Phase X]`. You determine the active phase and step by finding the first unchecked `- [ ]` task in `project-guide` and looking at its parent headers.

## Skills & Best Practices
For more specific technical guidance (e.g., creating run configs, working with Room, Navigation, and complex Video Playback components like `AndroidView` and iOS Sandbox UUID resolution), heavily refer to the `.agents/skills/project-skill/SKILL.md` (or `.agents/blueprint-skills/kmp-baseline-skill-blueprint/SKILL.md` templates). It contains vital workarounds for multiplatform video clipping and rendering.
```