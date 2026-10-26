---
name: render-mermaid-studio
description: Renders ```mermaid diagrams inside Markdown (.md) files into crisp local PNGs inside a sibling .mermaid/ folder so they render natively in Android Studio's Compose Markdown preview. Enforces Android Studio image rules (absolute file:// paths, macOS sips width resizing, clickable Full-Size PNG & .mmd source links, and --> escaping inside HTML comments).
version: 1.0.0
author: dyor
---

# Skill: Render Mermaid Diagrams for Android Studio (`render-mermaid-studio`)

## Overview
Android Studio's default Markdown preview uses the **`Compose (experimental)`** rendering engine, which is a pure Kotlin/Compose CommonMark renderer with **no JavaScript engine** (`mermaid.js` cannot execute inside it). Consequently, standard ```` ```mermaid ```` code blocks only display as raw syntax-highlighted text, and even installing the JetBrains Mermaid plugin does not render diagrams unless the user switches boot runtimes to JCEF.

Furthermore, Android Studio's Markdown preview has four strict rendering quirks:
1. **Absolute `file://` paths are required**: Relative paths (`./.mermaid/foo.png`) often fail to resolve in the preview. Every image and link must use `file:///absolute/path/to/...`.
2. **HTML tags (`<img>`, `<details>`, `<summary>`) are stripped**: You cannot resize images with `<img width="...">` or hide Mermaid code inside `<details>`.
3. **Physical pixel dimensions control display size**: Because width/height attributes are ignored, images must be physically resized using macOS `sips --resampleWidth <width>` (`1500` px for full-column Retina diagrams), paired with a clickable `[🔍 View Full-Size Diagram](file:///...-full.png)` link to the unscaled `@3x` image.
4. **Mermaid arrows (`-->`) prematurely close HTML comments (`<!-- ... -->`)**: If you hide the original Mermaid source inside an HTML comment block below the image, the very first `-->` arrow in the diagram will close the HTML comment in CommonMark and spill raw code into the preview! All `-->` sequences inside the comment must be escaped as `--&gt;` (and a clean `.mmd` file saved alongside the PNG).

This skill provides a self-contained Node.js CLI, file watcher, and MCP server (`scripts/render_mermaid.js`) that automates all four rules offline using local headless Google Chrome + `@mermaid-js/mermaid-cli`.

---

## Architecture: Skill Stays Clean, Outputs Live Alongside the User's Docs
Following the repository's core separation principle:
- **This skill directory** contains only the reusable `SKILL.md` and `scripts/render_mermaid.js`. Never write project diagrams or markdown files inside `.skills/`.
- **Generated diagram assets** (`.png`, `-full.png`, `.mmd`) are written into a hidden `.mermaid/` subfolder directly adjacent to the target `.md` file in the user's project (or a custom output directory if specified).

---

## Execution Protocol

### 1. First-Time Bootstrap (One-Time per Machine)
The script uses `@mermaid-js/mermaid-cli` installed in `~/.local/share/md-mermaid` (paired with the user's existing `/Applications/Google Chrome.app` so no Chromium download is needed).

If `~/.local/share/md-mermaid/node_modules/.bin/mmdc` does not exist yet, initialize it once:
```bash
mkdir -p ~/.local/share/md-mermaid && cd ~/.local/share/md-mermaid && npm init -y && PUPPETEER_SKIP_DOWNLOAD=true npm install @mermaid-js/mermaid-cli @modelcontextprotocol/sdk chokidar
```

### 2. Render / Sync Mermaid Diagrams in a File or Directory
Run `render_mermaid.js` (or `md-mermaid` if linked into `~/.local/bin`) against any `.md` file or directory of `.md` files:

```bash
node <path-to-this-skill>/scripts/render_mermaid.js sync <path-to-file-or-dir> [--width 1500] [--force]
```

What this does for each ```` ```mermaid ```` block (or existing `<!-- md-mermaid:start ... -->` block):
1. Computes a 10-character SHA-256 content hash of the Mermaid source (skipping re-rendering if the PNGs for that hash already exist on disk, unless `--force` is passed).
2. Writes the clean Mermaid source to `<md-dir>/.mermaid/<slug>-<index>-<hash>.mmd`.
3. Renders an unscaled `@3x` high-resolution PNG to `<md-dir>/.mermaid/<slug>-<index>-<hash>-full.png`.
4. Copies and resizes the inline preview PNG to `1500px` wide via `sips --resampleWidth 1500` at `<md-dir>/.mermaid/<slug>-<index>-<hash>.png`.
5. Replaces the block in the `.md` file with:
   ```markdown
   <!-- md-mermaid:start hash=b36b26ebd4 index=1 -->

   ![Mermaid Diagram 1](file:///absolute/path/to/.mermaid/doc-1-b36b26ebd4.png)

   [🔍 View Full-Size Diagram](file:///absolute/path/to/.mermaid/doc-1-b36b26ebd4-full.png) · [📐 Edit Mermaid Source (.mmd)](file:///absolute/path/to/.mermaid/doc-1-b36b26ebd4.mmd)

   <!-- md-mermaid:source
   ```mermaid
   flowchart LR
       A --&gt; B
   ```
   -->
   <!-- md-mermaid:end -->
   ```

### 3. Live Sidecar File Watcher Mode
To watch a documentation folder (e.g., `SPECS/`) and automatically re-render diagrams whenever a `.md` file is saved:
```bash
node <path-to-this-skill>/scripts/render_mermaid.js watch <path-to-dir>
```

### 4. Reverting Back to Plain Mermaid Blocks
To strip the embedded image blocks and restore the original ```` ```mermaid ```` fenced blocks cleanly:
```bash
node <path-to-this-skill>/scripts/render_mermaid.js revert <path-to-file-or-dir>
```

---

## Mermaid Authoring Tips for Best Layout in Android Studio
- **Avoid 4+ unconnected top-level subgraphs in `flowchart TD`**: Unconnected subgraphs are laid out horizontally side-by-side by Mermaid, creating an ultra-wide, short strip. Group them into rows or use `flowchart LR` with inner `direction TB` subgraphs for a balanced 2×2 aspect ratio.
- **Use `<br/>` instead of literal `\n` inside quoted node labels**: `A["First Line<br/>Second Line"]` renders cleanly across all Mermaid versions.
