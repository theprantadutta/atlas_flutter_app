# Atlas - Gamified Self-Improvement App

A gamified self-improvement mobile app built with Flutter. Track tasks, habits, and goals while earning XP, leveling up your avatar, unlocking achievements, and exploring a virtual world map.

## Screenshots

| Login | Home | Tasks |
|-------|------|-------|
| ![Login](screenshots/login.png) | ![Home](screenshots/home.png) | ![Tasks](screenshots/tasks.png) |

| Habits | Goals | World Map |
|--------|-------|-----------|
| ![Habits](screenshots/habits.png) | ![Goals](screenshots/goals.png) | ![World](screenshots/world.png) |

| Avatar | Achievements | Analytics |
|--------|-------------|-----------|
| ![Avatar](screenshots/avatar.png) | ![Achievements](screenshots/achievements.png) | ![Analytics](screenshots/analytics.png) |

| Profile | Dark Mode |
|---------|-----------|
| ![Profile](screenshots/profile.png) | ![Dark Mode](screenshots/dark_mode.png) |

## Features

- **Tasks** — Daily, weekly, and long-term tasks with category filtering, difficulty levels, and XP rewards
- **Habits** — Track daily habits with streak counting, completion rates, and frequency-based grouping
- **Goals** — Set goals with priority levels, deadlines, progress tracking, and sub-goals
- **Avatar** — Customize your avatar's appearance, level up, and boost Strength/Wisdom/Intelligence attributes
- **Achievements** — Unlock achievements across tiers (Bronze, Silver, Gold, Platinum, Diamond)
- **World Map** — Explore an 8x8 tile grid, unlock new regions with XP
- **Analytics** — XP trends, task completion charts, category breakdowns with fl_chart
- **Progress** — Daily progress tracking with heatmap-style visualization
- **Offline Support** — Full offline-first architecture with automatic sync when back online
- **Real-time Sync** — SignalR WebSocket for instant notifications (XP gained, level up, achievements)
- **Dark Mode** — Full Material 3 light and dark theme support

## Tech Stack

- **Flutter** 3.x with Dart
- **Riverpod** — State management (Notifier pattern)
- **GoRouter** — Navigation with auth guards and StatefulShellRoute
- **Dio** — HTTP client with automatic token refresh
- **Drift** — Local SQLite database (9 tables, 8 DAOs)
- **Firebase Auth** — Email/password and Google Sign-In
- **fl_chart** — Line, bar, and pie charts for analytics
- **SignalR** — Real-time sync notifications
- **flutter_animate** — Smooth UI animations
- **Google Fonts** — Poppins (headings) + Inter (body)

## Project Structure

```
lib/
├── core/                  # Config, constants, errors, utils
├── data/
│   ├── database/          # Drift tables, DAOs, database class
│   ├── models/            # JSON-serializable data models
│   ├── repositories/      # Offline-first API + local DB repositories
│   └── services/          # API, auth, token, SignalR, offline manager
├── features/
│   ├── auth/              # Login, signup screens + providers
│   ├── home/              # Dashboard screen + provider
│   ├── tasks/             # Tasks CRUD + completion flow
│   ├── habits/            # Habits tracking + completion
│   ├── goals/             # Goals with progress tracking
│   ├── avatar/            # Avatar customization
│   ├── achievements/      # Achievement gallery
│   ├── world/             # World map grid
│   ├── analytics/         # Charts dashboard
│   ├── progress/          # Progress history
│   └── profile/           # Profile, settings, sync management
├── router/                # GoRouter configuration
└── shared/
    ├── providers/         # Core, theme, connectivity providers
    ├── services/          # Overlay service
    ├── themes/            # Colors, typography, Material 3 themes
    └── widgets/           # Reusable UI components
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.11.3
- Firebase project configured (`flutterfire configure`)
- Atlas .NET backend running

### Setup

1. Clone the repository
2. Copy `.env` and fill in your values:
   ```
   API_BASE_URL_DEV=http://10.0.2.2:8020
   API_BASE_URL_PROD=https://your-domain.com
   GOOGLE_WEB_CLIENT_ID=your-google-client-id
   ```
3. Ensure Firebase is configured:
   - `google-services.json` in `android/app/`
   - `GoogleService-Info.plist` in `ios/Runner/`
   - `firebase_options.dart` generated via `flutterfire configure`
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
6. Run the app:
   ```bash
   flutter run
   ```

## Architecture

- **Offline-first** — All reads go through LRU cache then API (online) or local DB (offline)
- **Sync queue** — Write operations queue as sync operations when offline, with deduplication and exponential backoff retries
- **Bidirectional sync** — Push local changes, pull remote changes with last-write-wins conflict resolution
- **Periodic sync** — Automatic sync every 5 minutes when online
- **App lifecycle** — Sync on resume, disconnect SignalR on pause
