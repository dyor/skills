---
name: android-review
description: Conducts an exhaustive, rigorous Android code review following Android Studio principal code review standards, and doubles as an Android pre-release gate ("/android-review for release"). Dynamically checks installed domain skills, discovers missing skills from android/skills and firebase/agent-skills, cross-references official Android documentation via the android CLI (`android docs`), audits main thread safety, lifecycle leaks, coroutines, platform interop, and actionable fix generation, and for releases verifies R8 on a minified build that actually runs, scans for committed API keys/secrets, and flags unfinished code. When a review is heading to Google Play, also checks https://google.play/business/vitals/ for current Android Vitals bad-behavior thresholds and runs a constrained Play-review emulator pass with embedded screenshots in the final report. For Kotlin Multiplatform apps use kmp-review instead.
version: 1.3.1
---

# Android Change Review

Conduct an exhaustive, critical, and architecture-first code review for Android and Kotlin Multiplatform (KMP) codebases, modeled directly on the Android Studio principal code reviewer persona and evaluation methodology.

This skill integrates three specialized pillars:
1. **Installed Skills Base Activation:** Scans local project and IDE skills to apply domain-specific rules (e.g., CameraX, Media3, Edge-to-Edge, Compose Navigation, R8, Profiler).
2. **Discoverable Remote Skills Auditing:** Cross-references changes against authoritative remote repositories (`https://github.com/android/skills` and `https://github.com/firebase/agent-skills`) to identify relevant uninstalled skills and recommend their installation.
3. **Official Android Documentation Lookup:** Uses `search_android_docs` and `fetch_android_docs` to verify platform contracts, deprecations, threading models, and OEM variations against authoritative documentation.

---

## What Exists vs. What This Skill Provides

- **Existing general skill (`requesting-code-review`):** Focuses on subagent coordination and generic git SHA review (web, backend, CLI). It lacks Android-specific lifecycle audits, threading/ANR rules, Jetpack Compose patterns, and Kotlin Multiplatform native runtime constraints.
- **`android-review` (this skill):** Tailored specifically for Android and KMP. It provides a systematic multi-pass audit checklist covering Android OS lifecycles, main thread safety, coroutines, platform interop (JNI/cinterop), dynamic skill discovery, official documentation retrieval, and formats findings into actionable, standardized fix tickets.

---

## Review Methodology: 6-Phase Process

### Phase 0: Skills & Documentation Discovery (The Knowledge Mesh)

Before auditing diffs, assemble the domain-specific knowledge required for the review:

#### 1. Installed Android Skills Base Inspection
- Inspect the active skills list available in the environment (e.g. in `~/.android-studio/skills/`, `~/.agents/skills/`, or the active agent skills registry).
- Identify installed skills whose domains intersect with the modified code:
  - **Camera / Video Recording:** `camerax`, `media3-cast-integration`
  - **UI / Layout / Gestures:** `edge-to-edge`, `adaptive`, `styles`, `navigation-3`, `navigation-event`
  - **Permissions & Security:** `android-permissions-policy`, `play-policy-insights`, `verified-email`, `restore-credentials`
  - **Performance & Build:** `android-profiler`, `r8-analyzer`, `testing-setup`
  - **Specialized Form Factors:** `wear-compose-m3`, `leanback-to-compose-tv-migration`, `display-glasses-with-jetpack-compose-glimmer`
  - **Firebase / Cloud Services:** `firebase-firestore`, `firebase-auth-basics`, `firebase-crashlytics`, `firebase-basics`, etc.
  - **On-Device AI:** `appfunctions`, `ml-kit-genai-prompt-api`
- When relevant, read the skill definition (`read_file`) to load its specific constraints, anti-patterns, and validation rules into the review context.

#### 2. Discoverable Remote Skills Audit
- Cross-reference the subsystems touched in the change against official remote skill catalogs:
  - **Official Android Skills:** `https://github.com/android/skills` (e.g., `android-intent-security`, `agp-9-upgrade`, `android-cli`)
  - **Official Firebase Skills:** `https://github.com/firebase/agent-skills/tree/platform/android-studio/skills` (e.g., `firebase-remote-config`, `firebase-app-check`)
- If a change touches an area where a specialized skill exists on the remote repository but is **not installed**:
  - Flag the discoverable skill in the review overview.
  - Provide the exact installation command:
    - For Android skills: `android skills add <skill-name>`
    - For Firebase skills: `npx -y skills add firebase/agent-skills --agent android_studio --skill <skill-name>`
  - Apply the known principles of that skill to the review findings.

#### 3. Authoritative Android Documentation Retrieval
- For any platform API, Jetpack component, or hardware use-case involved in the change:
  - Invoke `search_android_docs` with targeted keywords (e.g., `MediaMetadataRetriever HAS_AUDIO`, `CameraX QualitySelector`, `AVAudioSession category options`, `Compose DisposableEffect`).
  - Use `fetch_android_docs` to read relevant `kb://` documentation articles.
  - Ground technical criticisms in official documentation (citing API levels, deprecations, and documented behavior).

---

### Phase 1: Context & Boundary Analysis
1. **Understand Intent & Subsystems:** Trace data flow and component boundaries across layers (UI/Compose, ViewModel, Repository/Domain, Platform/Hardware drivers).
2. **Whole-File Reads & Deep Inspection:** Read entire source files or large chunks (1,000+ lines). Never evaluate diff hunks in complete isolation from call sites, lifecycles, and surrounding state.
3. **Trace Concurrency & Resource Ownership:** Track which thread or dispatch queue executes each operation, where resources (cameras, microphones, decoders, file handles) are allocated, and where cleanup occurs.

---

### Phase 2: Systematic Audit Checklist

Scrutinize every modified file against these Android and KMP failure modes:

#### 1. Main Thread Safety & ANR Prevention
- **Blocking I/O:** Any synchronous file access, database queries, SharedPreferences/DataStore disk reads, or media header probing (e.g. `AVURLAsset`, `MediaMetadataRetriever`) executed on the Main thread (`Dispatchers.Main` / `dispatch_get_main_queue()`).
- **Heavy Computations:** CPU-intensive image processing, compression, cryptography, or parsing performed without offloading to `Dispatchers.Default` / `Dispatchers.IO`.

#### 2. Android Lifecycle & Memory Leaks
- **Context & Activity Leaks:** Storing `Context`, `Activity`, `Fragment`, or `View` references inside ViewModels, singletons, coroutine jobs, or background closures.
- **Resource Cleanup in Lifecycle Events:** Failure to release cameras, hardware decoders, audio taps, location listeners, or sensors in `onStop`, `onDestroy`, `DisposableEffect.onDispose`, or `awaitClose`.
- **Configuration Change Resilience:** Whether essential UI state survives activity recreation or process death (via `rememberSaveable`, `SavedStateHandle`).

#### 3. Concurrency, Coroutines & Kotlin/Native Memory
- **Thread Safety of Collections:** Unsynchronized mutable collections (`mutableSetOf`, `mutableListOf`, `HashMap`) accessed or mutated across threads or dispatch queues. On Apple targets in KMP, unsynchronized mutations cause fatal memory corruption.
- **Structured Concurrency:** Unmanaged `CoroutineScope` instantiation, missing `SupervisorJob`, or launching long-running work inside ephemeral composables without cancellation handling.
- **Cancellation & Failure Propagation:** Coroutines catching `CancellationException` and failing to rethrow; failure to clean up in-flight background state when a coroutine or deferred awaits abort.

#### 4. Platform & Interop Hazards
- **Native Exceptions in Kotlin/Native:** `runCatching` in Kotlin/Native catches Kotlin `Throwable` but **does not catch Objective-C `NSException`s**. Calling AVFAudio/CoreAudio APIs (e.g. `removeTapOnBus` when no tap is installed) triggers uncaught process crashes.
- **JNI / C-Interop References:** Failure to release pinned memory, native pointers, or local references; missing null checks on nullable platform lookups.
- **Device & OEM Divergence:** Relying on strict string matches from device metadata (e.g. `MediaMetadataRetriever` keys) instead of defensive checks that accommodate manufacturer variations.

#### 5. Encapsulation, Wake Locks & Play Vitals Thresholds
- **State Flow Exposure:** Exposing `MutableStateFlow` or `MutableList` publicly instead of read-only `StateFlow` / immutable `List`.
- **Contract Adherence & Nullability:** Respecting nullability contracts (e.g. returning `null` when a probe is indeterminate rather than fabricating `true` or `false`).
- **Wake Locks & Foreground Services (Android Vitals):** Unconditional or multi-hour `PARTIAL_WAKE_LOCK` acquisitions held while paused/idle (violating Play Vitals' 1-hour Stuck Wake Lock and 2-hour/24h Excessive Partial Wake Locks thresholds), or `startForegroundService` calls risked while `Dispatchers.Main` is congested (`ForegroundServiceDidNotStartInTimeException` on Android 14+).

---

### Phase 2.5: Google Play Release Gate — Live Vitals Check & Constrained Emulator Pass *(Play Releases Only)*

> **Scoping Rule:** **Skip Phase 2.5 on routine day-to-day PR, feature, or WIP code reviews.** Run Phase 2.5 **ONLY** when the changeset is heading to Google Play (e.g., invoked from `play-prepublish-check`, preparing an `internal`/`closed`/`production` Play upload, triaging a Play Store rejection, or when the user asks for a Play / release readiness review).

#### 1. Live Google Play Vitals Audit (`https://google.play/business/vitals/`)
Before building or signing off on a Play release, fetch/check **`https://google.play/business/vitals/`** (and its linked **"See all Android vitals metrics"** reference at `https://support.google.com/googleplay/android-developer/answer/9844486`) so the review reflects Google Play's latest Core Vitals and bad-behavior thresholds rather than stale assumptions. Audit the app against every active Play Vitals dimension:
- **Stability Core Vitals:** User-perceived ANR rate (`< 0.47%` overall, `< 8%` per device model — input dispatching >5s) and User-perceived Crash rate (`< 1.09%` overall, `< 8%` per device model), plus R8 `proguard.map` / native symbol bundling inside the AAB.
- **Battery & Wake Locks Core Vitals:** Excessive partial wake locks (`> 2–3h` cumulative background wake lock in 24h across `> 5%` of sessions) and Stuck partial wake locks (`>= 1h` continuous background lock). Confirm pause grace locks are bounded (e.g. `<= 5 min`) and active playback relies on audio-exempt APIs (`ExoPlayer.setWakeMode`).
- **Memory & LMK Vitals:** User-perceived Low Memory Kills (LMK), Anonymous RSS + Swap, and **Bitmap Memory Usage** (ensure Coil/Glide requests specify `.size(...)` bounds rather than decoding full `3000×3000` `ARGB_8888` covers, and avoid eager startup allocation of giant dictionaries/models).
- **Startup & UI Rendering Vitals:** Slow cold (`>= 5s`), warm (`>= 2s`), and hot (`>= 1s`) starts; Excessive slow frames (`> 50%` frames `> 16 ms`, including *Slow bitmap uploads > 3.2 ms* and *Slow UI thread > 8 ms*); and Excessive frozen frames (`> 0.1%` frames `> 700 ms`).
- **Background Wake-ups, Scans, Network & Permission Denials:** Excessive `AlarmManager` wake-ups (`RTC_WAKEUP` / `ELAPSED_REALTIME_WAKEUP`), background Wi-Fi scans (`> 4/hr`), unprompted background mobile network usage (`> 50 MB/day`), and cold-launch runtime **Permission denials** (e.g. requesting `POST_NOTIFICATIONS` on cold `onCreate` before user context).

#### 2. Constrained Play-Review Device Pass & Screenshot Capture
Validate the live runtime experience on an Android emulator matching **Google Play's constrained review virtual device**:
- **Constrained Play-Review Emulator Profile:** Boot an AVD with **2 GB RAM (`hw.ramSize=2048`)**, **256 MB ART heap ceiling (`vm.heapSize=256`)**, `google_apis_playstore` system image (prefer `ps16k` 16 KB page size when installed), and **no flagship-only AI hardware** (no Gemini Nano / Google AICore). Install the **R8-minified release build** whenever signing is configured (otherwise debug **without** any QA fixture/model-seeding flags).
- **Four Mandatory Runtime Probes:**
  1. **Probe A — Cold Launch & Baseline Heap:** Verify clean first frame (`< 5s` cold start, no cold-launch permission modal trap) and record `adb shell dumpsys meminfo <package>` against the 256 MB heap limit.
  2. **Probe B — Heavy Real Payload & Input Responsiveness (ANR Check):** Open the heaviest real-world screen/feed (e.g. 4–5 MB XML/JSON responses, 500+ item `LazyColumn`, 3000×3000 remote artwork) and tap controls during load to verify zero UI freezes or `am_anr` events (`dumpsys gfxinfo <package>`).
  3. **Probe C — Unavailable / Missing On-Device Model UX (`Broken Functionality` Check):** Exercise every feature backed by an on-device model (ML Kit GenAI / AICore, ML Kit Translate/Vision, downloadable ONNX/TFLite weights, local TTS) on this clean non-AICore device **before** optional downloads or where `FeatureStatus.UNAVAILABLE` is returned. Confirm graceful degradation with a working fallback path — **never** a crash, infinite spinner, or dead-end error screen.
  4. **Probe D — Pause / Lock-Screen / Wake-Lock Audit:** Start and pause playback/background work, then inspect `adb shell dumpsys power` and `dumpsys media_session` to confirm bounded wake locks (`<= 5 min` pause grace) and working headset/media-button resumption.
- **Capture & Embed Screenshots:** Capture PNG screenshots at each probe (`android screen capture` or `adb exec-out screencap -p > <reportDir>/<step>.png`; copy into `<artifactDir>/` when writing an artifact report) and embed every screenshot (`![Caption](/absolute/path/to/shot.png)`) in the final report.

---

## Phase 3: Review Document Structure

Generate the review output using this standard Markdown format *(include the `Google Play Vitals & Constrained-Device Verification` section ONLY when Phase 2.5 applies)*:

```markdown
# [Concise, Descriptive Title for Overall Changeset]

## Overview
[A comprehensive technical summary of what the changes accomplish, the subsystems affected, the problem solved, and the architectural approach. Include ASCII diagrams for complex multi-threaded or multi-component handoffs.]

### Active Domain Skills Applied
- `[skill-name]`: [How its guidelines were applied to this review]

### Discoverable Skills Recommended
- `[skill-name]` (`https://github.com/...`): [Why it is relevant and how to install it via CLI]

### Authoritative Documentation Consulted
- [Document Title](kb://... or URL): [Relevant API contract or threading model verified]

## Google Play Vitals & Constrained-Device Verification *(Play Releases Only)*
- **Live Vitals Audit (`https://google.play/business/vitals/`):** [Pass/Warn summary across Crash/ANR, Wake Locks, LMK & Bitmap Memory, Cold Start, Slow/Frozen Frames, Background Network/Wake-ups, and Permission Denials]
- **Device Profile:** [AVD name · API level · RAM / `vm.heapSize` · Page size · AICore/Model availability · Build variant (Release R8 / Debug unseeded)]
- **Memory, Frame & Wake-Lock Telemetry:** [`dumpsys meminfo` heap peak, `dumpsys gfxinfo` frozen frames, `am_anr` check, `dumpsys power` wake-lock bounds]
- **Missing / Unsupported Model UX:** [What happens when on-device AI/ML models cannot run or aren't downloaded on the review device]

| Probe | Scenario Tested | Verdict | Screenshot |
| :--- | :--- | :--- | :--- |
| 1. Cold Launch | [Summary] | PASS / FAIL | ![Cold Launch](/absolute/path/to/01_cold_launch.png) |
| 2. Heavy Payload / ANR Check | [Summary] | PASS / FAIL | ![Heavy Payload](/absolute/path/to/02_heavy_payload.png) |
| 3. Missing Model Fallback UX | [Summary] | PASS / FAIL | ![Model Fallback](/absolute/path/to/03_model_fallback.png) |

## Global Fixes and Criticisms
[List EVERY issue, bug, or deficiency found. Order by severity: Critical/Major -> Important/Moderate -> Minor/Trivial. Structure each finding with:]

### [Issue Number]. [Descriptive Title Identifying Flaw and Component]
- **Component:** [file-path#lines]
- **Technical Problem & Root Cause:** [Deep technical explanation of why it fails]
- **Runtime Impact & Failure Scenario:** [ANR, process crash, race condition, data corruption, silent failure]
- **Recommended Fix:** [Concrete explanation + valid unified diff]

```diff
--- /path/to/File.kt
+++ /path/to/File.kt
@@ -10,3 +10,4 @@
  existingCode()
+ replacementCode()
```
```

---

## Phase 4: Actionable Fix Tickets (Standard 5-Section Format)

For downstream tooling, AI subagents, or human executors, format each fix as a self-contained ticket:

```markdown
### Fix [N]: [One-Sentence Summary]
**Severity:** [MAJOR | MODERATE | MINOR | TRIVIAL]
**Location:** `/absolute/path/to/File.kt:startLine-endLine` (root cause location only)

#### 1. Problem Definition & Context
- Describe the exact bug, race condition, or lifecycle flaw.
- Detail the expected vs. actual behavior and symptoms (crash, ANR, silent drop).

#### 2. Investigation Scope
- File paths, classes, and methods directly involved in the root cause.

#### 3. Strict Scoping Rules
- Strict command forbidding drive-by refactors or unrelated formatting changes.
- Focus strictly on resolving the targeted defect.

#### 4. Required Cleanup
- Dead code removal, unused import pruning, lock release in `finally` blocks, idempotent teardown.

#### 5. Test Alignment
- Exact unit test, instrumented test, or compiler task to run and verify the fix.
```

---

## Phase 5: Release Gate (run when the user says "for release", "ready to ship", or similar)

A review of the diff is not a release check. For a release, also do all of this, then end
with a verdict (SHIP / SHIP AFTER FIXES / BLOCK). KMP apps: use `kmp-review`, which
includes this gate plus commonMain/iOS checks.

### 5.1 Mechanical scan
```bash
~/.claude/skills/android-review/scripts/release_scan.sh <appDir> [androidModule] [baseRef]
```
Exit 1 = at least one FAIL. Covers R8 settings, secrets/API keys (tracked files and git
history), unfinished code (stubs, TODOs, placeholders, dev URLs, empty handlers, ignored
tests), manifest hygiene and pre-release dependencies. Triage each WARN/FAIL by opening the
file; the script is a pattern match (public Firebase client keys are normal, a server key
in `.env` is not). With a built AAB, also run
`~/.claude/skills/play-prepublish-check/scripts/prepublish_check.sh <appDir> [module] [aab]`.

### 5.2 R8: enabled AND exercised
- Release build has `isMinifyEnabled = true`, `isShrinkResources = true`, and
  `proguard-android-optimize.txt` plus the app's `proguard-rules.pro`; no blanket
  `-keep class **` or `-dontwarn **`.
- Build `bundleRelease`; confirm `mapping.txt`; read `missing_rules.txt` if present.
- Install the minified build and exercise sign-in, purchases, every JSON decode path
  (kotlinx.serialization/Gson/Moshi), DI-injected screens (Koin/Hilt), Firebase reads,
  camera/media, deep links and any reflection. `adb logcat -b crash` stays empty.
- Use the `r8-analyzer` skill if installed (`android skills find r8`); otherwise note it
  as a discoverable skill. Compare size with the previous release.

### 5.3 Skills to invoke
Beyond Phase 0: list which installed/discoverable skills apply to the release
(`android skills list`, `android skills find <keyword>`), plus local dyor skills:
`google-play-publishing` and `play-prepublish-check` for Play, `adapty-store-payments` for
purchases, `febak-site-pages` for privacy/terms pages. Give exact install commands for
missing ones.

### 5.4 Docs via the android CLI
```bash
android docs search "<keywords>"      # then
android docs fetch kb://<id>
```
One search per distinct API/policy in the diff (target SDK requirements, foreground
service types, permission changes, deprecated APIs). If `android` is not installed, follow
the `android-cli` skill. Cite what you found in "Authoritative Documentation Consulted".

### 5.5 Secrets and API keys
Beyond the script: grep the diff for new keys, confirm `local.properties`, keystores and
`.env` files are ignored and were never in history (`git log --all -- <path>`), check
`BuildConfig` fields do not embed server secrets (they ship in the APK), and confirm
public client keys (Maps, Firebase) are restricted by package + SHA-1 in Cloud Console.
A secret that was ever committed must be rotated; deleting it from HEAD is not enough.

### 5.6 Anything not fully implemented
Every `TODO()`, `NotImplementedError`, "coming soon", empty `onClick`, disabled-but-visible
control, `@Ignore`d test and hard-coded/mock data path in production sources is either
finished, hidden from users, or consciously shipped (say which and why). Dead ends a user
can reach are MAJOR findings.

### 5.6b Version naming

Confirm the version follows the release-naming convention (`MAJOR.MINOR (BUILD)` first attempt,
`MAJOR.MINOR.BUILD (BUILD)` retry; see build-publisher "Release naming") and that the build
number is above the highest on either store (Play and App Store Connect).

### 5.7 Verdict
Write `SPECS/android-review-<date>.md`: scan table with triage, R8 run result, skills,
docs, findings (Phase 3/4 format), "Not verified" (what you could not run), release facts
(versionCode above Play, release notes, backend deploys). Any open FAIL, MAJOR finding or
unrun minified build = BLOCK. Never print a full secret; show file, line, first 4 chars.

---

## Review Guardrails

- **Zero Artificial Capping:** Never stop reviewing after discovering 2 or 3 bugs. Production PRs often contain 5 to 10+ distinct defects across different layers. Document every legitimate issue.
- **No Trivial Nitpicking:** Do not create tickets for missing routine KDoc or standard formatting unless an architectural invariant or threading contract is undocumented.
- **Root Cause Targeting:** Location references must point exclusively to where the defect originates, never downstream call sites that would merely adapt to an API update.
- **Valid Diffs:** Ensure unified diffs in code blocks include standard file headers (`--- ...`, `+++ ...`) and valid hunk headers with accurate line offsets.
