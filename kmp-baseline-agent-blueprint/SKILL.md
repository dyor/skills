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

## Materialization Instructions / Usage
To use this skill in a new project, copy or generate the contents of this blueprint into the `AGENTS.md` file at the root directory of the user's project (`/AGENTS.md`). Then, prompt the AI to generate or update `AGENTS.md` in accordance with it.

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

### BuildConfig for API Keys & Sensitive Information
*   **Problem**: How to manage API keys (e.g., Gemini API Key) and other sensitive configurations that differ per build type (debug vs. release) or platform without hardcoding them.
*   **Solution**: Use Kotlin Multiplatform's `BuildConfig` capabilities combined with `local.properties`.

1.  **Gradle Setup (`shared/build.gradle.kts`):**
    Ensure `buildConfig` plugin is applied and configured.
    ```kotlin
    plugins {
        // ...
        id("com.github.gmazzo.buildconfig").version("3.1.0") // Or the latest version
    }

    // ... inside kotlin { ... } block
    sourceSets {
        commonMain.dependencies {
            // ...
        }
        androidMain.dependencies {
            // ...
        }
        iosMain.dependencies {
            // ...
        }
    }

    buildConfig {
        // Common configuration for all source sets
        packageName.set("org.example.project") // Your base package name
        commonMain {
            // Define build config fields common to all platforms
            buildConfigField("String", "GEMINI_API_KEY", "\"${System.getenv("GEMINI_API_KEY")}\"")
            // You can also read from local.properties for development
            // buildConfigField("String", "GEMINI_API_KEY", ""${project.findProperty("GEMINI_API_KEY") ?: ""}"")
        }
        // Platform-specific overrides if needed (e.g., for different API keys)
        androidMain {
            // android-specific BuildConfig fields
        }
        iosMain {
            // ios-specific BuildConfig fields
        }
    }
    ```

2.  **`local.properties` (at project root):**
    Create or update `local.properties` to store your API key. This file is NOT committed to VCS.
    ```properties
    GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
    ```

3.  **Importing and Using `BuildConfig` in a Service (e.g., `GeminiServiceImpl.kt`):**
    ```kotlin
    package org.example.project.data.gemini // Replace with your service's package

    import org.example.project.BuildConfig // Import the generated BuildConfig class

    class GeminiServiceImpl {

        fun generateScript(prompt: String): String {
            val geminiApiKey = BuildConfig.GEMINI_API_KEY
            // Use geminiApiKey in your API call
            return "Generated script using API Key: $geminiApiKey for prompt: $prompt"
        }

        // How to override in another function (example using a different key)
        fun anotherFunctionWithDifferentKey(altPrompt: String): String {
            val anotherApiKey = BuildConfig.GEMINI_API_KEY // Still refers to the same key
            // If you need a *different* key, you'd define it as a separate BuildConfigField
            return "Another function with key: $anotherApiKey for alt prompt: $altPrompt"
        }
    }
    ```
    **Explanation**: `BuildConfig` generates a class (`org.example.project.BuildConfig` in this example) containing static fields for each `buildConfigField` defined in your `build.gradle.kts`. You simply import this class and access the fields directly.

4.  **Accessing properties from `local.properties` in Gradle (for `buildConfigField`):**
    The `buildConfigField` can directly read from `local.properties` using `project.findProperty("YOUR_KEY")`.
    ```kotlin
    buildConfig {
        commonMain {
            buildConfigField("String", "GEMINI_API_KEY", ""${project.findProperty("GEMINI_API_KEY") ?: ""}"")
        }
    }
    ```
    This approach ensures that during local development, the API key from `local.properties` is used, while CI/CD environments can inject it via environment variables.

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
* When I say "Execute", that means that I have validated the work and I am ready for you to continue with `.skills/project-guide/SKILL.md`.
* Ensure that the `project-guide` periodically invokes `.skills/project-calculator/SKILL.md` to determine how complete the project is.
* **CRITICAL**: Always begin your response with the current active Phase and Step (if present) from `project-guide` formatted exactly like either `[Phase X - Step Y]` or `[Phase X - Step Y.Z]` or `[Phase X]`. You determine the active phase and step by finding the first unchecked `- [ ]` task in `project-guide` and looking at its parent headers.

## Skills & Best Practices
For more specific technical guidance (e.g., creating run configs, working with Room, Navigation, and complex Video Playback components like `AndroidView` and iOS Sandbox UUID resolution), heavily refer to the `.skills/project-skill/SKILL.md` (or `/Users/mattdyor/.skills/kmp-baseline-skill-blueprint/SKILL.md` templates). It contains vital workarounds for multiplatform video clipping and rendering.
```