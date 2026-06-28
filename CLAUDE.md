# Atlas Flutter App — project instructions

## Design is the #1 priority of this app

Atlas must look and feel like one of the best-designed apps on the market — distinctive,
modern, and genuinely caring about the user's mental health. **Design/UX is the primary concern
of this project.** Never ship generic, templated, or default-Material UI. Every screen must be
intentional, polished, and visually unique — beautiful typography, deliberate color, generous
spacing, and tasteful motion are required, not optional.

### The visual identity: "Living World / Aurora"
The app's metaphor is a **living world that flourishes as you take care of yourself**. Hold this
identity on every screen:

- **Mood:** calm, atmospheric, caring. Gamified, but never anxiety-inducing (gentle nudges over
  streak-shaming).
- **Palette:** twilight ink base (dark is the hero); a restrained aurora gradient
  (teal `#5EEAD4` → lilac `#8B9CF7` → rose `#F5A9C0`) used sparingly as the single bold accent;
  warm reward gold `#F4C77B`; a warm "dawn paper" light theme. Tokens live in
  `lib/shared/themes/app_colors.dart`.
- **Type:** Fraunces (soft serif) for display/headlines, Hanken Grotesk for body/UI. See
  `lib/shared/themes/app_typography.dart`. Do not reintroduce Poppins/Inter.
- **Signature element:** the **living horizon** (`lib/shared/widgets/brand/living_horizon.dart`) —
  a time-of-day aurora sky over layered hills that grows richer with progress.
- **Logo:** custom-drawn vector mark (`lib/shared/widgets/brand/atlas_logo.dart`), used app-wide.
- **Motion:** calm by default, joyful at milestones. Always respect reduced-motion.

### Working rules
- Reuse the design tokens (`app_colors`, `app_typography`, `app_spacing`, `app_motion`) and the
  shared widgets in `lib/shared/widgets/`. No inline magic numbers — use `AppSpacing`.
- Avoid the AI-default looks: cream+serif+terracotta, near-black+acid-accent, broadsheet hairline.
- When unsure, bias toward fewer, calmer, more confident choices over busy ones.

## Architecture is offline-first

**The local Drift database is the source of truth. The backend is a second-class citizen.**

- **Write local-first, always.** Repositories write to Drift first, then mark the row dirty; the
  UI reads Drift reactively (`watch`). Never put the network in the read/write path. Do NOT write
  "try the API first, fall back to local" code — that is the opposite of this philosophy.
- **The app must work fully offline**, including staying logged in. After one online login the
  `User` is cached in Drift; offline app launches use the cached user (don't force re-login when
  `/auth/me` is unreachable).
- **Cloud sync is a PREMIUM feature and is gated** behind `SyncConfig.enabled` (default off). When
  off, the app is purely local and never hits the network. Build the engine, but never assume it's
  on. Billing/entitlement comes later.
- **Sync protocol:** use the backend's batch endpoints `POST /api/v1/sync/push` and
  `POST /api/v1/sync/pull` (not per-entity REST). Push dirty rows incl. tombstones; pull deltas
  with a `since` cursor.
- **Conflict resolution = last-write-wins, LOCAL wins ties.** The server only wins when its
  `updated_at` is *strictly* newer than the local `updated_at`; otherwise local wins.
- **Offline model:** new rows get client-generated **UUIDs**; deletes are **soft**
  (`isDeleted`/`deletedAt` tombstones) so they sync; every synced row carries `updatedAt`,
  `isDirty`, `isDeleted`, `deletedAt`, `lastSyncedAt`.

## Entity parity (hard rule)

Every synced entity must match field-for-field across the Flutter Drift table + model and the
backend entity/DTO (snake_case on the wire). When you add/rename/remove a field on one side, do
the **same on the other side in the same change**, and add the corresponding Drift migration
(bump `schemaVersion`) and EF Core migration. Mismatches silently break sync.

> UI was first built on dummy data in `lib/core/sample/`; entities are being migrated to Drift
> one vertical slice at a time (Tasks first). Sample data remains only for not-yet-migrated tabs.
