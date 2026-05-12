---
name: multi-project-skill
description: Central utility skill to resolve environment paths ($USER_HOME, $PROJECT_HOME) and share agentic capabilities across multiple local Android Studio projects.
version: 1.0.0
---

# Skill: Multi-Project Skill Utility

## Overview
When working across multiple Android Studio projects, maintaining duplicate `.skills/` folders can lead to configuration drift. This utility skill is designed to:
1. **Establish Standard Locations**: Define and enforce project-specific and multi-project skill folders compatible with Android Studio workspaces.
2. **Path Translation & Resolution**: Provide native commands and script protocols to instantly resolve dynamic variable placeholders (`$USER_HOME`, `$PROJECT_HOME`) to absolute system paths.

---

## Standard Directory Conventions
For Android Studio development environments, the following directories are supported:

| Scope | Path Convention | Example Target Location |
|---|---|---|
| **Project-Specific Skills** | `$PROJECT_HOME/.skills/` | `/Users/mattdyor/projects/MyAndroidApp/.skills/` |
| **Multi-Project (Shared) Skills** | `$USER_HOME/.agent/skills` or `$USER_HOME/.skills` | `/Users/mattdyor/.agent/skills` or `/Users/mattdyor/.skills` |

---

## Path Translation Protocols

When an AI agent or script needs to locate assets or code in these directories, use one of the following methods to translate the placeholders to actual absolute system paths.

### Method A: Executing the Python Path Resolver Script
The skill includes a dedicated Python utility to dynamically expand these variables. Run the following command in your terminal:

```bash
python3 $USER_HOME/.skills/multi-project-skill/scripts/resolve_path.py "<path_to_resolve>"
```

**Examples:**
* Resolve the central multi-project skills directory (option 1):
  ```bash
  python3 $USER_HOME/.skills/multi-project-skill/scripts/resolve_path.py '$USER_HOME/.agent/skills'
  # Output: /Users/mattdyor/.agent/skills
  ```
* Resolve the central multi-project skills directory (option 2):
  ```bash
  python3 $USER_HOME/.skills/multi-project-skill/scripts/resolve_path.py '$USER_HOME/.skills'
  # Output: /Users/mattdyor/.skills
  ```
* Resolve project home dynamically:
  ```bash
  python3 $USER_HOME/.skills/multi-project-skill/scripts/resolve_path.py '$PROJECT_HOME'
  # Output: /Users/mattdyor/projects/MyAndroidApp
  ```

---

### Method B: Inline Shell Terminal Commands
If you are running quick bash/zsh commands, you can directly perform translations using shell expansion or inline `sed` pattern replacements:

#### 1. Switching `$USER_HOME` to the User's Home Directory Path
To evaluate and output the absolute path for `$USER_HOME` (e.g., translating to `/Users/mattdyor`):
```bash
# Standard expansion using zsh/bash environment variables
echo "$USER_HOME" | sed "s|\$USER_HOME|$HOME|g"
```

#### 2. Dynamically Finding and Replacing `$PROJECT_HOME`
To resolve the project home by locating the nearest directory enclosing a git repository or skills directory:
```bash
# Find closest parent containing a .git folder and assign it to PROJECT_HOME
export PROJECT_HOME=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
echo "Project home is: $PROJECT_HOME"
```

---

## Execution Protocol for AI Agents
When this skill is active in a workspace, the agent must:
1. Check if `$USER_HOME/.skills/multi-project-skill` is present.
2. When paths with `$USER_HOME` or `$PROJECT_HOME` are referenced in prompts or instructions, automatically run the resolver utility (`resolve_path.py`) or inline shell commands to locate files accurately before calling file read/write tools.
