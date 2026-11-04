---
name: febak-site-pages
description: Edits pages on Febak-hosted sites (product sites and blogs) through the Febak MCP, especially legal pages such as a privacy policy, terms and support. Use whenever the user asks to update, draft, publish or check a live legal page or website copy on a Febak site. Each app's site details (site, pages, source files, extra checks) live in the app repo (distribution/web/README.md), never in this skill.
version: 1.1.0
---

# Febak site pages (`febak-site-pages`)

This skill is a **template**. It holds no site's ID, host, pages or file paths. Those live in the app's site file (below). When the user asks to change *this skill*, change what's true for every Febak site; when something is true for one app only, change that app's site file.

## 0. The app's site file
Look for it in this order:
1. A path named in the app's `AGENTS.md` (or `CLAUDE.md`/`GEMINI.md`), e.g. "Website: see `distribution/web/README.md`".
2. `distribution/web/README.md`.

If there is none, **bootstrap** it:
1. Copy `templates/site.md` from this skill to `distribution/web/README.md` in the app repo.
2. Fill it in: `list_sites` for the site (look up its ID there, never guess), `list_pages` for its pages, and the repo for the Markdown files that are their source. Put each live page's text in the repo if it isn't there yet.
3. Add one line to the app's `AGENTS.md`: `Website pages are Febak pages: see distribution/web/README.md; process is the febak-site-pages skill.`

Always read the site file's notes and its extra checks before a change.

## 1. What Febak is
- Febak hosts product sites (`kind: product`) and blogs. Pages are Markdown/MDX stored in Febak's database and served at `https://<host>/<slug>`. They are not in any git repo, and Febak keeps no history.
- Tools: `mcp__febak__list_sites`, `list_pages`, `get_page`, `create_page`, `update_page`, `delete_page`, `update_site`, `set_home_page`. If they are deferred, load them with ToolSearch (`select:mcp__febak__...`) before the first call.
- Look the site ID up with `list_sites` at the start of a session rather than storing it.

## 2. Rules
1. **Source first.** Edit the page's Markdown source in the repo, then push the same text to Febak. If a Febak page holds text the repo lacks, `get_page` it and reconcile before writing. Do not let the two drift.
2. **Read before write.** Call `get_page` first. `update_page` changes only the fields you pass, so pass `content` in full.
3. **Public content needs the user's explicit go-ahead.** A live legal page is what users and app reviewers read. Prepare changes as an unpublished draft: `create_page` with `published: false` at slug `<slug>-draft`. Publish with `update_page` (`published: true`) only after the user says so.
4. **Keep store promises in step.** Any change to what is collected or kept must match the App Store privacy label, the Play Data safety form and the in-app consent text. A policy must not describe features the app does not ship yet, such as a consent screen or a web deletion page.
5. **Deletion is confirm-gated.** `delete_page` needs `confirm: true`. Only delete on an explicit request, and look at the target first.
6. **Leave product config alone** (`update_site`, `set_home_page`) unless asked. Store URLs live in `product`.
7. **Effective date.** Legal pages open with `*Effective <date>.*`. Update it when the content changes, and say what changed in the Changes section. A draft says `*Draft of <date>. Effective when published.*`.
8. **Archive every published version.** Because Febak keeps no history, the repo does. Before a published legal page is overwritten, copy its current text to `<source folder>/archive/<name>-<effective-date>.md` (for example `privacy-policy-2026-10-12.md`), using the date the old text took effect. If the live text is already in git, `git show HEAD:<path>` gives it. Never overwrite an archive file. Unpublished drafts need no archive, but the repo copy of the draft is the source.
9. **Images** for a product site are not uploaded through the MCP: they are hosted elsewhere (the site file says where) and listed through `update_site`.

## 3. Legal-page change checklist
1. Edit the Markdown source (privacy policy, and terms if affected).
2. `get_page` the live page and compare it with the repo version.
3. Archive the live version (rule 8).
4. Create the `-draft` page unpublished and show the user the text.
5. After approval, publish with `update_page`, then delete the draft with confirmation.
6. Check the App Store privacy label, the Play Data safety form and the in-app consent text match.
7. Run the app's extra checks from its site file (for example, numbers in the policy that are mirrored in code).
