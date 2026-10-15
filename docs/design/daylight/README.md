# Handoff: Atlas "Daylight" redesign

> Start here: open `CLAUDE_CODE_PROMPT.md` and paste it into Claude Code from the root of
> the `atlas_flutter_app` repo. This README is the full spec that prompt refers to.

## Overview
Atlas is a gamified, offline-first habit, task and goal app built in Flutter, with an AI
companion called Aurora and a world that grows as the user tends themselves. This package
is a **ground-up visual redesign** called **Daylight**. Every feature, data model and flow
stays the same; the visual identity, layout and motion are replaced.

| | Before (current app) | After (Daylight) |
|---|---|---|
| Base | Dark twilight ink `#0E1326` | Warm light canvas `#F4F1EA` with ink `#16140F` |
| Accent | Aurora gradient teal → lilac → rose | Sunrise gradient `#FFB36B` → `#FF5E62` → `#8E6CFF` |
| Type | Fraunces + Hanken Grotesk | Funnel Display + Funnel Sans |
| Signature | Living Horizon (sky + hills) | The Atlas globe (places you discover) + one ink "hero" card |
| Aurora mark | Sparkle icon in a circle | Four-point spark, gradient filled, slowly shimmering |
| Nav | 5 tabs + floating FAB overlapping content | 4 tabs in an ink pill + separate gradient FAB; "You" moves to the avatar |

`before_current_app/` holds screenshots of the current app for reference. `screenshots/`
holds the new design (3x, 1170×2532), and `screenshots/dark/` holds the dark theme.

## About the design files
The files in `design_reference/` are **design references created in HTML**: prototypes that
show the intended look and behaviour. They are not production code. The task is to
**recreate them in the existing Flutter codebase** using its patterns (Riverpod,
go_router, Drift, `flutter_animate`, `google_fonts`, the token files in
`lib/shared/themes/`, and the shared widgets in `lib/shared/widgets/`).

To view the reference, open `design_reference/Atlas Redesign v2.dc.html` in a browser.
`support.js` must sit next to it. All six screens are shown on one board, with design
notes under each.

## Fidelity
**High fidelity.** Colors, type, spacing, radii and copy are final. Recreate them
pixel-accurately at a 390×844 logical viewport, then let layouts flex for other sizes.
Screens that weren't designed (see "Extrapolating" below) should be built from the same
system.

---

## Design tokens

Ready-to-drop Dart versions live in `tokens/`. They keep the **existing public token
names** wherever possible so widgets compile, and add new ones.

### Color
| Token | Hex | Use |
|---|---|---|
| canvas | `#F4F1EA` | Screen background |
| paper | `#FFFFFF` | Cards, rows, inputs, icon buttons |
| ink | `#16140F` | Primary text, hero card, nav pill, primary buttons, chart bars |
| inkSoft | `#4A453E` | Long-form body text (letters, chat) |
| textSecondary | `#5E5A53` | Supporting copy |
| textMuted | `#6E695F` (mock shows `#77726A`; darkened for 4.5:1 contrast) | Meta lines, labels, dates |
| textFaint | `#A39E95` | Placeholders |
| iconInactive | `#8C877E` | Inactive nav icons (on ink) |
| chevron | `#B3ADA2` | Trailing arrows |
| track | `#ECE7DD` | Progress tracks, segmented control track, secondary buttons |
| hairline | `#E7E2D8` | Dividers, header bottom borders, empty sparkline bars |
| outline | `#DDD6C9` | Unchecked check circle border |
| sunriseA | `#FFB36B` | Gradient stop 0 |
| sunriseB | `#FF5E62` | Gradient stop 0.55, notification dot, today label |
| sunriseC | `#8E6CFF` | Gradient stop 1 |
| letterA / B / C | `#FFE7D6` / `#FFDDE3` / `#E9E2FF` | Soft "letter" gradient (Aurora surfaces) |
| success | `#1E9A58` on `#E2F6EA` | Positive trend chip |

**Category colors** (fg / tint background):
- Health, Fitness: `#FF6A4D` / `#FFE9E3`
- Water, Info, Learning (charts): `#3FA7F5` / `#E3F1FD`
- Growth, Stretch: `#2FBF71` / `#E2F6EA`
- Forest (deep green): `#1E9A58` / `#DDF2E6`
- Mind, Sleep, Mindfulness: `#8E6CFF` / `#EEE8FF`
- Reward, Rest, Creative: `#F5A524` / `#FDF2DC`

**Gradients**
- `sunrise`: linear, 120° (begin topLeft → end bottomRight), stops `#FFB36B` 0, `#FF5E62` 0.55, `#8E6CFF` 1.
  Use it **only** for things that are alive: done checks, completed progress segments, the
  FAB, the send button, best-day bars, the Aurora spark, the avatar ring, the "%" glyph and
  the recommended Aurora action. Never as a large background.
- `sunriseBar`: horizontal version for progress fills (`#FFB36B` → `#FF5E62` → `#8E6CFF`).
- `letter`: 160°, `#FFE7D6` 0 → `#FFDDE3` 0.5 → `#E9E2FF` 1. Aurora's letter card and the Home letter tile.
- `heroGlow`: radial at 40%/45%, `#FFB36B` 0 → `#FF5E62` 0.38 → `#8E6CFF` 0.62 → transparent 0.72, blurred σ≈18. Drifts in the corner of the ink hero card.
- `globe`: radial at 34%/28%, `#FFF4E8` 0 → `#FFC79A` 0.22 → `#FF7F6A` 0.48 → `#B565D8` 0.72 → `#5B3CC4` 1.

**Dark theme:** fully specified in `DARK_THEME.md`, with target screenshots in `screenshots/dark/` and a ThemeExtension in `tokens/app_palette.dart`. In short: canvas `#0F0E0B`, paper `#1C1A16`, ink containers become raised `#26231D` with a 1px `#34302A` border, and primary actions flip to cream `#F4F1EA` with ink text. The gradients don't change.

### Typography
Both fonts are on Google Fonts. Use `GoogleFonts.funnelDisplay` / `GoogleFonts.funnelSans`
if the installed `google_fonts` version has them; otherwise download the TTFs from
fonts.google.com and bundle them under `assets/fonts/` (declare them in `pubspec.yaml`).
Remove Fraunces and Hanken Grotesk.

| Role | Font | Size / weight | Letter-spacing | Line height |
|---|---|---|---|---|
| hero number | Funnel Display | 96 / 700 | -0.06em | 0.78 |
| stat number | Funnel Display | 64 / 700 | -0.05em | 0.85 |
| screen title | Funnel Display | 40 / 700 | -0.04em | 1.0 |
| greeting | Funnel Display | 34 / 700 | -0.035em | 1.0 |
| letter headline | Funnel Display | 32 / 600 | -0.03em | 1.05 |
| sub-screen title | Funnel Display | 30 / 700 | -0.03em | 1.0 |
| card number | Funnel Display | 28 / 700 | -0.03em | 1.0 |
| section header | Funnel Display | 21 / 700 | -0.02em | 1.1 |
| chat header name | Funnel Display | 19 / 700 | -0.02em | 1.1 |
| row title | Funnel Sans | 15 / 700 | 0 | 1.3 |
| body | Funnel Sans | 15 / 400 | 0 | 1.55 |
| button / nav label | Funnel Sans | 14 / 700–800 | 0 | 1 |
| chip | Funnel Sans | 13 / 700 | 0 | 1 |
| meta | Funnel Sans | 12 / 600 | 0 | 1.3 |
| kicker | Funnel Sans | 12 / 800, UPPERCASE | 0.12em | 1 |
| day label | Funnel Sans | 11 / 700 | 0 | 1 |

Numbers in rows and charts use tabular figures (`FontFeature.tabularFigures()`).

### Spacing, radii, elevation
- Spacing: keep the existing `AppSpacing` 4/8 scale. Screen gutter is **20** (it was 20).
  Header content gets an extra 4 inset. Gaps between rows are **8**, between sections **14–16**.
- Radii: hero card **32**, letter card **32**, chart card **30**, tiles **26**, rows **22**,
  list buttons **20**, icon tiles **14–16**, check circles and pills full.
  Add `radiusXxl = 32` and `radiusRow = 22` to `AppSpacing`.
- Elevation: the design is flat. No card shadows. Only two glows exist:
  - FAB and send button: `0 12 26` blur, `#FF5E62` at 40% alpha.
  - Globe: `0 40 80` blur, `#5B3CC4` at 35% alpha, plus an inset shade bottom-right.

### Iconography
The design uses Material Symbols Rounded (outlined when inactive, filled when active or
inside tinted tiles). In Flutter, use the `_rounded` variants of `Icons.*`, or add
`material_symbols_icons` for exact parity. Key mappings: home, checklist (Grow),
auto_awesome (Aurora), language (Atlas), notifications, search, tune, arrow_back,
arrow_forward, more_horiz, add, check, mic, arrow_upward, play_arrow,
local_fire_department, trophy, sailing, grass, forest, water, menu_book, bedtime,
directions_run, water_drop, accessibility_new, hotel, self_improvement, directions_walk,
coffee, edit_note, calendar_month, celebration, cloud.

---

## Navigation shell (replaces `AuroraNavBar` + `AuroraFab` layout)
- **4 tabs:** Home, Grow, Aurora, Atlas (World is renamed "Atlas" in the UI; keep the route
  name `world`). **"You" leaves the tab bar**: tap the avatar in the Home header to go to
  `profile`. Keep the `you` branch in the router so deep links still work.
- **Bar:** floating ink pill, height 64, full radius, inset 16 left, 16 + 64 + 10 right
  (room for the FAB) and 26 from the bottom safe area. Inner horizontal padding is 8.
- **Active tab:** white pill 48 high, horizontal padding 16, filled icon 21 plus label
  14/800 ink. Inactive tabs: outlined icon 24 in `#8C877E`, no label.
- **FAB:** 64 circle, sunrise gradient, white `add` icon 30, glow shadow. It sits to the
  right of the bar with a 10 gap, so it can **never overlap content**.
- Scroll views get bottom padding of 64 + 26 + 24 = 114 (update `AppSpacing.bottomNavSpace`).
  A 120px fade from transparent to canvas sits behind the bar.
- **Wide (iPad):** keep `_WideShell`. Style the rail in ink, with the active item as a
  white pill and the FAB at the bottom.
- Back-button behaviour, coach marks and the notification primer stay exactly as they are.

## Screens
Measurements assume a 390pt-wide device with a 50pt status bar. Copy is final unless it's data.

### 1. Home (`home_screen.dart`)
**Purpose:** see how today is going and act on the next thing.
1. **Header** (top padding 12, gutter 20 + 4 inset): date "Tuesday, 14 October" (meta
   14/600 muted) above greeting "Hey {firstName}" (34 display). Right side: bell button (44
   white circle, notifications icon 22, 8px `#FF5E62` unread dot at top-right) and avatar
   (44 circle with a 2px sunrise ring, ink inner with white initial 14/800). Avatar → profile.
2. **Hero card** (height 236, radius 32, ink, padding 22, clips its content):
   - The `heroGlow` blob is 260×260, offset right -70 and top -80, and drifts (see motion).
   - Top row: "Today" (14/600, white 70%) and a streak chip (white 12% background, flame
     icon 15 in `#FFB36B`, "{n} days" 12/700).
   - A big percentage: day progress rounded to an integer, 96 display, white, with the "%"
     glyph in the sunrise gradient (ShaderMask). Beside it, "{done} of {total}\ntended" in
     15/600 at 75% white.
   - **Segmented bar:** one segment per item today (cap at 8, then switch to a continuous
     bar), 8 high, 6 gap, full radius. Done segments use the sunrise gradient; the rest are
     white at 15%.
3. **Two tiles** (2 columns, gap 10, radius 26, padding 16):
   - XP tile (white): "Level {n}" and "{xpInLevel}/{xpForLevel}" (12/700 muted), then
     "+{xpToday} XP" (28 display), then a 6px ink progress bar on the track color.
   - Letter tile (`letter` gradient): a 30px Aurora spark, "Your weekly letter is ready"
     (15/700), "from Aurora" (12/600 muted). Only show it when a reflection is unread;
     otherwise it becomes "Talk to Aurora". Tap → Aurora tab.
4. **"Up next"** (21 display) with "See all {n}" (13/700 muted) → Grow. Show at most 2 rows
   of not-done items, ordered by scheduled time then creation date.
   **Row:** height 64, white, radius 22, padding 0 10 0 12. A 42 icon tile (radius 14,
   category tint, filled category icon 22), title 15/700, meta "{time} · +{xp} XP" 12/600
   muted. Trailing action: **Tend** (ink pill, 40 high, padding 14, 13/700 white) for the
   first row, **Later** (track pill, ink text) for the rest.
   When everything is done, swap the section for a "Day complete" empty state: a large
   sunrise spark, "That's everything for today." and "Add something" (secondary).

### 2. Grow · Habits (`grow_screen.dart`)
1. Title "Grow" (40 display) and a search button (44 white circle).
2. **Segmented control:** track `#ECE7DD`, padding 5, full radius. Tabs Tasks / Habits /
   Goals at 14/700 muted; the active tab is an ink pill with white 14/800 text. The pill
   slides between tabs (see motion).
3. **Week strip** (white, radius 26, padding 14 12): 7 columns, each with a day letter
   (11/700, today in `#FF5E62`) and a 34px ring (3–4px stroke) showing that day's
   completion as a conic sweep in the sunrise gradient on the track color. The day number
   sits in the middle (12/800). Tapping a day filters the list to that date (read-only for
   past days).
4. Section header "Today · {done} of {total}" (21 display) with the frequency filter
   "Daily" (13/700 muted; tap to cycle Daily / Weekly / All).
5. **Habit row:** height 70, white, radius 22, padding 0 12. A 44 icon tile (radius 15),
   name 15/700, meta 12/600 muted ("{n} day streak", or the scheduled time when not done).
   Then a **7-day sparkline**: 7 bars, 4 wide, gap 2, heights 4–22, filled with the
   category color on days done and `#E7E2D8` (height 4) on missed days. Last is a **check**:
   a 34 circle; done is the sunrise gradient with a white check, not done is a 2px
   `#DDD6C9` border.
6. The Tasks and Goals tabs use the same row anatomy. Tasks are grouped Daily / Weekly /
   Long-term with 21-display headers. Goals use a taller row (radius 22): the title, a
   status chip, "{pct}%" as a 28-display number, a 6px progress bar in `sunriseBar`, and
   "Target · in N weeks".

### 3. Aurora (`aurora_screen.dart`)
1. Header: a 40px animated Aurora spark beside the title "Aurora" (40 display), and a tune
   button (44 white) → `auroraSettings`.
2. **Letter card** (`letter` gradient, radius 32, padding 22, clips its content). A 140px
   spark at 50% opacity bleeds off the top-right corner. Contents:
   - The kicker "SUNDAY LETTER" (12/800, 0.12em) and the date range "26 Jul to 2 Aug"
     (12/700 muted). House style: no en or em dashes, so write "to".
   - The headline: the **first sentence** of the reflection (32 display 600).
   - The body: the next 1–2 sentences (15/1.55 `#4A453E`), truncated cleanly at a sentence
     boundary.
   - Buttons: **Listen · {m} min** (ink pill, 46 high, play icon) and **Read all** (white
     70% pill) → full reflection screen. The "Deep"/mode tag moves into the full view.
3. "Start a conversation" (21 display), then a list of 4 starter rows: height 58, white,
   radius 20, a colored icon, label 15/700, arrow. Starters: "Tell it the way it is"
   (edit_note, coral), "Plan my week" (calendar_month, violet), "Celebrate a small win"
   (celebration, amber), "I feel stuck" (cloud, blue). Tap → chat, prefilled and sent.

### 4. Aurora chat (`aurora_chat_screen.dart`)
1. Header bar (bottom border hairline): back (42 white), a 34 spark, the name "Aurora"
   (19 display) over the status "{tone} · knows your week" (12/600 muted), and a more
   button.
2. **User bubble:** ink with white 15/1.45 text, radius 24/24/6/24 (tail bottom-right), max
   width 270, right aligned.
3. **Aurora bubble:** white with ink text, radius 24/24/24/6, max width 320. Render markdown
   (`gpt_markdown`) with italics allowed and no headings.
4. **Suggestion cards** (new): when Aurora proposes actions, render each as a card (white,
   radius 20, padding 10 10 10 12, 1.5px border). It has a 38 icon tile, title 14/700 and
   meta 12/600 ("Habit · 10:15 pm · +15 XP"), plus a trailing pill (34 high).
   - The **recommended** card has a `#FFB8A8` border and a sunrise-gradient **Add** pill.
   - Other cards have no border and an ink Add pill, or a track-colored "Remind me" pill
     for non-trackable ideas.
   - Add → creates the habit or task through the existing repositories (local-first).
5. **Composer** (canvas, top hairline, padding 12 16 30): quick-reply chips (white,
   13/700). Below them, the input (54 high, white pill, placeholder "Message Aurora" in
   `#A39E95`, mic icon) and a 54 gradient send button.

### 5. Atlas · World (`world_screen.dart`)
1. Title "Your Atlas" (40 display), subtitle "{alive} of {total} places discovered" (15/600
   muted), and a trophy button (amber filled icon) → achievements.
2. **The globe** (300×300, centred, top ≈150). A sphere painted with the `globe` radial
   gradient and a top-left specular highlight. Meridian lines (white 35%, 1.5px, every
   48px) scroll horizontally to fake rotation, with latitude lines (white 30%) every 42px
   and the edges masked. A soft coral halo extends 30px beyond the sphere.
   **Pins:** discovered places are 12px white dots with a white glow and a white label chip
   (11/800 ink). The **next** place is an ink dot with a 2.5px white border, a looping
   ping ring and an ink label "{name} · next".
3. **Next card** (ink, radius 26, padding 16): a 48 gradient icon tile, "Next: {name}"
   (15/700 white), "{xp} XP" (12/700, 70%), and a 6px `sunriseBar` progress bar on white 15%.
4. **Discovered** grid: 3 columns, gap 8. Each tile is white, radius 20, padding 12, with a
   34 icon tile, name 13/700 and "Found {date}" 11/600 muted. It scrolls; the most recent
   come first.

### 6. Insights · Your week (`analytics_screen.dart`)
1. Back button (42 white), title "Your week" (30 display), and a week chip
   ("Week {isoWeek}", white pill 12/700) that opens a week picker.
2. **Hero card** (white, radius 30, padding 20 18 16): the XP total (64 display), "XP earned
   this week" (13/600 muted) and a trend chip ("↑ 18%" success colors, or a neutral chip
   when the change is negative; never red).
   **Bars:** 7 columns, gap 10, 160 high, radius 14, ink bars with day letters below. The
   **best day** bar uses the sunrise gradient (vertical) and its label is `#FF5E62`.
3. Two tiles: **Best day** (ink tile: "Best day" 12/700 at 60% white, the day name in 28
   display with gradient text, "{xp} XP · {n} tended") and **Completion** (white tile:
   "{pct}%" in 28 display and a 6px ink bar).
4. **"Where your XP came from"**: one stacked bar (14 high, full radius, 3px gaps between
   segments) in category colors, with a legend row (dot plus "Health 380").

### Extrapolating to screens not drawn
Build these with the same rules: canvas background, white rows (radius 22), one ink hero
element per screen at most, Funnel Display titles at 40 (tab roots) or 30 (pushed
screens), back button as a 42 white circle, and the gradient only on live or completed
elements.
- **Quick add sheet:** a canvas sheet with radius 32 top corners and a grabber 40×5
  `#DDD6C9`. Title "Add something" (30 display). An Aurora input (white, 56 high, spark
  icon left, gradient send) with the placeholder "e.g. read 20 pages on weekdays". Below
  "or add manually", three white rows (New task, New habit, New goal) with tinted icon tiles.
- **Profile / You:** a header with a large avatar (sunrise ring) and name; an ink hero card
  with level, total XP and best streak; then grouped white rows (Aurora voice, Display,
  Notifications, Sync and data, About, Legal). Sync status uses a green success chip.
- **Progress:** "Day by day" white rows, each with the day, a `sunriseBar` progress fill
  and "+{xp} XP" in ink. Today's row is ink.
- **Achievements:** a 3-column grid of white tiles with tier-tinted icon tiles. Locked
  badges are an outline only.
- **Splash, auth and onboarding:** a canvas background, the gradient spark centred and the
  lockup `brand/atlas_lockup_light.svg`. Primary buttons are ink pills 56 high.
- **Paywall:** a full-bleed `letter` gradient top, an ink plan selector card, and a
  gradient primary CTA.

---

## Interactions & motion
The full spec is in `MOTION_AND_INTERACTIONS.md`. In short: calm ambient loops, crisp
120–360ms responses, one joyful moment per milestone, haptics on every commit, and **all
loops disabled when `AppMotion.reduceMotion` is true**.

## State & logic
The full spec is in `CLAUDE_CODE_PROMPT.md`, section "Internal logic". The data layer
(Drift, repositories, sync) does **not change**: no schema changes are required. The
WorldTile table now renders as places on the globe.

## Assets (`brand/`)
- `atlas_mark.svg` (gradient spark), `atlas_mark_ink.svg`, `atlas_mark_white.svg`
- `atlas_lockup_light.svg` / `atlas_lockup_dark.svg`: spark plus the "Atlas" wordmark in
  Funnel Display 700. The text is live, so convert it to outlines before shipping.
- `atlas_app_icon.svg` + `png/atlas_icon.png` (1024, full-bleed ink with a gradient spark)
- `png/atlas_icon_fg.png` / `png/atlas_icon_bg.png` (Android adaptive) and
  `png/atlas_splash.png` (768, transparent spark for the native splash)
- `png/atlas_mark_*_512.png` and `png/atlas_icon_preview_rounded.png`

The spark geometry, in unit coordinates with a radius of 1:
`(0,-1) (.22,-.22) (1,0) (.22,.22) (0,1) (-.22,.22) (-1,0) (-.22,-.22)`. Implement the
in-app logo as a `CustomPainter` with this path (replacing `atlas_logo.dart`).

## Files in this bundle
- `CLAUDE_CODE_PROMPT.md`: the prompt to paste into Claude Code
- `MOTION_AND_INTERACTIONS.md`: every animation, gesture and haptic
- `DARK_THEME.md`: the full dark theme spec (token map, per-screen notes, implementation rules)
- `CLAUDE_md_design_section.md`: replacement "visual identity" section for the repo's `CLAUDE.md`
- `tokens/`: drop-in `app_colors.dart`, `app_palette.dart` (light and dark ThemeExtension), `app_typography.dart`, `app_motion.dart`, `app_spacing.dart`
- `brand/`: logo, icon and splash assets
- `screenshots/`: the new light design at 3x plus an overview board, and `screenshots/dark/` for the same in dark
- `before_current_app/`: the current app for comparison
- `design_reference/`: the HTML prototypes, light (`Atlas Redesign v2.dc.html`) and dark (`Atlas Redesign v2 Dark.dc.html`)
