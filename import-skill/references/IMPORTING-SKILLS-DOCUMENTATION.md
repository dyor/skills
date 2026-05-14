# Importing Skills: End-to-End Documentation

This document explains how the `import-skill` and `update-importable-skill` skills work together, the lifecycle of a skill from authoring through downstream refresh, and how to think about bundling related skills.

If you only want to know which command to run, jump to [Cheat Sheet](#cheat-sheet) at the bottom.

**Where this file lives**
This doc ships inside `import-skill/references/`, following the Anthropic skill-creator convention for long-form reference material (the `references/` subfolder is *not* auto-loaded into agent context; the SKILL.md points agents here on demand). In the `dyor/skills` source repo it sits at `import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md`; in any project that has bootstrapped `import-skill` it sits at `.skills/import-skill/references/IMPORTING-SKILLS-DOCUMENTATION.md`. The bootstrap step downloads it alongside the SKILL.md and the python script, so an agent working in a downstream project can read it locally without a network call.

**Where to go next**
- To install a published skill into a project, read [`import-skill/SKILL.md`](https://raw.githubusercontent.com/dyor/skills/main/import-skill/SKILL.md) (consumer-side).
- To bump `version:` on a skill you're publishing, read [`update-importable-skill/SKILL.md`](https://raw.githubusercontent.com/dyor/skills/main/update-importable-skill/SKILL.md) (author-side).

---

## The Two Skills at a Glance

| Skill | Audience | Where it runs | What it does |
|---|---|---|---|
| `update-importable-skill` | **Skill authors** | Author's repo, before `git push` | Edits YAML front-matter on a `SKILL.md` — most importantly, bumps `version:` |
| `import-skill` | **Developers consuming skills** | Consumer's project, in `.skills/` | Pulls a remote skill into `.skills/imported-skills/` and refreshes it later by detecting drift |

They are deliberately separate because they have different audiences, run in different repos, and run at different times. They are connected through one shared contract: **the `version:` field in the SKILL.md front-matter.**

---

## The Happy Path (Author Uses `update-importable-skill`)

This is the lifecycle that everything is optimized for. Every actor below is exercising the canonical workflow.

### 1. Author creates a new skill
The author writes a new `SKILL.md` and declares a `version:` field up front:

```yaml
---
name: my-cool-skill
description: Does the cool thing.
version: 0.1.0
---

# Skill: My Cool Skill
...
```

The version string can use any scheme — semver, dates, monotonic integers — because `import-skill` only compares for equality, not order. Pick one and stay consistent.

### 2. Author pushes the skill to GitHub
A normal `git commit && git push`. The skill is now reachable at a URL like:

```
https://github.com/<owner>/skills/tree/main/my-cool-skill
```

### 3. Developer imports the skill
In a different project, the developer (or their agent) runs:

```bash
python3 .skills/import-skill/scripts/import_skill.py \
  --url "https://github.com/<owner>/skills/tree/main/my-cool-skill"
```

What happens under the hood:
- The skill is cloned into `.skills/imported-skills/my-cool-skill/`.
- `import-skill` reads the imported `SKILL.md`'s front-matter and captures `version: 0.1.0`.
- `import-skill` rewrites three importer-owned fields onto the local copy: `import_commit`, `import_date`, `import_url`. The author's `version:` is preserved as-is.
- A row is appended to `.skills/IMPORTED-SKILLS.md`:

```
| my-cool-skill | imported-skills/my-cool-skill | https://github.com/.../my-cool-skill | 0.1.0 | <sha> | 2026-05-13 09:00:00 |
```

### 4. Author makes a meaningful change and bumps the version
The author edits the skill — fixes a bug, adds a step, changes a default. **Before pushing**, they trigger `update-importable-skill`:

> "Bump the version on `my-cool-skill`."

`update-importable-skill` parses the YAML block, bumps `version: 0.1.0` → `version: 0.1.1` (or whatever the author asks for), confirms, writes, and reminds the author to commit and push. After the push, the new version is live on `main`.

**When the author should trigger `update-importable-skill`:**
- Right before pushing a change that downstream consumers should pick up — bug fix, new behavior, breaking change, script update.
- When changing other author-controlled metadata like `description:` or `author:`.

**When the author should NOT trigger it:**
- For pure documentation typos or comment edits that don't change behavior. Bumping for these creates churn for downstream refreshes without giving them anything useful.
- To set `import_commit`, `import_date`, or `import_url` — those are owned by `import-skill` on the consumer side. `update-importable-skill` will refuse or warn on those keys.

### 5. Developer refreshes
At some later time (proactively, or after seeing the "7 days stale" tip), the developer runs:

```bash
python3 .skills/import-skill/scripts/import_skill.py --refresh --check
```

`import-skill` walks every row in `IMPORTED-SKILLS.md` and, for each one:
1. Reads the local `SKILL.md`'s `version:` and `import_commit:`.
2. Fetches the upstream `SKILL.md` and reads its `version:`.
3. If both versions exist and differ → reports `[UPDATE] my-cool-skill: v0.1.0 -> v0.1.1`.
4. `--check` writes nothing; it just prints the per-skill plan.

The developer then runs `--refresh` (without `--check`) to apply the plan. Only skills whose versions actually changed get re-imported. Up-to-date skills are skipped.

This is the entire happy path. The author bumps; the developer refreshes; both sides agree on what's new because of one string in one YAML block.

---

## The Fallback Path (Author Did NOT Use `update-importable-skill`)

Not every author maintains a `version:` field. `import-skill` handles this case so consumers aren't stranded on stale third-party skills.

When either the local `SKILL.md` or the upstream `SKILL.md` is missing `version:`, `import-skill` falls back to **commit-SHA comparison**:

1. The local `import_commit` (written at import time) is compared against the current HEAD SHA of the upstream path. The SHA is looked up via the GitHub commits API, scoped to the sub-path of the import URL, so changes elsewhere in the repo don't cause false positives.
2. If the SHAs match → `[SKIP] up-to-date (sha abc1234, no version)`.
3. If they differ → `[UPDATE] sha abc1234 -> def5678 (no version)`.

If even SHA comparison is impossible (e.g. the import URL is a generic `raw` URL with no commit hash in its path, and the API call fails), `import-skill` reports `[FORCE] no version or SHA available; forcing re-import` and re-imports unconditionally. This preserves the original always-overwrite behavior as a last resort.

**Order of preference:** declared version → SHA → force. The further down this ladder a skill falls, the noisier the refresh; encouraging authors to adopt `version:` is the way to keep refresh quiet and precise.

---

## Using `update-importable-skill` Directly (Outside the Import Workflow)

`update-importable-skill` is a standalone front-matter editor. Even though it pairs naturally with `import-skill`, the author can run it any time they want to modify front-matter on any `SKILL.md` — including skills they don't intend to publish.

Common direct-use cases:

- **Bumping `version:` on every push.** The canonical use; described above.
- **Backfilling `version:` on a skill that doesn't have one.** First-time adoption. After this, the skill is on the happy path.
- **Updating `author:` or `description:`.** Ordinary metadata edits, no `import-skill` involvement.
- **Batch-updating a planning-skill bundle.** All `SKILL.md` files under a parent directory can be processed in one pass.
- **Cleanup of incorrectly-set importer fields.** If an author accidentally checked in `import_commit:` or `import_date:` (e.g. they ran `import-skill` against their own published copy for testing), `update-importable-skill` can strip them. Those three fields belong only on the consumer side.

**Things to remember when using it directly:**
- `update-importable-skill` does not push to GitHub. It only edits the file. The author still has to `git commit && git push`.
- The skill does not validate that `version:` is monotonically increasing — it only ensures the field is present and set to the value the author specified. Mis-typing `0.2.0` as `0.0.2` will not be caught; consumers will simply see a different string and refresh.
- Editing `name:` is allowed but causes downstream chaos — the local directory and tracking row are keyed off the name at import time. Renaming a published skill is effectively a new skill.

---

## Field Reference

| Field | Who writes it | Where it lives | Purpose |
|---|---|---|---|
| `name` | Author | Front-matter | The skill's identity. Used for the local directory name on import. |
| `description` | Author | Front-matter | How agents decide whether the skill is relevant. |
| `version` | Author (via `update-importable-skill`) | Front-matter | Primary drift signal. Compared as a string. |
| `author`, etc. | Author | Front-matter | Informational. |
| `import_commit` | `import-skill` | Front-matter, written at import time | The upstream SHA captured during import. Used as the SHA-fallback drift signal. |
| `import_date` | `import-skill` | Front-matter | When the consumer last imported. |
| `import_url` | `import-skill` | Front-matter | The URL the consumer imported from. |

The same three importer-owned fields also appear in `.skills/IMPORTED-SKILLS.md` alongside the captured `version` and a human-readable `Last Updated` timestamp.

---

## Cheat Sheet

**Author, publishing a new skill:**
```yaml
# In SKILL.md front-matter
version: 0.1.0
```
```bash
git commit && git push
```

**Author, releasing a change:**
> "Bump the version on `<skill>`."  *(triggers `update-importable-skill`)*
```bash
git commit && git push
```

**Developer, first-time import:**
```bash
python3 .skills/import-skill/scripts/import_skill.py \
  --url "<github tree URL>" [--name "<override>"]
```

**Developer, periodic refresh:**
```bash
python3 .skills/import-skill/scripts/import_skill.py --refresh --check
python3 .skills/import-skill/scripts/import_skill.py --refresh
```

**Developer, nuclear option (re-import everything):**
```bash
python3 .skills/import-skill/scripts/import_skill.py --refresh --force
```

---

## Bundling: How Should These Two Related Skills Be Organized?

You raised this directly: **should `import-skill` and `update-importable-skill` live together under a parent folder (with a README), the way `planning-skills/kmp-baseline/` does for its blueprints?**

My recommendation: **do not bundle them under a shared parent folder. Use a top-level family doc (this file) plus front-matter cross-references instead.** Here's the reasoning, and the alternatives if you disagree.

### Why the `kmp-baseline` pattern doesn't fit here

The `kmp-baseline` bundle works because its blueprints are **all consumed by the same actor, in sequence, as one workflow.** A developer who wants to bootstrap a KMP project needs every blueprint — prompt → agent → guide → hints → calculator → validation — and the README orchestrates them in order. The bundle exists because the blueprints are a single logical unit that was split into chunks only to keep individual SKILL.md files small.

`import-skill` and `update-importable-skill` are the opposite shape:
- They are **consumed by different actors**: end-user developers vs. skill authors.
- They run in **different repos**: the developer's project vs. the author's source.
- They run at **different times**: import is one-shot, refresh is periodic, version bumping is per-change.
- A developer importing skills almost never needs `update-importable-skill`, and an author bumping versions almost never needs `import-skill` locally (they may already have it for testing, but it's a separate concern).

Bundling them under `import-skills/` would put irrelevant content into both audiences' context. The agent at import time would load front-matter for a skill it has no business invoking; the author bumping a version would have to navigate past importer documentation. The bundling cost is real and the cohesion benefit is mostly imaginary because they're not run together.

There's also a concrete cost: `import-skill` has a fixed bootstrap URL baked into its `SKILL.md`. Moving it to a subfolder would change that URL and break every existing bootstrap prompt in the wild.

### What to do instead (concrete recommendations)

1. **Keep the flat layout.** `import-skill/` and `update-importable-skill/` stay as siblings at the repo root. This matches what's already deployed.

2. **Adopt this `IMPORTING-SKILLS-DOCUMENTATION.md` as the top-level family doc.** Top-level docs are the right level of indirection for "here's how two related skills fit together, and here's the contract that binds them." Link to it from each skill's `SKILL.md`.

3. **Cross-reference in each `SKILL.md`'s prose.** Add a short "Related Skills" section to both `SKILL.md` files. One sentence, with the partner skill's name and when to pivot to it. This is the part agents actually read at trigger time.
   - In `import-skill/SKILL.md`: *"If you are the author of a skill and want to bump its `version:` before publishing, use `update-importable-skill` instead."*
   - In `update-importable-skill/SKILL.md`: *"To install a published skill (yours or someone else's) into a project, use `import-skill`."*

4. **Make the `description:` lines do triage.** Agents pick which skill to invoke based on the description. Make sure each description names the other skill or its audience by hint:
   - `import-skill`: "Imports / refreshes a remote skill into `.skills/imported-skills`. *Consumer-side; for publishing/version bumping see update-importable-skill.*"
   - `update-importable-skill`: "Edits YAML front-matter (notably `version:`) on a SKILL.md before publish. *Author-side; for installing skills see import-skill.*"
   This is the cheapest, highest-leverage change: the discovery layer for agents is the description field.

5. **Optionally add a `family:` front-matter key.** Both skills could declare `family: importing-skills`. This is purely a convention for now — no tool reads it — but it makes the relationship machine-discoverable later (e.g. an index generator, a "list related skills" command). Don't add a key unless and until something consumes it; otherwise it's documentation cosplaying as data.

### When you *would* want the `kmp-baseline` pattern

The folder-with-README pattern is the right call when:
- The skills are sequenced steps of a single workflow run by one actor in one session.
- The skills genuinely don't make sense individually (e.g. the calculator only parses output from the guide).
- The number of related skills is large enough (4+) that a flat layout becomes noisy.

For two skills that share a contract but serve different audiences, a family doc plus prose cross-references is the cheaper, clearer pattern. Reach for bundling when cohesion is high *and* the audience is single.

### One pattern to steal from `kmp-baseline`

The README in `planning-skills/kmp-baseline/` opens with a numbered list of every blueprint and one sentence on what each does. That's a great onboarding pattern regardless of whether the skills are bundled. The opening table in this document is the same idea, scaled down for two skills.
