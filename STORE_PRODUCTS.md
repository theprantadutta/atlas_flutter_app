# Atlas — Store Products & Billing Setup

This is the checklist for making Atlas premium **permanent** in the Google Play Console and Apple
App Store Connect. The app + backend code is already wired to these exact product IDs; you only need
to create the products and provision the server credentials below.

> Prices are USD anchors — set the equivalent price tier per store; the store's localized price is
> what the app actually shows at runtime (the in-app numbers are only fallbacks).

---

## 1. Products

| Product ID | Type | Price (USD) | Free trial | Notes |
|---|---|---|---|---|
| `atlas_aurora_monthly` | Auto-renewing subscription | **$9.99 / month** | **3 days** | In subscription group **Atlas Aurora**. |
| `atlas_aurora_yearly` | Auto-renewing subscription | **$99.99 / year** | **7 days** | Same group. ~17% cheaper than monthly. Mark as the "best value". |
| `atlas_founder_lifetime` | Non-consumable (one-time) | **$199.99** | -- | Lifetime "Founder" — grants premium forever. |

> **The app reads trial length from the store, never from a constant.** Play only returns
> offers a user is still *eligible* for, so a returning subscriber is never promised a
> second free trial. The constants in `AtlasProducts.declaredTrialDays` are documentation
> only. If you change a trial length in the console, the UI follows on its own.

All three unlock the **same** entitlement ("Atlas Aurora" premium): unlimited Aurora chat +
natural-language quick-add + deeper (paid-model) weekly reflections, cloud sync/backup/multi-device,
and deep insights + export. Monthly & yearly are one subscription with two base plans; lifetime is a
separate non-consumable.

**Display name (both stores):** "Atlas Aurora"
**Marketing description:** "Unlimited Aurora AI reflections & chat, natural-language quick-add,
cloud sync & backup across devices, and deep insights with export. Your caring companion, deeper."

---

## 2. Google Play Console

1. **Play Console → Monetize → Products → Subscriptions**: create subscription **`atlas_aurora`** (or
   one subscription with two base plans) exposing base plans `atlas_aurora_monthly` (P1M, $9.99) and
   `atlas_aurora_yearly` (P1Y, $99.99). **No offers/free-trial phase.** Activate both base plans.
   - ⚠️ The app queries product IDs `atlas_aurora_monthly` and `atlas_aurora_yearly` directly. If Play
     forces a single subscription ID with base-plan IDs, make the **base plan IDs** exactly these two
     strings, or adjust `AtlasProducts` in `lib/features/billing/services/entitlement_service.dart`.
2. **Play Console → Monetize → Products → One-time products**: create `atlas_founder_lifetime`
   (managed/non-consumable, $199.99), Active.
3. **Server validation credentials** (backend calls the Play Developer API to verify tokens):
   - Google Cloud project linked to Play → create a **service account**, grant it access in
     **Play Console → Users & permissions** (View financial data + Manage orders/subscriptions).
   - Download the service-account **JSON key**.
4. **Real-time developer notifications (RTDN)** for renewals/cancels/refunds:
   - Create a **Pub/Sub topic**, set it in **Play Console → Monetize → Monetization setup → RTDN**.
   - Add a **push subscription** on that topic whose endpoint carries the shared secret
     from `GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN`:
     `https://atlas.pranta.dev/api/v1/billing/google/rtdn?token=<GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN>`
   - The route is `[AllowAnonymous]` (Pub/Sub cannot present our JWT), so that token is the
     only thing between the open internet and a forged "renewed"/"refunded" notification.
     A request without it is logged and dropped. **Rotating the token means updating both
     the `.env` and the Pub/Sub push endpoint.**
   - Use **Send test notification** in the RTDN panel to confirm delivery; the backend logs
     `RTDN test notification received ... endpoint is live`.

---

## 3. Apple App Store Connect

1. **App Store Connect → your app → Subscriptions**: create subscription group **"Atlas Aurora"**
   with `atlas_aurora_monthly` ($9.99, 1 month) and `atlas_aurora_yearly` ($99.99, 1 year).
   Add an **introductory offer → Free Trial** of **3 days** on monthly and **7 days** on yearly.
   Add localized display name + description + a review screenshot.
   - ⚠️ Unlike Play, StoreKit does **not** tell the app whether *this* Apple ID has already used
     its trial (`isEligibleForIntroOffer` isn't exposed by the Flutter plugin). So on iOS the
     paywall says the trial is "available to new subscribers" rather than promising it outright,
     and a returning subscriber who is charged immediately was told up front. Android has real
     eligibility, so it promises the trial directly. This asymmetry is deliberate.
2. **In-App Purchases** (non-consumable): create `atlas_founder_lifetime` ($199.99).
3. **App Store Server API** credentials:
   - **Users and Access → Integrations → In-App Purchase** → generate an **API key** (.p8), note the
     **Key ID** and **Issuer ID**.
   - Purchase verification itself does **not** need these — the StoreKit2 signed transaction is
     verified locally against Apple's certificate chain. They're required for the nightly
     `reconcile-subscriptions` job, which asks the App Store Server API for the current state of
     each subscription. **Without them, iOS has no backstop for a dropped notification.**
4. **App Store Server Notifications V2**: set the Production + Sandbox URL to:
   `https://atlas.pranta.dev/api/v1/billing/apple/notifications`

---

## 4. Backend environment variables

Add these to the backend `.env` (solution root of `atlas-dotnet-api`, gitignored). Keys also live in
`.env.example` with dummy values.

```
# Local dev only — grants premium without a real store. MUST be false in production.
BILLING_DEV_BYPASS=false

# Google Play
GOOGLE_PLAY_PACKAGE_NAME=com.pranta.atlas               # Android applicationId (android/app/build.gradle.kts)
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=google-play-service-account.json   # path (resolved from the solution root) or inline JSON
GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN=<32+ random chars>            # must match the ?token= on the Pub/Sub push endpoint
GRACE_PERIOD_DAYS=3                                     # fallback window when Google's extended expiry is unreadable

# Apple App Store
APPSTORE_BUNDLE_ID=com.pranta.atlas                  # must match ios/Runner PRODUCT_BUNDLE_IDENTIFIER
APPSTORE_ISSUER_ID=<issuer id>                       # only needed by the nightly reconciler
APPSTORE_KEY_ID=<key id>
APPSTORE_PRIVATE_KEY=<AuthKey_XXXX.p8 PEM, or a path to it>
APPSTORE_ALLOW_SANDBOX=false                         # see the warning below
```

> ⚠️ **`APPSTORE_ALLOW_SANDBOX`** — a Sandbox StoreKit transaction is signed by the *same* Apple
> certificate chain as a real one, so a valid signature alone does not prove money changed hands.
> With this flag on, anyone with a sandbox Apple ID can unlock lifetime premium for free. It has
> to be **on** to test on a real device with a Sandbox tester, and **off** before the app is
> public. The backend logs the environment of every transaction it verifies, so you can confirm
> which one you're getting.

> `google-play-service-account.json` is **gitignored** — it holds a private key. Deploy it
> alongside the app (the compose mount / image root) rather than committing it.

## 5. Webhook endpoints (already implemented in the backend)

| Store | Notification URL | Auth |
|---|---|---|
| Google Play RTDN | `POST /api/v1/billing/google/rtdn?token=...` | shared secret in the query string, compared in constant time; the affected purchase is then re-validated against the Play Developer API |
| App Store Server Notifications V2 | `POST /api/v1/billing/apple/notifications` | none; the outer `signedPayload` **and** the inner `signedTransactionInfo`/`signedRenewalInfo` are each verified against Apple's x5c chain before anything is applied |

App-facing endpoints (JWT-authenticated):

| Endpoint | Purpose |
|---|---|
| `POST /api/v1/billing/verify` | `{ platform, product_id, purchase_token }` -> validates with the store and grants. `402` = the store rejected it, `503` = we could not reach the store (retry). |
| `GET /api/v1/entitlements` | Server-authoritative snapshot: `is_premium`, `is_lifetime`, `is_trial`, `premium_until`, per-feature flags, Aurora usage. |

**Which Google Play RTDN types are handled:** recovered (1), renewed (2), canceled (3),
purchased (4), on hold (5), in grace period (6), restarted (7), price change confirmed (8),
deferred (9), paused (10), pause schedule changed (11), revoked (12), expired (13); plus
one-time product purchased/canceled and `voidedPurchaseNotification` (refunds & chargebacks).
Every one re-validates against the Play Developer API before entitlement moves — the
notification body is only ever used to learn *which* purchase to go ask Google about.

**Which App Store notification types are handled:** `SUBSCRIBED`, `DID_RENEW`, `EXPIRED`,
`GRACE_PERIOD`, `DID_FAIL_TO_RENEW` (its `GRACE_PERIOD` subtype keeps access, without it access
stops), `DID_CHANGE_RENEWAL_STATUS`, `OFFER_REDEEMED`, `RENEWAL_EXTENDED`, `REFUND`,
`REFUND_DECLINED`, and `REVOKE` (Family Sharing access withdrawn). Anything unrecognized falls
back to the transaction's own expiry/revocation rather than guessing.

**Platform parity.** Both stores get: a signed/authenticated webhook, orphan recovery for a
purchase the ledger never saw (Play's `obfuscatedExternalAccountId` / Apple's `appAccountToken`,
both set from `PurchaseParam.applicationUserName`), refund revocation, free-trial reporting via
`is_trial`, a payment-problem push notification, and nightly reconciliation.

**Backstops.** RTDN is the fast path, not a guarantee (Pub/Sub drops messages; Google does
not reliably push refunds for one-time products). Two Hangfire jobs make both failure
directions self-heal:

| Job | Schedule (UTC) | Platforms | What it catches |
|---|---|---|---|
| `reconcile-subscriptions` | 03:00 daily | Android + iOS | Renewals that never arrived (user stuck expired despite paying) and lapses that never arrived (user keeps premium for free). Android re-queries the Play purchase token; iOS goes through the App Store Server API, because an Apple signed transaction is a point-in-time snapshot and only the original transaction id is a durable handle. |
| `reconcile-voided-purchases` | 03:30 daily | Android | Refunds/chargebacks Play never pushed — without it a refunded Founder keeps lifetime premium forever. Apple pushes `REFUND` reliably, so iOS refunds ride the webhook. |

A store call that fails (network, credentials, Play 5xx) is treated as *inconclusive*, never
as "not entitled", so an outage cannot silently downgrade paying users.

## 6. Testing before going live

- **Play**: add **license testers** (Play Console → Setup → License testing) and use an **internal
  testing** track so purchases are real-flow but not charged. License testers get accelerated
  subscription periods, so a 3-day trial elapses in minutes — handy for exercising the
  trial -> renewal -> RTDN path end to end. To test a trial *again* on the same account, cancel
  and let it fully expire; Play will not re-offer a trial an account has consumed (which is
  exactly what the paywall's eligibility check reflects).
- **Apple**: create **Sandbox testers** (Users and Access → Sandbox) and sign in on-device via
  Settings → App Store → Sandbox Account. Set **`APPSTORE_ALLOW_SANDBOX=true`** on the backend
  first, or every sandbox purchase is (correctly) rejected as unverifiable. Sandbox subscription
  periods are heavily accelerated — a 3-day trial lasts minutes — so the trial → renewal →
  notification path is testable in one sitting. Reset a tester's purchase history from
  App Store Connect to make them intro-offer-eligible again.
  - Point **both** the Sandbox and Production Server Notification URLs at the endpoint; sandbox
    notifications go to the sandbox URL only.
- **Local, no store**: set `BILLING_DEV_BYPASS=true` in the backend `.env` — `/billing/verify`
  grants entitlement from the product id without contacting a store, so the whole paywall →
  entitlement → premium-unlock flow is exercisable on the connected device. Set it back to `false`
  before any real/public build.

## 7. Go-live order

1. Create products (sections 2 & 3) and wait for them to become "Ready to submit"/active.
2. Provision credentials + set backend env vars (section 4); deploy backend.
3. Configure webhooks (section 5) and confirm the backend receives a test notification.
4. Test with license/sandbox testers (section 6).
5. Flip `SyncConfig.enabled` → `true` in the Flutter app (`lib/core/config/sync_config.dart`) so
   premium users get cloud sync, then ship. (Until then premium = Aurora depth + deep insights;
   sync stays behind the kill-switch so it never rides on the dev-bypass.)
