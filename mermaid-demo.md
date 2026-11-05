# Mermaid Rendering Demo

This document demonstrates rendering Mermaid diagrams directly in Android Studio.

## Architecture & Workflow

<!-- md-mermaid:start hash=8bca288cff index=1 -->

![Mermaid Diagram 1](file:///Users/mattdyor/DyorProjects/local/skills/.mermaid/mermaid-demo-1-8bca288cff.png)

[🔍 View Full-Size Diagram](file:///Users/mattdyor/DyorProjects/local/skills/.mermaid/mermaid-demo-1-8bca288cff-full.png) · [📐 Edit Mermaid Source (.mmd)](file:///Users/mattdyor/DyorProjects/local/skills/.mermaid/mermaid-demo-1-8bca288cff.mmd)

<!-- md-mermaid:source
```mermaid
flowchart TD
    subgraph Input ["Source Input"]
        MD["Markdown Document<br/>with mermaid block"]
    end

    subgraph Processing ["Processing Pipeline"]
        MCP["MCP Tool / CLI<br/>(md-mermaid)"]
        CHROME["Headless Chrome + mmdc<br/>(Mermaid CLI)"]
        SIPS["macOS sips<br/>(Resample to 1500px)"]
    end

    subgraph Output [".mermaid/ Directory"]
        FULL_PNG["Full-Size Retina PNG<br/>(*-full.png)"]
        VIEW_PNG["Scaled Preview PNG<br/>(*.png)"]
        MMD["Clean Source<br/>(*.mmd)"]
    end

    subgraph Studio ["Android Studio"]
        PREVIEW["Compose Markdown Preview<br/>(Embedded Image & Links)"]
    end

    MD --&gt; MCP
    MCP --&gt; CHROME
    CHROME --&gt; FULL_PNG
    FULL_PNG --&gt; SIPS
    SIPS --&gt; VIEW_PNG
    MCP --&gt; MMD
    VIEW_PNG --&gt; PREVIEW
    FULL_PNG -.->|Clickable Link| PREVIEW
    MMD -.->|Source Link| PREVIEW
```
-->
<!-- md-mermaid:end -->

## Description
When rendered by the `render-mermaid-studio` tool:
1. The Mermaid block is converted into high-resolution PNG assets in a sibling `.mermaid/` directory.
2. The markdown is updated with absolute `file://` URLs so that Android Studio's Compose Markdown preview displays the image crisply.
3. Convenient clickable links allow viewing the full-size diagram and editing the raw `.mmd` definition.
