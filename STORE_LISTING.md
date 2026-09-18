# Atlas: store listing copy

Paste-ready ASO copy for Google Play and the App Store, written against the app as it actually
ships. Character limits are noted next to each field; the counts in brackets are the current copy.

House style, matching the app: **no em dashes and no en dashes anywhere.** Store listings are the
first writing a user reads, and a dash-heavy listing reads as generated. Commas, colons and full
stops only.

---

## 1. Keyword strategy

Atlas competes in a crowded category (habit trackers) from a distinctive angle (a world that
visibly grows, plus a gentle AI companion). The listing has to rank for the boring high-volume
terms while the copy sells the thing nobody else has.

**Tier 1, must rank (high volume, high intent).** These belong in the title, short description and
the first two lines of the full description, where both stores weight them most heavily.

- habit tracker
- daily habits
- goal tracker
- self care
- routine

**Tier 2, qualify the visitor (mid volume, high conversion).** Woven through the feature sections.

- streaks
- self improvement
- productivity
- mindfulness
- wellbeing
- to do list
- daily planner
- progress tracker

**Tier 3, differentiators (low volume, very high intent).** These are what makes someone choose
Atlas over the other twenty results, and they are what the screenshots should show.

- offline habit tracker
- gamified habits
- AI companion
- weekly reflection
- habit journal
- no ads

**Deliberately not chased:** "meditation", "therapy", "mental health app". Atlas is not a clinical
product, the copy must not imply it is, and ranking there invites the wrong reviews.

---

## 2. Google Play

### App name (30 char limit) [28]

```
Atlas: Habit Tracker & Goals
```

Brand first so existing users can find it, then the single highest-volume term. Alternatives if you
want to test: `Atlas: Daily Habits, Goals` [26] or `Atlas Habit Tracker: Routines` [29].

### Short description (80 char limit) [78]

```
Build daily habits, track goals, and grow a living world. Works fully offline.
```

This is the line Play shows in search results and it converts more than anything else on the page.
It carries two Tier 1 keywords and the strongest differentiator (offline) in one sentence.

### Full description (4000 char limit) [3076]

```
Atlas is a habit tracker for people who are tired of being nagged by their habit tracker.

Tend your daily habits, tasks and goals, and watch a quiet living world grow greener with you. Miss a day and nothing burns down. Atlas is built to be kind on the days you need it to be.

WHAT YOU CAN DO

Daily habits and streaks
Build a routine that sticks. Track daily and weekly habits, keep an honest streak, and see your completion rate over time. Break a streak and Atlas welcomes you back instead of scolding you.

Tasks and goals in one place
Daily, weekly and long term tasks with categories, difficulty and XP. Goals with deadlines, priorities and real progress tracking, so the big things stop living only in your head.

A world that grows with you
Every habit you tend earns XP, levels your avatar, and unlocks new tiles in your world. It is a progress tracker you can actually see, rather than another grid of numbers.

Aurora, your gentle companion
Aurora writes you a warm weekly reflection in your own words, and is there to talk things through when you need it. You choose how she speaks to you: her tone, how much she says, what to call you, and what matters to you right now. Never graded, never clinical.

Insights worth reading
XP trends, completion rates, category breakdowns and a day by day progress history. Enough to notice a pattern, not so much that tracking becomes the hobby.

Achievements and milestones
Unlock badges across five tiers as your practice deepens. Gentle recognition, not a slot machine.

WORKS FULLY OFFLINE

Atlas keeps everything on your device first. Open it on a plane, in a basement, or with data switched off, and every habit, task and goal is right there. Nothing waits on a connection, and nothing breaks when there is not one.

CALM BY DESIGN

No ads. No feed. No streak shaming. No dark patterns engineered to keep you scrolling. Atlas is a self care app that would rather you closed it and went to live your day.

Beautiful in dark and light, with a living horizon that shifts with the time of day, typography chosen with care, and motion that respects your reduced motion setting.

FREE, WITH AN OPTIONAL UPGRADE

Everything above is free, including your habits, tasks, goals, world, achievements and insights, and a weekly taste of Aurora.

Atlas Aurora, the optional premium upgrade, adds unlimited conversations with Aurora, deeper weekly reflections, natural language quick add (describe it in a sentence and Aurora sets it up), cloud sync and backup across your devices, and deeper insights with export.

Available monthly, yearly, or as a one time lifetime purchase. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the period, and can be managed or cancelled any time in your store account settings.

YOUR DATA IS YOURS

Your content stays on your device unless you turn on cloud sync. Delete any item, or your whole account, from inside the app at any time.

Privacy policy: https://legal.pranta.dev/privacy?projectName=atlas
Terms: https://legal.pranta.dev/terms?projectName=atlas
```

**Why it is shaped this way.** Play indexes the full description, and the first 2 to 3 lines are all
most people read before deciding. So line one states the category ("habit tracker") and the hook in
the same breath, and the Tier 1 terms all appear above the fold. The all-caps section headers are
scannable on a phone without needing markdown, which Play does not render.

---

## 3. Apple App Store

### App name (30 char limit) [28]

```
Atlas: Habit Tracker & Goals
```

### Subtitle (30 char limit) [30]

```
Daily habits, goals, self care
```

The subtitle is indexed by Apple, so it carries keywords the name cannot fit. Do not repeat words
already in the name; Apple treats the two fields as one keyword pool.

### Keywords field (100 char limit) [100]

```
habit,routine,streak,goal,todo,self-improvement,productivity,mindful,wellbeing,offline,journal,diary
```

Rules this follows, all of which are easy to get wrong:

- Comma separated, **no spaces after commas** (a space costs a character and buys nothing).
- **Singular only.** Apple matches plurals automatically, so "habits" wastes a character.
- **No words already in the app name or subtitle.** Those are indexed separately, so repeating
  "tracker", "daily", "care" or "Atlas" here is wasted space.
- **No category name.** Apple indexes your category automatically.
- No competitor names, no "app", no "free", no "best".

### Promotional text (170 char limit, editable without review) [162]

```
Aurora now speaks the way you want her to: choose her tone, how much she says, and what she keeps in mind. Plus a calmer back button and a tidier feel throughout.
```

Promotional text sits above the description and can be changed without submitting a build, so keep
it pointed at the most recent release.

### Description (4000 char limit)

Use the same body as the Play full description above. Apple does not index the description for
search, so it exists purely to convert, but the copy already does both jobs.

---

## 4. What still needs doing outside this file

- [ ] **Screenshots.** Caption the first two, since those are the only ones most people see. Lead
      with the living world and the habit list, not the login screen. Assets live in
      `play_store_screenshots/` and `android_screenshots/`.
- [ ] **Feature graphic** (Play, 1024x500). Should read at thumbnail size.
- [ ] **Localisation.** Even translating just the name, subtitle and short description into the top
      three non-English markets typically outperforms any amount of English keyword tuning.
- [ ] **Category.** Health & Fitness converts better than Productivity for this positioning, but
      test it; Play lets you change category without a new build.
- [ ] Re-check every character count in the console before publishing. Both stores count some
      characters differently from a plain text editor.
