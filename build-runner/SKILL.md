---
name: build-runner
description: Build "Runner", a macOS app that builds a Kotlin Multiplatform (KMP) or Android/iOS app and runs it on a chosen target - a plugged-in Android phone, a running or bootable emulator, an iPhone simulator, or a paired iPhone - with one click, streaming the build log, plus a fast iOS compile check, a build-time chart, and an optional Firebase functions deploy gate that makes sure the backend is current before running on a device. Plain Swift package; bundled shell scripts do the work. Use when the user says "build Runner", "set up Runner", "one-click run on my phone/simulator", or asks for /dyor-knowledge-base runner. Built as RunnerKit + a thin app, so Appos (build-appos) can show it inside its window. Mac only. Companion skills - build-operator, build-publisher, build-appos.
version: 1.2.0
---

# Build Runner

**Operator to code, Runner to try it, Publisher to publish.** Runner answers one question:
*"does my change work on a real device, right now?"* Pick the app, pick where it goes, press
Run (⌘R). It builds, installs and launches, and streams the log. It never publishes anything
and never touches git (that is Operator's job).

You (the agent) build it from this spec. Read `references/mac-app-recipe.md` first for the
package layout, AppKit bootstrap, `build.sh`, `rebuild.sh` and the Terminal helpers. The
shell scripts in this skill's `scripts/` folder are tested and should be copied, not rewritten.

## 0. Before you write anything: ask the user

1. **Which apps?** For each: a name, the folder containing `gradlew` or `./kotlin` (and
   `iosApp/` for iOS), and the Android `applicationId`. Runner targets KMP and native projects:
   `androidApp` and `shared` Gradle (or Kotlin Toolchain / Amper) modules, `iosApp/iosApp.xcodeproj`.
   Ask whether any use different module names (Compose Multiplatform wizard projects use
   `composeApp`) or an `applicationIdSuffix` / side-by-side debug suffix (for example `.dev`).
2. **Where should Runner's source live?** [`<their projects>/local/Runner` or `~/Runner`].
3. **Do they need physical iPhones?** If yes, the Xcode project needs a signing team (ask for
   the Team ID, or tell them to open the project in Xcode once and pick it under Signing &
   Capabilities).
4. **Does any app have a Firebase backend** (Cloud Functions) that the mobile app depends on?
   If so ask for the Firebase project id, what to deploy (default `functions`), a test command
   to run before deploying (for example `node --test functions/*.test.js`), and which paths
   count as backend code (default `["functions"]`). See "Firebase gate".
5. Bundle id prefix and whether they want an icon.

Prerequisites to verify, and to tell the user about if missing (do not install system
software without asking):
- Xcode command-line tools plus **full Xcode** for iOS builds (`xcodebuild -version`,
  `xcrun simctl`, `xcrun devicectl`; check via `xcodebuild`, not `/Applications/Xcode.app`, as
  versioned bundles like `/Applications/Xcode_26.x.app` are common).
- Android SDK: `ANDROID_HOME`, `ANDROID_SDK_ROOT`, or `~/Library/Android/sdk`, containing
  `platform-tools/adb` and `emulator/emulator`.
- A Gradle-compatible JDK (17 or 21). If `JAVA_HOME` is only set in `~/.zshrc` (skipped by
  `/bin/zsh -lc`) or a bleeding-edge JDK (e.g. 27) is installed at `/Library/Java/JavaVirtualMachines`,
  `/usr/bin/java` picks the highest version and crashes Gradle 8.x (`IllegalArgumentException: 27`).
  The bundled scripts and `RunModel` resolve a working JDK via `/usr/libexec/java_home -F -v 21`,
  `-F -v 17`, or `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- `firebase` CLI and `node` only if they use the Firebase gate.

## 1. The window

Dark, two panes, 1120x780, minimum 960x680, `NSAppearance.darkAqua`.

**Sidebar (260 pt):** logo, then a list of apps from `config.json`, each with its icon,
name, and a one-line status: package name when idle; "Running..." (amber) with a spinner;
"Last run failed" (red); or the first config problem (red). Below: "Add app in config.json"
(opens the file), "Reload config", "Rebuild & Relaunch". Switching app is disabled while a run
is in progress for a different app.

**Detail pane, top to bottom:**
1. **Header**: icon, name, `appDir`, pills for the Gradle modules, and the buttons
   **Compile iOS** and **Run on <target>** (primary, ⌘R, disabled while running or with no
   target). Left to right is the workflow: check iOS compiles, then try it on a device.
2. **Run banner**: only when there is something to say. Running (amber): title, the last
   non-empty log line, **Cancel**. Succeeded (green) or failed (red, plus the first diagnostic
   error line: starts with `e: `, contains a bullet, follows `* What went wrong:` or `FAILURE:`,
   or contains `Exception` or `error`), each with a dismiss button.
3. **Firebase strip** (only for apps with a `firebase` block): see below.
4. **"Run on" grid**: targets grouped by kind, as tiles in an adaptive grid (min 230 pt).
   Each tile has an icon, name, detail, and a status dot: green when the target is up and
   ready, amber for "unlock it", grey otherwise. Header has **Refresh**. Empty state says to
   plug in a phone or install an emulator or simulator.
5. **Build-time chart**: last 30 days, average minutes per day, Android vs iOS bars (Swift
   Charts, `BarMark` with `.position(by:)`). Persist records (`platform`, `finishedAt`,
   `duration`) as JSON in UserDefaults, capped at 5,000. Only real device builds and the iOS
   compile check are recorded; a Firebase deploy is not a build.
6. **Output log**: monospaced, selectable, auto-scrolls to the tail, **Copy log**. Cap the
   in-memory log (keep the last ~300,000 characters when it passes 400,000) so a chatty
   Gradle build does not freeze the UI.

Remember the last app and last target in `UserDefaults`.

## 2. Config

`config.json` beside `Runner.app`, else `~/.config/runner/config.json`; `$RUNNER_CONFIG`
overrides. Locate it at run time from the bundle's parent folder so the checkout can move.

```json
{ "apps": [ {
    "name": "My App",
    "appDir": "~/Projects/kmp/MyApp",
    "packageName": "com.me.myapp",
    "debugPackageSuffix": ".dev",
    "androidModule": "androidApp",
    "sharedModule": "shared",
    "iosProject": "iosApp/iosApp.xcodeproj",
    "iosScheme": "iosApp",
    "developmentTeam": "ABCDE12345",
    "firebase": { "project": "my-fb-id", "only": "functions",
                  "testCommand": "node --test functions/*.test.js", "paths": ["functions"] }
} ] }
```

Required: `name`, `appDir`, `packageName`. Everything else defaults as shown (`androidApp`,
`shared`, `iosApp/iosApp.xcodeproj`, `iosApp`, no suffix, project's own team, no Firebase).
Expand `~` so one config works on every Mac. `id` is `packageName`. A config problem
(`no gradlew or kotlin wrapper in <dir>`) is shown on the sidebar row and fails the run with a
readable message rather than failing halfway into a build. Icon: the Play listing icon
(`distribution/android/playstore_metadata/en-US/images/icon.png`) else
`<androidModule>/src/*/res/mipmap-xxxhdpi/ic_launcher.{png,webp}`, else a placeholder.

Every run passes the app settings to the scripts as **environment variables**:
- App: `APP_DIR`, `APP_NAME`, `BASE_PACKAGE` (`packageName`), `PACKAGE` (`packageName + debugPackageSuffix`),
  `ANDROID_MODULE`, `SHARED_MODULE`, `IOS_PROJECT`, `IOS_SCHEME`, optional `DEVELOPMENT_TEAM`.
- Firebase (when `firebase` is configured — required by `deploy_firebase.sh` under `set -u`):
  `FIREBASE_PROJECT` (`firebase.project`), `FIREBASE_ONLY` (`firebase.only`), optional
  `FIREBASE_TEST` (`firebase.testCommand`).
- Target: `SERIAL` | `AVD` | `TARGET_KIND`+`UDID`.

That keeps the scripts runnable by hand from Terminal, which is a feature: tell the user.

**The suffix matters.** In Gradle apps, `installDebug` installs `com.me.myapp.dev` when the
debug build sets `applicationIdSuffix = ".dev"` (launching `com.me.myapp` fails with exit 252).
In `./kotlin` (Kotlin Toolchain / Amper) apps where `applicationIdSuffix` does not exist,
`run_android.sh` compares `PACKAGE` against `BASE_PACKAGE` and automatically rewrites the debug
APK's package name (`aapt2 --rename-manifest-package`), authorities, and launcher label
(`<App> Dev`) and re-signs with `~/.android/debug.keystore` so dev builds install side-by-side
without overwriting Play Store builds.

## 3. Finding targets (`DeviceScanner`)

Run off the main thread (a few hundred ms per tool). Resolve `<sdk>/platform-tools/adb` and
`<sdk>/emulator/emulator` directly from `ANDROID_HOME` / `ANDROID_SDK_ROOT` /
`~/Library/Android/sdk` rather than relying on `PATH` (which lacks Android SDK folders when
launched from Finder/Dock). Return nothing, not an error, for a missing tool. Each target:
`kind`, `key`, `name`, `detail`.

| Kind | How | Notes |
|---|---|---|
| Android phones and running emulators | `adb devices -l` | `adb` ends lines with `\r\n`, so split on `.newlines`, not `"\n"`. For `emulator-*` serials ask `adb -s <serial> emu avd name` (first line) for the friendly name. A phone whose state is not `device` shows "unlock it and allow USB debugging". |
| Android emulators (will boot) | `emulator -list-avds` | Drop ones already running and `INFO` lines. Detail "boots before installing". |
| iOS simulators | `xcrun simctl list devices available -j` | Names beginning "iPhone" on the **newest installed iOS runtime**, plus any already booted on older runtimes. Sort booted first, then name. Parse runtime keys like `...SimRuntime.iOS-18-2`. |
| Paired iPhones | `xcrun devicectl list devices --json-output <tmpfile>` | Parse `result.devices[]`: keep `hardwareProperties.deviceType == "iPhone"` and `connectionProperties.pairingState == "paired"`. Name is `deviceProperties.name`. **Use `hardwareProperties.udid` as `UDID` (never top-level `device.identifier`, which is a CoreDevice UUID that `xcodebuild -destination "id=..."` rejects; `devicectl --device` accepts `hardwareProperties.udid` too).** `connectionProperties.tunnelState == "connected"` (or `"availableForPairing"` / wired) means ready; otherwise "not connected - unlock it, or plug it in". Write the JSON to a temp file and delete it after. |

Default selection when nothing remembered: a live Android device, else a booted simulator,
else the first target. Rescan on launch, on **Refresh**, after every run (an emulator or
simulator may have just booted), and when a `runner://` link arrives. A `--devices` command
line flag prints the list and exits (verification hook).

## 4. Running (`RunModel`)

One process at a time (`guard !isRunning`). `start(app, title, script, env)`:
- Run `/bin/zsh -lc 'export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"; exec /bin/bash "<scriptsDir>/<script>"'`
  with the environment merged as `ProcessInfo.environment` + app env + target env +
  `LC_ALL/LANG=en_US.UTF-8`. Prepend Homebrew **inside** the `-lc` command string because
  `/etc/zprofile` runs `/usr/libexec/path_helper -s` and reorders `/usr/bin` ahead of any
  `PATH` passed in `Process.environment`.
- `standardInput = FileHandle.nullDevice` so a tool that prompts fails fast instead of hanging.
- stdout and stderr to one `Pipe`; `readabilityHandler` appends chunks on the main queue.
- On exit: append `✅ <title>` or `❌ <title> (exit N)`, set state, `NSApp.requestUserAttention`
  (informational on success, critical on failure), rescan targets, record the build time.
- **Cancel** kills the whole process tree: Gradle and xcodebuild are grandchildren. Walk
  `pgrep -P <pid>` recursively, `SIGTERM` all descendants, then the process.
- `scriptsDir` = `Bundle.main.resourceURL/scripts` if it exists, else `<app's folder>/scripts`.

Scripts (copy from this skill's `scripts/`; each has a header documenting its variables):

| Script | What it does |
|---|---|
| `run_android.sh` | Resolves a compatible `JAVA_HOME`, optionally boots the AVD (double-forked so it outlives a Cancel, polls up to 3 minutes, waits for `sys.boot_completed`), verifies the device state, exports `ANDROID_SERIAL`, runs `./gradlew :<module>:installDebug` (or `./kotlin build` + optional `aapt2` `.dev` package rename), then launches by asking the *device* for the launcher activity (`cmd package resolve-activity --brief`), which survives namespace != applicationId; falls back to `monkey`. |
| `run_ios.sh` | Boots the simulator and opens Simulator.app, or for a device adds `-allowProvisioningUpdates` (and `DEVELOPMENT_TEAM` if set). `xcodebuild ... -derivedDataPath build/runner/<kind> build`, finds the `.app`, reads `CFBundleIdentifier` with PlistBuddy (iOS bundle id can differ from the Android package), installs and launches via `simctl` or `devicectl`. Prints targeted advice on failure (signing for devices; minimum iOS for simulators). |
| `compile_ios.sh` | Resolves `JAVA_HOME`, then runs `./gradlew :<shared>:compileKotlinIosSimulatorArm64 --stacktrace` (or `./kotlin build -m iosApp -p iosSimulatorArm64`). The fast "does iOS still compile?" check, no Xcode. |
| `deploy_firebase.sh` | Optional. Runs `FIREBASE_TEST` (and writes Publisher's shared `tests/<packageName>-<sha>` marker when clean), then `firebase deploy --only <target> --project <id> --non-interactive`. |

Make `build/runner/` ignorable: tell the user to add it to the app's `.gitignore`.

## 5. Firebase gate (optional; skip if no app has a backend)

Purpose: a phone running new app code against a stale backend gives confusing failures that
look like app bugs. Before Run on a device, check whether the backend is behind, and offer to
deploy first.

**State** (`FirebaseState`), computed from git on a background thread:
- `last` = the most recent record for this app in the deploy log (below).
- `commits` = `git log --oneline <last.commit>..HEAD -- <paths>` (or `-5` if never deployed).
- `uncommitted` = `git status --porcelain -- <paths>`.
- `behind` = never deployed, or any commits, or any uncommitted files.

**Deploy log**: JSON array of `{ id, commit, date }` (ISO-8601 dates, `id` = the app's
`packageName`, i.e. `BASE_PACKAGE`, without `debugPackageSuffix`) at
`~/Library/Application Support/Publisher/firebase_deploys.json`. This is the path
`build-publisher` uses, on purpose: a deploy from either app marks the backend current in the
other. Parse dates tolerantly (try `ISO8601DateFormatter` both with and without
`.withFractionalSeconds` so records written by either app decode cleanly). Read it fresh each
time (the other app may have written it), and append on success (read, add, write atomically).
Record the **HEAD sha captured when the deploy started**, not when it ended. `deploy_firebase.sh`
also touches `~/Library/Application Support/Publisher/tests/<packageName>-<sha>` when
`FIREBASE_TEST` passes on a clean tree so Publisher's Shared readiness gate sees the test run.

**Strip** (above the run grid): green check "Firebase functions are up to date", or amber
warning "need a deploy" / "not deployed yet", with a detail line (`Deployed <date> · <sha7> ·
2 commits since · 1 uncommitted file`) and a **Deploy functions** button. The button always
confirms (critical-style alert: "This updates the live backend that every installed copy of
<app> uses", warns about uncommitted changes, names the test command).

**Run gate**: when Run is pressed and the state is behind, show an alert naming the commits
(up to 5) and the uncommitted warning, with buttons **Deploy, then run**, **Run anyway**,
**Cancel**. "Deploy, then run" starts the deploy and, only if it succeeds, starts the run
(bypass the gate on the second step, or uncommitted backend files would re-trigger it forever).
A failed test or deploy stops the chain. Refresh the state after every run and when the app is
selected or a link arrives.

## 6. Links

`runner://open?app=<packageName>`: reload config, select that app, rescan targets, show the
window. Operator sends this from its ▶ Run button (see `build-operator`). The window stays
alive with no windows open (`applicationShouldTerminateAfterLastWindowClosed` false) so a
build keeps going and the link reopens it instantly. Also handle `applicationShouldHandleReopen`.

## 6a. Inside Appos

Follow recipe §9. For Runner specifically:

- `Config.repoDir` is a settable `static var`; `RunnerEmbed(repoDir:)` sets it before creating
  `RunModel`. Use the bundled `scripts/` only when the bundle id is Runner's own.
- `RunnerDefaults.store` replaces `UserDefaults.standard` for `lastApp`, `lastTarget` and
  `buildRecords`, so the build-time chart is the same in both apps.
- `ContentView(model:, embedded: true)` hides the sidebar; `minWidth` becomes 700.
- `RunnerEmbed.show(package:)` reloads config and selects the app. While a run is going for a
  *different* app it refuses and returns false, the same rule that disables the standalone
  sidebar rows. `runningPackage` and `failedPackage` drive the spinner and the "Last run
  failed" note in Appos's list.
- The ⌘R shortcut on Run still works inside Appos, because it lives on the button.

## 7. Files to write

```
Sources/RunnerKit/  RunnerMain.swift (public entry point, + --devices)  AppDelegate.swift
                    Config.swift  Devices.swift  RunModel.swift  Firebase.swift  ContentView.swift
                    Theme.swift  RebuildLauncher.swift  Embed.swift (RunnerEmbed, RunnerDefaults)
Sources/Runner/     main.swift: `import RunnerKit; RunnerMain.main()`
scripts/            run_android.sh run_ios.sh compile_ios.sh deploy_firebase.sh   (copy from this skill)
config.json  Package.swift (Kit + app, see recipe §1)  build.sh (copies scripts/*.sh into the bundle)
rebuild.sh  .gitignore
```

Don't name the public entry point `RunnerApp`: that's the config model's type name, and the
clash breaks the whole module.

Layout: the header (with **Run**) and the run banner stay pinned. Below them a single
`ScrollView` holds the Firebase strip, the target grid, the log (fixed 300 pt) and the chart,
so the window can shrink to ~420 pt tall and still reach everything. Don't give the target
grid its own height-capped scroll box: with phones listed last, a real iPhone ended up out of
sight. List targets in `Target.Kind` declaration order with **real phones first**: iPhones,
then Android phones and running emulators, then bootable emulators, then simulators. The
kind's raw value is part of the saved target id, so reorder the cases but don't reword them.
The header shows Runner's gem (`Gem("runner")`, see `build-appos`).

Theme: a warm near-black palette with one amber accent and status colors that differ in
lightness as well as hue (so they read for color-blind users). Ground `#111210`, surface
`#1A1B18`, line `#2E2F2A`, text `#F1EEE6`, muted `#A9A597`, accent/warn `#F2B23A`, ok
`#5CCB8C`, bad `#FF7A59`. Build small `Card`, `Pill`, `StatusDot`, `Eyebrow` and button
styles (primary, quiet, link) instead of repeating modifiers.

## 8. Build, verify

1. `./build.sh`; fix compile errors.
2. `Runner.app/Contents/MacOS/Runner --devices` lists the user's real devices. Show them.
3. `open Runner.app`, select an app, press **Compile iOS** (safe, no device needed) and show
   the result. Only press **Run** on a device the user has named; builds are slow and a
   physical phone must be unlocked.
4. Common failure triage to relay: exit 252 (suffix), "unauthorized" (accept the USB-debugging
   prompt), Gradle JDK errors (set `JAVA_HOME`), iOS signing (open the project in Xcode once,
   pick a team), simulator "Unable to find a destination" (pick a newer iOS).
5. If a Firebase gate is configured, verify it **without deploying**: show the strip's state
   and the Run dialog, then Cancel. Never run a real `firebase deploy` as a test.

## 9. Don'ts

- Don't commit, push or publish from Runner.
- Don't run `firebase deploy` unless the user pressed Deploy and confirmed.
- Don't store credentials; the scripts read everything from env and the project.
- Don't block the main thread on adb/simctl/git.
