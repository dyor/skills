---
name: build-tiny-projects
description: Build "Tiny Projects", a single-file, zero-dependency web page for a handful of projects and their tasks - a By Project view and a global By Priority view, drag-to-swap ranks, snooze, collapsible sections, dark/light, JSON backup - plus an optional local file backend (node server.js) and a dependency-free MCP server so a coding agent can "add these to tiny projects", plus an optional TinyProjectsKit so it opens inside Appos. Use when the user says "build Tiny Projects", "set up my own tiny projects", "a tiny task list my agent can write to", or asks for /dyor-knowledge-base tiny-projects. The page runs anywhere; the Appos Kit is Mac only. Companion skills - build-appos, build-operator.
version: 1.0.0
---

# Build Tiny Projects

A to-do list small enough to read in one sitting: a few projects, each with a ranked task
list, in one HTML file with no dependencies. It has three optional layers, and the user picks
how far to go:

1. **The page** (`index.html`): works offline from `file://` or any static host, and stores
   data in `localStorage`.
2. **File backend + MCP** (`server.js`, `lib/store.js`, `mcp/server.js`): data moves to
   `~/.tiny-projects/data.json`, and an agent can read and write it.
3. **TinyProjectsKit** (`Package.swift`, `Sources/TinyProjectsKit/`): shows the page inside
   Appos (`build-appos`).

## 0. Ask first

1. **Their own copy or a fork?** The fastest route is to fork or clone
   `https://github.com/dyor/tiny-projects` (public, no build step; it has no license file, so ask before redistributing a fork) into their
   projects folder, usually `<root>/local/tiny-projects`. Building from this spec is for when
   they want to change it substantially. Either way, read §1-§3 so you can explain and adapt it.
2. **Which layers?** [page + file backend + MCP]. Add the Kit only if they have Appos or want it.
3. **Port** [8777] and **data file** [`~/.tiny-projects/data.json`].
4. **Publishing the page** (GitHub Pages) is optional. If they publish, the published copy
   keeps using `localStorage`. Data never goes into the repo.

## 1. The page (`index.html`)

One file holding the HTML, CSS and JS. No frameworks, no CDN, no build.

**Data**: `{ projects: [{id, name, color, rank}], tasks: [{id, projectId, title, completed,
snoozedUntil, completedAt, rank}] }`. A higher `rank` means more important. New items get
`min(rank) - 10`, which puts them at the **bottom**. Ranks are never shown.
`localStorage` keys are versioned (`tiny_projects_app_data_v2`, `tiny_projects_theme_v2`). The
first run seeds three sample projects.

**By Project view**: one card per project, in rank order.
- Drag a project's `⋮⋮` handle onto another project to **swap** their ranks.
- Cards collapse. They default to collapsed when every task is done, and open otherwise
  (including new projects).
- Each card has Pending, Snoozed and Completed sections, each collapsible; Snoozed starts
  collapsed.
- Dropping a task on another task **in the same project** swaps their ranks.
- An inline "+ Add task" field: Enter adds the task and **keeps focus**, so several can be
  typed in a row.
- Project names can be edited. Deleting a project asks for confirmation.

**By Priority view**: every task in one list by rank, with a coloured project pill. Dragging
swaps ranks across projects. It has the same three sections.

**Snooze**: 1 day, 2 days, 1 week, or a custom date. A 30-second timer moves tasks back to
Pending when their snooze date passes.

**Deep link**: `index.html#project=<name or id>` (and a global `focusProject(nameOrId)`,
also called on `hashchange`). It switches to By Project, expands that card, scrolls it into
view, and outlines it briefly (`.is-focused`). Names match ignoring case and anything that
isn't a letter or digit, so `#project=habit-hero` finds "Habit Hero".

**Header**: the view switch, **New Project**, and the theme toggle (system default, then
remembered). A stats line ("9 projects • 87 pending • 32 completed") and Export/Import JSON.

## 2. File backend (`server.js` + `lib/store.js`)

`localStorage` is per-origin, so nothing outside the browser can reach it. The server moves
the data into a file that the page and the MCP server share.

- `lib/store.js` is **the only code that touches the file**: `readStore()` returns
  `{version, projects, tasks}`, where `version` is the file's mtime in ms (`null` if the file
  is missing). `writeStore()` writes a temp file and renames it (atomic). It also holds `id()`,
  `nextRank()`, `findProject()` (by id, then exact name, then substring) and the colour list.
  The path is `$TINY_PROJECTS_DATA` or `~/.tiny-projects/data.json`, **outside the repo** on
  purpose.
- `server.js` (Node's built-in `http` only) listens on `127.0.0.1:<port>` (`--port` or
  `$TINY_PROJECTS_PORT`):
  - `GET /api/data` returns the store.
  - `PUT /api/data` takes `{version, projects, tasks}`. If `version` doesn't match the file,
    it answers **409 with the current store** instead of overwriting an MCP write.
  - Static files are confined to the folder (403 outside it), with `Cache-Control: no-store`.
- In the page: on load, try `fetch('api/data')`. On success, switch to the backend, show
  "· local file" in the subtitle, poll every 3 s (so an agent's write appears without a
  refresh), and on a 409 reload instead of saving. On failure (`file://` or GitHub Pages
  return 404), stay on `localStorage`. The same file works in both places.

## 3. MCP server (`mcp/server.js`)

JSON-RPC 2.0 over stdio, written by hand: `initialize`, `tools/list` and `tools/call`, with
no SDK and no `node_modules`. Tools: `list` (with `include_completed`), `add_project`,
`add_tasks` (`project` name or id plus `titles[]`; creates the project if it doesn't exist), `complete_task`, `update_task`,
`delete_task`. Tasks are addressed by id **or a unique title substring**. An ambiguous
substring returns the candidates instead of guessing. Every tool goes through
`lib/store.js`. Register it with:

```bash
claude mcp add -s user tiny-projects -- node <repo>/mcp/server.js
```

Then test: "list my tiny projects", then "add 'try the MCP' to <project>". With `server.js`
running, the open page shows the new task within 3 seconds.

## 4. TinyProjectsKit (for Appos)

Tiny Projects isn't a Swift app, so its Kit is small. It **hosts the page** and doesn't
re-implement it. Add `Package.swift` (one `.library` product, macOS 13), and
`Sources/TinyProjectsKit/TinyProjectsKit.swift`:

- `@MainActor public final class TinyProjectsEmbed: ObservableObject`, with
  `init(repoDir:port: = 8777)`, `state` (`idle`, `starting`, `ready`, `failed(String)`),
  `start()`, `retry()`, `reload()`, `openInBrowser()`, and `view: AnyView`.
- `start()`: if `GET /api/data` answers 200, the server is ready. If not, run
  `<node> server.js --port <port>` with `cwd = repoDir` and poll for up to ~6 s. Find node in
  `/opt/homebrew/bin`, `/usr/local/bin` or `/usr/bin`, because apps opened from the Dock
  don't get the shell's `PATH`.
- **Stop only the server this app started** (on `NSApplication.willTerminateNotification`).
  A server the user started (Operator's dev-server button, a Terminal) is left alone.
- **One `WKWebView` for the app's lifetime**, so closing and reopening the pane keeps scroll
  position and collapsed sections. Set `drawsBackground` to false to avoid a white flash
  before the dark theme loads. `target=_blank` links and links to other hosts open in the
  default browser.
- `show(projectNamed:)`: when the page is loaded, call `focusProject(...)` through
  `evaluateJavaScript` (pass the name JSON-encoded). Otherwise remember it and load
  `…/#project=<name>` on the first load.
- `lists: [String: TaskList]`, read **directly from the data file**, so it works even before
  the server starts. Check the file's mtime every 3 s and re-parse only when it changes.
  `TaskList` has `id`, `name`, `pending`, `snoozed`, `done`, `next` (the top 5 pending titles
  by rank) and `summary` ("3 tasks · 1 snoozed", "2 snoozed", "All done", "No tasks yet").
  Count with the page's own rule: completed, else snoozed while `snoozedUntil` is in the
  future, else pending. Key lists by `TaskList.key(name)` (lowercased letters and digits) and
  look them up with `list(named:)`.
- `createList(named:)` appends `{id: "proj_<base36 time><random>", name, color, rank: min-10}`
  the way the MCP server does. Keep every other field, write atomically (temp file plus
  `replaceItemAt`), and do nothing if the name already matches a list. An open page picks it
  up on its next poll; a stale save gets a 409 and reloads.
- `reload()` does nothing until the first `start()`, so the host's **Reload config** never
  starts a server nobody asked for.
- The view shows a spinner while starting, and an error with **Try again** and **Open in
  browser** if it fails.

Add `.build/` and `.swiftpm/` to `.gitignore`. Then follow `build-appos`: a pinned **Tools →
Tiny Projects** row, `case tinyProjects` in `Pane`, `tinyProjects.reload()` in **Reload
config**, task counts in the sidebar, and a Tasks card on each project page that opens its
list with `show(projectNamed:)`. Check it with
`APPOS_PANE=tiny APPOS_SNAPSHOT=…`: the snapshot should show the user's real tasks.

## 5. Verify

- Open `index.html` from Finder: sample projects appear. Add, drag, snooze, complete, export.
- `node server.js`, then open `http://localhost:<port>`: the subtitle says "· local file".
- MCP: add a task through the agent and watch it appear in the open page.
- Kit: `swift build` in the folder, then the Appos snapshot.

## 6. Don'ts

- Don't commit `data.json` or anything under `~/.tiny-projects/`. Many forks are public.
  Keep `data.json` in `.gitignore` as a guard against a stray local override.
- Don't add dependencies (npm packages, frameworks, a bundler). Zero dependencies is the
  point.
- Don't let the browser overwrite the file blindly. Keep the version check and the 409.
- Don't make the Kit start the server at Appos launch. Start it when the pane opens.
