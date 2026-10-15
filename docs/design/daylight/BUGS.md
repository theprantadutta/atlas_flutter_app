# Bug audit (2026-10-15) and fix status

Found while starting the Daylight redesign. Status is updated as fixes land.
Owner "redesign" = fixed as part of the screen/data work on `redesign/daylight`;
"sync" = fixed in the sync-hardening pass (Flutter + .NET).

| # | Sev | Bug | Owner | Status |
|---|---|---|---|---|
| 1 | Critical | Habits never reset `isCompletedToday`; streak only ever increments | redesign | fixed (ledger + rollover; UI wiring in screens) |
| 2 | Critical | `seed-*` ids are not Guids; server mints new ids on every push, duplicating rows | redesign (client) + sync (server) | fixed (UUID v5 seeds + one-time re-key of legacy rows; server rejects non-UUID) |
| 3 | Critical | No local XP / progress ledger; level/streak read from stale server user; `xp % 1000` | redesign | fixed (ledger); UI wiring in screens |
| 4 | High | World tiles unlock for free on tap, never from XP | redesign | fixed (XP-driven discovery; taps only open the place) |
| 5 | High | Achievements never progress or unlock | redesign | fixed (local evaluation from the ledger, monotonic) |
| 6 | High | Server awards XP on every toggle re-push; never recomputes TotalXp/streak | sync | fixed (sync pass) |
| 7 | High | Logout leaves sync cursor and user-scoped prefs; next account misses data | sync | fixed (sync pass) |
| 8 | High | Token-refresh queue completes every queued request with the first response | sync | fixed (sync pass) |
| 9 | Medium | Sync cursor uses client clock, ignores server `sync_timestamp` | sync | fixed (sync pass) |
| 10 | Medium | `markSynced` clears dirty flag even if row was edited during push | sync | fixed (sync pass) |
| 11 | Medium | Starter data not user-scoped; re-adding after removal silently does nothing | redesign | fixed (StarterSeeder: user-scoped, revives, exact ledger removal) |
| 12 | Medium | LWW compares server receive time, not client `updated_at` | sync | fixed (sync pass) |
| 13 | Medium | `getSingleOrNull` on day/position can throw and abort sync | sync | fixed (sync pass) |
| 14 | Medium | Unchecking corrupts counters; completed daily tasks never come back | redesign | fixed (TaskSchedule rollover + untend recovers from ledger) |
| 15 | Medium | Sync engine gated on `isPremium`, UI on `canSync` (needs `cloud_sync`) | sync | fixed (sync pass) |
| 16 | Low | `demo-user` fallback seeds orphan rows during logout | sync | open |
| 17 | Low | Home doesn't roll over at midnight | redesign | fixed (todayProvider ticks at midnight) |
| 18 | Low | Completed goal's `completedAt` moves on every tap | redesign | fixed (TendController.setGoalProgress keeps completedAt) |
| 19 | Low | Dead `HabitRepository`/`TaskRepository` | redesign | fixed (deleted, with the ledger-bypassing toggles) |
| 20 | Low | First-run starter prompt never built | redesign | fixed (asked once on Home, before the tour) |
| D1 | UI | "Forgot password?" does nothing | redesign | partly: honest sheet; real reset needs a backend endpoint + email provider |
| D2 | UI | Bell badge hard-coded on | redesign | fixed (reads unread count) |
| D3 | UI | Tapping a notification does nothing (no markRead, no deep link) | redesign | fixed (marks read, deep-links by entity/type) |
| D4 | UI | No edit UI for tasks, habits, goals; goal progress only +25% | redesign | editor done; goal progress in Grow |
| D5 | UI | Avatar level/XP/stats never updated locally | redesign | fixed (derived from ledger) |

Note on #7: logout keeps the local database (offline-first: it is the only copy for free users). It resets the sync cursor and user-scoped prefs; only Delete account wipes the database.
| E1 | High | World economy: all 30 places unlocked at 775 total XP (about a week) | redesign | fixed (curve to ~13,000 XP; untouched old costs re-costed) |
| E2 | Medium | Android notifications used the full-colour launcher icon (white square) | redesign | fixed (monochrome spark drawable) |
