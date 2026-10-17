---
name: app-store-assets
description: Refresh an app's store and website assets from a pool of phone screenshots. Use when the user says "update screenshots", "update_screenshots", "refresh store screenshots", "new App Store / Play screenshots", "choose / reorder the screenshots", or asks to update store listing text or the app website's screenshots. File names pick which captures are published and in what order (1_home.png, 2_coach.png; extra_* are candidates). Produces captioned App Store and Google Play screenshots, checks listing text against store limits, and updates the website's screenshot gallery and copy. App-specific settings live in the app repo (distribution/assets.md), never in this skill.
version: 1.1.0
---

# Skill: App Store Assets

## Overview

A **pool** of raw captures drives three destinations:

| Destination | What it gets | Written by |
|---|---|---|
| App Store | Captioned screenshots at each size in `outputs` | `scripts/assets.py compose` |
| Google Play | Same, at Play's sizes | `scripts/assets.py compose` |
| App website | Raw screens (no baked-in caption), plus title and caption | `scripts/assets.py web`, then the website provider |

Store listing text and website copy are reviewed against the screenshots by you, the
agent, and changed only with the user's approval.

This skill is a **template**. It contains no app's paths, captions, colours or hosts.
Those live in the app repo's config file. When the user asks to change *this skill*,
change the template for every app; when they want something different for one app,
change that app's config.

## The pool and its file names

Raw captures live in dated folders, `<media_dir>/YYYY-MM-DD/` (default
`distribution/media`). Together they are the pool, and **file names decide what is
published**:

| Name | Meaning |
|---|---|
| `1_<id>.png`, `2_<id>.png`, … | Published, left to right in number order. Gaps are fine (1, 2, 5); the stores get them renumbered 1, 2, 3. |
| `extra_<id>.png` | A candidate: kept in the pool, not published. |
| anything else (`IMG_1234.PNG`) | Unsorted: look at it and rename it. |

- `<id>` is the rest of the name (`home_review_last_round`). It keys the shot's
  caption in the config, and names the website image.
- If an id appears in several folders, the **newest folder wins**. Re-shooting a
  screen means saving it under the same name in today's folder.
- **Select** an extra: rename `extra_<id>` to `<n>_<id>`. **Drop** a published shot:
  rename `<n>_<id>` to `extra_<id>`. **Reorder:** change the numbers. Rename in the
  folder that holds the newest copy of that id (`verify` shows it).
- Stores cap the count: App Store 10, Google Play 8 phone screenshots. The first two
  or three are the ones people see in search results.

## The app config

Look for the config in this order:
1. A path named in the app's `AGENTS.md` (or `CLAUDE.md`/`GEMINI.md`), e.g. "App store
   assets: see `distribution/assets.md`".
2. `distribution/assets.md`.

If there is none, **bootstrap** it:
1. Copy `templates/assets.md` from this skill to `distribution/assets.md` in the app repo.
2. Fill it in from the repo: the fastlane metadata folders (`*/appstore_metadata`,
   `*/playstore_metadata`), existing screenshots and their sizes, any existing screenshot
   script (port its captions and colours into `shots` and `style`), and the website.
3. Move existing raw captures into a dated folder and name them by the scheme above.
   Add `<media_dir>/contact-sheet.png` (written by `sheet`) to the app's `.gitignore`.
4. Add one line to the app's `AGENTS.md` (create it if missing):
   `App store assets (screenshots, listing text, website gallery): see distribution/assets.md.`
5. Show the user the filled-in config and confirm before the first run.

The config is Markdown with one ```json block (the script reads it) and free-text notes
(you read them: privacy, upload steps, website details). Always read the notes.

## Workflow: update screenshots

Run the script from the app repo root:
`python3 <this skill>/scripts/assets.py <command>` (add `--config PATH` if the config
is not at `distribution/assets.md`). It needs Pillow (`pip install Pillow`).

### 1. Ask for the captures

Run `checklist`. It creates today's capture folder and writes `SHOTLIST.md` there: the
published shots in order (with their file names, so re-shoots can reuse them), the
extras, and the naming rules. Then tell the user, and **stop until they reply**:

> New captures go in `<folder>`; `SHOTLIST.md` there lists what's published now and the
> naming rules. Re-shoot only the screens that changed, add any candidates, and tell me
> when they're in.

Pass along `capture_notes` from the config (device, data to load).

### 2. Sort the pool

When the user says they're done:
1. Run `verify`. For every **unsorted** file: open it, give it a short descriptive id,
   and rename it `extra_<id>` (or `<n>_<id>` if it's clearly a re-shoot of a published
   screen; ask if unsure). Anything that isn't an app screenshot (a photo, landscape)
   also goes to `extra_`, and you mention it.
2. Run `sheet`. It writes `<media_dir>/contact-sheet.png`: every shot with its label,
   the published ones outlined in order. Look at it yourself, then point the user to it.
3. **Let the user choose.** Show the current order and the extras, and ask which to
   publish and in what order. Suggest an order if asked (strongest screens first), but
   the user decides. Apply it by renaming files, then re-run `verify` until it reports
   no problems.
4. Check every **new** or newly selected image:
   - Does it show what its `screen` description says?
   - Personal data: real names, emails, **coordinates or addresses**, notifications.
     Propose a `"blur": [[x0, y0, x1, y1]]` box (raw-image pixels) for each and ask.
   - Debug banners, error states, placeholder data, a status bar showing odd states.

### 3. Captions

Every published id needs `headline` and `subline` in the config's `shots`. `verify`
lists those missing. For new or changed screens, write or check them and propose a short
before/after list; `*starred*` words are drawn in the accent colour. Write approved
changes into `shots`. Entries for ids not in the pool are harmless: keep them, since an
extra may be selected again.

### 4. Store screenshots

Run `compose`. It refuses while `verify` has problems. It replaces the previous set in
every `outputs` folder (only files matching that output's `name` pattern). Open two or
three results to check the layout: the headline fits, nothing important is under the
caption.

### 5. Store listing text

Read the listing text (`text` folders, fastlane layout: `description.txt`,
`promotional_text.txt`, `full_description.txt`, …) next to the new screenshots. If a
feature is new, renamed or gone, propose the edits. Show a diff and write only approved
changes. Then run `text` and fix anything over a store limit.

### 6. Website

Skip if the config has no `website`.

1. Run `web`. It writes one JPEG per published shot (no caption, status bar cropped;
   set `"web": false` on a shot to leave it off the site) into
   `static_repo/static_dir`, and prints the screenshot list as JSON: `[{src, title, caption}]`.
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

Report what changed: shots captured, selection and order, captions, files written, text,
website. Then say what's left, from the config notes. This skill never uploads to App
Store Connect or Google Play; that's the app's release tooling (fastlane
`deliver`/`supply`, or a front end built on them).

## Commands

| Command | Does |
|---|---|
| `checklist` | Creates today's capture folder and `SHOTLIST.md`; prints the folder. |
| `verify` | Published shots in order, extras, unsorted files, with size checks. Fails on duplicate numbers, missing captions, an empty selection, or more shots than a store takes. |
| `sheet` | Writes `<media_dir>/contact-sheet.png` of the whole pool, published shots outlined. |
| `compose` | Writes captioned screenshots for every entry in `outputs`. |
| `web` | Writes website images; prints the `[{src, title, caption}]` list as JSON. |
| `text` | Prints listing text lengths against App Store and Play limits. Fails if any is over. |

## Config reference

See `templates/assets.md` for a complete example. Fields:

| Field | Meaning |
|---|---|
| `app` | Display name. |
| `media_dir` | Folder of dated capture folders (default `distribution/media`). |
| `style` | `background`, `headline`, `accent`, `subline` (hex), `font` (path to .ttf/.ttc), `headline_font_index`, `subline_font_index`, `status_bar_px` (rows cropped off the top of each raw shot). |
| `outputs` | One entry per store size: `dir`, `size` `[w, h]`, `name` pattern (`{n}`, `{n:02d}`, `{id}`, `{stem}` = raw file's name), optional `max` (count limit; defaults: `ios` 10, `play` 8). |
| `text` | `ios` and/or `play`: folder of fastlane-style listing text files. |
| `website` | `provider`, `site`, `static_repo`, `static_dir`, `url_prefix`, `width` (default 1179), `jpeg_quality` (default 85). |
| `shots[]` | The caption library, keyed by `id` (order doesn't matter; file names set the order). `id`, `screen` (what to capture), `headline`, `subline`, optional `blur` boxes, `web` (false to skip on the site), `web_title`/`web_caption` overrides. |
| `capture_notes` | Shown to the user with the checklist. |

Paths are relative to the app repo; `~` is expanded.
