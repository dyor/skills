---
name: build-operator
description: Build "Operator", a keyboard-first macOS launcher for every project in a projects folder (~/Projects/<category>/<project>). One window lists all projects with git status; each row opens a coding-agent session in that folder, continues the last session, opens Finder/Terminal/Android Studio, and ships to GitHub with one reviewed button (Push on main, Merge → main on a branch, Pull when behind). Plain Swift package, no Xcode project. Use when the user says "build Operator", "set up my Operator", "project launcher for my Mac", or asks for /dyor-knowledge-base operator. Mac only. Companion skills - build-runner and build-publisher.
version: 1.1.0
---

# Build Operator

**Operator to code, Runner to try it, Publisher to publish.** Operator is the front door: a
small Mac app that lists every project on the machine and gets you into the right one in a
keystroke. Runner (`build-runner`) and Publisher (`build-publisher`) are optional siblings it
links to.

You (the agent) build the app for the user from this spec. Nothing here is copied code to
paste blindly: the *behavior* and the *gotchas* are the product. Write the Swift yourself,
following the recipe in `references/mac-app-recipe.md` for the package, bundle, build script
and Terminal-driving helpers. Read that file first.

## 0. Before you write anything: ask the user

Ask these in one message, with the default in brackets. Do not proceed on guesses for 1 and 2.

1. **Projects folder.** Where do their projects live? [`~/Projects`]. Operator expects
   `<root>/<category>/<project>`, one level of grouping (for example `kmp/`, `web/`, `local/`).
   If their projects are flat (`<root>/<project>`), treat the whole root as a single category.
2. **Where should the Operator source live?** [`<root>/local/Operator`, or `~/Operator`].
3. **Coding agent.** Which should the main click open? [Claude Code desktop app via
   `claude://code/new?folder=<path>`]. Alternatives: `claude` CLI in Terminal; another CLI
   (Codex, Gemini) run in Terminal as `cd '<path>' && <command>`. Make this a single
   `agent` setting in config (`"claude-desktop"` default, or any CLI command string) so it is
   easy to change.
4. **Which optional buttons do they want?** Android Studio (only if they do Android/KMP),
   Codex button, Digest, local dev servers. Build only the ones they name; the rest is noise.
5. **Bundle id prefix** (for `CFBundleIdentifier`, e.g. `com.theirname.operator`) and whether
   they want a custom icon.

Check prerequisites: macOS 13+, `swift --version` works (otherwise tell them to run
`xcode-select --install`), `git` present. A GitHub login is only needed for the push buttons
to work; Operator itself never stores credentials.

## 1. What Operator is

One window, 820x600, dark, search box on top, projects below grouped by category. Keyboard
first: type to filter, **Enter** opens the first match, **⌘1-⌘9** open by position, **Esc**
quits. It stays open after launching something, so several projects can be opened in a row.
`applicationShouldTerminateAfterLastWindowClosed` returns true; Operator is a launcher, not a
daemon.

### Discovery (`Scanner`)

- Categories are the visible subfolders of the root, skipping dot-folders and `.app` bundles,
  sorted case-insensitively. A category title is the folder name capitalized; `kmp`/`rn`/`ios`
  are uppercased; underscores become spaces.
- Projects are the visible subfolders of each category. Empty categories are hidden.
- Rescan on launch, on dock-icon reopen, and on a manual reload, so new folders appear
  without a restart.
- A project carries: `name`, `path`, `category`, `isGitRepo` (`.git` exists; it is a *file*
  for worktrees, so test existence, not directory-ness), `branch`, `latestSession`, plus
  optional links to Runner and Publisher (below).
- **Branch without spawning git**: read `<path>/.git/HEAD`; if it starts `ref: refs/heads/`
  the rest is the branch — **except** `ref: refs/heads/.invalid` (written by Git 2.45+ / Xcode
  `reftable` repos as a compatibility stub), which must return `nil` so the background
  `git branch --show-current` populates the real branch name. Detached HEAD and worktrees also
  give `nil`. Scanning stays instant even with 100 projects.
- **Config**: resolve in order `$OPERATOR_CONFIG`, `~/.config/operator/config.json`,
  `<OperatorSourceDir>/config.json` (read `OperatorSourceDir` from `Info.plist` so
  `/Applications/Operator.app` still finds the checkout's `config.json` and `rebuild.sh`), or
  `config.json` beside the `.app`. Missing file means defaults, never an error:
  ```json
  {
    "root": "~/Projects",
    "agent": "claude-desktop",
    "devServers": {
      "local/my-web-app": { "command": "npm run dev", "port": 3000, "dir": "web" }
    }
  }
  ```
  Key `devServers` by `<category>/<project>` (falling back to `<project>`) so identically named
  folders in different categories do not collide; `dir` is optional (relative to project root).

### Git status on every git project (`GitOverview`)

Read-only, local, and fast; run it on a background queue and publish into the model.

- Branch: `git branch --show-current` (empty means detached, show `detached at <short sha>`).
- Changed files: `git status --porcelain -z`. With `-z`, records are NUL-terminated and git
  **never** writes ` -> `: renames/copies (`R` or `C` in column 1 or 2) emit **two** NUL
  tokens (`XY new_path\0old_path\0`), so consume and skip the second token instead of treating
  `old_path` as its own status entry.
- Ahead/behind: `git rev-list --left-right --count HEAD...@{upstream}`. No upstream means
  show "no upstream".
- Possible overlap: when both ahead and behind, intersect the files in
  `git diff --name-only @{upstream}...HEAD` and `HEAD...@{upstream}`; when only behind,
  intersect the *uncommitted* files with `HEAD...@{upstream}`. Flag these as "⚠︎ N overlap"
  because they are where a pull will conflict.
- Summary string like `3 changed · ↑1 · ↓2 · ⚠︎ 1 overlap`, or `clean · synced`. The hover
  tooltip lists the branch and up to 12 changed files.
- **Never fetch implicitly.** Fetching is a network call. A header button, **Fetch & Refresh**
  (`git fetch --quiet --prune` per repo, then re-read), does it on demand. Re-read local
  status (no fetch) whenever the app becomes active again, which catches the push or pull you
  just did in Terminal.

### The one GitHub button (`Ship`)

Every git project shows exactly one ship button. Its action depends on state, decided in
this order:

1. Behind upstream (`behind > 0`) means **Pull**: Terminal, `git pull --rebase --autostash`.
   `--autostash` carries uncommitted work across. A push would be rejected anyway.
2. On a branch other than `main`/`master` means **Merge → main**.
3. Uncommitted changes, or unpushed commits, or no upstream means **Push**.
4. Otherwise "Up to date as of the last fetch."

Why one button: with a branch checked out, pushing the branch ships nothing (CI and releases
build main). Collapsing "Push" and "Merge" into a state-aware button removes that mistake.
Give each state a distinct tooltip that says what will happen.

**Push review** (modal alert, then Terminal):
- Title: `Push <project> → <owner/repo> (<branch>)`. Parse `owner/repo` from the `origin` URL
  (`git@github.com:o/r.git` or `https://github.com/o/r`).
- Warn if on a non-main branch ("pushes the branch, not main").
- Warn if the repo owner is not the user ("⚠️ This repo belongs to X, not you"). Take the
  user's GitHub login from `gh api user -q .login` or config; skip the warning if unknown.
- List changes in words, not raw porcelain: `new`, `modified`, `deleted`, `renamed`,
  `conflict`. **Fold runs of 4 or more new entries under one folder** into
  `new  skills/ (38 folders)` so a vendored directory does not bury the list. Cap at 20 lines
  with "... and N more".
- **Secret flagging, never blocking.** If any path (lowercased) contains `keystore`, `.jks`,
  `local.properties`, `.env`, `service-account`, `service_account`, `.p8`, `.p12`,
  `.mobileprovision`, `secret`, `credential`, `password`, show "⚠️ N files look like a
  secret" and list those files individually even if they would have been folded.
- A commit-message text field (only when there are changes). Empty means "Update".
- On confirm, in Terminal: if there are uncommitted changes, run `cd '<path>' && git add -A &&
  git commit -m '<msg>' && git push -u origin HEAD && open https://github.com/<owner/repo>/actions`;
  if the working tree is clean (`ahead > 0` or no upstream), skip `git add`/`git commit` and
  run `cd '<path>' && git push -u origin HEAD && open https://github.com/<owner/repo>/actions`
  (`git commit` exits 1 on a clean tree and would otherwise abort the push).

**Merge → main review** (a project on a branch):
- Compute the target (`main` if `refs/heads/main` exists, else `master`).
- List uncommitted changes (same description and secret warning) and the commits on the
  branch not on target (`git log --oneline target..branch`, cap at 15).
- Optional checkbox: "Delete <branch> afterwards (here and on GitHub)".
- In Terminal, chained with `&&` so any failure stops it where the user can see it:
  commit if needed, `git fetch origin`, `git checkout main`, `git pull --ff-only origin main`,
  `git merge --no-edit <branch>`, `git push origin main`, then optional
  `git branch -d <branch>` and `(git push origin --delete <branch> || true)`, then open
  GitHub Actions. A merge conflict simply stops the chain; the user sees which files.

All review dialogs use `NSAlert` (activate the app first), and the git commands run in
Terminal so output and auth prompts are visible.

### Row buttons

Show a button only when it applies. Primary click on the row, or ⌘N:

| Button | When | Action |
|---|---|---|
| Row click / agent chip | always | New agent session in the folder. Claude desktop: open `claude://code/new?folder=<path>&source=operator`. CLI agents: Terminal `cd '<path>' && clear && (type update_terminal_cwd >/dev/null 2>&1 && update_terminal_cwd; printf '\e]1;%s\a' "${PWD##*/}") && <agent command>` so Terminal sets both the tab working directory and tab title to the project name |
| ↻ Continue | a session exists | `claude://code/continue?session=<id>`. See "Finding sessions" |
| Studio | category is `kmp`, or user asked for Android | `open -a "Android Studio" <path>` (prefer "Android Studio Preview" if installed) |
| MobileApp | `<path>/MobileApp` exists | same, on that subfolder |
| ▶ Run | project appears in Runner's config | `runner://open?app=<packageName>` |
| Publish | project appears in Publisher's config | `publisher://open?package=<packageName or iOS bundleId>` |
| GitHub | git repo | the Ship button above |
| 📬 Digest | executable `scripts/digest.sh` | run it in Terminal |
| Finder | always | open the folder |
| Terminal | always | `open -a Terminal <path>` |
| Codex | user asked | Terminal `cd '<path>' && '<codex>' --cd '<path>'`. Prefer the CLI bundled in the Codex desktop app over a stale npm shim |
| ▶ Run (dev server) | configured per project | Terminal `cd '<dir>' && <command>`, so the URL and logs stay visible and Ctrl-C stops it; plus a chip that opens `http://localhost:<port>` |

Controls wrap onto a second line instead of squeezing (a small custom `Layout` that
right-aligns children and flows to new rows works well; SwiftUI's built-in stacks do not
wrap).

**Matching a project to Runner/Publisher**: locate each sibling tool's `config.json` in order:
`$<TOOL>_CONFIG` (`RUNNER_CONFIG` / `PUBLISHER_CONFIG`), `<root>/local/<Tool>/config.json`,
`~/<Tool>/config.json`, `~/.config/<tool>/config.json`. Read `projects` for Publisher and
`apps` for Runner, take each entry's `appDir` (expand `~`), and attach it to the project whose
path equals `appDir` or is a **directory-bounded** prefix of it (`appDir == project.path ||
appDir.hasPrefix(project.path + "/")` — always require the trailing `"/"` so `MyApp-OG` or
`myapp-kmp` never matches `MyApp` / `myapp`). Many apps keep the mobile app in a `MobileApp/`
subfolder, so the bounded prefix match matters. App Store-only apps have no `packageName`; fall
back to `ios.bundleId`. When opening `runner://` or `publisher://`, look for `<Tool>.app` beside
the resolved `config.json` (else `/Applications/<Tool>.app`) and pass it to
`NSWorkspace.shared.open(_:withApplicationAt:configuration:)` so the link works even before
LaunchServices has indexed the bundle. If neither config exists, those buttons never appear.

### Finding sessions (Claude desktop app)

The Claude desktop app keeps one JSON file per Code session under
`~/Library/Application Support/Claude/claude-code-sessions/**/local_*.json`, with `sessionId`,
`originCwd` (or `cwd`), `title`, `lastActivityAt` (milliseconds) and `isArchived`. Pick the
newest unarchived session per folder, counting sessions whose cwd equals `project.path` or
starts with `project.path + "/"` (worktrees live under it). **This is an internal format, not a
public API.** Treat every field as optional; on any surprise the Continue button disappears and
everything else keeps working. Say so in a code comment.

### Header

Title, a project count, **Fetch & Refresh** (with a spinner), **Rebuild** (opens Terminal and
runs `rebuild.sh`; see recipe), and a hint line for the shortcuts. A footer shows the root path.

### Links in (`application(_:open:)`)

`operator://ship?path=<folder>` opens that project's Ship review. The path may be a
*subfolder* (Publisher and Runner know an app by `MobileApp/`, Operator by the repo root), so
resolve in order: `git -C <path> rev-parse --show-toplevel`, then the closest enclosing known
project by longest path prefix. Unknown path means an alert "Operator doesn't have a project
at <path>". This link asks to *ship*, never to pull, so it calls the review with no cached
status.

## 2. Files to write

```
Sources/Operator/
  main.swift          AppKit bootstrap + `--list` flag (print categories/projects/buttons, exit)
  AppDelegate.swift   window, key monitor (Esc, ⌘1-9), reopen handler, operator:// links
  Projects.swift      Project, Category, Scanner, Launcher (all the "open X" helpers)
  GitOverview.swift   read-only git summary
  Push.swift          Push review, change description, secret flagging, git helper, shell quoting
  Merge.swift         Merge review + Ship (state -> action) + pull
  ContentView.swift   LauncherModel, search, rows, ChipButton, FlowLayout
build.sh  rebuild.sh  Package.swift  .gitignore  [scripts/make_icon.swift scripts/make_icns.sh]
```

Hard-won details:
- Shell-quote **every** path interpolated into a Terminal command with single quotes
  (`'` -> `'\''`). Folder names with spaces or apostrophes are normal.
- `Process` needs `executableURL`, and stderr to `FileHandle.nullDevice` for the read-only
  git calls; read stdout fully *before* `waitUntilExit()` to avoid a pipe-buffer deadlock.
- Run all git scans off the main thread; publish results on main.
- The key monitor (`NSEvent.addLocalMonitorForEvents(matching: .keyDown)`) handles Esc
  (keyCode 53) and ⌘1-⌘9 by indexing the *filtered, flattened* list shown on screen. Guard
  `NSApp.modalWindow == nil` first so pressing Esc inside a Push or Merge `NSAlert` cancels the
  modal dialog instead of quitting Operator.
- Put `NSAppleEventsUsageDescription` in Info.plist; the first Terminal action triggers a
  macOS automation permission prompt that the user must accept once.
- `--list` output should include, per project, which buttons would show. It is the
  verification hook.

## 3. Build, install, verify

1. Write the files, `chmod +x build.sh rebuild.sh`, run `./build.sh`. Fix compile errors.
2. `Operator.app/Contents/MacOS/Operator --list` must print their real categories and
   projects, with `push`/`merge:` annotations on git repos and `continue:` where sessions
   exist. Show the user this output.
3. `open Operator.app` and confirm the process is running. Tell them to right-click the Dock
   icon, then Options, then **Keep in Dock** (or launch from Spotlight, since `build.sh`
   also installs to `/Applications`).
4. Smoke-test with the user's consent: the Terminal button, and a Push review on a repo with
   no changes ("Nothing to push") so nothing is actually pushed. Do not push or merge anything
   on their behalf as a test.
5. Offer `git init` in the Operator folder with the recipe's `.gitignore`, and a short
   `README.md` listing the buttons, so they can evolve it.

## 4. Extending

- **Adding a project-specific button** (dev server, digest script, start script): add an
  optional field to config, a computed property on `Project`, one `Launcher` helper, and one
  `ChipButton`. Keep buttons conditional.
- **Runner and Publisher** are separate skills (`build-runner`, `build-publisher`). Build them
  after Operator and the Run/Publish chips light up by themselves.
- Keep Operator thin. It launches; it should not build, deploy or publish.

## 5. Don'ts

- Don't store tokens, passwords or keys. Operator shells out to `git`, which uses the user's
  own credentials.
- Don't auto-commit, auto-push or auto-merge. Every ship action is a reviewed, confirmed
  step the user clicks.
- Don't fetch on a timer; it is surprising and burns battery. Fetch on the button.
- Don't depend on the Claude app's session file format for anything but the Continue button.
