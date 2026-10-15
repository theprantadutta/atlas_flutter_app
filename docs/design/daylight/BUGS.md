# Bug audit (2026-10-15) and fix status

Found while starting the Daylight redesign. Status is updated as fixes land.
Owner "redesign" = fixed as part of the screen/data work on `redesign/daylight`;
"sync" = fixed in the sync-hardening pass (Flutter + .NET).

| # | Sev | Bug | Owner | Status |
|---|---|---|---|---|
| 1 | Critical | Habits never reset `isCompletedToday`; streak only ever increments | redesign | open |
| 2 | Critical | `seed-*` ids are not Guids; server mints new ids on every push, duplicating rows | redesign (client) + sync (server) | open |
| 3 | Critical | No local XP / progress ledger; level/streak read from stale server user; `xp % 1000` | redesign | open |
| 4 | High | World tiles unlock for free on tap, never from XP | redesign | open |
| 5 | High | Achievements never progress or unlock | redesign | open |
| 6 | High | Server awards XP on every toggle re-push; never recomputes TotalXp/streak | sync | open |
| 7 | High | Logout leaves sync cursor and user-scoped prefs; next account misses data | sync | open |
| 8 | High | Token-refresh queue completes every queued request with the first response | sync | open |
| 9 | Medium | Sync cursor uses client clock, ignores server `sync_timestamp` | sync | open |
| 10 | Medium | `markSynced` clears dirty flag even if row was edited during push | sync | open |
| 11 | Medium | Starter data not user-scoped; re-adding after removal silently does nothing | redesign | open |
| 12 | Medium | LWW compares server receive time, not client `updated_at` | sync | open |
| 13 | Medium | `getSingleOrNull` on day/position can throw and abort sync | sync | open |
| 14 | Medium | Unchecking corrupts counters; completed daily tasks never come back | redesign | open |
| 15 | Medium | Sync engine gated on `isPremium`, UI on `canSync` (needs `cloud_sync`) | sync | open |
| 16 | Low | `demo-user` fallback seeds orphan rows during logout | sync | open |
| 17 | Low | Home doesn't roll over at midnight | redesign | open |
| 18 | Low | Completed goal's `completedAt` moves on every tap | redesign | open |
| 19 | Low | Dead `HabitRepository`/`TaskRepository` | redesign | open |
| 20 | Low | First-run starter prompt never built | redesign | open |
| D1 | UI | "Forgot password?" does nothing | redesign | open |
| D2 | UI | Bell badge hard-coded on | redesign | open |
| D3 | UI | Tapping a notification does nothing (no markRead, no deep link) | redesign | open |
| D4 | UI | No edit UI for tasks, habits, goals; goal progress only +25% | redesign | open |
| D5 | UI | Avatar level/XP/stats never updated locally | redesign | open |
