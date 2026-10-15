# Prompt for Claude Code: implement the Atlas "Daylight" redesign

> Copy everything below the line into Claude Code, run from the root of the
> `atlas_flutter_app` repository. First, copy this whole handoff folder into the repo
> at `docs/design/daylight/` so the agent can read it.

---

You are implementing a **complete visual redesign** of the Atlas Flutter app, called
**Daylight**. The full spec, assets and references are in `docs/design/daylight/`. Read
these first, in this order, before writing any code:

1. `docs/design/daylight/README.md`: tokens, nav shell, and every screen measured.
2. `docs/design/daylight/MOTION_AND_INTERACTIONS.md`: every animation, gesture and haptic.
2b. `docs/design/daylight/DARK_THEME.md`: the complete dark theme. Dark is a first-class deliverable, not an afterthought.
3. `docs/design/daylight/screenshots/*.png`: the target visuals (3x, 390×844 logical).
   `00_overview_board.png` shows all six screens with design notes, and `screenshots/dark/*.png`
   shows the same screens in dark.
4. `docs/design/daylight/before_current_app/*.jpg`: the current app, to understand what
   exists. **Do not carry over any of its visual language.**
5. `docs/design/daylight/design_reference/Atlas Redesign v2.dc.html`: the HTML prototype.
   It is a reference only; read its inline styles for exact values. Never port the HTML.
6. The repo's own `CLAUDE.md` (offline-first and entity-parity rules still apply in full).

## Ground rules
- **The visual layer changes; the data layer does not.** No Drift schema changes, no
  backend or DTO changes, and no changes to sync, auth, billing or repositories unless a
  step below explicitly says so. Every write stays local-first (Drift first, mark dirty).
- Keep all existing routes and route names working (`RouteNames`). Deep links must not break.
- Keep feature parity: every action available today must still be reachable.
- Use the existing stack: Riverpod, go_router, `flutter_animate`, `google_fonts`,
  `fl_chart` (or custom painters), `gpt_markdown`. Only add a dependency when a step says
  you may.
- No magic numbers in widgets: everything comes from `AppColors`, `AppTypography`,
  `AppSpacing` and `AppMotion`.
- Gate every looping animation behind `AppMotion.reduceMotion(context)`.
- Copy has no em dashes or en dashes.
- Work in small, reviewable commits in the order below. After each phase, run
  `flutter analyze` and `flutter test`, and fix everything before moving on.

## Phase 0: Foundations
1. Copy `tokens/app_palette.dart` to `lib/shared/themes/app_palette.dart`. **Every widget
   you write or restyle reads colors via `context.palette.*`**, never `AppColors.paper`
   directly, and never by checking brightness in widgets.
1b. Replace `lib/shared/themes/app_colors.dart`, `app_typography.dart`, `app_motion.dart`
   and `app_spacing.dart` with the versions in `docs/design/daylight/tokens/`. They keep
   legacy names mapped to new values, so the app should compile immediately. Fix any
   compile errors.
2. Fonts: check that `GoogleFonts.funnelDisplay` and `GoogleFonts.funnelSans` exist in the
   installed `google_fonts`. If they don't, download the Funnel Display and Funnel Sans
   TTFs (weights 400–800) from Google Fonts into `assets/fonts/`, register them in
   `pubspec.yaml`, and switch `AppTypography` to `TextStyle(fontFamily: ...)`. Remove every
   reference to Fraunces and Hanken Grotesk.
3. Rebuild `lib/shared/themes/app_theme.dart` for **light** and **dark**, registering
   `AtlasPalette.light` and `AtlasPalette.dark` as theme extensions. The default is
   `ThemeMode.system`; keep the existing toggle and persist the choice. Animate theme
   switches over 360ms, and set `SystemUiOverlayStyle` per mode (see `DARK_THEME.md`):
   - scaffold background is canvas;
   - `splashFactory: NoSplash.splashFactory`, with no ripples;
   - cards flat, no elevation;
   - inputs are white pills with no border;
   - `ElevatedButton` is an ink pill 56 high;
   - `TextButton` uses ink text;
   - `Switch` thumb is white, active track is ink;
   - the bottom sheet is canvas with 32 top radius and a grabber;
   - `SnackBar`/toast is an ink pill with white text.

   In dark, follow `DARK_THEME.md` exactly: `ElevatedButton` becomes a cream pill with ink
   text, sheets are `#0F0E0B`, and the toast is a raised `#26231D` pill with a `#34302A`
   border.
4. Update `lib/shared/widgets/feedback/atlas_toast.dart` to the ink-pill style with an
   optional **Undo** action.
5. Replace the "visual identity" section of the repo `CLAUDE.md` with
   `docs/design/daylight/CLAUDE_md_design_section.md`. Leave the architecture sections as
   they are.

## Phase 1: Brand
1. Rewrite `lib/shared/widgets/brand/atlas_logo.dart` as `AtlasSpark`: a `CustomPainter`
   for the four-point spark using the unit path in the README, filled with `AppColors.sunrise`
   (variants: gradient, ink, white). Add an `animated` flag for the shimmer loop
   (rotation ±12°, scale 1 → 1.08, 5s mirror) and a `busy` flag (1.2s loop plus an opacity
   pulse). Export a `AtlasLockup` widget (spark + "Atlas" in Funnel Display 700).
2. Copy `docs/design/daylight/brand/png/*` into `assets/brand/`, replacing the old icon,
   foreground, background and splash files with the same filenames
   (`atlas_icon.png`, `atlas_icon_fg.png`, `atlas_icon_bg.png`, `atlas_splash.png`).
   Change `flutter_native_splash.color` to `#F4F1EA` and add `color_dark: "#0F0E0B"`. Use `android_12.color`
   `#F4F1EA` too, plus a dark override of `#0F0E0B` if supported. Regenerate with
   `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
3. Delete `living_horizon.dart` once nothing references it (end of Phase 3).

## Phase 2: Shared components (`lib/shared/widgets/ui_kit.dart` + new files)
Build these, each with a widget test where they hold logic:
- `Pressable`: wraps any child; scales to 0.96 (or 0.92 with `circle: true`) on tap
  down over 90ms and springs back with easeOutBack over 220ms; optional haptic. Every
  tappable in the app uses it.
- `AtlasRow`: height 64 or 70, white, radius 22, padding 0 10 0 12. It takes a leading
  `IconTile`, a title, meta, an optional trailing widget, and optional swipe actions
  (right = tend, left = later/skip, with gradient check or track backgrounds that scale
  with drag, committing past 30% of the width).
- `IconTile`: a 38–48 square with radius 14–16, the category tint background and the
  filled category icon.
- `CheckCircle`: 30–34. It animates its border out and its gradient fill in (scale from
  0.4, easeOutBack, 220ms); the check draws in.
- `SegmentedPill`: the track container with an ink sliding pill driven by a spring.
- `InkHeroCard`: radius 32, ink, clips its content, with an optional drifting `heroGlow`
  blob (an `ImageFiltered` blur with σ 18, translation (-18, 14), scale 1 → 1.12, 9s mirror).
- `ProgressSegments` (a segmented day bar, max 8 segments, then continuous) and
  `GradientBar` (a 6px progress bar).
- `CountUpText`: tweens integer changes over 600ms with tabular figures.
- `XpFloat`: the "+N" chip that rises 28px and fades over 600ms, with gradient text via
  `ShaderMask`. Trigger it through an overlay.
- `Sparkline7`: 7 bars, 4 wide, gap 2, heights 4–22, growing from the bottom on first build.
- `DayRing`: a 34 ring with a conic sunrise sweep that animates 0 → value.
- `GradientText`: a `ShaderMask` helper.
- `SparkBurst`: 8 small sparks bursting radially over 900ms (day complete and discovery).
- `AtlasSkeleton`: `#ECE7DD` blocks with a 1.4s shimmer (the `shimmer` package is
  already a dependency).

## Phase 3: Navigation shell
Rewrite `AuroraNavBar`, `AuroraFab` and the layout in `app_navigation_shell.dart` to match
the README "Navigation shell" section:
- **4 visible tabs** (Home, Grow, Aurora, Atlas). Keep the 5th `you` branch in the router,
  but reach it from the Home avatar and from the rail on wide layouts.
- The sliding white active pill (spring), outlined/filled icon swap, and
  `HapticFeedback.selectionClick()`.
- The FAB sits **to the right of** the bar (never over content). On tap it rotates its
  icon 45° and opens the Quick Add sheet. Keep `coachMarkKeys.fab` on it and update the
  coach mark positions to the new layout.
- Re-tapping the active tab scrolls to the top.
- Set `AppSpacing.bottomNavSpace` to 114 everywhere and add the 120px canvas fade
  behind the bar.
- Keep the back-button handling, notification primer and wide-shell logic unchanged.
  Restyle the rail in ink with a white active pill.

## Phase 4: Screens (match the screenshots and the README section for each)
Build in this order: **Home → Grow → Aurora → Aurora chat → Atlas (World) → Insights**,
then extrapolate the rest. For each screen: build the layout, wire it to the existing
providers, add the motion from `MOTION_AND_INTERACTIONS.md`, then add loading, empty and
error states.

### Internal logic (read carefully)
**Home** (`home_provider.dart`):
- `dayProgress = done / total` for today's items (tasks due or done today, plus today's
  scheduled habits). Hero % is `(dayProgress * 100).round()`. The segment count is
  `min(total, 8)`.
- **Level math bug to fix:** Home currently shows `xp % 1000` out of 1000, while
  `GamificationConstants.xpRequiredForLevel` uses a quadratic curve. Use the real curve:
  `floor = xpRequiredForLevel(level)`, `ceil = xpRequiredForLevel(level + 1)`,
  `xpInLevel = totalXp - floor`, `xpForLevel = ceil - floor`. Make this one shared helper
  and use it on Home, Profile and the level-up logic.
- `xpToday` = the sum of XP from items completed today (already computed).
- **Up next** = not-done items sorted by scheduled time ascending (nulls last), then
  `createdAt`. Show 2; "See all" goes to Grow.
- **Tend** calls the existing complete-task / complete-habit repository methods (they
  already award XP via `GamificationConstants` and update streaks). Then trigger the motion
  sequence (XpFloat, segment fill, count-up, row collapse) and show an Undo toast for 4s.
  Undo calls the existing uncomplete path. If there isn't one, add a repository method that
  reverses completion **locally** (decrement XP, restore streak, mark dirty). Do not touch
  the backend.
- **Later** = snooze for today without changing the schema. Store
  `Map<String itemId, DateTime snoozedUntil>` in `SharedPreferences` under
  `atlas.snoozed.v1`. Snoozed items sort to the end of Up next until `snoozedUntil`, which
  is the next full hour, or 9:00 tomorrow if it's after 21:00. Expose it via a small
  Riverpod notifier.
- **Day complete** fires once per calendar day. Persist the last-celebrated date in
  `SharedPreferences` (`atlas.dayComplete.lastDate`).
- **Letter tile** shows when the latest weekly reflection's id differs from
  `atlas.letter.lastReadId` in prefs. Mark it read when the full letter is opened.

**Grow**:
- **Week strip** (Monday-start, current ISO week): each day's ring value = completed
  habit instances that day ÷ scheduled habits that day, from progress entries or habit
  completion history. Future days are empty rings. Tapping a past day shows that day's
  list as read-only.
- **Habit sparkline**: the last 7 calendar days ending today, true if completed that day.
  Height per done day is a gentle deterministic variation (14–22, seeded by habit id and
  day) so it reads as a rhythm, not data. Missed days are 4px.
- The frequency filter (Daily / Weekly / All) is local UI state.

**Aurora**:
- Split the reflection with the existing `lib/core/utils/prose.dart` (add a
  `firstSentence` / `nextSentences(n)` helper if needed). Headline is sentence 1; body is
  sentences 2–3.
- **Listen** is optional: you may add `flutter_tts`. Estimate minutes at 160 words per
  minute. If TTS isn't added, hide the Listen button and make **Read all** primary (ink).
- Starters send their label as the first chat message.

**Aurora chat** (structured suggestions):
- In `aurora_repository.dart` / `aurora_providers.dart`, extend the system prompt so that
  when Aurora suggests concrete actions, she appends a fenced JSON block:
  ```suggestions
  [{"title":"5 min stretch before bed","kind":"habit","time":"22:15","xp":15,"recommended":true},
   {"title":"A short walk outside","kind":"task","xp":10},
   {"title":"Sit with a warm drink","kind":"idea"}]
  ```
  Strip the block from the rendered markdown, parse it defensively (ignore it on any
  error), and render the cards. `kind` habit/task → **Add**, which creates the entity via
  the existing repositories, local-first. `kind` idea → **Remind me**, which schedules a
  local notification in 2h through the existing notifications service. Exactly one card
  may be `recommended` and gets the gradient treatment.
- Fallback: if there's no JSON but the reply has a bullet list after a question, render
  the bullets as `idea` cards.
- Stream the reply if the API supports it; otherwise reveal the text in chunks over about
  600ms. Show the three-dot typing indicator before the first token. Spark `busy` is true
  while generating.
- Quick-reply chips: "Plan tomorrow" and "Why am I tired?", or 2 suggested follow-ups if
  the JSON provides `"followUps": [...]`.
- Offline: the composer shows "Aurora is offline. Your plans still work." and disables
  send. Do not queue messages.

**Atlas (World)**: no schema change; WorldTile rows become places.
- Map each tile to a globe coordinate deterministically:
  `lon = (positionX / 5) * 360 + positionY * 37` (mod 360) and
  `lat = -55 + positionY * 22` (rows 0–5 map to -55…55).
- Project onto the visible hemisphere with the current rotation `θ` (ambient
  `θ += 360°/14s * speedFactor`, plus drag inertia). A pin is visible when `cos(lon - θ) > 0`;
  its screen x is `cx + r * sin(lon - θ) * cos(lat)` and its screen y is `cy - r * sin(lat)`.
  Scale and opacity fall off with `cos(lon - θ)`.
- Display names: keep `tile.name`, but if the name is one of the generic seed names
  (Meadow, Forest, Mountain, Lake, Dunes, Town, Cottage, Wonder), decorate it
  deterministically by index from a list (Meadow → "Sun Meadow", Forest → "Pine Ridge",
  Lake → "Still Lake", Water → "Lantern Bay", and so on) so places feel unique. Do this in
  the UI layer only.
- **Next place** = the locked tile with the lowest `unlockRequirement`. XP to go is
  `unlockRequirement - user.totalXp` (min 0), and progress is relative to the previous
  unlocked threshold.
- **Discovery:** if `user.totalXp >= unlockRequirement` for the next tile, call the
  existing `WorldActions.unlock(id)` (local-first) and run the discovery celebration.
  Check this after every XP-changing action and on app resume. Remember celebrated tile ids
  in prefs (`atlas.discovered.celebrated`) so it never replays.
- The globe is a `CustomPainter` driven by a `Ticker`. Meridians are a horizontally
  scrolling pattern clipped to a circle, and the specular highlight is a radial overlay.
  Repaint only the globe layer.

**Insights** (`analytics_screen.dart`):
- XP per day for the ISO week comes from progress entries. Best day = max (ties go to the
  latest). Completion = done ÷ set for the week. The trend compares with the previous week
  as a whole percentage; when negative, show a neutral chip "{n}% lighter week" with no red.
- The category breakdown comes from completed items' categories, using the category colors.

### Screens not in the mocks
Apply the "Extrapolating" rules from the README to Quick Add, Profile/You, Progress,
Achievements, Avatar, Notifications, Settings, Sync and data, Paywall, Onboarding
(intro + setup), Auth (splash, login, signup), Legal and About. Keep their current
logic; restyle only. Where a screen had a horizon or aurora art, replace it with an
`InkHeroCard` or the spark.

## Phase 5: Polish & verification
- **Reduced motion:** turn on the OS setting and verify there are no loops (glow, spark,
  globe, pings, shimmer), that transitions become crossfades, and that the haptics remain.
- **Dark theme:** verify every screen against `screenshots/dark/`. Check that raised
  containers have their 1px border, actions are cream with ink text, chart bars are
  `#4A453E`, and the gradient, spark and globe are unchanged. Toggle the theme while on each
  screen: there should be a smooth 360ms transition, and ambient loops must not restart.
- **Accessibility:** text contrast is at least 4.5:1 (check `textMuted` on canvas: it's
  4.6:1, so don't go lighter). Tap targets are at least 44. Every icon-only button has a
  `Semantics` label. Rows announce "{title}, {meta}, {done/not done}". Dynamic type: layouts
  must not clip at 1.3× text scale (let rows grow; never fix heights on text).
- **Performance:** wrap ambient animations in `RepaintBoundary`. The globe and hero glow
  must not rebuild their parents. Hold 60fps on a mid-range Android, profiling with the
  existing `refresh_rate_provider` for 120Hz.
- **Tablet:** check the wide shell (rail plus content max-width 720, centred).
- **Golden tests:** add a golden test per redesigned screen at 390×844, light and dark,
  with sample data from `lib/core/sample/`.
- Finally, compare every screen side by side with `docs/design/daylight/screenshots/` and
  fix any visible differences in spacing, size, color, radius or copy.

## Definition of done
- All six designed screens match the screenshots at 390×844 within a few pixels, in **both**
  light (`screenshots/`) and dark (`screenshots/dark/`).
- No widget hardcodes a surface or text color: everything goes through `context.palette`.
- The nav never overlaps content, and the FAB is never on top of a row.
- Every interaction in `MOTION_AND_INTERACTIONS.md` is implemented and respects reduced motion.
- No Fraunces, Hanken Grotesk, aurora teal/lilac/rose, Living Horizon, or old icon remains.
- `flutter analyze` is clean, all tests pass, and there are no Drift or backend schema changes.
