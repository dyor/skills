# Payments: <App name>

Process: the `adapty-store-payments` skill. This file holds this app's setup and how far it
has got. Tick a box only when you saw it done, with the date. No secrets here: name where
keys and webhook authorization values are kept instead.

## Setup
| What | Value |
|---|---|
| Adapty account | <email> |
| Play Console account | <email> |
| App Store Connect account | <email> |
| Package / bundle ID | <com.example.app> (dev build: <...>) |
| Products (same ID on both stores) | `credit_pack_20` $1.99, ... |
| Adapty placement | `credit_packs` |
| Webhook endpoint | <URL> (code: <file>) |
| Sandbox cap | <N> credits per account (<where it's set>) |
| Server switch | `purchasesOpen` (<where it's set>) |
| Play service account | <name> (key kept: <where>) |
| License testers list | <list name>: <emails> |

## Google Play
- [ ] One-time products created and active
- [ ] Service account invited with financial data and orders access
- [ ] Service account key and package name in Adapty Android settings
- [ ] RTDN topic set in Play Console; Adapty shows it Active
- [ ] License testers list set

## App Store
- [ ] Paid Apps agreement active (banking, tax)
- [ ] Consumable IAPs created, with review screenshot and notes
- [ ] In-App Purchase key in Adapty App Store settings
- [ ] Server Notifications V2 URLs set (production and sandbox)
- [ ] IAPs attached to the version being submitted

## Adapty
- [ ] Products have both store IDs and type Consumable
- [ ] Paywall on the placement
- [ ] Webhook production and sandbox URLs with authorization

## End-to-end test (skill section 5)
| Step | Android | iOS |
|---|---|---|
| Store prices shown | | |
| Smallest pack credited (Sandbox) | | |
| Same pack bought again | | |
| Refund takes credits off | | |
| Kill mid-purchase: no double/lost credit | | |
| Adapty webhook events all Success | | |

## Notes
