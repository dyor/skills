#!/usr/bin/env python3
import sys
import argparse
import os
import shutil
import tempfile
import subprocess
import urllib.request
import urllib.parse
import datetime
from pathlib import Path

def setup_argparse():
    parser = argparse.ArgumentParser(description="Import a remote skill from a URL")
    parser.add_argument("--url", required=False, help="Target URL (Raw file or GitHub tree)")
    parser.add_argument("--name", help="Optional local directory name")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing skill if it exists")
    parser.add_argument("--refresh", action="store_true", help="Refresh all skills from IMPORTED-SKILLS.md")
    return parser.parse_args()

def clean_url(url: str) -> str:
    if not url: return ""
    url = url.strip()
    if url.endswith("/"):
        url = url[:-1]
    if url.endswith(".git"):
        url = url[:-4]
    return url

def update_tracking_file(base_skills_dir: Path, name: str, dest_dir: Path, url: str, commit: str):
    md_file = base_skills_dir / "IMPORTED-SKILLS.md"
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    header = "# Imported Skills\n\n| Name | Destination | URL | Commit / Version | Last Updated |\n|---|---|---|---|---|\n"

    try:
        rel_dest = dest_dir.relative_to(base_skills_dir).as_posix()
    except ValueError:
        rel_dest = dest_dir.as_posix()

    if not md_file.exists():
        md_file.write_text(header)

    content = md_file.read_text()
    lines = content.splitlines()

    new_lines = []
    found = False
    for line in lines:
        if line.startswith("|") and f"| {name} |" in line:
            new_lines.append(f"| {name} | `{rel_dest}` | {url} | {commit} | {now} |")
            found = True
        else:
            new_lines.append(line)

    if not found:
        if new_lines and not new_lines[-1].strip() == "":
            pass
        new_lines.append(f"| {name} | `{rel_dest}` | {url} | {commit} | {now} |")

    md_file.write_text("\n".join(new_lines) + "\n")

def inject_frontmatter(dest_dir: Path, commit: str, url: str):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for root, _, files in os.walk(dest_dir):
        for file in files:
            if file == "SKILL.md":
                file_path = Path(root) / file
                content = file_path.read_text('utf-8')
                if content.startswith("---"):
                    end_idx = content.find("---", 3)
                    if end_idx != -1:
                        frontmatter = content[3:end_idx]
                        rest = content[end_idx+3:]

                        lines = frontmatter.strip().split('\n')
                        new_lines = [line for line in lines if not line.startswith("import_commit:") and not line.startswith("import_date:") and not line.startswith("import_url:")]

                        new_lines.append(f"import_commit: {commit}")
                        new_lines.append(f"import_date: {now}")
                        new_lines.append(f"import_url: {url}")

                        new_content = "---\n" + "\n".join(new_lines) + "\n---" + rest
                        file_path.write_text(new_content, 'utf-8')

def check_overwrite(dest_dir: Path, overwrite: bool):
    if dest_dir.exists() and any(dest_dir.iterdir()):
        if not overwrite:
            print(f"ALREADY_EXISTS: {dest_dir}")
            print("The skill already exists locally. Agent should prompt the user to either run with --overwrite to replace it, or abort/merge manually.")
            sys.exit(2)
        else:
            print(f"Overwriting existing local directory: {dest_dir}")
            shutil.rmtree(dest_dir)

def download_raw(url: str, dest_dir: Path, name: str, base_skills_dir: Path, overwrite: bool):
    check_overwrite(dest_dir, overwrite)
    print(f"Downloading raw file from {url}...")
    dest_dir.mkdir(parents=True, exist_ok=True)

    parsed = urllib.parse.urlparse(url)
    filename = os.path.basename(parsed.path)
    if not filename:
        filename = "SKILL.md"

    dest_file = dest_dir / filename
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open(dest_file, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)
        print(f"Successfully saved to {dest_file}")

        # for raw files, try to parse commit hash from url or fallback to "raw"
        commit = "raw"
        if "raw.githubusercontent.com" in url:
            parts = url.split("/")
            if len(parts) > 5:
                # https://raw.githubusercontent.com/owner/repo/commit/...
                commit_candidate = parts[5]
                if len(commit_candidate) == 40: # looks like git SHA
                    commit = commit_candidate

        update_tracking_file(base_skills_dir, name, dest_dir, url, commit)
        inject_frontmatter(dest_dir, commit, url)
    except Exception as e:
        print(f"Error downloading file: {e}")
        sys.exit(1)

def relocate_skill_or_folder(src_path: str, dest_dir: Path, is_task_bundle: bool = False):
    if os.path.exists(os.path.join(src_path, "SKILL.md")):
        # Single skill mode
        dest_dir.mkdir(parents=True, exist_ok=True)
        if os.path.isdir(src_path):
            for item in os.listdir(src_path):
                s = os.path.join(src_path, item)
                d = os.path.join(dest_dir, item)
                if os.path.isdir(s):
                    shutil.copytree(s, d, dirs_exist_ok=True)
                else:
                    shutil.copy2(s, d)
        print(f"Successfully imported single skill to {dest_dir}")
    else:
        # Multi-skill mode (collection folder)
        skills_found = False
        target_dir = dest_dir if is_task_bundle else dest_dir.parent
        target_dir.mkdir(parents=True, exist_ok=True)

        for item in os.listdir(src_path):
            s = os.path.join(src_path, item)
            if os.path.isdir(s) and os.path.exists(os.path.join(s, "SKILL.md")):
                skills_found = True
                single_dest = target_dir / item
                single_dest.mkdir(parents=True, exist_ok=True)
                for subitem in os.listdir(s):
                    ss = os.path.join(s, subitem)
                    dd = os.path.join(single_dest, subitem)
                    if os.path.isdir(ss):
                        shutil.copytree(ss, dd, dirs_exist_ok=True)
                    else:
                        shutil.copy2(ss, dd)
                print(f"Successfully imported skill from collection into {single_dest}")

        if not skills_found:
            print(f"Error: No SKILL.md found directly in {src_path} or any of its immediate subdirectories.")
            sys.exit(1)

def download_git_sparse(url: str, dest_dir: Path, name: str, base_skills_dir: Path, overwrite: bool, is_task_bundle: bool = False):
    check_overwrite(dest_dir, overwrite)
    parsed = urllib.parse.urlparse(url)
    parts = [p for p in parsed.path.strip("/").split("/") if p]

    if len(parts) < 2:
        print("Error: Invalid GitHub URL structure.")
        sys.exit(1)

    owner = parts[0]
    repo = parts[1]
    repo_url = f"https://github.com/{owner}/{repo}.git"

    branch = None
    sub_path = ""

    if len(parts) >= 4 and parts[2] == "tree":
        branch = parts[3]
        sub_path = "/".join(parts[4:])
    elif len(parts) > 2:
        sub_path = "/".join(parts[2:])

    print(f"Cloning {repo_url} (branch: {branch if branch else 'default'}, path: '{sub_path}')...")

    with tempfile.TemporaryDirectory() as temp_dir:
        try:
            cmd = ["git", "clone", "--depth", "1", "--filter=blob:none", "--sparse"]
            if branch:
                cmd.extend(["-b", branch])
            cmd.extend([repo_url, temp_dir])

            subprocess.run(cmd, check=True, capture_output=True)

            commit_hash = "unknown"
            try:
                res = subprocess.run(["git", "rev-parse", "HEAD"], cwd=temp_dir, check=True, capture_output=True, text=True)
                commit_hash = res.stdout.strip()
            except Exception:
                pass

            if sub_path:
                subprocess.run(["git", "sparse-checkout", "set", sub_path], cwd=temp_dir, check=True, capture_output=True)

            src_path = os.path.join(temp_dir, sub_path)

            if not os.path.exists(src_path):
                print(f"Error: Path '{sub_path}' does not exist in the repository.")
                sys.exit(1)

            relocate_skill_or_folder(src_path, dest_dir, is_task_bundle)
            update_tracking_file(base_skills_dir, name, dest_dir, url, commit_hash)
            inject_frontmatter(dest_dir, commit_hash, url)

        except subprocess.CalledProcessError as e:
            err = e.stderr.decode('utf-8') if e.stderr else "Unknown error"
            print(f"Git command failed. Error: {err}")
            sys.exit(1)

def refresh_skills(base_skills_dir: Path):
    md_file = base_skills_dir / "IMPORTED-SKILLS.md"
    if not md_file.exists():
        print("No IMPORTED-SKILLS.md found. Nothing to refresh.")
        return

    content = md_file.read_text()
    lines = content.splitlines()

    urls_to_refresh = []

    for line in lines:
        if line.startswith("|") and not "URL" in line and not "---" in line:
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 5:
                # Handle parts array appropriately (it has empty elements for bounds | |)
                if len(parts) > 3:
                    name = parts[1]
                    url = parts[3]
                    urls_to_refresh.append((name, url))

    if not urls_to_refresh:
        print("No tracked skills found.")
        return

    print(f"Found {len(urls_to_refresh)} skill(s) to refresh.")
    for name, url in urls_to_refresh:
        print(f"\n--- Refreshing {name} ---")
        run_import(url, base_skills_dir, name, overwrite=True)

def run_import(url: str, base_skills_dir: Path, given_name: str, overwrite: bool):
    parsed = urllib.parse.urlparse(url)
    path_parts = [p for p in parsed.path.strip("/").split("/") if p]
    is_task_bundle = False
    bundle_name = ""

    if "tasks" in path_parts:
        tasks_index = path_parts.index("tasks")
        if tasks_index + 1 < len(path_parts):
            is_task_bundle = True
            bundle_name = path_parts[tasks_index + 1]

    if is_task_bundle:
        dest_dir = base_skills_dir / "tasks" / bundle_name
        name = bundle_name
    else:
        name = given_name
        if not name:
            name = path_parts[-1] if path_parts else "imported-skill-unnamed"
            if not name or name in ("SKILL.md", "tree", "raw", "main", "master"):
                name = "imported-skill-unnamed"
        dest_dir = base_skills_dir / "imported-skills" / name

    if "raw.githubusercontent.com" in url or "raw=true" in url or "gitlab.com/.../raw" in url:
        download_raw(url, dest_dir, name, base_skills_dir, overwrite)
    elif "github.com" in url:
        if "/blob/" in url:
            url = url.replace("/blob/", "/raw/")
            download_raw(url, dest_dir, name, base_skills_dir, overwrite)
        else:
            download_git_sparse(url, dest_dir, name, base_skills_dir, overwrite, is_task_bundle)
    else:
        download_raw(url, dest_dir, name, base_skills_dir, overwrite)


def main():
    args = setup_argparse()
    script_dir = Path(__file__).resolve().parent
    base_skills_dir = script_dir.parent.parent

    if args.refresh:
        refresh_skills(base_skills_dir)
        return

    if not args.url:
        print("Error: --url is required unless --refresh is used.")
        sys.exit(1)

    url = clean_url(args.url)
    run_import(url, base_skills_dir, args.name, args.overwrite)

if __name__ == "__main__":
    main()