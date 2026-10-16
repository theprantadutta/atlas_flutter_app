## Design is the #1 priority of this app

Atlas must look and feel like one of the best-designed apps on the market: distinctive,
modern, and genuinely caring about the user's mental health. Never ship generic,
templated, or default-Material UI.

### The visual identity: "Daylight"
The metaphor: **every day is a small sunrise, and over time you discover a whole world.**

- **Mood:** bright, warm, confident, kind. Gamified but never anxiety-inducing: no red
  failure states and no streak-shaming copy.
- **Palette:** warm canvas `#F4F1EA`, white paper cards, ink `#16140F` for text, the hero
  card, the nav and primary buttons. One signature **sunrise gradient** (`#FFB36B` →
  `#FF5E62` → `#8E6CFF`), used ONLY for things that are alive: done checks, completed
  progress, the FAB, Aurora's spark, and best-day highlights. A soft "letter" tint
  (`#FFE7D6` → `#FFDDE3` → `#E9E2FF`) for Aurora surfaces. Tokens live in
  `lib/shared/themes/app_colors.dart`.
- **Type:** Funnel Display for titles and numbers (tight negative tracking), Funnel Sans
  for UI and body. See `lib/shared/themes/app_typography.dart`. Do not reintroduce
  Fraunces, Hanken Grotesk, Poppins or Inter.
- **Dark theme:** first-class. Canvas `#0F0E0B`, paper `#1C1A16`, ink containers become
  raised `#26231D` with a 1px `#34302A` border, and actions flip to cream. The gradient is
  unchanged. Colors come only from `context.palette` (`lib/shared/themes/app_palette.dart`).
  See `docs/design/daylight/DARK_THEME.md`.
- **Signature elements:** (1) the ink **hero card** with a drifting sunrise glow on Home;
  (2) the **Atlas globe**, where world tiles are places you discover; (3) the four-point
  **spark** mark for Aurora and the app logo (`lib/shared/widgets/brand/atlas_logo.dart`).
- **Surfaces:** flat. No card shadows. Rows radius 22, tiles 26, hero cards 32. The only
  glows are the FAB and the globe.
- **Navigation:** a 4-tab ink pill (Home, Grow, Aurora, Atlas) with a separate gradient
  FAB to its right, which never overlaps content. Profile is reached from the avatar.
- **Motion:** calm ambient loops, crisp 90–360ms touch responses, one joyful moment per
  milestone, haptics on every commit. Always respect reduced-motion. The full spec is in
  `docs/design/MOTION_AND_INTERACTIONS.md`.
- **Copy:** no em or en dashes anywhere (use commas, colons, "to").

### Working rules
- Reuse the design tokens (`app_colors`, `app_typography`, `app_spacing`, `app_motion`) and
  the shared widgets in `lib/shared/widgets/`. No inline magic numbers.
- The gradient is a reward, not decoration: if nothing is alive, it shouldn't be there.
- When unsure, choose fewer, calmer, more confident options.
