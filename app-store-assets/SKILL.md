---
name: app-store-assets
description: Refresh an app's store and website assets from one set of phone screenshots. Use when the user says "update screenshots", "update_screenshots", "refresh store screenshots", "new App Store / Play screenshots", or asks to update store listing text or the app website's screenshots. Produces captioned App Store and Google Play screenshots, checks listing text against store limits, and updates the website's screenshot gallery and copy. App-specific settings live in the app repo (distribution/assets.md), never in this skill.
version: 1.0.0
---

# Skill: App Store Assets

## Overview

One shot list drives three destinations:

| Destination | What it gets | Written by |
|---|---|---|
| App Store | Captioned screenshots at each size in `outputs` | `scripts/assets.py compose` |
| Google Play | Same, at Play's sizes | `scripts/assets.py compose` |
| App website | Raw screens (no baked-in caption), plus title and caption from the shot list | `scripts/assets.py web`, then the website provider |

Store listing text and website copy are reviewed against the new screenshots by you,
the agent, and changed only with the user's approval.

This skill is a **template**. It contains no app's paths, captions, colours or hosts.
Those live in the app repo's config file. When the user asks to change *this skill*,
change the template for every app; when they want something different for one app,
change that app's config.

## The app config

Look for the config in this order:
1. A path named in the app's `AGENTS.md` (or `CLAUDE.md`/`GEMINI.md`), e.g. "App store
   assets: see `distribution/assets.md`".
2. `distribution/assets.md`.

If there is none, **bootstrap** it:
1. Copy `templates/assets.md` from this skill to `distribution/assets.md` in the app repo.
2. Fill it in from the repo: find the fastlane metadata folders (`*/appstore_metadata`,
   `*/playstore_metadata`), existing screenshots and their sizes, any existing screenshot
   script (port its captions and colours into `shots` and `style`), and the website.
3. Add one line to the app's `AGENTS.md` (create it if missing):
   `App store assets (screenshots, listing text, website gallery): see distribution/assets.md.`
4. Show the user the filled-in config and confirm before the first run.

The config is Markdown with one ```json block (the script reads it) and free-text notes
(you read them: privacy, upload steps, website details). Always read the notes.

## Workflow: update screenshots

Run the script from the app repo root:
`python3 <this skill>/scripts/assets.py <command>` (add `--config PATH` if the config
is not at `distribution/assets.md`). It needs Pillow (`pip install Pillow`).

### 1. Ask for the captures

Run `checklist`. It creates today's capture folder (`<media_dir>/YYYY-MM-DD/`) and
writes `SHOTLIST.md` there: every shot's id, what screen to show, and which file it
uses now. Then tell the user, and **stop until they reply**:

> The screenshots to update go in `<folder>`. Save each as `<id>.png`. The list of shots
> is in `<folder>/SHOTLIST.md`. Re-shoot only the screens that changed; the others keep
> their current image. Tell me when they're in.

Pass along `capture_notes` from the config (device, data to load).

### 2. Check the captures

When the user says they're done:
1. If files in the folder don't match shot ids (e.g. `IMG_1234.PNG`), open each image,
   match it to a shot by its `screen` description, and rename it to `<id>.png`. Ask if
   a match is unclear. Don't guess.
2. Run `verify`. Every shot must resolve; `new` marks the ones from today's folder.
   Treat `LANDSCAPE?`, odd aspect ratios or narrow widths as problems to raise.
3. Look at every **new** image:
   - Does it show what `screen` says?
   - Personal data: real names, emails, locations, notifications. Propose a
     `"blur": [[x0, y0, x1, y1]]` box (raw-image pixels) for each and ask.
   - Debug banners, error states, placeholder data.

### 3. Captions

For each new or changed screen, check the `headline` and `subline` still describe it.
Propose edits as a short before/after list; `*starred*` words are drawn in the accent
colour. Write approved changes into the config's `shots`.

### 4. Store screenshots

Run `compose`. It replaces the previous set in every `outputs` folder (only files
matching that output's `name` pattern). Open two or three results to check the layout:
the headline fits, nothing important is under the caption.

### 5. Store listing text

Read the listing text (`text` folders: fastlane layout, e.g. `description.txt`,
`promotional_text.txt`, `full_description.txt`) next to the new screenshots. If a
feature is new, renamed or gone, propose the edits. Show a diff and write only approved
changes. Then run `text` and fix anything over a store limit.

### 6. Website

Skip if the config has no `website`.

1. Run `web`. It writes one JPEG per shot (no caption, status bar cropped; set
   `"web": false` on a shot to leave it off the site) into `static_repo/static_dir`,
   and prints the screenshot list as JSON: `[{src, title, caption}]`.
2. Publish the images according to `website.provider` and the config notes:
   - **`febak`:** the images are static files in the Febak repo. Commit them there
     (only those files) and, **with the user's OK**, push `main`, which deploys. Wait
     until each `https://<site><src>` returns 200; only then call the Febak MCP
     `update_site` with `product.screenshots` set to the JSON, so the site never points
     at images that aren't live yet.
   - **Other providers:** follow the config notes. If they don't say, ask.
3. Website copy: read the site's current copy (tagline, features, FAQ; for Febak, the
   product config) against the new screenshots. Propose changes and apply only the
   approved ones.

### 7. Wrap up

Report what changed: shots re-captured, captions edited, files written, text changed,
website updated. Then say what's left, from the config notes. This skill never uploads
to App Store Connect or Google Play; that's the app's release tooling (fastlane
`deliver`/`supply`, or a front end like Publisher).

## Commands

| Command | Does |
|---|---|
| `checklist` | Creates today's capture folder and `SHOTLIST.md`; prints the folder. |
| `verify` | Lists the raw file each shot resolves to, with size checks. Fails if any is missing. |
| `compose` | Writes captioned screenshots for every entry in `outputs`. |
| `web` | Writes website images; prints the `[{src, title, caption}]` list as JSON. |
| `text` | Prints listing text lengths against App Store and Play limits. Fails if any is over. |

**How shots find their raw file:** capture folders are named `YYYY-MM-DD`. A shot uses
the newest folder containing `<id>.png` (or `.jpg`/`.jpeg`). If none has one, it uses
the newest folder containing its legacy `file` name. So a re-shoot only needs the
screens that changed, and old folders stay as history.

## Config reference

See `templates/assets.md` for a complete example. Fields:

| Field | Meaning |
|---|---|
| `app` | Display name. |
| `media_dir` | Folder of dated capture folders (default `distribution/media`). |
| `style` | `background`, `headline`, `accent`, `subline` (hex), `font` (path to .ttf/.ttc), `headline_font_index`, `subline_font_index`, `status_bar_px` (rows cropped off the top of each raw shot). |
| `outputs` | One entry per store size: `dir`, `size` `[w, h]`, `name` pattern (`{n}`, `{n:02d}`, `{id}`, `{stem}` = raw file's name). |
| `text` | `ios` and/or `play`: folder of fastlane-style listing text files. |
| `website` | `provider`, `site`, `static_repo`, `static_dir`, `url_prefix`, `width` (default 1179), `jpeg_quality` (default 85). |
| `shots[]` | In display order (stores show the first few in search results). `id`, `screen` (what to capture), `headline`, `subline`, optional `file` (legacy raw name), `blur` boxes, `web` (false to skip on the site), `web_title`/`web_caption` overrides. |
| `capture_notes` | Shown to the user with the checklist. |

Paths are relative to the app repo; `~` is expanded.
