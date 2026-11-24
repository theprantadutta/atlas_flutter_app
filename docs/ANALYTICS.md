# Measuring Atlas

How to tell whether Atlas is growing, and the baseline to compare against.
Everything here is real data read from the consoles; refresh the baseline
table whenever you take a new reading, and never decide from a single week.

## Where the numbers live

| What | Where |
|---|---|
| Play funnel (impressions, listing visitors, installs) | Play Console > Grow users, and Store listings > "Your performance on Play" |
| Play search terms | Store listings > Visitors > Show details > dimension "Search term" |
| Android crashes the SDK can't see | Play Console > Android vitals > Crashes and ANRs |
| Crashes and non-fatals | Firebase Crashlytics, project `atlas-b9aae` |
| In-app events, funnels, retention | GA4 property `a167242807p529647677` (Firebase Analytics) |
| iOS funnel and sales | App Store Connect > Analytics (app id 6797224284) |
| Revenue | Play Console > Monetize, App Store Connect > Sales, backend `purchases` table |

## Events (all defined in `lib/core/telemetry/telemetry.dart`)

First run, in order:

1. `first_open` (automatic)
2. `intro_page` {page} for each intro page seen, then `intro_exit` {action: skip | create_account | have_account, page}
3. `auth_attempt` {method: email | google | apple, screen: login | signup},
   **or** `guest_start` (tapped "Try it without an account")
4. `legal_accept` {where: auth | gate | guest}
5. `login` / `sign_up` {method}, or `auth_fail` {method, kind: cancelled | network | rejected | server | other}
6. `setup_complete` {focus_count} **(key event)**
7. `first_tend` {minutes}: first habit or task done within 24 h of setup, minutes after setup
8. `day0_three_tends` {minutes}: the third one within those 24 h

`first_tend` and `day0_three_tends` only fire for accounts created on 2.1.3 or
later (the clock starts in setup, which existing users never revisit).
Logic and tests: `lib/core/telemetry/activation.dart`,
`test/core/telemetry/activation_test.dart`.

Guests (no account, local only, since 2.1.3):
- `guest_start` when they begin, `guest_upgrade` {method} when they make an
  account or sign in (their rows move to the account,
  `AtlasDatabase.reassignUser`).
- User property **`account_type`** = `guest` | `account`, registered in GA
  as the user-scoped dimension "Account type". Use it as a breakdown or
  comparison on any report: retention, funnel, paywall.
- Guests can't reach Aurora, purchases or sync; those routes send them to
  sign-up (`firstRunRedirect`), and `ApiService.guest` blocks every
  non-`/auth/` request before it leaves the device.

Using the app: `tend_habit`, `tend_task`, `goal_reached`, `day_complete`,
`level_up`, `aurora_message`, `aurora_letter`.

Money: `paywall_view` {source}, `paywall_dismiss` {source},
`purchase_start` {product_id, source}, `purchase_complete` {product_id,
trial, lifetime, source}. `source` values are in `PaywallSource`.

GA registrations: custom dimensions for action, page, where, method, screen,
kind, source, product_id, focus_count (plus the others listed under Admin >
Custom definitions); custom metric "Minutes after setup" (`minutes`).

**To do once they first appear in GA (Admin > Events > Recent events, click
the star):** mark `purchase_complete` and `first_tend` as key events. GA
can't star an event that hasn't fired yet.

## The questions to ask, and how

0. **Saved report:** GA > Explore > **"First-run funnel"**: first open, saw
   the intro, chose a way in (`auth_attempt` or `guest_start`), finished
   setup, first habit or task, three done on day 0. Switch the breakdown
   to "Account type" once guests exist.
1. **Is the listing bringing the right people?** Play search terms: share of
   visitors whose term is just "atlas" (people looking for other apps), and
   listing conversion (install clicks / visitors). Compare 28-day windows.
2. **Do new people get through the door?** GA Explore > Funnel exploration
   with the first-run steps above, "open funnel" off, broken down by
   platform. The biggest drop is the thing to fix next.
3. **Do they get going on day 0?** Median `minutes` on `first_tend`, and the
   share of `setup_complete` users who reach `day0_three_tends`. Snake
   Classic found day-0 depth is the best predictor of coming back (1 run: 9%
   D1, 4 to 6 runs: 28%).
4. **Do they come back?** GA Retention report (D1, D7), and Play "7-day
   device retention". Split by whether `first_tend` happened.
5. **Does anyone pay?** `paywall_view` by source, then `purchase_start`, then
   `purchase_complete`. Compare against Play/App Store revenue: the store is
   the source of truth for money.

## Baseline, 2026-11-24 (last 28 days unless noted)

| Metric | Value |
|---|---|
| Play impressions | 33K (peaked ~3,300/day early Nov, ~430/day by Nov 22) |
| Play listing visitors | 292 (search 264, ads/referrals 28) |
| Play search term "atlas" | 174 of 273 search visitors (64%) |
| Play install clicks | 10 (3%); default listing conversion 2.4% |
| Play device acquisitions / first opens | 6 / 4 |
| Play monthly active devices | 12 |
| iOS (30 days) impressions / page views / first downloads | 504 / 16 / 8 |
| GA first_open (both platforms) | 46 |
| GA users reaching paywall / starting a purchase | 3 / 1 (5 attempts, all cancelled) |
| Revenue | $0 |
| Crashlytics crash-free users (7 days) | 90%, the only issue being a cancelled purchase wrongly reported as fatal (fixed in 795911d) |
| Play vitals crashes / ANRs | none |

Before 2.1.2 (28 days to Nov 16), screen views: splash 28, intro 24, legal 13,
login 11, signup 2, setup 7. That is ~70% lost between the intro and setup.

## Changes to judge against this baseline

| Date | Change | Read it by |
|---|---|---|
| 2026-11-21 | 2.1.2 on Play: "Create your account" opens sign-up, documents accepted inline | First-run funnel, `intro_exit` actions |
| 2026-11-24 | Play title "Atlas" to "Atlas: Habit Tracker & Planner", short description now says "habit tracker & daily planner" (sent for review) | Search-term mix and listing conversion, 28 days after approval |
| 2026-11-24 | iOS App Store Server Notifications URL set | Backend logs for `apple/notifications`; iOS renewals/cancels reflected in `purchases` |
| 2.1.3 | Guest mode ("Try it without an account"); `first_tend` / `day0_three_tends`; cancelled purchases no longer fatal | First-run funnel step 3 to 4 (was ~30% before 2.1.2), `guest_start` vs `auth_attempt`, `guest_upgrade` rate, D1/D7 split by Account type, Crashlytics crash-free users |
