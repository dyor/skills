---
name: generate-code-review
description: Generates a comprehensive Markdown Change Review document by aggregating journey reports, grading contexts, key architectural decisions, and a pre-publishing checklist. Features optional Git integration and scope-based historical summaries.
version: 1.1.1
author: dyor
---

# `generate-code-review` Skill

This skill consolidates critical information from a project (like an iOS-to-Android migration) into a single, comprehensive Markdown Code Review document. It embeds visual evidence and grading from journey tests, integrates optional Git history, and provides a structured checklist for pre-publishing review.

## Workflow

1.  **Input Collection & Scoping:**
    *   Determines the `scope` of the review (default: "since the last code review", or a specific timestamp like `2026-05-02-10-00`). If a custom timestamp is provided, the review includes context since the *last* review PLUS summaries and clickable links to all previous code reviews generated since that specified timestamp.
    *   Reads the `feature_specification.md` for overall context.
    *   Reads the `walkthrough.artifact.md` for a summary of the migration process.
    *   Iterates through all subdirectories in `.journey_reports/` to locate the `latest/report.md` file for each journey.
    *   From each `latest/report.md`, extracts the absolute path of the **last "After" screenshot** AND the corresponding **"Grading" text** to provide context for the image.
    *   *(Optional Git Integration)*: If a `.git` directory is present, uses `git log --since="<timestamp>" --oneline` (or similar) to include a high-level summary of commits. This is a progressive enhancement and should silently skip if Git is unavailable.

2.  **Output Directory Setup:**
    *   Creates a dedicated output directory: `.code_reviews/`.
    *   Clears any previous `latest/` data within this directory.
    *   Creates the necessary subdirectory for images: `.code_reviews/latest/images/`.

3.  **Image Consolidation:**
    *   For each extracted "After" screenshot, copies the image file into `.code_reviews/latest/images/`. Renames images to be unique (e.g., `lines_browsing_final.png`).
    *   Resizes copied images to a consistent width (e.g., 600px).

4.  **Markdown Report Generation (in memory):**
    *   Constructs the entire Markdown file in memory.
    *   Includes a "Migration Scope & Executive Summary" (incorporating the `scope` and optional Git history).
    *   Creates a "Visual Proof of Completion" section. For each journey, it presents the extracted **"Grading"** text, followed by a newline, and then embeds the *newly copied/renamed images* on its own newline.
    *   Integrates the "Pre-Publishing Review Checklist".
    *   Includes a "Confidence Assessment".

5.  **Final Output & Archiving:**
    *   Generates a timestamp (e.g., `yyyy-MM-dd-HH-mm`).
    *   Saves the complete Markdown report to `.code_reviews/latest/change-review-<timestamp>.md`.
    *   Creates an archive directory: `.code_reviews/archive/<timestamp>/`.
    *   Copies the entire `latest/` directory to the newly created archive directory.

## Inputs

-   `source_project_root`: Absolute path to the root of the project.
-   `feature_spec_path`: Absolute path to the feature specification file.
-   `walkthrough_artifact_path`: Absolute path to the `walkthrough.artifact.md` file.
-   `journey_reports_root`: Absolute path to the `.journey_reports` directory.
-   `scope`: (Optional) "default" (since last review) or a specific timestamp (e.g., `2026-05-02-10-00`).

## Outputs

-   `.code_reviews/latest/change-review-<timestamp>.md`: The generated Markdown change review document.
-   `.code_reviews/latest/images/`: Directory containing all embedded screenshots.
-   `.code_reviews/archive/<timestamp>/`: Archived versions of the report and images.