# App Store Connect: handover for a macOS session

Written 2026-11-24 from a Windows session that can read and edit App Store
Connect in Chrome but cannot build or upload iOS binaries. A macOS session
should work through the list below. Measurement context and the baseline
numbers are in `docs/ANALYTICS.md`; listing copy rules are in
`STORE_LISTING.md`.

App: **Atlas: Habits & Self-Care**, Apple ID `6797224284`, bundle
`com.pranta.atlas`, SKU `atlas`. Console: https://appstoreconnect.apple.com/apps/6797224284

## State on 2026-11-24

| Item | State |
|---|---|
| iOS 2.1.1 | Ready for Distribution (live) |
| iOS 2.1.2 | In Review. App information is locked until it clears |
| Name | `Atlas: Habits & Self-Care` (25/30) |
| Subtitle | `Daily routines, goals, streaks` (30/30) |
| Keywords | `tracker,routine,goal,task,todo,streak,wellbeing,journal,mindfulness,productivity,reminder,planner` (97/100) |
| Category | Health & Fitness, secondary Productivity |
| App Store Server Notifications, production | **Set today** to `https://atlas.pranta.dev/api/v1/billing/apple/notifications` |
| App Store Server Notifications, sandbox | Deliberately empty (see below) |
| 30-day funnel | 504 impressions, 16 product page views, 8 first downloads (page to download ~50%, healthy) |

Note on reading the console: the small number under the Name and Subtitle
fields is characters **remaining**, not used. A "0" under the subtitle means
it is full, not empty.

## To do, in order

### 1. Ship the next iOS build (needs a Mac)

master now holds, beyond 2.1.2:
- `795911d`: a cancelled purchase is no longer reported to Crashlytics as a
  fatal crash.
- Activation measurement (`first_tend`, `day0_three_tends`), see
  `docs/ANALYTICS.md`.

Steps: wait for 2.1.2 to finish review (release it if approved), pull
master, confirm `pubspec.yaml` version (bump to the next patch and build
number if the Android release hasn't already), `flutter build ipa
--release`, upload with Xcode Organizer or Transporter, attach the build to a
new version, and submit. What's New (no em or en dashes, house style):

> Small fixes under the hood: a cancelled purchase no longer counts as a
> problem, and a few things are steadier on first run.

The review notes and demo account are already on the version page; carry
them over, don't paste them anywhere else.

### 2. Keywords (after 2.1.2 clears review)

The subtitle already contains "routines", "goals" and "streaks", and Apple
pools name, subtitle and keywords, so `routine`, `goal` and `streak` in the
keywords field are wasted. Proposed (99/100, singular, no spaces, nothing
from the name or subtitle):

```
tracker,task,todo,planner,journal,mindful,productivity,reminder,wellbeing,mood,focus,ritual,offline
```

Keywords only change with a new version submission, so put this on the
version from step 1. Record the date in the "Changes to judge" table in
`docs/ANALYTICS.md`, then compare impressions and search-sourced downloads
(Analytics > Acquisition > Sources) 28 days later.

### 3. Server notifications check

The production URL is set, and the endpoint answers 200. To confirm real
traffic: after the next iOS subscription event (purchase, renewal, cancel),
check the API logs for `POST /api/v1/billing/apple/notifications`, then the
matching row in the `purchases` table. The handler verifies Apple's signed
payload itself (`AppleNotificationParser`) and needs no extra config.

**Sandbox is left empty on purpose.** The backend has one database, and the
handler doesn't check the notification's environment, so sandbox
(TestFlight/test-account) events would change real accounts. Only set a
sandbox URL once the handler ignores `environment == "Sandbox"` or there is
a staging API.

### 4. Screenshots

The App Store screenshots still show the pre-Daylight design
(`ios_app_store_screenshots/`, `ipad_app_store_screenshots/`); Play already
has the Daylight set. Capture new ones on a simulator with seeded demo data
(lead with the living world and the habit list, not the login screen) and
upload with the next version.

### 5. Don't do

- Don't rename the app without numbers: the name is fine and the page
  converts at ~50%. The iOS problem is volume (504 impressions/month), which
  keywords and screenshots address.
- Don't put credentials, review-account details or personal contact info in
  any repo file or chat.
- No co-author or AI attribution in commit messages (owner's rule).
