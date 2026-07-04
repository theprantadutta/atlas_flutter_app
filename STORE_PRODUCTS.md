# Atlas — Store Products & Billing Setup

This is the checklist for making Atlas premium **permanent** in the Google Play Console and Apple
App Store Connect. The app + backend code is already wired to these exact product IDs; you only need
to create the products and provision the server credentials below.

> Prices are USD anchors — set the equivalent price tier per store; the store's localized price is
> what the app actually shows at runtime (the in-app numbers are only fallbacks).

---

## 1. Products

| Product ID | Type | Price (USD) | Notes |
|---|---|---|---|
| `atlas_aurora_monthly` | Auto-renewing subscription | **$4.99 / month** | In subscription group **Atlas Aurora**. No free trial / intro offer. |
| `atlas_aurora_yearly` | Auto-renewing subscription | **$39.99 / year** | Same group. ~33% cheaper than monthly. No trial. Mark as the "best value". |
| `atlas_founder_lifetime` | Non-consumable (one-time) | **$79.99** | Lifetime "Founder" — grants premium forever. |

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
   one subscription with two base plans) exposing base plans `atlas_aurora_monthly` (P1M, $4.99) and
   `atlas_aurora_yearly` (P1Y, $39.99). **No offers/free-trial phase.** Activate both base plans.
   - ⚠️ The app queries product IDs `atlas_aurora_monthly` and `atlas_aurora_yearly` directly. If Play
     forces a single subscription ID with base-plan IDs, make the **base plan IDs** exactly these two
     strings, or adjust `AtlasProducts` in `lib/features/billing/services/entitlement_service.dart`.
2. **Play Console → Monetize → Products → One-time products**: create `atlas_founder_lifetime`
   (managed/non-consumable, $79.99), Active.
3. **Server validation credentials** (backend calls the Play Developer API to verify tokens):
   - Google Cloud project linked to Play → create a **service account**, grant it access in
     **Play Console → Users & permissions** (View financial data + Manage orders/subscriptions).
   - Download the service-account **JSON key**.
4. **Real-time developer notifications (RTDN)** for renewals/cancels/refunds:
   - Create a **Pub/Sub topic**, set it in **Play Console → Monetize → Monetization setup → RTDN**.
   - Add a **push subscription** on that topic pointing at:
     `https://atlas.pranta.dev/api/v1/billing/google/rtdn`

---

## 3. Apple App Store Connect

1. **App Store Connect → your app → Subscriptions**: create subscription group **"Atlas Aurora"**
   with `atlas_aurora_monthly` ($4.99, 1 month) and `atlas_aurora_yearly` ($39.99, 1 year).
   **No introductory offer / free trial.** Add localized display name + description + a review
   screenshot.
2. **In-App Purchases** (non-consumable): create `atlas_founder_lifetime` ($79.99).
3. **App Store Server API** credentials (backend verifies StoreKit2 transactions):
   - **Users and Access → Integrations → In-App Purchase** → generate an **API key** (.p8), note the
     **Key ID** and **Issuer ID**.
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
GOOGLE_PLAY_PACKAGE_NAME=com.pranta.atlas            # Android applicationId (from android/app/build.gradle.kts)
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=<path or inline JSON of the service-account key>

# Apple App Store
APPSTORE_BUNDLE_ID=com.pranta.atlas                  # your iOS bundle id (set to match your App Store Connect app)
APPSTORE_ISSUER_ID=<issuer id>
APPSTORE_KEY_ID=<key id>
APPSTORE_PRIVATE_KEY=<contents of the AuthKey_XXXX.p8, PEM>
```

> Verify the exact env var names against the backend implementation once it lands — this file is the
> spec; the code is the source of truth.

## 5. Webhook endpoints (already implemented in the backend)

| Store | Notification URL | Auth |
|---|---|---|
| Google Play RTDN | `POST /api/v1/billing/google/rtdn` | none (Pub/Sub); payload verified server-side |
| App Store Server Notifications V2 | `POST /api/v1/billing/apple/notifications` | none; signed JWS verified server-side |

Purchase verification (called by the app): `POST /api/v1/billing/verify`
`{ platform: "android"|"ios", product_id, purchase_token }`.

## 6. Testing before going live

- **Play**: add **license testers** (Play Console → Setup → License testing) and use an **internal
  testing** track so purchases are real-flow but not charged.
- **Apple**: create **Sandbox testers** (Users and Access → Sandbox) and sign in on-device via
  Settings → App Store → Sandbox Account.
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
