# Store listing contract

What the **Store Listing** action actually sends to Google Play, and the rules a project's
`metadataPath` has to follow for it to work.

The README describes the action. This describes the *data* — it is the contract every project
in `config.json` conforms to, so it is the thing to code against when adding an app.

## The action

`AppModel.uploadListing` → `Runner.uploadListing` runs `supply` with no binary:

```
skip_upload_apk:true   skip_upload_aab:true          # no build
skip_upload_metadata:false                            # text, yes
skip_upload_images:false                              # icon + feature graphic, yes
skip_upload_screenshots:false                         # screenshots, yes
skip_upload_changelogs:true                           # release notes, NO
changes_not_sent_for_review:true                      # staged, not submitted
```

Release notes are deliberately not part of this action — they belong to a build, and go up via
**Build & Upload** instead (see *Release notes* in the README).

## Directory convention

`supply` discovers files by path, not by configuration. `metadataPath` must look like this:

```
<metadataPath>/
└── en-US/                          # one directory per Play language code
    ├── title.txt                   → app name           (max 30 chars)
    ├── short_description.txt       → short description  (max 80 chars)
    ├── full_description.txt        → full description   (max 4000 chars)
    ├── images/
    │   ├── icon.png                → 512x512
    │   ├── featureGraphic.png      → 1024x500
    │   └── phoneScreenshots/       → phone screenshots, ordered BY FILENAME
    │       ├── 1.png
    │       └── ...
    └── changelogs/
        └── <versionCode>.txt       → release notes (NOT sent by this action)
```

Anything outside this layout is ignored. Habit Hero has `app_icon_512.png` and
`feature_graphic_1024x500.png` sitting at the `metadataPath` root; they upload nothing and
exist only to confuse. Stray `.DS_Store` files are harmless but worth deleting.

`supply` also understands `video.txt`, `tabletScreenshots/`, `sevenInchScreenshots/`,
`tenInchScreenshots/`, `wearScreenshots/` and `tvScreenshots/`. We use none of them today; drop
a directory in and it starts uploading.

## Screenshots replace, they do not merge

Uploading screenshots **deletes the existing set for that language** and replaces it with the
folder contents. Four files in means exactly four on the listing. Removing a file from the
folder removes it from Play.

Order is filename order, which is why they are `1.png`–`4.png` rather than named after the
screens they show.

## Image geometry — the part that bites

Play constrains screenshot aspect ratio to between 9:16 and 16:9. This is the binding
constraint on our pipeline, and it is tighter than it looks:

| | Width | Height | Ratio | |
|---|---|---|---|---|
| Staging render | 1282 | 2776 | 0.4618 | **rejected** — narrower than 9:16 |
| Padded for Play | 1562 | 2776 | 0.56268 | accepted, by 0.00018 |

9:16 is `0.5625`. For a 2776px-tall image the minimum acceptable width is
`0.5625 × 2776 = 1561.5`, so **1562 is the smallest integer width that passes**. One pixel
narrower fails.

That is why listing images are the staging screenshots padded with 140px of the app's
background (`#090D16` for Habit Hero) on each side. The padding is not cosmetic framing — it is
what makes the images uploadable. Do not "clean it up".

A project whose screenshots are a different height needs its own width recomputed as
`ceil(height × 0.5625)`, and its own background colour. When Publisher goes multi-app, this
belongs in `Project` as settings rather than being assumed.

> Verify the ratio rule against current Play documentation before relying on it for a new app —
> Google has changed screenshot requirements before, and our margin here is half a pixel.

## Text limits

Checked at the time of writing, for Habit Hero:

| Field | Limit | Current | Headroom |
|---|---|---|---|
| `title.txt` | 30 | 30 | **none** |
| `short_description.txt` | 80 | 79 | 1 char |
| `full_description.txt` | 4000 | 713 | plenty |

The title is exactly at the cap, with no trailing newline. Any edit that adds a character will
be rejected by Play. Note that `supply` sends file contents including a trailing newline if
present, so keep `title.txt` and `short_description.txt` newline-free.

## Nothing goes live until you send it for review

Every action passes `changes_not_sent_for_review:true`. The upload commits an edit to Play, but
it is **not** submitted — it waits in the Play Console until you press **Send for review**.

This is the single most common source of "I clicked the button and nothing changed". It is
intentional: it means an accidental click cannot alter a live listing.

## Onboarding a new app

For a project to support **Store Listing**, it needs:

1. `metadataPath` in `config.json`, pointing at a directory in the layout above.
2. At minimum `en-US/title.txt`, `short_description.txt`, `full_description.txt`.
3. `en-US/images/icon.png` at 512×512 and `featureGraphic.png` at 1024×500.
4. `en-US/images/phoneScreenshots/` with at least two screenshots inside the ratio bounds.
5. A service-account key with Play publishing rights for that `packageName`.

`Project.listingProblems` checks items 2 and 4 (text files present and within the caps counting
any trailing newline; at least two PNGs) before Store Listing starts. It does not check image
dimensions — verify those with the `store-listing` skill.

## Habit Hero, as of this writing

`MobileApp/distribution/android/playstore_metadata/` — conforms, four phone screenshots
regenerated from the in-repo generator and padded to 1562×2776. They are committed but have
**not** been uploaded to Play.

Regenerate the staging screenshots with:

```bash
cd <appDir> && ./scripts/generate_store_screenshots.sh
```

then pad them to listing geometry before they are uploadable. The generator is deterministic —
two runs produce byte-identical output — so any diff in a regenerated screenshot is a real UI
change.
