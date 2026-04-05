---
name: run-journeys
description: Automates running Journey tests and subsequently extracting their results into the persistent .changereview folder.
---

# `run-journeys` Skill

When a user asks to run a journey (e.g., "run the writers room journey"), follow these steps:

## Step 1: Run the Journey Test
1. Determine the journey file name (e.g., `1_writers_room.journey.xml`). You can omit the `.journey.xml` extension when determining the `<journey_name>` base.
2. Execute the Gradle command to run the specific journey:
   `run_shell_command("JOURNEYS_FILTER=<journey_name>.journey.xml ./gradlew :androidApp:testJourneysTestDefaultDebugTestSuite")`
   *(Note: Adjust `:androidApp:` if the target module is different).*

## Step 2: Extract Results
1. Wait for the build/test run to complete.
2. Once finished, activate the `changereview-from-journey` skill to extract the results for the `<journey_name>` you just ran. Follow its instructions exactly to create the markdown report and images.
