---
name: execute-and-report-journey
description: Executes a UI Journey (from a `.journey.xml` file or a Markdown `JOURNEY_SPEC.md` specification) across Android, iOS, or dual-OS (KMP/CMP/React Native/Native-Native) apps, visually audits every captured screenshot for layout/clipping/runtime defects, supports both Self-TDD Repair and Adversarial Review modes, and writes a Markdown report with Before/After screenshot comparisons.
version: 2.0.0
author: dyor
---

# `execute-and-report-journey` Skill

Executes a structured end-to-end UI Journey against a live running app (Android Emulator/Device, iOS Simulator/Device, or both side-by-side), **visually inspects every captured screenshot** (never blind-capturing), audits real-device failure paths, and produces a persistent Markdown Journey Report in `.journey_reports/<journey_name>/latest/report.md` with **Before / After** image tables whenever defects are repaired.

---

## 1. Supported Inputs & Operating Modes

### Journey Input Sources
A journey may be defined by **either**:
1. **XML Journey File (`.journey.xml`):** e.g., `app/src/journeys/01_onboarding.journey.xml` (`<journey><actions><action>...</action></actions></journey>`).
2. **Markdown Journey Specification (`JOURNEY_SPEC.md` or inline spec):** Ordered user-flow steps, expected visual states, and platform/hardware invariants to verify at the end of a feature stage.

### Two Operating Modes
1. **Builder TDD Mode (Default):** The authoring agent runs the journey, inspects screenshots, fixes any failing application code (at least 1–3 retries without weakening the journey), and emits a **Before / After** report showing the broken vs. repaired screens.
2. **Adversarial Reviewer Mode (Cross-Agent Gate):** A separate reviewer agent executes the journey **read-only against production code**, captures and visually audits every screenshot, performs a hostile code review for physical-device traps masked by virtual-device fixtures, and writes `.journey_reports/<journey_name>/latest/report.md` plus `.journey_reports/<journey_name>/latest/verdict.json` (`{"passed": false, "defects": [...]}`) so the builder agent can remediate and produce the **Before / After** comparison on the follow-up pass.

---

## 2. Platform Execution & Screenshot Capture Primitives

Use whichever toolset matches the active project and environment:

- **Android (IDE MCP or CLI):**
  - *Inspect UI hierarchy:* `ui_state` (IDE) or `android layout` / `adb -s <serial> shell uiautomator dump /sdcard/ui.xml && adb -s <serial> cat /sdcard/ui.xml`.
  - *Interact:* `adb_shell_input` (IDE) or `adb -s <serial> shell input tap/text/swipe ...`.
  - *Capture clean binary PNG:* `adb -s <serial> exec-out screencap -p > .journey_reports/<journey_name>/latest/images/step_<NN>_android.png` *(prefer `exec-out screencap -p` over `shell screencap -p` to avoid CRLF byte corruption)*.
- **iOS Simulator (CLI / XCUITest):**
  - *Interact & capture via XCUITest:* Record `XCTAttachment(screenshot: app.screenshot())` with `.keepAlways` and export via `xcrun xcresulttool export attachments --path <bundle.xcresult> --output-path <dir>`, **or** drive the booted Simulator and run:
  - *Direct Simulator capture:* `xcrun simctl io <udid|booted> screenshot .journey_reports/<journey_name>/latest/images/step_<NN>_ios.png`.
- **Dual-OS Projects (KMP, Compose Multiplatform, Native-Native Monorepo, React Native / Expo):**
  - Capture **both** `step_<NN>_android.png` and `step_<NN>_ios.png` for every journey step and audit cross-platform visual & functional parity side-by-side.

---

## 3. Step-by-Step Workflow

### Step 1 — Archive Previous Run & Initialize Directories
1. If `.journey_reports/<journey_name>/latest/images/` already contains screenshots from a prior (failed/pre-fix) run and has not been archived yet, archive it first so it becomes the **"Before"** baseline:
   ```bash
   TS="$(date '+%Y-%m-%d-%H-%M')"
   mkdir -p ".journey_reports/<journey_name>/archive/$TS"
   cp -R .journey_reports/<journey_name>/latest/* ".journey_reports/<journey_name>/archive/$TS/" 2>/dev/null || true
   ```
2. Reset `latest/`:
   ```bash
   rm -rf .journey_reports/<journey_name>/latest/
   mkdir -p .journey_reports/<journey_name>/latest/images/
   ```

### Step 2 — Execute Each Journey Action & Visually Inspect Every Screenshot (MANDATORY)
For each step in the `.journey.xml` or `JOURNEY_SPEC.md`:
1. Drive the app to the target state and verify functional behavior.
2. Save the screenshot(s) into `.journey_reports/<journey_name>/latest/images/`.
3. **MANDATORY VISUAL INSPECTION (`read_file` on the PNG):** Never assume a step passed just because an assertion or command exited `0`. Open and look at the captured image(s) with `read_file` and check every item on this **Visual & UX Defect Checklist**:
   - **Horizontal / Vertical Clipping & Overflow:** Are characters, cards, or buttons clipped at the left/right/bottom screen edges? *(Watch out for `.scaledToFill()` on `1:1` square images inside unconstrained SwiftUI `ZStack`s or wide bottom docks exceeding `393pt`/`412dp`!)*
   - **Awkward Wrapping & Collisions:** Do pill badges or button titles wrap onto 2 lines (`"1/3 ·\nEspañol"`, `"Hear it\nslowly"`)? Do overlaid badges cover artwork text? Does content collide with the Dynamic Island, status bar, or gesture navigation bar?
   - **Error Banners, Blank States & Grammar:** Are there red/amber error banners, stuck spinners, raw `—` / empty translation placeholders, or `"1 phrases"` pluralization bugs?

### Step 3 — Hostile Real-Device Code Audit (When Virtual Fixtures Are Used)
Simulators and Emulators often bypass real hardware pipelines (e.g., offline ASR/Translation packs, real VBR MP3 trailing frames, runtime permissions, modal sheet presentation). Before marking a journey `PASSED`, audit the production source code for:
1. **Media/File EOF Resilience:** Real-world MP3s with ID3/VBR headers often report `AVAudioFile.length` slightly larger than decodable frames; unguarded `try file.read()` near EOF must be treated as end-of-stream rather than cancelling the entire pipeline.
2. **Runtime Permissions & Resource Quotas:** Verify explicit permission requests (`SFSpeechRecognizer.requestAuthorization`, Android runtime permissions) and quota eviction (`AssetInventory.maximumReservedLocales`).
3. **Modal Lifecycle Conflicts:** Verify `.translationTask` or system prompts are not attached to a background view occluded by `.fullScreenCover` / `.sheet`.
4. **Background / Lock-Screen & Voice Fallbacks:** Verify foreground service / audio keep-alive continuity and safe fallback when only compact/monolingual TTS voices are installed.

### Step 4 — Failure & Repair Loop
- **In Builder TDD Mode:**
  - Do **NOT** weaken or alter the journey spec to force a pass.
  - Archive the failing `latest/` run (Step 1), fix the **application code**, rebuild/redeploy, and re-run the journey (up to 2–3 repair attempts; if still failing, stop and report clearly to the user).
- **In Adversarial Reviewer Mode:**
  - Do **NOT** edit application source files. Record every visual and code-level defect with exact file/line citations and screenshot evidence in `report.md` and write `.journey_reports/<journey_name>/latest/verdict.json`:
    ```json
    {
      "passed": false,
      "score": 71,
      "defects": [
        {
          "severity": "critical",
          "category": "device_pipeline",
          "file": "BuenDia/Services/OnDeviceTranscriber.swift",
          "line": 110,
          "summary": "Unguarded try file.read() throws on MP3 trailing frames and calls cancelAndFinishNow(), aborting transcription."
        }
      ]
    }
    ```

### Step 5 — Batch Resize Images & Write Final `report.md` Once
1. Locate `copy_and_resize_images.sh` (either in this skill's `scripts/` folder next to `SKILL.md`, or `.skills/imported-skills/execute-and-report-journey/scripts/copy_and_resize_images.sh`) and batch-resize captured screenshots to `420px` wide (preserving full-res originals in `latest/images/full/`):
   ```bash
   SKILL_SCRIPT="$(dirname "<path-to-this-SKILL.md>")/scripts/copy_and_resize_images.sh"
   bash "$SKILL_SCRIPT" .journey_reports/<journey_name>/latest/images .journey_reports/<journey_name>/latest/images 420
   ```
2. Check for the most recent pre-fix archive (`ls -td .journey_reports/<journey_name>/archive/* 2>/dev/null | head -1`).
3. Use the native **`write_file`** tool *once* to write `.journey_reports/<journey_name>/latest/report.md` using absolute `file://` image paths:
   - **Single-run (no prior archive):** Embed `![Step 1](file:///abs/path/step_01_ios.png)` (or `| Android | iOS |` for dual-OS).
   - **Post-remediation (prior archive exists):** Embed `| Before | After |` (or `| Before (Android) | After (Android) | Before (iOS) | After (iOS) |`) so every fix is visually proven!
4. Archive the completed `latest/` directory into `.journey_reports/<journey_name>/archive/<yyyy-MM-dd-HH-mm>/`.

---

## 4. Report Format Template

```markdown
# Journey Report: <journey_name>

*Mode: <Builder TDD | Adversarial Review | Post-Review Remediation> | Verdict: <✅ PASSED | ❌ FAILED>*

## Execution Summary

| Step | Action & Expected State | Android | iOS | Visual & Code Audit Notes |
| :---: | :--- | :---: | :---: | :--- |
| 1 | Home catalog & floating MiniPlayer | ✅ Passed | ✅ Passed | Zero clipping; badges & glass chrome clean. |
| 2 | Show Detail & live RSS episode list | ✅ Passed | ❌ Failed | iOS `ZStack` `.scaledToFill()` overflows `393pt` width. |

## Real-Device & Systems Audit
- **MP3 / Audio Decode EOF:** ✅ Guarded as `.endOfStream`
- **Permissions & Asset Quotas:** ✅ Verified
- **Translation / TTS Lifecycle:** ✅ Verified

## Detailed Step Evidence

### Step 2: Show Detail & live RSS episode list
* **Result:** ✅ Repaired (was ❌ Failed)
* **Audit:** Scoped blurred cover art inside `.background { ... .clipped() }` so `1:1` artwork no longer widens `ZStack` beyond `393pt`.

| Before | After |
| :---: | :---: |
| ![Before](file:///abs/path/.journey_reports/stage0/archive/2026-11-13-07-00/images/step_02_ios.png) | ![After](file:///abs/path/.journey_reports/stage0/latest/images/step_02_ios.png) |
```
