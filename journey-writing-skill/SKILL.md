---
name: journey-writing-skill
description: Use this skill when you need to test or validate app behavior, write an Android Studio Journey, automate UI testing, or define user flow validation requirements.
version: 1.0.0
author: dyor
date_created: 2026-03-27
import_commit: 87ef0d7a10afcc447de9de8454fecd4577738abc
import_date: 2026-04-25 15:38:10
import_url: https://github.com/dyor/skills/tree/main/journey-writing-skill
---

## Overview: The TDD Agentic Journey Flow

This skill forms **Step 1** of the Test-Driven Development (TDD) workflow for large codebase tasks (like migrating an app).

1. **Onset (Journey Writing):** At the beginning of a large batch of work (such as migrating from iOS to Android), run this `journey-writing-skill`. You must look at `.migration/import/feature_specification.md` (or similar spec documentation) to determine candidate Journeys. You should add journey tests at the end of each *user-facing phase*. Note: You do not need to create journey tests for pure setup phases (e.g., setting up databases and libraries), but as soon as there is user-facing functionality, a journey test must be created and linked to that phase.
2. **Verification:** Depending on the migration mode (Guided vs. Autonomous), the generated journey tests are either verified by the developer upfront, or accepted autonomously by the agent.
3. **Execution & Repair:** When a user-facing phase of work is complete, the agent runs the particular journey test associated with that phase.
   * **If the journey fails:** The agent MUST attempt to repair the *application code* (not the test itself) with at least one retry. If after multiple tries (e.g., 2-3 attempts) the code cannot be adjusted to make the journey pass, the agent must *stop work* (breaking out of any continuous loop) and report the issue to the user for manual intervention.
   * **If the journey passes:** The agent executes the `generate-journey-report` skill to generate a clean, business-level markdown report. In the case where the agent fails the first time and then passes on a subsequent retry, the report will feature a "Before and After" view showcasing the fix.

## Audience & Usage

*   **For Agents:** Use Journeys to drive spec-driven feature implementation, validate app behavior (via ADB), and optimize performance.
*   **For Developers:** Use Journeys to define requirements in natural language and create test matrices across different device configurations.

## File Specification

Journeys must be saved as artifacts within the Android Studio project structure using the following convention:
*   **Path:** `[Android Studio Project]/[module]/src/journeys/[order_number]_[journey_name].journey.xml` (e.g., `01_onboarding.journey.xml`)
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


## Example

**File:** `app/src/journeys/calendar_dentist_event.journey.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<journey name="Calendar Dentist Event">
    <description>Creates an event in the calendar to capture a dentist appointment.</description>
    <actions>
        <action>Create an event with the title "Dentist" that starts at 12:00 PM.</action>
        <action>Set the color of the event to yellow.</action>
        <action>Save the event and check that it appears in the calendar in the correct color and at the correct time.</action>
        <action>Open the details of the event that was just created and check that there is a header image that represents a dentist visit.</action>
    </actions>
</journey>
```