# Dark theme: Atlas Daylight "after dark"

The target visuals are in `screenshots/dark/` (3x). `00_overview_board_dark.png` shows all
six screens. The live reference is `design_reference/Atlas Redesign v2 Dark.dc.html`.

## Principle
Dark is **not an inversion**. It keeps the same hierarchy with three moves:
1. **Canvas → warm near-black** `#0F0E0B` (never pure black, never blue-black).
2. **Paper → charcoal** `#1C1A16`. Cards stay flat, with no shadows and no borders.
3. **Ink surfaces split in two:**
   - *Containers* (the hero card, nav pill, Next card, Best day tile) become **raised
     charcoal** `#26231D` with a **1px `#34302A` border**, so they still read as the
     "heavy" element.
   - *Actions* (Tend, Listen, active segment, active nav pill, user chat bubble, Add,
     progress fills) **flip to cream** `#F4F1EA` with ink `#16140F` text. The primary
     action is always the brightest thing on screen.

**Unchanged in dark:** the sunrise gradient, the spark mark, the globe, the FAB, the hero
glow, the category foreground colors (except pine, see below) and every motion spec.

## Token map (light → dark)
| Role | Light | Dark | Notes |
|---|---|---|---|
| canvas | `#F4F1EA` | `#0F0E0B` | Scaffold, sheets, chat composer |
| paper | `#FFFFFF` | `#1C1A16` | Rows, tiles, inputs, icon buttons, Aurora bubble |
| raised (ink container) | `#16140F` | `#26231D` + 1px `#34302A` | Hero card, nav pill, Next card, Best day tile |
| action (primary fill) | `#16140F` + white text | `#F4F1EA` + `#16140F` text | Tend, Listen, segmented pill, active nav pill, user bubble, ink Add |
| progress fill (ink bars) | `#16140F` | `#F4F1EA` | XP bar, completion bar |
| chart bar (non-best) | `#16140F` | `#4A453E` | Best day keeps the gradient |
| textPrimary | `#16140F` | `#F4F1EA` | |
| textBody (letters, chat) | `#4A453E` | `#D9D2C5` | |
| textSecondary | `#5E5A53` | `#A8A296` | |
| textMuted | `#6E695F` | `#9C968B` | 6.5:1 on canvas, 5.9:1 on paper |
| textFaint (placeholder) | `#A39E95` | `#6E695F` | |
| chevron | `#B3ADA2` | `#5E5A53` | |
| iconInactive (nav) | `#8C877E` | `#8C877E` | Same |
| track | `#ECE7DD` | `#2A2722` | Tracks, Later and Remind me pills, segmented track |
| hairline | `#E7E2D8` | `#34302A` (raised border), `#2A2722` (dividers) | Empty sparkline bars use `#34302A` |
| outline (unchecked circle) | `#DDD6C9` | `#4A453E` | |
| letter gradient | `#FFE7D6` → `#FFDDE3` → `#E9E2FF` | `#3A2418` → `#3A1C26` → `#241C45` | Same angles (150° tile, 160° card) |
| letter secondary button | white 70% | white 10% | "Read all" |
| recommended card border | `#FFB8A8` | `#FF5E62` at 60% | |
| success fg / bg | `#1E9A58` / `#E2F6EA` | `#4FD08A` / `#2FBF71` at 18% | Trend chip, sync chip |
| pine (category fg) | `#1E9A58` | `#4FD08A` | Lifted for contrast |
| tints (category bg) | solid pastels | category fg at 18–24% alpha | violet 20%, pine 24%, the rest 18% |
| device/status text | ink | `#F4F1EA` | Use `SystemUiOverlayStyle.light` |
| scroll fade behind nav | canvas → transparent | `#0F0E0B` → transparent | |
| backdrop scrim (sheets) | ink at 35% | `#000` at 55% | |
| skeleton | `#ECE7DD` | `#2A2722`, shimmer highlight `#34302A` | |

Exact Flutter values are in `tokens/app_colors.dart` (the `*Dark` constants) and
`tokens/app_palette.dart` (the `AtlasPalette.light` and `AtlasPalette.dark` ThemeExtension).

## Screen-specific notes
- **Home:** the hero card is raised charcoal with a border. The glow blob keeps the same
  colors and opacity; it reads stronger on dark, and that's intended. Inactive segments
  stay white at 15%. The letter tile uses the dark letter gradient, with title text
  `#F4F1EA` and meta `#9C968B`.
- **Grow:** the active segment is a cream pill with ink text. Ring tracks are `#2A2722`.
  The unchecked circle border is `#4A453E`. Sparkline done bars keep the category color;
  missed bars are `#34302A`.
- **Aurora:** the dark letter card, with the 140px spark still at 50% opacity. Body text is
  `#D9D2C5`. Listen is a cream pill and Read all is white 10%.
- **Chat:** the user bubble is cream with ink text; Aurora's bubble is charcoal paper. The
  recommended card has a coral 60% border and a gradient Add. Other Add pills are cream
  with ink text, and Remind me uses the track color with cream text.
- **Atlas world:** the globe is identical. Its coral halo is more visible, which is fine.
  Pin label chips stay white 85% with ink text, and the next pin stays ink with a white
  border (it sits on the globe, not on the canvas). The Next card is raised charcoal.
- **Insights:** non-best bars are `#4A453E`; the best-day bar keeps the gradient and its
  label stays `#FF5E62`. Best day is a raised tile with gradient text. The completion bar
  fill is cream.

## Implementation rules
1. **Use only `AtlasPalette`.** Widgets must read colors through
   `context.palette.paper`, `context.palette.action` and so on. Never use
   `AppColors.paper` directly, and never branch on `Theme.of(context).brightness` inside
   widgets. The theme extension is the single switch.
2. **Theme mode:** keep the existing theme toggle and `ThemeMode.system` default. Map the
   options to `ThemeMode.light`, `ThemeMode.dark` and `ThemeMode.system`, and persist the
   choice in the existing settings provider.
3. **Switching animates:** wrap the `MaterialApp` theme change in an implicit
   `AnimatedTheme` (360ms, easeOutCubic). Ambient loops must not restart on theme change, so
   keep their controllers above the theme.
4. **System UI:** set `SystemUiOverlayStyle.light` in dark (status-bar icons light, nav-bar
   color `#0F0E0B`) and `.dark` in light, via an `AnnotatedRegion` in the shell.
5. **Native splash and icon:** the app icon is the same in both modes (the ink tile already
   suits dark). For `flutter_native_splash`, use `color: "#F4F1EA"` and `color_dark: "#0F0E0B"`
   (plus the `android_12` equivalents), with the same `atlas_splash.png`.
6. **Images and illustrations:** anything with a baked light background must have a dark
   variant or a transparent background.
7. **Markdown in chat:** the `gpt_markdown` text color must come from the palette
   (`textBody`). Links are `#FF5E62` in both themes.
8. **Contrast check:** every text-on-surface pair in the table above is at least 4.5:1. If
   you add a new pair, verify it.
9. **Golden tests:** every redesigned screen is goldened in light **and** dark at 390×844.
   Compare the dark goldens against `screenshots/dark/`.
