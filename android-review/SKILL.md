---
name: android-review
description: Conducts an exhaustive, rigorous Android and Kotlin Multiplatform (KMP) code review following Android Studio principal code review standards. Dynamically checks installed domain skills, discovers missing skills from android/skills and firebase/agent-skills, cross-references official Android documentation via search_android_docs, and audits main thread safety, lifecycle leaks, coroutines, platform interop, and actionable fix generation.
---

# Android Code Review

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

## Review Methodology: 5-Phase Process

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

#### 5. Encapsulation & API Contracts
- **State Flow Exposure:** Exposing `MutableStateFlow` or `MutableList` publicly instead of read-only `StateFlow` / immutable `List`.
- **Contract Adherence & Nullability:** Respecting nullability contracts (e.g. returning `null` when a probe is indeterminate rather than fabricating `true` or `false`).

---

## Phase 3: Review Document Structure

Generate the review output using this standard Markdown format:

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

## Review Guardrails

- **Zero Artificial Capping:** Never stop reviewing after discovering 2 or 3 bugs. Production PRs often contain 5 to 10+ distinct defects across different layers. Document every legitimate issue.
- **No Trivial Nitpicking:** Do not create tickets for missing routine KDoc or standard formatting unless an architectural invariant or threading contract is undocumented.
- **Root Cause Targeting:** Location references must point exclusively to where the defect originates, never downstream call sites that would merely adapt to an API update.
- **Valid Diffs:** Ensure unified diffs in code blocks include standard file headers (`--- ...`, `+++ ...`) and valid hunk headers with accurate line offsets.
