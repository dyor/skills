---
name: adapty-store-payments
description: Set up, test and launch in-app purchases (consumable credit packs) through Adapty on both Google Play and the App Store. Use when wiring Adapty into a mobile or KMP app, when products don't load (NO_PRODUCT_IDS_FOUND), when test purchases succeed but nothing is granted, when deciding whether payments can be tested before launch, before submitting an app with its first in-app purchases, or when a store build should temporarily give credits away instead of selling them. Each app's payment setup and test progress live in the app repo (distribution/payments.md), never in this skill.
version: 1.1.0
---

# Adapty store payments (`adapty-store-payments`)

Consumable packs (credits, coins, tokens) sold on both stores through Adapty, credited by your own server from Adapty's webhook. Facts are marked **verified** (seen working in a real setup, or read in the SDK source) or **unverified** (from docs or memory: check before relying on it).

This skill is a **template**. It holds no app's product IDs, accounts, URLs or progress. Those live in the app's state file (below). When the user asks to change *this skill*, change what's true for every app; when something is true for one app only, or records how far that app has got, it goes in the app's state file.

## 0. The app's state file
Look for it in this order:
1. A path named in the app's `AGENTS.md` (or `CLAUDE.md`/`GEMINI.md`), e.g. "Payments: see `distribution/payments.md`".
2. `distribution/payments.md`.

If there is none, **bootstrap** it:
1. Copy `templates/payments.md` from this skill to `distribution/payments.md` in the app repo.
2. Fill in what the repo already shows: product IDs, placement ID, webhook function and its URL, server switch, sandbox cap. Leave the checklist unticked unless you have seen the step done.
3. Add one line to the app's `AGENTS.md`: `Payments (Adapty, both stores): see distribution/payments.md; process is the adapty-store-payments skill.`

Read the state file before doing anything, and update it as steps are done: tick a box only when you saw it done (a console page, a ledger entry), and record the date. Never put secrets in it (keys, webhook authorization values); name where they are kept instead.

## 1. Yes, payments can be tested before launch
The most common wrong belief: "purchases can't work until the app is live". They can, on both stores, without anyone being charged.

| Store | Who can test | How | Charged? |
|---|---|---|---|
| App Store | Any TestFlight tester, or a Sandbox Apple ID on a development build | Every TestFlight purchase is a sandbox purchase automatically | No |
| Google Play | Accounts on **Play Console → Settings → License testing** | Install from an internal/closed track, buy with the test card | No |

- Adapty reports both as `environment: "Sandbox"` on the webhook (**verified** on Android).
- Android needs a real device whose Play Store account is a license tester, with the app installed **from the Play track** (not sideloaded) (**verified** working that way; **unverified** that a sideloaded build fails, but it is Google's documented rule).
- License testers: create a dedicated email list (for example "Purchase testers") under License testing. Play may pre-tick your internal-testers list there too; untick it unless every internal tester should buy for free.
- Apple's reviewer also buys in sandbox. Anything you do to sandbox purchases, you do to App Review.

## 2. Setup, in order
Product IDs carry the amount (`credit_pack_60`, `credit_pack_60_v2` after a price change) so the server can credit any pack without a code change. Use the **same ID on both stores**.

### Google Play
1. Play Console → Monetize with Play → Products → **One-time products** (not subscriptions): create each pack with the same ID as iOS, set prices, **Activate**. Products need an app with a build uploaded to some track first. Having IAPs on iOS does nothing for Play: check this list actually has the products (**verified**: an empty list gives `NO_PRODUCT_IDS_FOUND` on Android).
2. Google Cloud: a service account, invited in Play Console → Users and permissions with app access to view financial data and manage orders. Upload its JSON key in **Adapty → App settings → Android SDK**, where the package name also goes (**verified**). Permissions can take hours to apply.
3. **Real-time developer notifications (RTDN)**: Adapty's Android settings show a Pub/Sub topic name. Paste it in Play Console → Monetization setup → Real-time developer notifications, content "Subscriptions, voided purchases, and all one-time products", then send a test notification; Adapty then shows RTDN as Active (**verified**). Without it, purchases can work while refunds never arrive.

### App Store
1. App Store Connect → Agreements, Tax and Banking: the **Paid Apps** agreement active, with banking and tax filled in. Products won't load in production without it.
2. App → In-App Purchases: create each pack as **Consumable**, with a review screenshot and review notes.
3. Adapty → App settings → App Store: the In-App Purchase key (or App Store Connect API key) and issuer ID.
4. **App Store Server Notifications V2** URL set to the one Adapty gives you (production and sandbox).
5. **First in-app purchases must be submitted together with an app version.** On the version page, under "In-App Purchases and Subscriptions", add them before submitting. A server switch can't turn on IAPs that Apple never reviewed. Until then Adapty shows the products' App Store status as "Action required" (**verified**); that alone is expected, but check the agreement too.

### Adapty dashboard
1. **Products**: one Adapty product per pack, with **both** the App Store product ID and the Google Play product ID filled in. A product with only the iOS ID loads on iOS and is invisible on Android: that is `NO_PRODUCT_IDS_FOUND` (error 1000) (**verified**).
2. Product **type Consumable**. The Android SDK consumes a purchase only when the product's type is Consumable; anything else is *acknowledged*, so the pack can be bought once and never again (**verified** in `StoreManager.acknowledgeOrConsume`, AdaptySDK-Android). Google refunds purchases that are neither consumed nor acknowledged within 3 days.
3. **Paywall** containing the products, attached to a **placement** whose ID is the only thing hardcoded in the app (for example `credit_packs`).
4. **Integrations → Webhook**: *Production endpoint URL* and *Sandbox endpoint URL* are separate fields, each with its own *Authorization header value*. Fill in both. Saving sends a verification request (an empty body); answer 200.

## 3. Server: credit from the webhook, never from the app
- Events: `non_subscription_purchase` (credit) and `non_subscription_purchase_refunded` (take back) (**verified**). Ignore everything else with a 200, or Adapty retries.
- Identify the user with `customer_user_id`: call `Adapty.identify(<your user id>)` (or `withCustomerUserId`) before any purchase.
- **Idempotent on the store transaction id** (`store_transaction_id`, falling back to `transaction_id`): write a ledger doc keyed by it in the same transaction as the balance increment. Adapty retries until it gets a 200.
- Check the `Authorization` header with a constant-time compare.
- **Sandbox: credit it, with a cap.** Rejecting sandbox events looks safe, but it means testers and App Review pay and get nothing (a near-certain rejection), and it hides whether the pipeline works. Credit sandbox purchases up to a per-account cap (a few hundred credits; track the running total on the balance doc). TestFlight is open to anyone with a public link, so an uncapped sandbox is free credits for anyone.
- Don't test with an "unlimited credits" debug account. Its balance never moves, so it can't prove anything.

## 4. App
- Load packs from the placement (`getFlow`/`getPaywall` then `getPaywallProducts`), never from hardcoded product IDs.
- Treat `makePurchase` success as "the store took payment", then poll your own balance until the webhook lands (a few seconds; give up politely after ~30 s).
- Keep a **server switch** (`purchasesOpen` on the balance endpoint) so selling can be turned off without a release.
- **The closed-shop screen must not mention prices.** "Email us to buy 60 credits for $4.99" is steering payment outside the store (App Store 3.1.1, Play Payments policy). "Credits are free during launch; email us how many you'd like" is fine. Build the mailto with the amount and the user id in it, so granting is copy-paste.
- Show the underlying store error in debug builds only. Release builds should show a plain "coming soon".

## 5. End-to-end test (do it on both stores before submitting)
Use an ordinary account (not a debug/unlimited one), on the exact build you will submit (Android: the release AAB with R8 on, since R8 can strip billing classes). Record each result in the app's state file.
1. Open the shop: real prices from the store appear, not your placeholders.
2. Buy the smallest pack: the store sheet says sandbox/test; credits arrive within seconds; a ledger doc appears with `environment: Sandbox`.
3. **Buy the same pack again.** "You already own this item" (Play) means it was acknowledged instead of consumed: fix the Adapty product type (section 2). A second ledger doc with a new transaction id means consumption works (**verified** on Android).
4. Refund it (Play Console → Order management; iOS: sandbox refund request): the refund event arrives and the credits come off.
5. Kill the app mid-purchase, reopen: no double credit, no lost credit.
6. Check the webhook's "Last sent events" in Adapty: all Success.

## 6. Launch sequences
**Payments at launch (preferred when there's time):** section 2 complete → section 5 passes on both stores → `purchasesOpen = true` → submit the iOS version *with* the IAPs attached and review notes saying where the shop is → submit Android.

**Free credits first, payments later (when the launch date can't move):** set `purchasesOpen = false` and ship the email screen (section 4) → finish sections 2 and 5 on the test tracks → submit an **iOS update with the IAPs attached** → once Apple approves it, set `purchasesOpen = true`. Android needs no new build if the purchase code already shipped.

## 7. Symptoms
| Symptom | Cause |
|---|---|
| `NO_PRODUCT_IDS_FOUND` / error 1000 on Android only | No active Play one-time products, or Adapty products have no Google Play ID |
| Packs show "coming soon" on a store build | Products failed to load; reproduce on a debug build to see the error |
| Test purchase succeeds, no credits | Webhook drops sandbox; sandbox endpoint URL blank; or `customer_user_id` not set before purchase |
| Can buy a pack once, never again (Android) | Adapty product type isn't Consumable, so the purchase was acknowledged, not consumed |
| Refunds never reduce the balance (Android) | RTDN not connected to Adapty |
| Adapty shows App Store status "Action required" | IAPs not yet submitted with a version (expected before first review), or an agreement needs accepting |
| App Review: "IAP not found" / "could not purchase" | IAPs not attached to the version, Paid Apps agreement inactive, or sandbox purchases not credited |
