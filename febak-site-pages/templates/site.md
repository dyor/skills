# <host> (Febak <product site | blog>)

Process: the `febak-site-pages` skill. The site's pages live in Febak's database, not
here. The Markdown files in this folder are their source: edit them first, then push the
same text to Febak with the MCP. Find the site's ID with `list_sites` (host `<host>`).

| File | Febak page slug | URL | Published? |
|---|---|---|---|
| privacy-policy.md | `privacy-policy` | https://<host>/privacy-policy | yes |
| terms.md | `terms` | https://<host>/terms | yes |
| support.md | `support` | https://<host>/support | yes |

Pages on Febak with no file here (managed only in Febak): <slugs, or "none">.

Archive of published legal versions: `archive/<name>-<effective-date>.md`.

Product config (Febak `update_site` → `product`):

    appStoreUrl:  <url or "not live yet">
    playStoreUrl: <url or "not live yet">

Images: <where product-site images are hosted, e.g. a static repo path>.

## Extra checks for this app
- <e.g. numbers stated in the policy that are mirrored in code: update both>

## Notes
