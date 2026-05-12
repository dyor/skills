#!/usr/bin/env python3
import os
import sys
from pathlib import Path

def find_project_home() -> Path:
    # Try to find the project home by looking for .git or .skills starting from the current directory
    current = Path.cwd().resolve()
    for parent in [current] + list(current.parents):
        if (parent / ".git").exists() or (parent / ".skills").exists():
            return parent
    # Fallback to environment variable or current working directory
    if "PROJECT_HOME" in os.environ:
        return Path(os.environ["PROJECT_HOME"]).resolve()
    return current

def get_user_home() -> Path:
    # Resolve the user home directory
    if "USER_HOME" in os.environ:
        return Path(os.environ["USER_HOME"]).resolve()
    return Path.home().resolve()

def resolve_path(path_str: str) -> str:
    user_home = get_user_home()
    project_home = find_project_home()
    
    # Normalize path separators and expand variables
    resolved = path_str
    
    # Replace $USER_HOME or ${USER_HOME}
    resolved = resolved.replace("$USER_HOME", str(user_home))
    resolved = resolved.replace("${USER_HOME}", str(user_home))
    
    # Replace $PROJECT_HOME or ${PROJECT_HOME}
    resolved = resolved.replace("$PROJECT_HOME", str(project_home))
    resolved = resolved.replace("${PROJECT_HOME}", str(project_home))
    
    # Expand standard environment variables
    resolved = os.path.expandvars(resolved)
    
    # Expand user tilde (~)
    resolved = os.path.expanduser(resolved)
    
    # Return normalized absolute path
    return os.path.normpath(resolved)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 resolve_path.py <path_to_resolve>")
        print("Examples:")
        print("  python3 resolve_path.py '$USER_HOME/.agent/skills/my-skill'")
        print("  python3 resolve_path.py '$USER_HOME/.skills/my-skill'")
        sys.exit(1)
        
    input_path = sys.argv[1]
    print(resolve_path(input_path))

if __name__ == "__main__":
    main()
