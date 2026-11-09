---
name: build-appos
description: Build "Appos", a macOS home for Operator, Runner, Publisher and Tiny Projects in one window. Operator's project list (with an icon per project) sits on the left; the right side shows Operator's page for the selected project, and Run / Publish open Runner or Publisher for that project in place, closing back to Operator with Esc. Each tool stays a standalone app too, because each is split into a Kit library plus a thin app, and Appos links the Kits from the sibling checkouts. Plain Swift package, no Xcode project. Use when the user says "build Appos", "put Operator, Runner and Publisher in one app", "one dock app for my tools", or asks for /dyor-knowledge-base appos. Mac only. Requires build-operator; build-runner, build-publisher and build-tiny-projects are optional.
version: 1.0.0
---

# Build Appos

**Appos** (the Greek god of apps, and the App Operating System) is one Dock app for the tools
you build with the other skills:

| Tool | Skill | Where it shows in Appos |
|---|---|---|
| Operator | `build-operator` | Always: the project list on the left, and each project's page on the right |
| Runner | `build-runner` | The right side, after **Run** on a project |
| Publisher | `build-publisher` | The right side, after **Publish** on a project |
| Tiny Projects | `build-tiny-projects` | The right side, after the pinned **Tools → Tiny Projects** row |

Running a tool's own app still gives the standalone tool, unchanged. Appos is a second host for
the same code. Nothing is copied, so a fix in Runner shows up in both after a rebuild.

You (the agent) build this from the spec. Read `references/mac-app-recipe.md` first,
especially **§1 (Kit + app layout)** and **§9 (Kit rules)**. Appos is mostly glue, and those
rules are what make the glue possible.

## 0. Before you write anything

1. **Check what exists.** Look for the user's Operator, Runner, Publisher and tiny-projects
   checkouts (the default is `<projects root>/local/<Tool>`; ask if they aren't there).
   Operator is required. Leave out any tool they don't have.
2. **Check each tool is already split into a Kit.** Its `Package.swift` must have a
   `.library(name: "<Tool>Kit", ...)` product. If not, do the split first (recipe §1: move the
   sources to `Sources/<Tool>Kit/`, make the entry point `public enum <Tool>Main`, add a
   one-line `Sources/<Tool>/main.swift`). Then add what recipe §9 lists and what each tool's
   skill describes under "Inside Appos". Run `swift build` in that tool's folder afterwards:
   the standalone app must still build. If a tool's folder has uncommitted work, say so before
   restructuring it, and move files rather than rewriting them.
3. **Ask** in one message (defaults in brackets):
   - Where Appos should live [`<root>/local/Appos`, next to the others].
   - Bundle id [`com.<name>.appos`].
   - Whether they want Tiny Projects in it (only if they have it).

## 1. How it fits together

```
local/
  Operator/      OperatorKit  + Operator.app        ← list, icons, project page, ship review
  Runner/        RunnerKit    + Runner.app          ← RunnerEmbed
  Publisher/     PublisherKit + Publisher.app       ← PublisherEmbed
  tiny-projects/ TinyProjectsKit + the web page     ← TinyProjectsEmbed
  Appos/         Package.swift depends on all four by path
```

`Appos/Package.swift`:

```swift
dependencies: [
    .package(path: "../Operator"),
    .package(path: "../Runner"),
    .package(path: "../Publisher"),
    .package(path: "../tiny-projects"),
],
targets: [
    .executableTarget(name: "Appos", dependencies: [
        .product(name: "OperatorKit", package: "Operator"),
        .product(name: "RunnerKit", package: "Runner"),
        .product(name: "PublisherKit", package: "Publisher"),
        .product(name: "TinyProjectsKit", package: "tiny-projects"),
    ], path: "Sources/Appos"),
]
```

Path dependencies compile from source into `Appos/.build`, so the four builds never interfere.
The package identity is the **folder name** (`tiny-projects`), not the `name:` in its manifest.

## 2. The window

1360×880, dark (`.darkAqua`), transparent title bar with `.fullSizeContentView`, autosaved
frame, and a `minWidth` of 1100 (290 for the sidebar plus room for Publisher). The app keeps running
when its window is closed, so a build or upload carries on; reopening from the Dock shows the
window again. Its main menu has Quit, a **full** Edit menu (Undo, Redo, Cut, Copy, Paste,
Select All: Publisher's release notes need Paste) and Window.

### Sidebar (290 pt, same palette as Runner and Publisher)

- Header: an amber tile with **Α**, "Appos", and the subtitle "Operator · Runner · Publisher".
  Keep the subtitle on one line, because a fourth name wraps.
- A filter field bound to `LauncherModel.searchText`.
- **Tools**: one row per cross-project tool (Tiny Projects: green tile, `checklist` symbol,
  "Every project's to-do list"). It's selected while its pane is open.
- One section per category (`filteredCategories`). Each row has a `ProjectIconView` (38 pt),
  the name, and one status line, in this order of precedence:
  1. **Running…** with a spinner, if `runner.runningPackage == project.runPackage`
  2. **Publishing…** with a spinner, if `publisher.runningPackage == project.publishPackage`
  3. **Last run failed**, if `runner.failedPackage == project.runPackage`
  4. **What's left to do**: `tinyProjects.list(named: project.name)?.summary` ("3 tasks",
     "2 snoozed", "All done", "No tasks yet"), amber when tasks are pending. Without a list,
     show "No task list" (dim).
  Git status is **not** in the list. It's on the project page's GitHub card. (Without Tiny
  Projects, fall back to the git summary.)
- Footer links: **Fetch & Refresh** (`refreshGit(fetch: true)`), **Reload config** (Operator
  rescan, plus `reload()` on every embed), **Rebuild & Relaunch** (`./rebuild.sh` in Terminal).

Only the sidebar observes the embeds (`@ObservedObject` on each). They forward every model
change, including each log line, so keep the root view observing only Appos's own model.

### Right side: one pane at a time

```swift
enum Pane { case project, runner, publisher, tinyProjects }
```

- `.project`: `OperatorProjectPage(project:model:onRun:onPublish:tasks:)`, with
  `.id(project.path)`. `tasks` is Appos's **TasksCard**, which the page shows first: the list's
  summary, its next three tasks, and **Open in Tiny Projects** (`openTasks(project)`). If there
  is no list, it shows "No Tiny Projects list called …" and **Create task list**
  (`tinyProjects.createList(named:)`, then `openTasks`).
- `.runner`, `.publisher`: a 52 pt **EmbedBar**, then `embed.view`. The bar shows
  **‹ Operator** (button), the project's icon and name, `›`, the tool name in amber, "esc to
  close" and a ✕ on the right.
- `.tinyProjects`: the same bar, then `tinyProjects.view`. From the Tools row
  (`tinyProjectsFor == nil`) the bar has no project, and the page shows every list. From a
  project's Tasks card, the bar names the project and `tinyProjects.show(projectNamed:)`
  scrolls the page to that project's card. Highlight the project row in the sidebar in the
  second case, and the Tools row in the first.

**Project ↔ task list**: a project's list is the Tiny Projects project whose name matches,
ignoring case, spaces, dashes and underscores (`TaskList.key`). `habit-hero` ↔ "Habit Hero".
There's no mapping file. To link a project, create the list from its page, or rename the
list in Tiny Projects.

Navigation rules (these are the product, so keep them):

- Clicking a project row selects it and **always** shows `.project`.
- **Run** calls `runner.show(package:)`, then `pane = .runner`. **Publish** does the same with
  Publisher. They only open from a project page, so you can never go straight from Runner to
  Publisher.
- **‹ Operator**, ✕, and **Esc** set `pane = .project` for the same project. Handle Esc in an
  `NSEvent` local key monitor, and pass it through when the first responder is an editable
  `NSTextView`, so Esc in a text field doesn't close the pane.
- Remember the selected project across launches (`UserDefaults` key `lastProject`).

### Wiring

Create the embeds once, in the model's initializers, pointing at the sibling checkouts
(`OperatorEmbed.projectsRoot + /local/<Tool>`):

```swift
let operatorModel = LauncherModel()
let runner = RunnerEmbed(repoDir: local.appendingPathComponent("Runner"))
let publisher = PublisherEmbed(repoDir: local.appendingPathComponent("Publisher"))
let tinyProjects = TinyProjectsEmbed(repoDir: local.appendingPathComponent("tiny-projects"))
// in init:
PublisherEmbed.openShip = { path in OperatorEmbed.ship(path: path) }
```

Appos.app has no `Resources/scripts`: Runner and Publisher run their scripts from their own
checkouts (recipe §9 rule 1). That's deliberate, so editing a script never needs an Appos
rebuild.

## 3. Files to write

```
Appos/
  Package.swift  build.sh  rebuild.sh  README.md  .gitignore (.build/ Appos.app/ .DS_Store)
  icon_1024.png                the app icon (1024², squircle on the macOS grid, transparent corners)
  gems/                        gem-operator.png gem-runner.png gem-publisher.png gem-appos.png (256²)
  scripts/make-icon.swift      placeholder icon, only used when there's no icon_1024.png
  Sources/Appos/
    main.swift          MainActor.assumeIsolated { NSApplication bootstrap }
    AppDelegate.swift   window, menus, Esc monitor, APPOS_SNAPSHOT
    ApposModel.swift    Pane, the embeds, select/open/close, reloadAll, rebuildAndRelaunch
    ApposView.swift     Theme, ApposView, EmbedBar, Sidebar, SidebarRow, ToolRow
```

`build.sh` follows the recipe. It builds Appos.app in the checkout, rebuilds `Appos.icns` with
`sips` + `iconutil` whenever `icon_1024.png` is newer (or draws the placeholder if there's no
PNG), copies `gems/*.png` to `Contents/Resources/gems/`, and sets `NSAppleEventsUsageDescription` (agents, pushes
and Rebuild drive Terminal). Appos needs no URL scheme yet.

`APPOS_SNAPSHOT=<png>` plus optional `APPOS_PROJECT=<path suffix>` and
`APPOS_PANE=runner|publisher|tasks|tiny` render the window after `APPOS_SNAPSHOT_WAIT` seconds
(default 5) and quit. Use it to check every pane without Screen Recording permission.

### Gems

Each tool has a gem: a blue rocket for Operator, an orange play button for Runner, and a green
flame for Publisher. They're cut from the Appos icon artwork, which has the three gems under
its Α. Use them wherever a tool is named: the tool's own header (standalone), Publish and Run
on the project page, **Open Runner / Open Publisher**, the **‹ Operator** back button, and the
tool name in the EmbedBar. Each Kit has a small `Gem(name, size:, fallback:)` view that loads
`Bundle.main.resourceURL/gems/gem-<name>.png` and falls back to an SF Symbol. Each app's
`build.sh` copies its own `gems/`, and Appos copies all of them, since it draws every Kit's
screens. If artwork arrives as a JPG with a "transparent" checkerboard baked in, cut it out
with a rounded-rectangle mask for the tile and a hexagon mask for each gem. After adding a
file to a dependency, `rm -rf .build` in Appos: the path-dependency cache can miss new files.

Give the tools their own gems in Appos's list too: copy each gem to that checkout's
`.appos/icon.png` (`Appos/.appos/icon.png` ← `gem-appos.png`, `Operator/.appos/icon.png` ←
`gem-operator.png`, and so on). Commit those `.appos/` folders with each repo.

## 4. Build and verify

1. `swift build` in each tool's folder (the standalone apps still build), then `./build.sh`
   in Appos.
2. Snapshot the project page, the Runner pane, the Publisher pane (wait ~12 s for Play) and
   Tiny Projects. Look at each one: real projects, real icons, the pane's own content.
3. `open Appos.app`. Tell the user to keep it in the Dock (right-click → Options → Keep in
   Dock).
4. Don't press Run, Publish or Push as a test. Opening the panes is enough.

## 5. Adding another tool later

- **A per-project Swift tool**: split it into a Kit (recipe §1, §9), add a `Pane` case, an
  `open<Tool>(_ project:)`, a button on `OperatorProjectPage` (add a closure parameter), and
  a status rule in the sidebar.
- **A cross-project tool** (like Tiny Projects): add a `ToolRow` under **Tools** and a `Pane`
  case. A web tool can be a tiny Kit that hosts its page in a `WKWebView` (see
  `build-tiny-projects` §4).
- The rule stays: every tool opens from Operator and closes back to it.

## 6. Don'ts

- Don't copy a tool's code into Appos. If Appos needs something, make it `public` in the
  Kit, or add an embed method.
- Don't move window, menu-bar or URL-scheme code into the Kits. That belongs to each app's
  AppDelegate.
- Don't give the Kits Appos-specific knowledge beyond the embed type and hooks such as
  `openShip`.
- Don't run anything that ships (push, upload, deploy) to test the build.
