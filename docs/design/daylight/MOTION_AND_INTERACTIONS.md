# Motion & interactions: Atlas Daylight

Principle: **calm by default, crisp on touch, joyful at milestones.** Motion always
explains something: progress moving, an item being committed, or a place being discovered.

Implement with `flutter_animate` (already a dependency) and implicit animations. Wrap
every **looping or ambient** effect in `if (!AppMotion.reduceMotion(context))`. With
reduced motion on, replace movement with a 120ms opacity crossfade and keep the haptics.

## Tokens (see `tokens/app_motion.dart`)
| Name | Value | Use |
|---|---|---|
| press | 90ms, easeOut | Scale down on touch |
| instant | 120ms | Icon swaps, chip toggles |
| fast | 220ms, easeOutCubic | Check pop, small fades |
| medium | 360ms, easeOutCubic | Fills, sheet and nav pill movement |
| slow | 600ms, easeOutCubic | Count-ups, chart growth |
| deliberate | 900ms | Celebrations |
| emphasized | easeOutBack | Things that "land" (checks, pins, toasts) |
| springSnappy | `SpringDescription(mass:1, stiffness:420, damping:30)` | Nav pill, segmented pill |
| ambientGlow | 9s, easeInOut, mirror | Home hero blob |
| ambientSpark | 5s, easeInOut, mirror | Aurora spark shimmer |
| ambientGlobe | 14s, linear, repeat | Globe rotation |
| ping | 2s, easeOut, repeat | "Next" pin and unread dots |

## Global
- **Press feedback (every tappable):** scale to 0.96 (rows, cards) or 0.92 (circle buttons)
  over 90ms, release with easeOutBack over 220ms. No ink ripples anywhere (set
  `splashFactory: NoSplash.splashFactory` in the theme).
- **Haptics:** `selectionClick` on tab, segment or chip changes; `lightImpact` on tend, add
  or send; `mediumImpact` on long-press menus; `heavyImpact` only for day complete and
  place discovered.
- **Page transitions:** tab switches crossfade over 220ms with a 12px upward slide on the
  incoming page (no horizontal slide). Pushed routes use the platform default on iOS; on
  Android, fade through with a 0.96 → 1 scale over 300ms.
- **Lists on first appear:** rows fade and slide up 12px, staggered by 40ms, capped at 8
  rows. They don't re-animate on rebuilds, only on first mount per session.
- **Numbers:** any number that changes because of the user (%, XP, streak) counts up with
  a tween over 600ms easeOutCubic, using tabular figures so the width doesn't jitter.

## Navigation
- **Tab pill:** the white active pill is one widget that slides and resizes between tab
  slots (`AnimatedPositioned` plus `AnimatedContainer`, or a spring). The label fades in
  over 120ms after the pill settles. The icon switches outlined → filled over 120ms.
  Haptic `selectionClick`.
- **FAB:** press scales to 0.92. On tap, the `add` icon rotates 45° (becoming ×) over
  220ms while the Quick Add sheet rises from the bottom (360ms easeOutCubic) and the
  backdrop dims to ink at 35%. Closing reverses both.
- **Re-tapping an active tab** scrolls it to the top over 360ms.

## Home
- **Hero glow:** the blob drifts with a translation of (-18, +14) and a scale of 1 → 1.12,
  9s mirror loop. As the day fills, its opacity goes from 0.6 at 0% to 1.0 at 100%.
- **Tend (the core interaction):**
  1. Tap Tend, or swipe a row right past 30% of its width (the background shows a
     sunrise-gradient check that scales with the drag).
  2. The button morphs into a 40 gradient circle with a check (220ms, easeOutBack).
     `lightImpact`.
  3. A **"+{xp}" chip** in sunrise gradient text floats up 28px and fades out over 600ms
     from the row.
  4. In the hero, the next segment fills left to right (360ms), and the % counts up (600ms).
     The streak chip pulses once (scale 1 → 1.08 → 1) if this was the first tend of the day.
  5. After 400ms the row collapses (height to 0 over 220ms) and the next item slides up
     into "Up next".
  6. An **Undo** toast appears for 4s (existing `AtlasToast`, restyled as an ink pill).
     Undo reverses all the effects.
- **Later:** tap, or swipe the row left. The row slides out to the left and is snoozed
  (see logic). Haptic `selectionClick`.
- **Day complete** (the last item tended): the hero glow scales to 1.6 and brightens.
  Eight small sparks burst from the % (radial, 900ms, then fade), the % lands at 100 with
  easeOutBack, the copy becomes "All tended", and `heavyImpact` fires. This plays once per day.
- **Long-press a row:** `mediumImpact` and a context sheet with Edit, Skip today,
  Snooze to tomorrow and Delete.
- **Unread letter tile:** the spark shimmers. Once it has been read, the tile turns static.

## Grow
- **Segmented control:** the ink pill slides with the snappy spring and the list
  crossfades over 220ms.
- **Week strip:** rings sweep from 0 to their value on first appear (600ms, staggered by
  40ms). Tapping a day moves a 2px ink underline under it with a spring and filters the list.
- **Sparklines:** bars grow from the bottom on first appear (staggered by 30ms, 360ms).
  When a habit is tended, today's bar grows to full height in the category color over 360ms.
- **Check circle:** tap → the border fades out, the gradient fill scales from 0.4 to 1
  (220ms, easeOutBack), and the check icon draws in. The streak meta count ticks up.
  Unchecking reverses it with no celebration.
- **Swipe a row right** to tend and **left** to skip today, with the same visuals as on Home.
- **Goals:** progress bars animate their width over 600ms when the screen appears or a
  value changes. At 100%, the status chip flips to "Complete" with a confetti-free glint:
  a white sheen sweeps across the bar over 700ms.

## Aurora
- **Spark mark:** a shimmer loop of rotation ±12° and scale 1 → 1.08 over 5s. While Aurora
  is **thinking or streaming**, the loop speeds up to 1.2s and the spark pulses its opacity
  between 0.7 and 1.
- **Letter card:** on first appear the headline fades up (fast), then the body (staggered
  80ms), then the buttons. **Listen** turns into a playing state: play becomes pause, a
  thin `sunriseBar` progress line grows along the bottom of the card, and the headline
  text highlights word by word (a gradient sweep) in sync with TTS if you add `flutter_tts`.
- **Starters:** press scale, then a push into chat with the starter text sent as the first
  message.
- **Chat:**
  - Sending: the bubble scales from the composer (0.9 → 1) and moves into place over 220ms.
    `lightImpact`.
  - Aurora's reply **streams**: render tokens as they arrive. Each new chunk fades in over
    120ms. Show a typing indicator before the first token: three 6px dots in sunrise colors
    bouncing with a 120ms stagger.
  - **Suggestion cards** slide up 12px and fade in (staggered by 60ms) once the text has
    finished. Tapping **Add** morphs the pill into "Added ✓" (width animates, 220ms), turns
    the card border to sunrise, creates the entity, shows a toast "Added to Grow", and fires
    `lightImpact`.
  - Quick-reply chips scroll horizontally. Tapping one sends it immediately.
  - The mic button is press-and-hold to talk (if speech-to-text is added). While held, the
    button scales to 1.15 and a soft gradient ring pulses.

## Atlas · World
- **Globe rotation:** meridians scroll continuously (14s per 300px, linear), and the pins
  move with the same offset, wrapping around the visible hemisphere. Pins near the edge
  fade and scale down (cos falloff) to sell the curvature.
- **Drag to spin:** a horizontal drag sets the angular velocity, which decays with friction
  0.92 per frame, then eases back into the ambient speed. A vertical drag tilts ±15°.
- **Tap a pin:** the globe eases to centre that pin (600ms easeInOutCubic) and a place
  sheet opens (name, found date, the habits that earned it, and XP).
- **Next pin:** a looping ping ring (scale 0.6 → 2.2, opacity 1 → 0, every 2s).
- **Discovery** (an XP threshold is crossed):
  1. A full-screen moment on next app open, or immediately if on Atlas: the globe spins to
     the new place (900ms).
  2. The pin drops from 40px above with easeOutBack, eight sparks burst out, and
     `heavyImpact` fires.
  3. The label chip pops in, then a card "You discovered {name}" with **Visit** and
     **Close** buttons.
  4. The "Next" card animates to the following place and its progress bar resets with a
     600ms tween.
- **Discovered grid:** a new tile inserts at the start with a scale-in (0.8 → 1, easeOutBack).

## Insights
- On appear, the bars grow from 0 (600ms, staggered by 50ms), the hero number counts up,
  and the trend chip fades in last. The best-day bar gets a single white sheen sweep after
  its growth finishes.
- Tap a bar: a tooltip pill (ink, 12/700 white) shows "{day}: {xp} XP · {n} tended"; the
  other bars dim to 40%. Tap elsewhere to clear it.
- The week chip opens a bottom sheet with the last 12 weeks. Changing week crossfades the
  bars to their new heights (360ms) with no regrow.
- Stacked category bar segments animate their widths over 600ms.

## Loading, empty & error states
- **Loading:** skeleton rows and cards in `#ECE7DD` with a slow shimmer (1.4s). Never use
  spinners, except a spark spinning for pull-to-refresh.
- **Pull to refresh** (Home, Grow, Insights): the spark rotates in proportion to the pull
  distance, then spins while refreshing. Haptic on trigger.
- **Empty:** a large spark at 30% opacity, one line of copy in 21 display and one ink pill
  button.
- **Errors:** an inline white row with a coral icon and a "Try again" text button. Offline
  is **not** an error, because the app is offline-first, so never show offline banners for
  local features. Only Aurora (network) shows "Aurora is offline. Your plans still work."
