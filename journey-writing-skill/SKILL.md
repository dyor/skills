---
name: journey-writing-skill
description: Use this skill when you need to test or validate app behavior, write an Android Studio Journey, automate UI testing, or define user flow validation requirements.
version: 1.0.0
author: dyor
date_created: 2026-03-27
import_commit: raw
import_date: 2026-04-19
import_url: https://github.com/dyor/skills/tree/main/journey-writing-skill
---

## Overview: The TDD Agentic Journey Flow

This skill forms **Step 1** of the Test-Driven Development (TDD) workflow for large codebase tasks (like migrating an app).

1. **Onset (Journey Writing):** At the beginning of a large batch of work, run this `journey-writing-skill`. Use `feature_specification.md` (or similar spec documentation) to determine candidate Journeys. You must capture all significant user-facing functionality (Critical User Journeys or CUJs) in `.journey.xml` files. 
2. **Verification:** Depending on the migration mode (Guided vs. Autonomous), the generated journey tests are either verified by the developer upfront, or accepted autonomously by the agent.
3. **Execution & Repair:** When a phase of work involving user-facing functionality is complete, the agent runs the particular journey test associated with that phase.
   * **If the journey fails:** The agent must attempt to repair the *application code* (not the test itself). If after multiple tries the code cannot be adjusted to make the journey pass, the agent must *stop work* (breaking out of any continuous loop) and ask for manual user intervention.
   * **If the journey passes:** The agent executes the `generate-journey-report` skill to generate a clean, business-level markdown report with screenshots to provide the developer with verifiable proof of progress.

## Audience & Usage

*   **For Agents:** Use Journeys to drive spec-driven feature implementation, validate app behavior (via ADB), and optimize performance.
*   **For Developers:** Use Journeys to define requirements in natural language and create test matrices across different device configurations.

## File Specification

Journeys must be saved as artifacts within the Android Studio project structure using the following convention:
*   **Path:** `[Android Studio Project]/[module]/src/journeysTest/[order_number]_[journey_name].journey.xml` (e.g., `01_onboarding.journey.xml`)
*   **Format:** Strict XML syntax.
*   **Ordering:** Always prepend a two-digit order number mapping directly to the phase or feature number in the `feature_specification.md`. This ensures deterministic execution for end-to-end runs where state dependencies exist (e.g., testing the profile dashboard requires a travel to be logged first).

### XML Syntax Structure

*   `<journey>`: The root element. Must include a name attribute providing a human-readable identifier.
*   `<description>`: (Optional but recommended) A short summary of the user experience.
*   `<actions>`: A container for the steps.
*   `<action>`: A natural language description of a discrete step (action and/or assertion) the user performs or expects.

### Template

```xml
<?xml version="1.0" encoding="utf-8"?>
<journey name="[Human Readable Name]">
    <description>[Short description of the experience]</description>
    <actions>
        <action>[Step 1: Action + Expected Result]</action>
        <action>[Step 2: Action + Expected Result]</action>
    </actions>
</journey>
```

## Agent Capabilities

When writing actions, limit interactions to the following supported capabilities to ensure high reliability:

*   **Tap:** Touching UI elements.
*   **Type:** Inputting text into fields.
*   **Swipe/Scroll:** Navigating the UI in specific directions.

### Unsupported/Inconsistent Capabilities

Avoid writing steps that require:

*   Multi-finger gestures (pinch-to-zoom).
*   Long-press.
*   Double tap.
*   Screen rotation or device folding.
*   Memory (recalling context from previous steps).
*   Counting.
*   Conditional logic (if/else).

## Authoring Best Practices

To create **effective** Journeys, follow these rules:

1. **Assume App is Foregrounded:** Do not write "Launch the app" as the first step. The Journey runner handles this automatically.
2. **Use Unambiguous Language:**
    *   *Bad:* "Select the button."
    *   *Good:* "Tap 'Dismiss'." or "Type 'celery' in the search bar."
3. **Combine Action and Assertion:** Include the success criteria within the step to clarify when an action is complete.
    *   *Bad:* "Select the send button."
    *   *Good:* "Send the email by tapping the submit button. This should close the email and return you to the inbox."
4. **Maintain Granularity:** Break complex interactions into multiple specific steps to avoid timeout errors (Error: Could not successfully complete the action in max allowed attempt).
5. **Use Feature Specifications as Sources:** Use `feature_specification.md` to identify candidate Journeys—typically one Journey should be created for each phase or major work element. Not all phases warrant journeys (e.g., data/networking), but any phase with a UI component needs a journey to test its key user flows.

## Troubleshooting: Enabling Android Instrumented Test Suite

When encountering the error "There is no test suite configured in your module's Gradle build file" while attempting to run Journeys or Android Instrumented Tests, perform the following steps to configure `[module]/build.gradle.kts` (e.g., `app/build.gradle.kts` or `androidApp/build.gradle.kts`):

1.  **Enable Experimental Test Suite Support**: Open your project's `gradle.properties` file and ensure the following flag is present. This is **required** to use the `suites` block in AGP, otherwise you will encounter `Unresolved reference 'suites'`, `Unresolved reference 'useJunitEngine'`, and similar compilation errors:
    ```properties
    # Opt in to AGP test suite support.
    android.experimental.testSuiteSupport=true
    ```

2.  **Ensure Compatible AGP Version**: The test suite support typically requires a recent version of the Android Gradle Plugin (e.g., AGP 9.0.0+). If you encounter unresolved references after adding the flag, ensure your AGP version in `gradle/libs.versions.toml` or your project-level build file is up to date (e.g., `agp = "9.0.0"`). If upgrading AGP, you may also need to upgrade Kotlin and dependent plugins (like KSP or Room) to compatible versions.

3.  **Set `testInstrumentationRunner`**: Inside the `android { defaultConfig { ... } }` block, ensure `testInstrumentationRunner` is set:
    ```gradle
    defaultConfig {
        // ...
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    ```

4.  **Configure `testOptions` with `packaging` and Test Suites**: Update the `testOptions` block to handle packaging of native libraries and explicitly define the `journeysTest` suite:
    ```gradle
    android {
        // ...
        testOptions {
            packaging {
                jniLibs {
                    useLegacyPackaging = true
                }
            }
            suites {
                create("journeysTest") {
                    assets {
                    }
                    targets {
                        create("default") {
                        }
                    }
                    useJunitEngine {
                        inputs += listOf(com.android.build.api.dsl.AgpTestSuiteInputParameters.TESTED_APKS)
                        includeEngines += listOf("journeys-test-engine")
                        enginesDependencies(libs.junit.platform.launcher)
                        enginesDependencies(libs.junit.platform.engine)
                        enginesDependencies(libs.journeys.junit.engine)
                    }
                    targetVariants += listOf("debug")
                }
            }
        }
    }
    ```

5.  **Add `androidTestImplementation` Dependencies and Test Engines in TOML**: Ensure the necessary testing libraries are included in your top-level `dependencies { ... }` block in your module's `build.gradle.kts`:
    ```gradle
    dependencies {
        // ... other dependencies ...
        androidTestImplementation(libs.androidx.testExt.junit)
        androidTestImplementation(libs.androidx.espresso.core)
        androidTestImplementation(libs.androidx.test.runner)
        androidTestImplementation(libs.junit)
    }
    ```
    And ensure your `gradle/libs.versions.toml` includes the engine dependencies:
    ```toml
    [versions]
    junitPlatformLauncher = "1.13.4"
    junitPlatformEngine = "1.13.4"
    journeysJunitEngine = "0.2.2"

    [libraries]
    junit-platform-launcher = { group = "org.junit.platform", name = "junit-platform-launcher", version.ref = "junitPlatformLauncher" }
    junit-platform-engine = { group = "org.junit.platform", name = "junit-platform-engine", version.ref = "junitPlatformEngine" }
    journeys-junit-engine = { group = "com.android.tools.journeys", name = "journeys-junit-engine", version.ref = "journeysJunitEngine" }
    ```

6.  **Perform Gradle Sync**: After making these changes, always run a Gradle sync to apply the new configurations.

### Important Note on IDE Sync Issues
If you have correctly configured your module's `build.gradle.kts` file (as verified by a successful `./gradlew :[module]:assembleDebugAndroidTest` build) and the "There is no test suite configured" message persists in the Journey Editor, this is likely an IDE caching bug. **You can still execute the journeys manually via the terminal:**
```bash
./gradlew :[module]:connectedDebugAndroidTest
```

## Example

**File:** `app/src/journeysTest/calendar_dentist_event.journey.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<journey name="Calendar Dentist Event">
    <description>Creates an event in the calendar to capture a dentist appointment.</description>
    <actions>
        <action>Open the Google Calendar App.</action>
        <action>Create an event with the title "Dentist" that starts at 12:00 PM.</action>
        <action>Set the color of the event to yellow.</action>
        <action>Save the event and check that it appears in the calendar in the correct color and at the correct time.</action>
        <action>Open the details of the event that was just created and check that there is a header image that represents a dentist visit.</action>
    </actions>
</journey>
```