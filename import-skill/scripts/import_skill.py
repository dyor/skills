#!/usr/bin/env python3
import sys
import argparse
import os
import shutil
import tempfile
import subprocess
import urllib.request
import urllib.parse
from pathlib import Path

def setup_argparse():
    parser = argparse.ArgumentParser(description="Import a remote skill from a URL")
    parser.add_argument("--url", required=True, help="Target URL (Raw file or GitHub tree)")
    parser.add_argument("--name", help="Optional local directory name")
    return parser.parse_args()

def clean_url(url: str) -> str:
    url = url.strip()
    if url.endswith("/"):
        url = url[:-1]
    if url.endswith(".git"):
        url = url[:-4]
    return url

def download_raw(url: str, dest_dir: Path):
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
    except Exception as e:
        print(f"Error downloading file: {e}")
        sys.exit(1)

def relocate_skill_or_folder(src_path: str, dest_dir: Path):
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
        for item in os.listdir(src_path):
            s = os.path.join(src_path, item)
            if os.path.isdir(s) and os.path.exists(os.path.join(s, "SKILL.md")):
                skills_found = True
                single_dest = dest_dir.parent / item
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

def download_git_sparse(url: str, dest_dir: Path):
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
            
            if sub_path:
                subprocess.run(["git", "sparse-checkout", "set", sub_path], cwd=temp_dir, check=True, capture_output=True)
            
            src_path = os.path.join(temp_dir, sub_path)
            
            if not os.path.exists(src_path):
                print(f"Error: Path '{sub_path}' does not exist in the repository.")
                sys.exit(1)
                
            relocate_skill_or_folder(src_path, dest_dir)
            
        except subprocess.CalledProcessError as e:
            err = e.stderr.decode('utf-8') if e.stderr else "Unknown error"
            print(f"Git command failed. Error: {err}")
            sys.exit(1)

def main():
    args = setup_argparse()
    url = clean_url(args.url)
    
    name = args.name
    if not name:
        parsed = urllib.parse.urlparse(url)
        name = os.path.basename(parsed.path)
        if not name or name in ("SKILL.md", "tree", "raw", "main", "master"):
            name = "imported-skill-unnamed"

    script_dir = Path(__file__).resolve().parent
    dest_dir = script_dir.parent.parent / "imported-skills" / name

    if "raw.githubusercontent.com" in url or "raw=true" in url or "gitlab.com/.../raw" in url:
        download_raw(url, dest_dir)
    elif "github.com" in url:
        if "/blob/" in url:
            url = url.replace("/blob/", "/raw/")
            download_raw(url, dest_dir)
        else:
            download_git_sparse(url, dest_dir)
    else:
        # Fallback raw download
        download_raw(url, dest_dir)

if __name__ == "__main__":
    main()
