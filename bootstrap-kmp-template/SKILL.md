---
name: bootstrap-kmp-template
description: Bootstraps a new KMP project by cloning a specified GitHub template repository into a new directory, seeding it with core AI skills, stripping its git history, and initializing a fresh workspace.
version: 1.0.0
---

# Skill: Bootstrap KMP Template

## Overview
This skill automates the creation of a new Kotlin Multiplatform (KMP) project from a "Host" Android Studio window. It will download a remote GitHub template, place it in a new folder (handling name collisions automatically), seed the new folder with core AI skills from the host project, and initialize a fresh Git repository. 

## Execution Protocol

When the user asks you to "create a new KMP project", "apply a KMP template", or invokes this skill directly, follow these steps sequentially:

### 1. Gather Requirements
Determine the following three variables from the user's prompt, or ask the user for them if they are missing:
1.  **Template URL**: The GitHub URL of the template (e.g., `https://github.com/Kotlin/KMP-App-Template`). Check the `dyor-knowledge-base` or prompt the user if unspecified.
2.  **Project Name**: The desired name of the project (e.g., `MyAwesomeApp`).
3.  **Base Directory**: The location on the user's disk where the new project folder should be created. If the user does not specify one, default to their home directory (`~` or `/Users/<username>`).

### 2. Execute the Clone, Cleanup, and Seed Scripts
Once you have the variables, use the `run_shell_command` tool to execute the following Bash script. Replace the placeholders `<URL>`, `<PROJECT_NAME>`, `<BASE_DIR>`, and `<CURRENT_PROJECT_DIR>` with the actual values.

*(Note: `<CURRENT_PROJECT_DIR>` should be the absolute path to the root of the project you are currently running in, so you can copy `.skills` from it).*

```bash
# Variables
TEMPLATE_URL="<URL>"
PROJECT_NAME="<PROJECT_NAME>"
BASE_DIR="<BASE_DIR>"
HOST_SKILLS_DIR="<CURRENT_PROJECT_DIR>/.skills"

# 1. Resolve Target Directory with Incrementing
TARGET_DIR="$BASE_DIR/$PROJECT_NAME"
COUNTER=1
while [ -d "$TARGET_DIR" ]; do
  TARGET_DIR="$BASE_DIR/${PROJECT_NAME}-${COUNTER}"
  COUNTER=$((COUNTER + 1))
done

echo "Creating new project in: $TARGET_DIR"

# 2. Clone the template
git clone --depth 1 "$TEMPLATE_URL" "$TARGET_DIR"

# 3. Seed Skills from the Host Project
mkdir -p "$TARGET_DIR/.skills"

if [ -d "$HOST_SKILLS_DIR/import-skill" ]; then
  echo "Seeding import-skill..."
  cp -R "$HOST_SKILLS_DIR/import-skill" "$TARGET_DIR/.skills/"
fi

if [ -d "$HOST_SKILLS_DIR/imported-skills/dyor-knowledge-base" ]; then
  echo "Seeding dyor-knowledge-base..."
  mkdir -p "$TARGET_DIR/.skills/imported-skills"
  cp -R "$HOST_SKILLS_DIR/imported-skills/dyor-knowledge-base" "$TARGET_DIR/.skills/imported-skills/"
  
  # Also copy the tracking file so the new project knows it's imported
  if [ -f "$HOST_SKILLS_DIR/IMPORTED-SKILLS.md" ]; then
    cp "$HOST_SKILLS_DIR/IMPORTED-SKILLS.md" "$TARGET_DIR/.skills/"
  fi
fi

# 4. Cleanup and re-init git
cd "$TARGET_DIR"
rm -rf .git
git init
git add .
git commit -m "Initial commit from KMP template: $TEMPLATE_URL"

# Output the final path so the Agent can use it in the next step
echo "SUCCESS_TARGET_DIR=$TARGET_DIR"
```

### 3. Post-Bootstrap Adjustments
1.  **Parse the Output**: Look for `SUCCESS_TARGET_DIR=` in the shell output to find the exact absolute path of the newly created directory.
2.  **Update settings.gradle.kts**: Use the `replace_file_content` tool on `<SUCCESS_TARGET_DIR>/settings.gradle.kts` to update the `rootProject.name` to the user's chosen `<PROJECT_NAME>`. *(Note: Be sure to use the absolute path to the newly created folder, not the host project).*

### 4. Handoff
Do **NOT** run `gradle_sync`, as the new project is external to your current Android Studio workspace.

Instead, inform the user that the project has been successfully bootstrapped, seeded with their skills, and is ready for development. Provide the exact path and instruct them to open it in a new window:

*"Your new project has been created and seeded with your core skills! You now need to open this folder in Android Studio:"*
`[Provide the exact path to the new directory]`
