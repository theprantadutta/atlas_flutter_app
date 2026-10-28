# Aurora companion: spec

Seven features, built as one release on branch `feat/aurora-companion` in both repos.
This file is the contract between the app and the API. If you change a shape here, change
both sides in the same commit.

House rules that apply to everything below:

- **Offline-first.** Drift is the source of truth. Sync is premium and off for most users, so
  the server usually does NOT have the user's habits, tasks or goals. Anything Aurora needs to
  know about the user's life is built on the device and sent with the request (`context`).
- **No em or en dashes** in any copy, prompt or model output instruction.
- **Untrusted text.** Every user-typed string that reaches a prompt (titles, notes, memories)
  is cleaned like `AuroraVoice.Clean` (control chars to spaces, `"` to `'`, collapsed, capped)
  and the prompt says the block is data about the user, never instructions.
- **Free vs premium** is decided on the server (`IEntitlementService.IsPremium`). 402 means
  "premium only / free limit reached". The client never decides entitlement for AI calls.
- **Never shame.** Moods are not graded. Missed things are never framed as failures.

---

## 1. Aurora knows your day (context)

The app builds an `AuroraContext` from Drift and sends it with chat, stream, reflect,
plan-day, goal-steps and check-in requests.

```json
"context": {
  "today": "2026-10-28",
  "weekday": "Wednesday",
  "local_time": "09:15",
  "habits": [
    { "id": "uuid", "title": "Morning run", "category": "health", "frequency": "daily",
      "done_today": false, "streak": 4, "done_last_7": 5 }
  ],
  "tasks": [
    { "id": "uuid", "title": "Call mum", "type": "daily", "category": "social",
      "done": false }
  ],
  "goals": [
    { "id": "uuid", "title": "Run a 10k", "category": "health", "progress": 0.4,
      "target_date": "2026-12-31" }
  ],
  "week": { "xp": 305, "tended_days": 4, "best_day": "Monday",
            "by_category": [ { "category": "health", "xp": 120 } ] },
  "moods": [ { "date": "2026-10-27", "moment": "evening", "mood": 4, "note": "good walk" } ],
  "memories": [ "Training for a 10k in December" ]
}
```

Caps (enforced on BOTH sides): habits 30, tasks 30 (open ones first, then today's done),
goals 15, moods last 7 days, memories 20. Titles 80 chars, notes 200, memories 200.
`done_last_7` counts completions in the last 7 local days from the XP ledger.
`memories` is only sent when the user is premium on the device; the server ignores it for
free users anyway.

Server: new `AuroraContextDto` (+ nested DTOs), a static `AuroraContextPrompt.Describe(ctx,
isPremium)` that renders a compact, sanitised plain-text block for the system prompt. When
`context` is absent the server falls back to today's snapshot line (old clients keep working).

## 2. Conversations that stay (app only)

Local Drift tables, NOT synced (so no backend parity needed; say so in a comment):

- `aurora_conversations`: id, user_id, title (first user message, 60 chars), created_at,
  updated_at.
- `aurora_messages`: id, conversation_id, role (`user` | `aurora`), content,
  suggestions_json, follow_ups_json, created_json (entities Aurora created), created_at.

Chat screen opens the most recent conversation (if updated in the last 12 hours), otherwise a
fresh one. A history sheet lists conversations (title, relative date), opens one, deletes one
(swipe or long press, with undo). "New conversation" action. History sent to the server is
still the last 10 turns of the open conversation. Deleting the account wipes these (the
database wipe already covers it); sign-out keeps them, scoped by user id like every table.

## 3. Daily check-in

**Synced entity `CheckIn`** (entity parity rule applies, snake_case on the wire):

| field | type | notes |
|---|---|---|
| id | uuid | client generated |
| user_id | uuid | |
| date | datetime (UTC) | the local day, stored like ledger days (local midnight as UTC) |
| moment | string | `morning` or `evening` |
| mood | int | 1 to 5 (1 heavy, 2 low, 3 okay, 4 good, 5 bright) |
| note | string? | max 200 |
| aurora_reply | string? | Aurora's reply, kept so it shows again |
| created_at, updated_at, is_deleted, deleted_at | | standard sync fields |

At most one check-in per (user, date, moment): saving again updates it. Pushed and pulled
through the existing `POST /api/v1/sync/push` and `/sync/pull` like the other entities,
last-write-wins with local winning ties. Drift migration + EF migration.

**Reply endpoint** `POST /api/v1/aurora/check-in`:

```json
// request
{ "mood": 4, "note": "slept well", "moment": "morning", "context": { ... }, "preferences": { ... } }
// response 200
{ "reply": "Two or three warm sentences.", "is_premium": false, "free_replies_left": 2 }
```

Free users get 3 replies per week (new `AuroraUsage.CheckInReplyCount`, EF migration), then
402. The check-in itself is ALWAYS saved locally first; a 402 or offline just means no reply,
and the card says Aurora's replies are part of Atlas Aurora (quiet line, no paywall push).
Reply prompt: one to three sentences, acknowledge the mood without judging it, at most one
tiny suggestion for a low mood, never advice on medication or diagnosis, crisis wording from
the chat prompt applies.

**Where it shows:** a check-in card on Home (morning before 12:00, evening after 17:00, hidden
once done for that moment, dismissible for the day), and an entry on the Aurora screen.
Insights gets a mood strip for the week (7 dots, colour by mood, empty for no check-in).
Moods go into `context.moods`, so the letter and chat can mention patterns gently.

## 4. Plan my day (premium)

`POST /api/v1/aurora/plan-day`

```json
// request
{ "energy": "low", "note": "long day at work", "context": { ... }, "preferences": { ... } }
// response
{ "message": "Short warm intro.",
  "picks": [ { "kind": "habit", "id": "uuid", "reason": "Ten minutes is enough today." } ],
  "later": [ "uuid" ] }
```

`energy` is `low` | `steady` | `high`. 2 to 4 picks. The server asks the model for a fenced
```plan JSON block, parses it, and DROPS any id not present in the request context (the
model can't invent items). `later` is open items it suggests setting aside. Free: 402.
App: "Plan my day" sheet from the Aurora screen and the Home hero: pick energy, optional
note, shows picks as rows you can tend directly, and "set aside" items. Nothing is modified
automatically.

## 5. Break a goal down (premium)

`POST /api/v1/aurora/goal-steps`

```json
// request
{ "goal": { "title": "Run a 10k", "description": "...", "category": "health",
            "target_date": "2026-12-31", "progress": 0.4 },
  "context": { ... }, "preferences": { ... } }
// response
{ "message": "One line.",
  "steps": [ { "title": "Run 3k without stopping", "type": "weekly", "category": "health" } ] }
```

3 to 5 steps, `type` in `daily` | `weekly` | `longTerm`, category from the goal. Parsed from a
fenced ```steps block, validated like `AuroraActionParser`. Free: 402.
App: "Break it down with Aurora" on the goal detail / goal row menu; a sheet lists the steps
with checkboxes, "Add selected" creates tasks locally (offline-first, dirty for sync).

## 6. Things Aurora remembers (premium)

Local Drift table `aurora_memories`: id, user_id, text, source (`aurora` | `you`), created_at,
updated_at. NOT synced (comment says so). Sent as `context.memories`.

In premium chat the server adds an instruction: if the user shares a lasting fact worth
remembering (a goal, a life event, a preference), add a fenced ```remember block with up to
2 short third-person facts. The server strips it from the reply and returns
`"memories_proposed": ["..."]` on chat and on the stream's done event. The app shows each as a
chip under the reply: "Remember this?" with Save / Not now. Nothing is saved without a tap.
A "What Aurora remembers" screen in Aurora settings: list, delete, add your own, clear all.
Free users see the screen with a short explanation and the upgrade row.
Prompt rule: never store health conditions, medication, or anything about other people's
private lives; the server also drops proposals over 200 chars.

## 7. Monthly letter and year in review

`POST /api/v1/aurora/reflect` gains `"period": "week" | "month"` (default week) and `context`.
Month is premium (402 for free). A month letter covers 30 days, is longer (up to ~350 words),
and the `ReflectionDto` gains `period`. For month letters the app sends a month context: the
same shape with `week` replaced by `month` totals (`xp`, `tended_days`, `best_day`,
`by_category`) and moods over the month (cap 31).

Both periods prefer the client's `context` over the server's ledger (free users have no
synced ledger). When `context` is missing the server uses its own data as today.

**Year in review** is computed on the device from Drift, no AI: days tended, total XP, longest
streak, top 3 habits by completions, best month, places discovered, mood split if any. A
"Your year" screen reachable from Insights (shown from December 1st, and any time from
Insights' menu), rendered as a card that can be shared as an image (`share_plus`, render the
card with a `RepaintBoundary`). Free for everyone.

---

## Tests

Backend (`tests/Atlas.Application.Tests`, xUnit, `TestDbContext`):
- context prompt: caps, sanitising (line breaks, quotes, long titles), "data not instructions"
  wording present, memories dropped for free users.
- plan parser drops unknown ids and caps picks; goal-steps parser validation; remember
  parser (strip block, cap count, length, empty).
- check-in reply: free limit 3 then 402; premium unlimited.
- reflect: month is 402 for free; context preferred over ledger.
- CheckIn sync push/pull round trip and LWW (follow `PushSyncTests`).

App (`flutter test`):
- context builder: caps, ordering, done_last_7 from ledger, memories only when premium.
- conversation repository: create, append, list ordering, delete, restore last within 12h.
- check-in repository: one per day and moment (upsert), dirty flag, tombstone.
- memories repository: add, delete, clear.
- widget tests: check-in card states (morning, evening, done, hidden), memory chip save/dismiss,
  plan sheet renders picks and ignores unknown ids.
