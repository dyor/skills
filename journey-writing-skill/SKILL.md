---
name: journey-writing-skill
description: This skill helps you write an Android Studio Journey to test and validate your app behavior
---

## Audience & Usage

*   **For Agents:** Use Journeys to drive spec-driven feature implementation, validate app behavior (via ADB), and optimize performance.
*   **For Developers:** Use Journeys to define requirements in natural language and create test matrices across different device configurations.

## File Specification

Journeys must be saved as artifacts within the Android Studio project structure using the following convention:
*   **Path:** [Android Studio Project]/[module]/src/journeys/[journey_name].journey.xml
*   **Format:** Strict XML syntax.

### XML Syntax Structure

*   <journey>: The root element. Must include a name attribute providing a human-readable identifier.
*   <description>: (Optional but recommended) A short summary of the user experience.
*   <actions>: A container for the steps.
*   <action>: A natural language description of a discrete step (action and/or assertion) the user performs or expects.

### Template

    XML

<?xml version="1.0" encoding="utf-8"?> \
<journey name="[Human Readable Name]"> \
    <description>[Short description of the experience]</description> \
    <actions> \
        <action>[Step 1: Action + Expected Result]</action> \
        <action>[Step 2: Action + Expected Result]</action> \
    </actions> \
</journey> \

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
    *   _Bad:_ "Select the button."
    *   _Good:_ "Tap 'Dismiss'." or "Type 'celery' in the search bar."
3. **Combine Action and Assertion:** Include the success criteria within the step to clarify when an action is complete.
    *   _Bad:_ "Select the send button."
    *   _Good:_ "Send the email by tapping the submit button. This should close the email and return you to the inbox."
4. **Maintain Granularity:** Break complex interactions into multiple specific steps to avoid timeout errors (Error: Could not successfully complete the action in max allowed attempt).

## Example

**File:** app/src/journeys/calendar_dentist_event.journey.xml

    XML

<?xml version="1.0" encoding="utf-8"?> \
<journey name="Calendar Dentist Event"> \
    <description>Creates an event in the calendar to capture a dentist appointment.</description> \
    <actions> \
        <action>Open the Google Calendar App.</action> \
        <action>Create an event with the title "Dentist" that starts at 12:00 PM.</action> \
        <action>Set the color of the event to yellow.</action> \
        <action>Save the event and check that it appears in the calendar in the correct color and at the correct time.</action> \
        <action>Open the details of the event that was just created and check that there is a header image that represents a dentist visit.</action> \
    </actions> \
</journey> \
