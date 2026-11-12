---
name: google-play-publishing
description: How publishing and testing on Google Play actually behaves, learned the hard way shipping Golf Sparks. Use when releasing an Android app to Play (internal, closed testing, production), when a tester sees "App not available", when an upload fails a declaration check such as AD_ID, when deciding which track to publish to, or when writing public copy that offers an Android beta. Also compares TestFlight.
version: 1.3.0
---

# Google Play publishing (`google-play-publishing`)

Facts below were verified on a real app unless marked **unverified**. Sources: the Play Console Help page "Set up an open, closed, or internal test", the Play Developer API docs, and Golf Sparks releases in October 2026.

## 1. Tracks and who can use them
| Track | Who gets in | Review before testers can install? |
|---|---|---|
| Internal testing | Up to 100 Google accounts on an email list (or a Google Group) | No. Available within minutes, even for a draft app |
| Closed testing | Email lists / Google Groups you choose | Yes for a new app; each release is "sent for review automatically" |
| Open testing | Anyone, from the Play listing or a link | Yes |
| Production | Everyone | Yes |

- A `completed` release on a draft app is rejected for production-like tracks; Play only accepts `draft` and the release must be sent for review by hand in Console (Publishing overview).
- Production access: **personal** developer accounts created after Nov 2023 must run a closed test with 12 testers opted in for 14 days first (**unverified, check Console**). **Organization** accounts can go internal → production.

## 2. Testers: the invite is two steps, and the link is not an invite
1. **Add** the tester's Google account to the track's email list (Console → Testing → Internal testing → Testers) and **tick that list for the track**. Creating a list is not enough.
2. The tester **opens the join link while signed in to that same account** and taps "Become a tester", then installs from the Play Store.

The join link (`play.google.com/apps/internaltest/<id>`, "Copy link" under *How testers join your test*) can be shared freely but gives access to no one who is not on the list. The Console text "Testers can join your test on the web" reads as if anyone can join; they cannot (that is open testing).

Error messages, and what they mean:
- "Your account hasn't yet been invited to participate in this app's internal testing program" → account not on the list, wrong account signed in, or list not ticked for the track. (The release is fine.)
- "A testing version of this app hasn't been published yet or isn't available for this account" → no live release on that track for this account: closed testing still waiting for review, or no release at all.

The Play Developer API cannot read email lists (`testers.get` returns Google Groups only), so confirm lists in Console.

## 3. You cannot delete a track: assume closed testing lives forever
- Nothing in the Help pages or API docs describes deleting a track. Console offers *Manage track → Pause track*: testers stop getting updates, the app stays installed. Whether a paused track is excluded from Play's validation is **unverified**; one forum report says old APKs on a paused track still raised a policy warning.
- **Play validates every release in the edit it commits, across tracks**, and the error never says which track is at fault. Real example: a new build with the `AD_ID` permission removed was rejected with "This release includes the AD_ID permission but your declaration says your app doesn't use advertising ID" because closed testing still held the older build 4.
- Therefore: **keep every non-production track that holds a release on the newest build, in the same Play edit.** Upload the bundle once, then `PUT edits/{id}/tracks/{track}` for internal and for every other non-production track that already has a release, then commit. Never touch production this way. Do this even if nobody uses closed testing.
- Cost of publishing to both: each closed-testing release goes through review (days) and any closed testers get every build. Whether that review delays internal testers is **unverified**.
- Find the culprit: Console → App bundle explorer shows which version codes are active and on which tracks; or read tracks via the API (`edits.tracks.get` for internal/alpha/beta/production inside a throwaway edit, then delete the edit).
- Halting is not a way out: the API only lets you halt a `completed` release when an earlier completed release exists on that track.

Golf Sparks implements this in Publisher: `scripts/play_release.rb` (single edit, all populated non-production tracks) called by `android_upload.sh`; set `PUBLISHER_USE_SUPPLY=1` for the old single-track fastlane path. Once production has started, Publisher drops closed testing from its UI and promotes internal → production, but still keeps the old closed track current.

## 4. API quirks that cost time
- Commit with `changesNotSentForReview=true` on a draft app; an app whose changes are sent automatically answers 400 "the query parameter changesNotSentForReview must not be set". Try with the flag, retry without when Play says so.
- Release notes are limited to **500 characters** (UTF-16 units, an emoji counts 2). Over the limit the whole upload fails.
- `versionCode` only has to increase (Play orders by it); `versionName` is a free label and can look "backwards".
- `edits:validate` checks an edit without committing; useful for a dry run. Delete abandoned edits.
- A promotion copies the source release including its release notes; pass `version_code` and the notes file to set notes on the destination.

- **Approval is silent.** Play often sends no email when a production release passes review, and the API never says it passed (a first release can still read `draft`). The signal is public: the store page (`play.google.com/store/apps/details?id=<pkg>`) returns 200 once the app is live, and its "Updated on <date>" changes when a later release goes live. Publisher watches both and notifies (build-publisher, "Store watch"). Golf Sparks went live with no email; its page showed "Updated on Nov 1, 2026".

## 5. Declarations that bite
- **Advertising ID:** libraries can merge `com.google.android.gms.permission.AD_ID` in. If the app shows no ads, add `<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />` and check the *built AAB* (strings of `base/manifest/AndroidManifest.xml`), not just the merged manifest. Declare "No" only if the permission is truly absent from every live release.
- **Health apps:** `ACTIVITY_RECOGNITION` makes Play ask for a health feature declaration. "Activity and fitness" is the honest category for step counting / walk detection. The privacy policy must say so.
- **Location prominent disclosure:** the in-app text must match what the app really does (Android foreground-only vs iOS background). A foreground service needs its own Play declaration.
- **Google Sign-In (Credential Manager) says "No credentials available" in a Play-installed build:** Firebase/Google Cloud has no Android OAuth client for the package + the SHA-1 of the key that signed the build. A build installed from Play is signed with the **Play app signing key**, not your upload key, so register that one. Register all three, per package (including a `.dev` suffix app):
  1. **Play app signing SHA-1:** Play Console → Test and release → App integrity → App signing (the value sits behind a copy button; copy it, or read the clipboard write in the page).
  2. **Upload key SHA-1:** `keytool -list -v -keystore <keystore.jks> -alias <alias>` (covers APKs you build and sideload).
  3. **Debug key SHA-1:** `keytool -list -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey` (the `.dev`/debug app).
  Add each with `firebase apps:android:sha:create <appId> <SHA-1>` (list with `firebase apps:android:sha:list <appId>`; app ids from `firebase apps:list ANDROID`). Firebase then creates the Android OAuth clients; refresh `google-services.json` with `firebase apps:sdkconfig ANDROID <appId>`. It can take a few minutes to take effect. The web (server) client id in code is unaffected. The old app's SHA-1 does not carry over to a new package.
- Keep the Data safety form, the privacy policy page and the in-app text in step (see the `febak-site-pages` skill).

## 6. Public copy while the app is internal-only
- Do not show a download button or the join link as if anyone can install. The link does nothing for people not on the list.
- Offer an email path instead: "Email admin@dyor.com from the Google account you use for Play; I add you to the tester list, then send the join link; you open it and accept the invite, then install." A `mailto:` with a body prefilled "The Google account I use for Google Play is:" saves a round trip.
- Do not link the Play store listing page until production is live; it returns "not found" to non-testers.
- iPhone: the TestFlight public link is genuinely open (see below), so the two platforms need different wording.
- **Counter-example (Golf Sparks, 2026-10-28):** the join link was put on the Play badge and in a "now on Google Play" post that said "open the link, accept the invite, install". That overpromises: anyone not on the tester list hits "App not available". If the link is shown at all, say next to it that access needs the tester list, and give the email path. Prefer "Android internal testing" wording over "now available on Google Play".

- **Pattern that works:** a "Request access" control that is a real `mailto:` link, not a plain text label. Plain text such as "Invite-only: email admin@dyor.com" cannot be clicked, and is easy to miss. Address it to the developer's support mailbox, put the app name in the subject (one mailbox serves several apps), and prefill the body: "Please add me to the <app> Google Play testers. The Google account I use for Google Play is:". Show it where the store badge would be, and in any header "Get the app" button.
- Keep one owner for the public wording. In Golf Sparks two sessions edited the same site config, and one replaced the other's link with the unclickable text above. If a config is shared, read it before writing and change only your keys.

## 6b. Febak sites (optional, delete this section if you do not use Febak)
Everything here is specific to the author's Febak-hosted product sites (golfsparks.dyor.com, apps.dyor.com). It is not part of Google Play itself: if you host elsewhere, remove this whole section and keep section 6.

- Both sites read one config: Febak MCP `update_site` → `product`. Keys: `playStoreUrl` / `appStoreUrl`, `playStoreStatus` / `appStoreStatus`, and `playStoreRequestEmail` / `appStoreRequestEmail`. apps.dyor.com is the hub; it lists a site while `hub` is not false, so it needs no separate edit. The hub caches, so a change can take a while to show there.
- **Invite-only Android:** leave `playStoreUrl` unset and set `playStoreRequestEmail` (e.g. admin@dyor.com). The badge becomes a "Request access" mailto with the subject and body from section 6, and the header button becomes App Store | Android: request access. Clear `playStoreStatus` so no unclickable text competes with it.
- `playStoreStatus` text shows under a badge. Without a link the badge is greyed out; with a link the badge is clickable and the label still shows (a link with no label looks like a launched app).
- With both URLs set, the header "Get the app" button renders a split App Store / Google Play pill; with one it is a single button.
- When going to production: set the real store URLs and clear the status labels and request emails.
- Images in Febak pages: use relative `/_static/<site>/...` paths. Absolute URLs on the site's own host fail Next's image optimizer (400 INVALID_IMAGE_OPTIMIZE_REQUEST) and show as broken. Pages without an `image` fall back to the Febak logo in cards, and a site without `logo` uses the Febak favicon, so set both for every product site.
- Static images go in the Febak repo (`public/_static/<site>/`), pushed to `main` (Vercel deploys, about a minute); wait for 200s before pointing `product.screenshots` at them.
- Code lives in the Febak repo: `components/product/store-badges.tsx` and `header.tsx`; config validation in `lib/product.ts`.

## 7. TestFlight compared (Golf Sparks setup, checked in App Store Connect)
- **Internal TestFlight group:** App Store Connect users on your team only (up to 100). No review; builds arrive in minutes. Closest to Play internal testing, but it is for the team, not friends.
- **External TestFlight group:** up to 10,000, by email **or a public link** (`testflight.apple.com/join/<code>`). Anyone with the link can join, no invite step. The first build of each version goes through **Beta App Review** (lighter than App Review; Apple does not call it automated); later builds of the same version usually skip it.
- Golf Sparks has two groups: "Golfers" (internal, all builds) and "Golfers external" (public link `R7hTm1vN` enabled, no limit). Latest builds were `IN_BETA_TESTING` for both.

### Side by side
| | Who can join | Google/Apple review | What the tester does |
|---|---|---|---|
| **TestFlight external** | Anyone with the public link | Beta App Review, first build per version | Install TestFlight, open link, install |
| **Play internal** | Only accounts you add to the list (max 100) | **None** | You add their account; they open the join link, accept, install |
| **Play closed** | Only invited accounts or groups | **Yes, for a new app** | Same as internal, after Google approves |
| **Play open** | Anyone | Yes | Join from the Play listing |

Common misreading to avoid: Play internal testing is *not* reviewed (not even a light review) and is *not* open to anyone with the link. The reviewed track on Play is closed testing. The "anyone can join" experience on Play is open testing, not internal.

## 8. Details to add from other sessions
This skill was written from one session. Add specifics from these sessions if they hold more:
- "Google Play internal testing release" (first release steps, store listing, Data safety answers).
- "Golf Sparks Google Play launch" (launch posts, apps.dyor.com update, listing copy).
Look for: Data safety answers, content rating, target audience, app access instructions, screenshot specs, and any review rejection details.
