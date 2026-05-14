#!/usr/bin/env python3
from __future__ import annotations
import sys
import argparse
import os
import shutil
import tempfile
import subprocess
import urllib.request
import urllib.parse
import urllib.error
import json
import ssl
import datetime
from pathlib import Path

TRACKING_HEADER = (
    "# Imported Skills\n\n"
    "| Name | Destination | URL | Version | Commit | Last Updated |\n"
    "|---|---|---|---|---|---|\n"
)

_REMOTE_CACHE = {"version": {}, "sha": {}}


def setup_argparse():
    parser = argparse.ArgumentParser(description="Import a remote skill from a URL")
    parser.add_argument("--url", required=False, help="Target URL (Raw file or GitHub tree)")
    parser.add_argument("--name", help="Optional local directory name")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing skill if it exists")
    parser.add_argument("--refresh", action="store_true", help="Refresh skills listed in IMPORTED-SKILLS.md")
    parser.add_argument("--check", action="store_true", help="Report drift without modifying anything (use with --refresh)")
    parser.add_argument("--force", action="store_true", help="With --refresh, re-import every skill regardless of detected version/SHA")
    return parser.parse_args()


def clean_url(url: str) -> str:
    if not url:
        return ""
    url = url.strip()
    if url.endswith("/"):
        url = url[:-1]
    if url.endswith(".git"):
        url = url[:-4]
    return url


def _ssl_ctx():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def _http_get(url: str, accept: str = None) -> bytes:
    headers = {"User-Agent": "import-skill/1.0"}
    if accept:
        headers["Accept"] = accept
    token = os.environ.get("GITHUB_TOKEN")
    if token and "api.github.com" in url:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, context=_ssl_ctx()) as resp:
        return resp.read()


def parse_frontmatter(text: str) -> dict:
    if not text.startswith("---"):
        return {}
    end_idx = text.find("\n---", 3)
    if end_idx == -1:
        return {}
    block = text[3:end_idx].strip()
    fm = {}
    for raw_line in block.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or ":" not in line:
            continue
        key, _, value = line.partition(":")
        fm[key.strip()] = value.strip().strip('"').strip("'")
    return fm


def read_local_frontmatter(dest_dir: Path) -> dict:
    candidate = dest_dir / "SKILL.md"
    if not candidate.exists():
        # Fall back to the first SKILL.md in the tree.
        for root, _, files in os.walk(dest_dir):
            if "SKILL.md" in files:
                candidate = Path(root) / "SKILL.md"
                break
    if not candidate.exists():
        return {}
    try:
        return parse_frontmatter(candidate.read_text("utf-8"))
    except Exception:
        return {}


def _raw_url_for_skill_md(url: str) -> str | None:
    """Return a raw URL pointing at the SKILL.md for this import URL, if we can."""
    if "raw.githubusercontent.com" in url:
        if url.endswith("SKILL.md"):
            return url
        return None
    if "github.com" not in url:
        return None
    parsed = urllib.parse.urlparse(url)
    parts = [p for p in parsed.path.strip("/").split("/") if p]
    if len(parts) < 2:
        return None
    owner, repo = parts[0], parts[1]
    branch = "main"
    sub_path = ""
    if len(parts) >= 4 and parts[2] in ("tree", "blob"):
        branch = parts[3]
        sub_path = "/".join(parts[4:])
    elif len(parts) > 2:
        sub_path = "/".join(parts[2:])
    sub_path = sub_path.rstrip("/")
    if sub_path.endswith("SKILL.md"):
        suffix = f"/{sub_path}"
    else:
        suffix = f"/{sub_path}/SKILL.md" if sub_path else "/SKILL.md"
    return f"https://raw.githubusercontent.com/{owner}/{repo}/{branch}{suffix}"


def fetch_remote_version(url: str) -> str | None:
    if url in _REMOTE_CACHE["version"]:
        return _REMOTE_CACHE["version"][url]
    raw = _raw_url_for_skill_md(url)
    version = None
    if raw:
        try:
            body = _http_get(raw).decode("utf-8", errors="replace")
            fm = parse_frontmatter(body)
            version = fm.get("version")
        except (urllib.error.URLError, urllib.error.HTTPError, ValueError):
            version = None
    _REMOTE_CACHE["version"][url] = version
    return version


def fetch_remote_sha(url: str) -> str | None:
    """Best-effort latest-commit SHA for a github.com URL."""
    if url in _REMOTE_CACHE["sha"]:
        return _REMOTE_CACHE["sha"][url]

    sha = None
    if "raw.githubusercontent.com" in url:
        parts = url.split("/")
        if len(parts) > 5 and len(parts[5]) == 40:
            sha = parts[5]
    elif "github.com" in url:
        parsed = urllib.parse.urlparse(url)
        parts = [p for p in parsed.path.strip("/").split("/") if p]
        if len(parts) >= 2:
            owner, repo = parts[0], parts[1]
            branch = "main"
            sub_path = ""
            if len(parts) >= 4 and parts[2] in ("tree", "blob"):
                branch = parts[3]
                sub_path = "/".join(parts[4:])
            elif len(parts) > 2:
                sub_path = "/".join(parts[2:])
            api = f"https://api.github.com/repos/{owner}/{repo}/commits"
            params = f"?sha={urllib.parse.quote(branch)}&per_page=1"
            if sub_path:
                params += f"&path={urllib.parse.quote(sub_path)}"
            try:
                body = _http_get(api + params, accept="application/vnd.github+json")
                data = json.loads(body)
                if isinstance(data, list) and data:
                    sha = data[0].get("sha")
            except (urllib.error.URLError, urllib.error.HTTPError, ValueError, json.JSONDecodeError):
                sha = None

    _REMOTE_CACHE["sha"][url] = sha
    return sha


def decide_update(name: str, url: str, dest_dir: Path, force: bool) -> tuple[str, str]:
    """Return (action, reason). action in {"update", "skip", "force"}."""
    if force:
        return ("force", "force flag")
    if not dest_dir.exists() or not any(dest_dir.iterdir()):
        return ("update", "missing locally")

    local_fm = read_local_frontmatter(dest_dir)
    local_version = local_fm.get("version")
    local_commit = local_fm.get("import_commit")

    remote_version = fetch_remote_version(url)
    if local_version and remote_version:
        if local_version == remote_version:
            return ("skip", f"up-to-date (v{local_version})")
        return ("update", f"v{local_version} -> v{remote_version}")

    remote_sha = fetch_remote_sha(url)
    if local_commit and remote_sha:
        if local_commit == remote_sha:
            return ("skip", f"up-to-date (sha {local_commit[:7]}, no version)")
        return ("update", f"sha {local_commit[:7]} -> {remote_sha[:7]} (no version)")

    return ("force", "no version or SHA available; forcing re-import")


def _parse_tracking_row(line: str) -> dict | None:
    if not line.startswith("|") or "---" in line:
        return None
    parts = [p.strip() for p in line.split("|")]
    cells = [c for c in parts if c != ""] if parts and parts[0] == "" else parts
    if not cells or cells[0].lower() in ("name",):
        return None
    if len(cells) >= 6:
        return {"name": cells[0], "dest": cells[1], "url": cells[2], "version": cells[3], "commit": cells[4], "updated": cells[5]}
    if len(cells) == 5:
        return {"name": cells[0], "dest": cells[1], "url": cells[2], "version": "", "commit": cells[3], "updated": cells[4]}
    return None


def update_tracking_file(base_skills_dir: Path, name: str, dest_dir: Path, url: str, commit: str, version: str | None):
    md_file = base_skills_dir / "IMPORTED-SKILLS.md"
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    try:
        rel_dest = dest_dir.relative_to(base_skills_dir).as_posix()
    except ValueError:
        rel_dest = dest_dir.as_posix()

    version_cell = version or "-"
    row = f"| {name} | `{rel_dest}` | {url} | {version_cell} | {commit} | {now} |"

    if not md_file.exists():
        md_file.write_text(TRACKING_HEADER + row + "\n")
        return

    content = md_file.read_text()
    # If we detect a legacy 5-column file, rebuild the header and rewrite rows in the new 6-column shape.
    legacy = "| Commit / Version |" in content or "| Name | Destination | URL | Commit / Version |" in content
    lines = content.splitlines()

    if legacy:
        existing_rows = []
        for line in lines:
            parsed = _parse_tracking_row(line)
            if parsed and parsed["name"] != name:
                existing_rows.append(parsed)
        out = [TRACKING_HEADER.rstrip()]
        for r in existing_rows:
            out.append(f"| {r['name']} | {r['dest']} | {r['url']} | {r['version'] or '-'} | {r['commit']} | {r['updated']} |")
        out.append(row)
        md_file.write_text("\n".join(out) + "\n")
        return

    new_lines = []
    found = False
    for line in lines:
        parsed = _parse_tracking_row(line)
        if parsed and parsed["name"] == name:
            new_lines.append(row)
            found = True
        else:
            new_lines.append(line)
    if not found:
        new_lines.append(row)
    md_file.write_text("\n".join(new_lines) + "\n")


def inject_frontmatter(dest_dir: Path, commit: str, url: str):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for root, _, files in os.walk(dest_dir):
        for file in files:
            if file != "SKILL.md":
                continue
            file_path = Path(root) / file
            content = file_path.read_text("utf-8")
            if not content.startswith("---"):
                continue
            end_idx = content.find("---", 3)
            if end_idx == -1:
                continue
            frontmatter = content[3:end_idx]
            rest = content[end_idx + 3:]

            lines = frontmatter.strip().split("\n")
            # Preserve everything except the three import_* fields we own.
            new_lines = [
                line for line in lines
                if not line.startswith("import_commit:")
                and not line.startswith("import_date:")
                and not line.startswith("import_url:")
            ]
            new_lines.append(f"import_commit: {commit}")
            new_lines.append(f"import_date: {now}")
            new_lines.append(f"import_url: {url}")

            new_content = "---\n" + "\n".join(new_lines) + "\n---" + rest
            file_path.write_text(new_content, "utf-8")


def check_overwrite(dest_dir: Path, overwrite: bool):
    if dest_dir.exists() and any(dest_dir.iterdir()):
        if not overwrite:
            print(f"ALREADY_EXISTS: {dest_dir}")
            print("The skill already exists locally. Agent should prompt the user to either run with --overwrite to replace it, or abort/merge manually.")
            sys.exit(2)
        print(f"Overwriting existing local directory: {dest_dir}")
        shutil.rmtree(dest_dir)


def download_raw(url: str, dest_dir: Path, name: str, base_skills_dir: Path, overwrite: bool):
    check_overwrite(dest_dir, overwrite)
    print(f"Downloading raw file from {url}...")
    dest_dir.mkdir(parents=True, exist_ok=True)

    parsed = urllib.parse.urlparse(url)
    filename = os.path.basename(parsed.path) or "SKILL.md"
    dest_file = dest_dir / filename
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, context=_ssl_ctx()) as response, open(dest_file, "wb") as out_file:
            shutil.copyfileobj(response, out_file)
        print(f"Successfully saved to {dest_file}")

        commit = "raw"
        if "raw.githubusercontent.com" in url:
            parts = url.split("/")
            if len(parts) > 5 and len(parts[5]) == 40:
                commit = parts[5]

        fm = read_local_frontmatter(dest_dir)
        version = fm.get("version")

        update_tracking_file(base_skills_dir, name, dest_dir, url, commit, version)
        inject_frontmatter(dest_dir, commit, url)
    except Exception as e:
        print(f"Error downloading file: {e}")
        sys.exit(1)


def relocate_skill_or_folder(src_path: str, dest_dir: Path, is_planning_skill: bool = False):
    if os.path.exists(os.path.join(src_path, "SKILL.md")):
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
        skills_found = False
        target_dir = dest_dir if is_planning_skill else dest_dir.parent
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
            elif os.path.isfile(s) and item.lower() == "readme.md" and is_planning_skill:
                shutil.copy2(s, target_dir / item)
                print(f"Successfully imported README.md to {target_dir / item}")

        if not skills_found:
            print(f"Error: No SKILL.md found directly in {src_path} or any of its immediate subdirectories.")
            sys.exit(1)


def download_git_sparse(url: str, dest_dir: Path, name: str, base_skills_dir: Path, overwrite: bool, is_planning_skill: bool = False):
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

            relocate_skill_or_folder(src_path, dest_dir, is_planning_skill)

            fm = read_local_frontmatter(dest_dir)
            version = fm.get("version")

            update_tracking_file(base_skills_dir, name, dest_dir, url, commit_hash, version)
            inject_frontmatter(dest_dir, commit_hash, url)

        except subprocess.CalledProcessError as e:
            err = e.stderr.decode("utf-8") if e.stderr else "Unknown error"
            print(f"Git command failed. Error: {err}")
            sys.exit(1)


def _resolve_dest_dir(url: str, base_skills_dir: Path, given_name: str) -> tuple[Path, str, bool]:
    parsed = urllib.parse.urlparse(url)
    path_parts = [p for p in parsed.path.strip("/").split("/") if p]
    is_planning_skill = False
    planning_index = -1
    if "planning-skills" in path_parts:
        planning_index = path_parts.index("planning-skills")
        if planning_index + 1 < len(path_parts):
            is_planning_skill = True

    if is_planning_skill:
        rel_path = "/".join(path_parts[planning_index + 1:])
        dest_dir = base_skills_dir / "planning-skills" / rel_path
        name = path_parts[-1]
    else:
        name = given_name
        if not name:
            name = path_parts[-1] if path_parts else "imported-skill-unnamed"
            if not name or name in ("SKILL.md", "tree", "raw", "main", "master"):
                name = "imported-skill-unnamed"
        dest_dir = base_skills_dir / "imported-skills" / name
    return dest_dir, name, is_planning_skill


def refresh_skills(base_skills_dir: Path, check_only: bool, force: bool):
    md_file = base_skills_dir / "IMPORTED-SKILLS.md"
    if not md_file.exists():
        print("No IMPORTED-SKILLS.md found. Nothing to refresh.")
        return

    rows = []
    for line in md_file.read_text().splitlines():
        parsed = _parse_tracking_row(line)
        if parsed:
            rows.append(parsed)

    if not rows:
        print("No tracked skills found.")
        return

    print(f"Found {len(rows)} skill(s) to evaluate.")
    skipped, updated, forced = [], [], []

    for row in rows:
        name = row["name"]
        url = row["url"]
        dest_dir, resolved_name, _ = _resolve_dest_dir(url, base_skills_dir, name)
        # Prefer the tracking row's name for consistency.
        resolved_name = name or resolved_name

        action, reason = decide_update(resolved_name, url, dest_dir, force)
        status_label = {"skip": "SKIP   ", "update": "UPDATE ", "force": "FORCE  "}[action]
        print(f"  [{status_label}] {resolved_name}: {reason}")

        if action == "skip":
            skipped.append(resolved_name)
            continue

        if check_only:
            (updated if action == "update" else forced).append(resolved_name)
            continue

        print(f"\n--- Refreshing {resolved_name} ---")
        run_import(url, base_skills_dir, resolved_name, overwrite=True)
        (updated if action == "update" else forced).append(resolved_name)

    print(
        f"\nSummary: {len(skipped)} up-to-date, {len(updated)} updated, {len(forced)} forced "
        f"({'check-only — no files changed' if check_only else 'changes written'})."
    )


def run_import(url: str, base_skills_dir: Path, given_name: str, overwrite: bool):
    dest_dir, name, is_planning_skill = _resolve_dest_dir(url, base_skills_dir, given_name)

    if "raw.githubusercontent.com" in url or "raw=true" in url or "gitlab.com/.../raw" in url:
        download_raw(url, dest_dir, name, base_skills_dir, overwrite)
    elif "github.com" in url:
        if "/blob/" in url:
            url = url.replace("/blob/", "/raw/")
            download_raw(url, dest_dir, name, base_skills_dir, overwrite)
        else:
            download_git_sparse(url, dest_dir, name, base_skills_dir, overwrite, is_planning_skill)
    else:
        download_raw(url, dest_dir, name, base_skills_dir, overwrite)

    if is_planning_skill:
        readme_path = dest_dir / "README.md"
        if not readme_path.exists():
            curr = dest_dir.parent
            while curr and curr != base_skills_dir / "planning-skills" and curr != base_skills_dir:
                if (curr / "README.md").exists():
                    readme_path = curr / "README.md"
                    break
                curr = curr.parent

        if readme_path.exists():
            print("\n[IMPORTANT FOR AGENT] This is a planning-skill. You MUST read the README.md file located at:")
            try:
                rel_readme = readme_path.relative_to(base_skills_dir).as_posix()
                print(f"  .skills/{rel_readme}")
            except ValueError:
                print(f"  {readme_path.as_posix()}")
            print("immediately to understand how to initialize and execute this planning skill. Do not attempt to run any blueprints or guides before reading the README.md first.")


def main():
    args = setup_argparse()
    script_dir = Path(__file__).resolve().parent
    base_skills_dir = script_dir.parent.parent

    if args.refresh:
        refresh_skills(base_skills_dir, check_only=args.check, force=args.force)
        return

    if args.check:
        print("Error: --check must be used with --refresh.")
        sys.exit(1)

    if not args.url:
        print("Error: --url is required unless --refresh is used.")
        sys.exit(1)

    url = clean_url(args.url)
    run_import(url, base_skills_dir, args.name, args.overwrite)


if __name__ == "__main__":
    main()
