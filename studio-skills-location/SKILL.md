---
name: studio-skills-location
description: Reference guide for where Android Studio (Quail 1+ and Rabbit 2+) places, discovers, and manages Agent Mode skills across Global and Project scopes (.android-studio/skills and .agents/skills), how catalog vs. custom skills work, and how to migrate from legacy pre-Quail directories (.skills and .agent/skills).
version: 2.0.0
---

# Skill: Android Studio Skills Location & Management (`studio-skills-location`)

## Overview
Skills let you enhance Android Studio Agent Mode's capabilities with specialized, on-demand expertise and custom workflows based on the **Agent Skills open standard**.

Unlike `AGENTS.md` files (which are always loaded into context), skills represent on-demand expertise:
- When an installed skill is **enabled**, only its `name` and brief `description` are registered in the agent's system prompt.
- The model autonomously decides when to employ an enabled skill based on the user's request and the skill's description, or when explicitly referenced in chat via `@<skill-name>`.
- When activated, the model dynamically pulls in the full `SKILL.md` instructions and supporting resources.

---

## Standard Skill Directories in Android Studio

Android Studio separates skill locations by **Scope** (Global vs. Project) and by **Origin** (Catalog vs. Custom):

| Scope | Catalog Skills Directory | Custom Skills Directory | Precedence & Sharing |
|---|---|---|---|
| **Global** | `~/.android-studio/skills` | `~/.agents/skills` | Available across **all projects** in Android Studio. |
| **Project** | `<project>/.android-studio/skills` | `<project>/.agents/skills` | Available only to the **current project**. Can be committed to version control and shared with your team. |

### Key Directory Rules for Agents & Developers
1. **Plural `.agents/skills` (Not Singular)**: Always use `.agents/skills` (`~/.agents/skills` or `<project>/.agents/skills`) for custom skills.
2. **One Level Deep (`<skills-dir>/<skill-name>/SKILL.md`)**: Android Studio discovers skills located one directory level beneath the skills folder (e.g., `~/.agents/skills/my-skill/SKILL.md` or `<project>/.agents/skills/my-skill/SKILL.md`).
3. **Project Overrides Global**: If a skill with the same name is installed in both Global and Project scopes, the **Project-scoped skill takes precedence** for that project.
4. **Catalog vs. Custom Directories**:
   - **`.android-studio/skills`** is managed by Android Studio's built-in Skills Catalog and the Android CLI (`android skills add`).
   - **`.agents/skills`** is where custom or third-party skills following the Agent Skills open standard should be placed.
   - **Customizing Catalog Skills**: If you customize an official catalog skill, **rename it** (and place it in `.agents/skills`), or it may be overwritten when updating the skill via the Skills Catalog or Android CLI.

---

## Migrating from Legacy (Pre-Quail) Directories

> [!WARNING]
> Prior to **Android Studio Quail 1**, Android Studio loaded skills from non-standard directories:
> - `<project>/.skills` or `~/.skills`
> - `<project>/agent/skills`, `<project>/.agent/skills`, or `~/.agent/skills` (singular)
>
> When working in Android Studio **Quail 1, Rabbit 2 (Canary), or later**, skills placed only in `.skills` or `.agent/skills` will **not** be discovered natively by Android Studio's Agent Mode. Move them to `.agents/skills` or `.android-studio/skills`.

If an agent finds legacy skills in `<project>/.skills/` or `~/.agent/skills/`:
1. Recommend moving or symlinking top-level skills into `<project>/.agents/skills/<skill-name>/` (for Project scope) or `~/.agents/skills/<skill-name>/` (for Global scope).
2. Verify each skill folder contains a valid `SKILL.md` with YAML frontmatter (`name` and `description`).

---

## Managing Skills in Android Studio (Rabbit 2+)

Starting in **Android Studio Rabbit 2 (Canary)**, developers can browse, inspect, install, and manage skills visually via the **Skills Manager** editor tab.

### Opening the Skills Manager
- **Agent tool window**: Click **More Options** (three-dot menu) > **Manage Agent Skills**.
- **Agent chat input**: Type `@` in the chat input box and click **Manage skills** at the top of the completion popup.
- **Settings**: Go to **File** (**Android Studio** on macOS) > **Settings** > **Tools** > **AI** and click **Skills Manager** under **Skills**.
- **Search Everywhere**: Press `Shift` twice and search for **Manage Agent Skills**.

### Official Catalogs & CLI Installation
By default, Android Studio installs and checks background updates for official skill repositories:
- **Android Skills**: Official Android workflows (Jetpack Compose migration, adaptive layouts, edge-to-edge support, AGP upgrades, CameraX, Navigation 3, performance profiling, R8 analysis, testing setup).
- **Firebase Agent Skills**: Official workflows for Firebase Authentication, Cloud Firestore, Crashlytics, Remote Config, Data Connect, and Firebase AI Logic.
- **Android CLI**: Skills can also be installed from the terminal using `android skills add`.

### Activating, Disabling, and Moving Skills
- **Automatic Activation**: Enabled skills activate automatically when the prompt matches the skill's description.
- **Explicit `@` Invocation**: Type `@<skill-name>` (e.g., `@adaptive` or `@edge-to-edge`) in the Agent chat box.
- **Enable / Disable**: Use the toggle in the top-right corner of the skill inspector in the Skills tab. Disabling a skill removes its description from the system prompt to save context window space, while still allowing manual invocation via `@<skill-name>`.
- **Change Scope**: Use the scope dropdown at the top of the skill inspector to move a skill between **Global** and **Project** scope.
- **Add Custom Skills**: Click **Add (+)** at the top of the Installed Skills sidebar to upload a custom skill directory or `SKILL.md`, or write files directly into `<project>/.agents/skills/<skill-name>/SKILL.md` or `~/.agents/skills/<skill-name>/SKILL.md`.
