---
name: build-publisher
description: Build "Publisher", a macOS app for shipping mobile builds to Google Play and the App Store/TestFlight without a terminal - pre-flight checks, one-click Build & Upload to the internal track with a safe version code, promote internal to closed testing to production, store-listing diff and upload (text, icon, screenshots), iOS TestFlight upload and App Review submission, release notes, a publish lock, store-watch notifications (live, approved, rejected, new release live), and a "ready to publish" gate (committed, pushed, backend deployed, tests passed). Plain Swift package with fastlane/Ruby/shell scripts bundled in this skill. Use when the user says "build Publisher", "set up one-click Play/TestFlight publishing", or asks for /dyor-knowledge-base publisher. Built as PublisherKit + a thin app, so Appos (build-appos) can show it inside its window. Mac only. Companion skills - build-operator, build-runner, build-appos, play-prepublish-check, google-play-publishing.
version: 1.3.0
---

# Build Publisher

**Operator to code, Runner to try it, Publisher to publish.** Publisher is the only one of the
three that changes things the world can see (Play tracks, TestFlight, App Review, your live
backend). Everything it does is therefore: explicit, confirmed where it matters, logged, and
refused with a readable reason rather than failing halfway into a 10-minute build.

You (the agent) build it from this spec. Read `references/mac-app-recipe.md` first (package
layout, AppKit bootstrap, `build.sh`, `rebuild.sh`, process streaming). The scripts in this
skill's `scripts/` folder (Play and App Store Connect uploads, snapshots, listing sync) are
tested and should be **copied**, not rewritten; the Swift app around them is yours to write.
`references/store-listing-layout.md` is the on-disk contract for the store listing.

This is the largest of the three apps. **Build it in phases and verify each with the user
before the next** (section 2). Do not try to land everything at once.

## 0. Before you write anything: ask the user

1. **Which apps, and which stores?** Per app: name, `appDir`, and Android `packageName` (Play)
   and/or iOS bundle id (App Store). Android-only, iOS-only, or both.
2. **Where should Publisher's source live?** [`<projects>/local/Publisher` or `~/Publisher`].
3. **Android: do they already have** a Play Console developer account, the app created in the
   Console with its **first AAB uploaded by hand** (the Play API cannot create an app), a
   service-account JSON key with Play Console access, and a release keystore? If not, explain
   each (section 7) and build only what they can use; the Play parts can wait.
4. **iOS: do they have** an App Store Connect app record, an App Store Connect API key (`.p8`,
   with key id and issuer id), the Apple ID signed in to Xcode, **and an `Apple Distribution`
   certificate in this Mac's Keychain**? (Signing in to Xcode only creates an *Apple Development*
   cert by default; check with `security find-identity -v -p codesigning` and walk them through
   creating the Distribution cert in Xcode if missing — see section 7.) Same: the API cannot
   create the app record.
5. **Firebase backend** (Cloud Functions) that must be deployed before releases? Same
   `firebase` block as Runner (project id, `only`, `testCommand`, `paths`).
6. Bundle id prefix, icon, and where the Mac's `fastlane`/Ruby come from (see prerequisites).

**Prerequisites** (verify; tell the user, never silently install system software):
- Xcode command-line tools; **full Xcode** for iOS archive/upload (verify via `xcodebuild -version`,
  not `/Applications/Xcode.app` existence, as versioned bundles like `/Applications/Xcode_26.x.app`
  are common), plus an **`Apple Distribution` signing identity in Keychain** for any iOS app
  (`security find-identity -v -p codesigning` must list `"Apple Distribution: ..."`).
- **Ruby 3+ with Bundler / Fastlane**, and in each app's `appDir`: a `Gemfile` declaring
  `fastlane` (`googleauth` and `jwt` are often transitive in `Gemfile.lock` rather than listed
  directly in `Gemfile`, so accept either). **Two macOS Ruby traps to guard against in Swift**:
  1. `/bin/zsh -lc` skips `~/.zshrc`, and `/etc/zprofile` runs `/usr/libexec/path_helper -s`,
     which **reorders `/usr/bin` (Apple Ruby 2.6, which syntax-errors on Ruby 3 endless methods
     in `appstore_*.rb`) ahead of Homebrew** even if `Process.environment["PATH"]` was set.
     `brew install ruby` on Apple Silicon is also **keg-only** at `/opt/homebrew/opt/ruby/bin`.
     Always prepend `export PATH="/opt/homebrew/opt/ruby/bin:/usr/local/opt/ruby/bin:$HOME/.rbenv/shims:/opt/homebrew/bin:/usr/local/bin:$PATH";`
     **inside** the `-lc` command string.
  2. `brew install fastlane` isolates gems in `/opt/homebrew/opt/fastlane/libexec`, so
     `bundle check` in `appDir` may fail if `bundle install` was not run locally; check
     `bundle check` first and fall back to Homebrew fastlane's `GEM_HOME`/`GEM_PATH` (or tell
     the user to run `bundle install` in `appDir`).
- Each app has `fastlane/Fastfile` (can be minimal: a `first_time_build` lane that runs
  `gradle(task: "bundleRelease")`), `gradlew`, and `<module>/build.gradle.kts` with
  `versionCode = N` and `versionName = "x"` literals on their own lines. Publisher reads and
  rewrites `versionCode` with a regex, so it must be a literal (not computed).
- Release signing: a `keystore.properties` file (gitignored) that the Gradle release build
  reads. Without it the build **silently falls back to the debug key and Play rejects the AAB
  at the end of the whole build**. Publisher refuses to start instead (pre-flight).
- `git`, and `firebase`/`node` only if a Firebase gate is configured.

## 1. What Publisher is

A window plus a menu-bar item driving the same code. Dark theme (the same palette as Runner:
ground `#111210`, surface `#1A1B18`, accent amber `#F2B23A`, ok `#5CCB8C`, bad `#FF7A59`).
**Shell is AppKit** (`NSWindow` + `NSStatusItem`), SwiftUI renders the contents.

**Sidebar**: every app from `config.json` with icon and a one-line status: blocked (red, for
example "Upload key missing"), pending (amber, "N listing changes"), or healthy (green, what is
on internal). Buttons: Fetch Store Data, Reload Config, Rebuild & Relaunch.

**Per app, tabs**: **Overview**, **Store**, **Activity**, and **Shared** (the repo-level
readiness checklist, section 5). Apps with iOS get a **Google Play | App Store** switch in the
header; the same tabs then show the App Store side.

**Run banner**: what is running (with **Cancel**), or the result of the last run.

**Output log** streams live with **Copy Log**; a macOS notification fires on finish.

### Config

`config.json` beside `Publisher.app` (else `~/.config/publisher/config.json`; `$PUBLISHER_CONFIG`
wins). Always call `expandingTildeInPath` on every configured path (`appDir`, keys, metadata,
`appStoreConnect.keyPath`) before checking whether it is absolute or resolving relative paths
against `appDir`.

```json
{
  "projects": [ {
    "name": "My App",
    "appDir": "/Users/me/Projects/kmp/MyApp",
    "packageName": "com.me.myapp",
    "androidModule": "androidApp",
    "serviceAccountKey": "distribution/android/play-service-account.json",
    "keystoreProperties": "distribution/android/keystore/keystore.properties",
    "metadataPath": "distribution/android/playstore_metadata",
    "playConsoleURL": "https://play.google.com/console/...",
    "testersURL": "https://play.google.com/apps/internaltest/...",
    "ios": { "project": "iosApp/iosApp.xcodeproj", "scheme": "iosApp",
             "bundleId": "com.me.myapp",
             "metadataPath": "distribution/ios/appstore_metadata",
             "appStoreConnectURL": "https://appstoreconnect.apple.com/apps/.../distribution" },
    "firebase": { "project": "my-fb-id", "only": "functions",
                  "testCommand": "node --test functions/*.test.js", "paths": ["functions"] }
  } ],
  "appStoreConnect": { "keyId": "ABC123DEF4", "issuerId": "00000000-...", "keyPath": "~/.appstoreconnect/private_keys/AuthKey_ABC123DEF4.p8" }
}
```

- Required for Play apps: `name`, `appDir`, `packageName`, `serviceAccountKey`. Defaults:
  `androidModule` = `androidApp`; `metadataPath` = `distribution/android/playstore_metadata`;
  `ios.metadataPath` = `distribution/ios/appstore_metadata`; `keystoreProperties` unset (not
  checked, **tell the user to set it**).
- **iOS-only apps** omit `packageName` and `serviceAccountKey`; they get no Play switch or
  Android checks. The app's key everywhere (`id`) is `packageName` if it has one, else the iOS
  bundle id.
- The App Store Connect block holds only the key's **path**; the `.p8` stays in
  `~/.appstoreconnect/private_keys/`. **Publisher stores no credentials**: it passes paths to
  scripts.
- `appDir` is the folder holding `Gemfile`, `gradlew` and `fastlane/` (often a `MobileApp/`
  subfolder of the repo, sometimes the repo root).
- **Reload Config** re-reads without restarting. Everything optional defaults, so an older
  entry keeps working.

### Pre-flight (Android), shown as a checklist with passing items

Before any action, check and **refuse with a readable message** instead of failing midway:
`appDir` exists; `fastlane/Fastfile`, `Gemfile`, `gradlew` exist; `<module>/build.gradle.kts`
exists; keystore properties file exists (when configured); service-account key exists;
`targetSdk` in the build file is acceptable for Play's current requirement (warn, not
block — support both literal integers and multi-line version-catalog references like
`libs.versions.android.targetSdk.get().toInt()` resolved from `gradle/libs.versions.toml` or
`../gradle/libs.versions.toml`); **no publish in progress** (lock, below). A red blocking item
blocks builds; actions that only talk to Play (listing, promote, pull) need just the tooling
and the service-account key, so a missing upload keystore does not lock the user out of the
store listing.

### Pre-flight (iOS), shown on the App Store side

When an app has an `ios` block, check and explain clearly before starting a multi-minute archive:
`appDir` and `<ios.project>/project.pbxproj` exist; `Gemfile` / fastlane gems ready; full Xcode
installed (`xcodebuild -version`); **`Apple Distribution` certificate in Keychain**
(`security find-identity -v -p codesigning` contains `"Apple Distribution:"` — blocks builds only;
if missing, tell the user: *Xcode -> Settings -> Accounts -> select Apple ID -> Manage
Certificates... -> `+` -> Apple Distribution; once it appears in solid black with blank Status it
is already in Keychain — click Done, nothing to download*); **App Store Connect API key (`.p8`)**
configured in `appStoreConnect` (`keyId`, `issuerId`, `keyPath`) and file present on disk; **no
publish in progress** (lock). Local store-listing edits and the HTML preview still work before the
API key is configured.

### The publish lock

A publish holds `<appDir>/.publisher.lock` (gitignored) for its whole run, containing
`pid=<n>`, `action=<name>`, `started=<ISO time>`. Anything else trying to publish the same
project refuses with a readable message: a second copy of the app, a terminal run of the
scripts, another machine on a shared checkout. If the recorded pid is dead (`kill -0` fails),
the lock is stale and is taken over. The Swift app takes the lock, then sets
`PUBLISHER_LOCK_OWNED=1` for the script, which otherwise takes its own lock (see
`android_upload.sh`). Why: two publishes once raced onto the same version code.

### Running things

Same as Runner: `/bin/zsh -lc` login shell, merged environment, pipe both streams into the
log, `standardInput = nullDevice`, kill the process **tree** on Cancel, request user
attention on finish. After every run, re-fetch store data. Record each run in an **activity
log** (`~/Library/Application Support/Publisher/activity.json`: date, app, title, ok, last
4,000 characters of log) shown on the Activity tab with the live run at the top.

## 2. Build in phases (verify each with the user)

### Phase 1 - Read-only Play dashboard + Android Build & Upload (internal)

1. Package, bootstrap, config, sidebar, tabs, theme, run plumbing, activity log.
2. **Play snapshot** (`scripts/play_snapshot.rb <package> <key> <outDir>`): opens an edit,
   reads tracks, the en-US listing text and listing image hashes/thumbnails, **always deletes
   the edit**, prints one JSON object. It commits nothing, so it is safe to run at launch, on
   **Fetch Store Data**, and after every run. (A leaked open edit makes the *next* real
   upload fail with "This edit has expired".) Show what Play has on internal, closed
   (`alpha`), and production, read from Play, never remembered.
3. **Release card** on Overview: answers "is there anything to publish?"
   - Keep `releases.json` (`~/Library/Application Support/Publisher/releases.json`): after
     each successful upload append `{packageName, versionCode, versionName, commit (HEAD sha
     captured when the build *started*), track, date, platform}`.
   - Show `git log --oneline <lastUploadedCommit>..HEAD`. Only when there are commits, show
     the big **Publish** button (labelled with the version code it *will* get) and a notes
     box with **Fill from commits**. With no new commits say **Up to date** and demote to
     "Rebuild anyway...". For builds made before recording, fall back to the oldest commit
     whose build file sets exactly that versionCode (`git log -G versionCode`).
   - Flag uncommitted files and unpushed commits (a build from them would not match GitHub).
     Re-read git whenever the app becomes active.
4. **Build & Upload -> Internal**: runs `scripts/android_upload.sh <appDir> <package>
   <serviceKey> <metadataPath> internal <notesFile> <module>`. Read the script; the contract:
   - **Version codes are never reused.** Read `versionCode` from source; ask Play for the
     highest code it has (via an edit that is deleted afterwards); if source is not higher,
     bump past Play's highest and **write it back into `build.gradle.kts`**. If the Play query
     fails, say so loudly and fall back to source (worst case Play rejects, never overwrites).
     `versionName` is never touched.
   - Release notes: written to `<metadata>/en-US/changelogs/<versionCode>.txt` (what `supply`
     reads). Empty box keeps an existing file; if none, write "Bug fixes and improvements."
     Play rejects notes over **500 UTF-16 units** (an emoji is 2); the script trims whole lines.
   - Optional pre-publish gate: the `play-prepublish-check` skill (R8 on, AAB signed with the
     upload key, no stray permissions, no secrets tracked). If not installed the script
     downloads it from github.com/dyor/skills; `PUBLISHER_SKIP_PREPUBLISH=1` skips once.
   - `./gradlew :<module>:bundleRelease`, then `play_release.rb`, which uploads the AAB and
     sets it on the target track **and on every other non-production track that already holds
     a release, in one Play edit** (Play validates declarations of every release in the edit
     and never says which track is at fault, so a stale build on a forgotten track would block
     all future uploads). Production is never touched here. Commit with
     `changesNotSentForReview=true`, retry without if Play says it must not be set.
   - Afterwards commit **just** the version bump and the changelog
     (`chore(release): versionCode N to internal`) and push, best effort, so the tree is not
     left dirty (a dirty tree blocks the next publish).
   - Release bookkeeping edits (changelog files; a build-file diff that is only `versionCode`
     or `CURRENT_PROJECT_VERSION`) must not count as "uncommitted changes" in the readiness
     check, or a failed upload would block its own retry. Pass `-uall` to
     `git status --porcelain` so untracked `changelogs/<code>.txt` files are listed
     individually (not collapsed into a directory entry), and match paths by suffix or relative
     to `git rev-parse --show-toplevel` because `git status` returns repo-root-relative paths
     (`MobileApp/androidApp/...`) when `appDir` is a `MobileApp/` subfolder.
5. **Phase 1 verification**: `swift build` clean; `play_snapshot.rb` returns JSON for a real
   app; the Overview shows tracks and the Release card. **Do not upload a build as a test.**
   If the user wants to try it, they press Publish themselves; you can run
   `VALIDATE_ONLY`-style checks, never a real upload on their behalf.

### Phase 2 - Promote + store listing

6. **Promote** (internal -> closed testing -> production), **no rebuild**, so the exact
   artifact testers validated ships. `fastlane run upload_to_play_store` with
   `track:<from> track_promote_to:<to> skip_upload_apk/aab:true skip_upload_metadata/images/
   screenshots:true`. **Always confirm first**, and treat production as critical.
   - A never-live ("draft") app only accepts `track_promote_release_status:draft`, and the API
     cannot send a draft for review: tell the user to press **Send changes for review** in Play
     Console and give an "I've sent it for review" button, since Play's API reports a rejected
     release the same as one in review.
   - Otherwise send for review in the same step with `changes_not_sent_for_review:false`; if
     Play refuses (`changesNotSentForReview` in the error), re-run with `true` and say to
     press Send for review in the Console.
   - Send the build's own notes when its changelog exists and is <= 500 chars; otherwise skip
     changelogs and warn (an empty note would replace the copied one).
7. **Store tab**: the live listing beside the local `metadataPath`, one row per field, each
   marked unchanged / changed / new. Screenshots and graphics compare by **sha256** against
   what Play stores; text compares ignoring surrounding whitespace that Play strips. Check
   limits (title 30, short description 80, full 4000; a trailing newline counts), and at least
   2 phone screenshots. Optionally OCR artwork with Vision and spell-check it (catches
   "STREEK" before it ships). **Upload N changes...** names every change before sending;
   uses `supply` with `skip_upload_changelogs:true changes_not_sent_for_review:true`.
   **Pull listing from Play** seeds an empty folder (refuse if `en-US/title.txt` exists, since
   the download overwrites local files). See `references/store-listing-layout.md`.
8. **What's next** card: derive the single next step from pre-flight, git, tracks, and whether
   the public store page exists: commit -> publish internal -> test -> promote -> send for
   review -> live. A blocking pre-flight failure or a run in progress comes back alone.

8b. **Store watch** (both stores, no credentials needed for the public half). Approvals often
   arrive with no email, so Publisher watches and notifies (macOS notification) on its own:
   - **Public pages, every 30 minutes** and on every refresh: GET the Play page
     (`play.google.com/store/apps/details?id=<pkg>&hl=en_US&gl=US`; 200 = public, 404 = not)
     and Apple's lookup (`itunes.apple.com/lookup?bundleId=<id>&country=us`; `resultCount>0`
     = on sale, with `version`, `releaseDate`, `currentVersionReleaseDate`, `trackViewUrl`).
   - **Went live**: a page seen missing, then present -> "🎉 <app> is live on Google Play / the
     App Store", and record the date ("live since"). An app already live when first checked
     gets no date rather than a wrong one.
   - **New release live**: Play's API never says a release passed review, but the public
     page's "Updated on <date>" changes when one goes live; on the App Store the lookup's
     `version` changes. Persist the last marker per app and store; notify on a change, never
     on the first value seen.
   - **App Review result** (iOS): App Store Connect state per version, persisted; a move out of
     `WAITING_FOR_REVIEW`/`IN_REVIEW` to `PENDING_DEVELOPER_RELEASE` / `PENDING_APPLE_RELEASE` /
     `READY_FOR_SALE` notifies "approved", to `REJECTED` (or metadata/binary rejected) notifies
     "rejected". The half-hourly check re-reads versions only, not the listing.
   - **Show it**: the sidebar line leads with "Live ·" while the current platform's public page
     is up (unless something blocks); the Production / App Store cards link to the public page
     with "live since", Play's "updated" date and the App Store's first and current release
     dates. A first production release that Play still reports as "draft" shows "● Live" once
     the public page exists.
   - Keep these in `UserDefaults` (`liveSince`, `lastPublic`, `publicRelease`, `reviewStates`).

### Phase 3 - iOS / TestFlight / App Review

9. **Snapshot** `scripts/appstore_snapshot.rb` (builds, versions, review state).
   TestFlight card (newest build, processed or not); App Store card in App Store Connect's own
   words (*Waiting for review*, *In review*, *Rejected*, *Live*); unlike Play, ASC reports
   review status.
10. **Upload to TestFlight** `scripts/ios_upload.sh <appDir> <bundleId> <xcodeproj> <scheme>
    <keyId> <issuer> <keyPath> <notesFile> [recordId]`: picks a build number above ASC's
    highest **and** the last Publisher recorded (a failed ASC read once fell back to 0 and was
    rejected as a duplicate after a full archive; now a failed read falls back to the record or
    refuses), writes it back to `CURRENT_PROJECT_VERSION` (and `project.yml` for XcodeGen),
    archives, exports with `destination=upload`, then attaches "What to Test" notes
    (`appstore_notes.rb`) once processed. `DRY_RUN=1` archives/exports without uploading.
    **Signing uses the Apple ID signed in to Xcode**, not the API key: cloud signing of the
    distribution certificate needs an Admin role an App Manager key lacks ("Cloud signing
    permission error"). `SIGN_WITH_API_KEY=1` signs with an Admin key instead.
11. **Submit for review...** (`appstore_submit.rb`): attaches the newest processed build to
    the App Store version and submits. Always confirms. Anything ASC still needs (screenshots,
    privacy answers, export compliance) comes back as its message and nothing is submitted.
12. **App Store listing** (`appstore_listing.rb`): fastlane-deliver layout under
    `distribution/ios/appstore_metadata/{texts,screenshots}/en-US/`, field limits (name and
    subtitle 30, keywords 100, promotional text 170, description 4000), screenshots compared
    per device size by MD5, **Pull listing** seeds the folder, **Upload N changes...** edits the
    version being prepared and never a live one.
    `scripts/store_preview.rb <metadataDir> <outDir> [icon]` builds a local HTML mockup of the
    App Store page from the same files, so order, copy and screenshots can be seen before
    publishing (a **Preview** button that opens `index.html`).
13. **In-app purchase review screenshots** (`appstore_iap.rb`): list purchases with state and
    whether a review screenshot exists; upload `<metadataPath>/in_app_purchases/
    review_screenshot.png` (or `<productId>.png`) to those lacking it.

### Phase 4 - Shared readiness, Firebase, polish

14. **Shared tab** (below), Firebase card, menu-bar item, `publisher://` links, snapshot env
    var for screenshots.

## 3. Menu bar and links

`NSStatusItem` with the same actions as the window (Publish, Store Listing, Tester Link,
Play Console). Keep the Dock tile (`setActivationPolicy(.regular)`). `publisher://open?package=
<packageName or bundleId>` selects an app (Operator's **Publish** button sends it); if it
arrives at cold launch, store the selection and show the window after.

### Inside Appos

Follow recipe §9. For Publisher specifically:

- Put everything in `Sources/PublisherKit/`. `Sources/Publisher/main.swift` is
  `MainActor.assumeIsolated { PublisherMain.main() }`, because the AppDelegate and `AppModel`
  are `@MainActor`.
- `Config.repoDir` gets an override (`repoDirOverride`) that `PublisherEmbed(repoDir:)` sets.
  Use bundled scripts only when standalone.
- `PublisherDefaults.store` replaces `UserDefaults.standard` (release-note drafts,
  `sentForReview`), so a draft started in one app shows in the other.
- `RootView(model:runner:store:embedded: true)` hides the sidebar, relaxes `minWidth` to 800,
  and skips the `onAppear` store fetch. `PublisherEmbed` fetches Play and App Store Connect
  once, on the first `show(package:)`, and re-reads git on `didBecomeActive` as the
  AppDelegate does.
- `show(package:)` matches `packageName`, `id` or `iosBundleId`, because App Store-only apps
  have no Android package. `runningPackage` returns the running project's `id`.
- The Shared tab's **Commit & push…** checks `PublisherEmbed.openShip` before opening
  `operator://ship`.
- Every tab scrolls on its own, so the window's `minHeight` is 460, not 700. The sidebar's app
  list is in a `ScrollView` too. The header shows Publisher's gem (`Gem("publisher")`).
- **The menu-bar item isn't part of Appos.** It lives in the AppDelegate, which Appos doesn't
  use. Standalone Publisher keeps it.

## 4. Version names and what Publisher never does

- Never edits `versionName`. Never uploads without being asked. Never sends anything for
  review without a confirmation. Never commits, except the two release files after a
  successful upload. Never deletes a track, release or listing.
- Every Play action passes `changes_not_sent_for_review:true` by default, so uploads land in
  Play but nothing is submitted for review until the user presses **Send for review** in the
  Console (or confirms a promote that sends it).

## 5. Shared readiness (the gate every publish waits on)

Repo-level work that must be finished before *anything* goes to a store. `blockers` for an app
is the list of what is not true yet; a store action with any blocker **refuses to start** and
prints them. The Shared tab shows a banner ("Ready to publish" / "Not ready: N items") and
the checklist:

1. **Committed**: `git status --porcelain -uall` empty (excluding release bookkeeping, matched
   repo-root-aware when `appDir` is a subfolder like `MobileApp/`).
2. **Pushed**: `git rev-list --count @{u}..HEAD` is 0; no upstream is also a blocker.
3. **Backend deployed** (only with a `firebase` block): not behind the last deploy.
   Compute exactly as in `build-runner` section 5 and share the same
   `~/Library/Application Support/Publisher/firebase_deploys.json` log (decode ISO-8601 dates
   both with and without `.withFractionalSeconds` so entries written by either Runner or
   Publisher parse cleanly). A Firebase card on Overview shows deployed-at, commits since,
   uncommitted files, and a **Deploy** button that always confirms and runs `testCommand` first
   (`<test> && firebase deploy --only <target> --project <id> --non-interactive`), recording
   HEAD (captured at the start) on success.
4. **Tests passed on this commit** (only when `firebase.testCommand` is set): a marker file
   `~/Library/Application Support/Publisher/tests/<appId>-<sha>` written whenever `testCommand`
   succeeds on a clean tree (including during a Firebase deploy from either Runner or
   Publisher), so a new commit invalidates it.

Also show per-platform "commits since the last upload", and a "changes since last Firebase
deploy" list. Re-read this whenever the app becomes active or a run finishes.

## 6. Verification checklist (give the user this at the end)

- `./build.sh` clean; app opens; sidebar lists their apps with sensible statuses.
- Overview shows real data from Play (and ASC if configured). No red pre-flight items, or the
  red items are explained and match reality.
- `Store` tab shows unchanged/changed rows against their local metadata.
- `Shared` tab banner matches `git status`.
- **Nothing was published during setup.** Say so explicitly and list what you ran (snapshots
  only, `DRY_RUN=1` iOS export if requested).

## 7. First-time setup the user must do by hand (explain, don't automate)

- Create the app in Play Console and upload the first AAB manually
  (`bundle exec fastlane android first_time_build` builds one). The API cannot create apps.
- Create a Google Cloud service account, enable the Google Play Android Developer API, add the
  account in Play Console -> Users and permissions with release permissions, download its JSON
  key to the (gitignored) path in config.
- Generate a release keystore and `keystore.properties`; **back both up outside the repo**.
- **For iOS** (give the user these exact steps when setting up an iOS app — Xcode and App Store
  Connect UIs are confusing here):
  1. **App Store Connect app record**: create the app in App Store Connect with matching bundle id
     (the API cannot create app records).
  2. **Apple Distribution certificate in Xcode** (signing in to Xcode alone only creates an *Apple
     Development* cert, NOT a Distribution cert):
     - Open **Xcode -> Settings (`⌘,`) -> Accounts**, sign in with the Apple ID on the team, select
       the account/team, and click **Manage Certificates...**.
     - Click **`+` (bottom-left) -> Apple Distribution**.
     - **Important UI gotcha**: Xcode generates the private key locally and installs the certificate
       straight into this Mac's Keychain — **there is nothing to download**. As soon as `Apple
       Distribution` appears in **solid black text with a blank `Status` column**, click **Done**
       (greyed-out rows marked `Not in Keychain` belong to other Macs and can be ignored). Verify
       with `security find-identity -v -p codesigning`.
     - *(Only if Apple refuses because the account hit its maximum distribution certificate limit:
       either export an existing `Apple Distribution` cert + private key as a `.p12` from Keychain
       Access on another Mac and import it here, or revoke an unused cert.)*
  3. **App Store Connect API key (`.p8`)**:
     - Open `https://appstoreconnect.apple.com/access/integrations/api` (**Users and Access ->
       Integrations -> App Store Connect API**).
     - Click **`+`** to generate a key, name it (e.g. `<Mac> Publisher`), and choose **App Manager**
       access.
     - Click **Download API Key** (Apple only lets you download a `.p8` once; on a second Mac it is
       often easiest to generate a new key rather than copying the old `.p8`) and move
       `AuthKey_<KEY_ID>.p8` to `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`.
     - Copy the **Issuer ID** (top of that page) and **Key ID** into `config.json`:
       `"appStoreConnect": { "keyId": "<KEY_ID>", "issuerId": "<ISSUER_UUID>", "keyPath": "~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8" }`.
- Put `.publisher.lock`, key files, keystores, `distribution/ios/build/` in `.gitignore`.
- For deeper Play behavior (tracks cannot be deleted, tester invites, AD_ID, "App not
  available"), point them to the `google-play-publishing` skill, and to
  `play-prepublish-check` for the release checklist.

## 8. Don'ts

- Don't store credentials in config, source or logs; paths only.
- Don't run a real upload, promote, submit or deploy as a "test". Dry runs and read-only
  snapshots only, unless the user explicitly presses the button.
- Don't leave a Play edit open (always delete in `ensure`/`at_exit`).
- Don't trust Play's API for review rejection (it cannot report one); say so in the UI.
- Don't hand-edit scripts inside `Publisher.app`; edit `scripts/` and rebuild.
