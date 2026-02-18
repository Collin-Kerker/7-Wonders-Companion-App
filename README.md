# 7 Wonders Score Tracker

A Flutter mobile application for tracking scores in the board game **7 Wonders**. Built with Firebase for authentication, cloud storage, and real-time data syncing.

## Overview

This app allows users to log games of 7 Wonders, manage players, and track detailed scoring breakdowns across all seven scoring categories. Each user's data is synced to the cloud via Firebase Firestore, so games and players persist across sessions and devices.

## Features

- **User Authentication** — Sign up, log in, and email verification powered by Firebase Auth
- **Player Management** — Add, view, and delete players; view individual player stats and game history
- **Game Logging** — Create and edit games with per-player score breakdowns
- **7 Wonders Scoring** — Track all scoring categories: Military, Treasury, Wonders, Civilian, Commerce, Guilds, and Science (with compass/gear/tablet breakdown)
- **Wonder Selection** — Assign a wonder (Alexandria, Gizah, Babylon, etc.) to each player per game
- **Real-Time Sync** — Firestore streams keep game and player lists up to date in real time
- **Profile Management** — Edit profile info and upload a profile picture (stored in Firebase Cloud Storage)
- **Light & Dark Themes** — Full theme support with custom color schemes

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Cloud Storage |
| Routing | GoRouter |
| UI | Material Design 3 |

## Project Structure

```
lib/
├── main.dart                          # App entry point, provider setup, router config
├── firebase_options.dart              # Firebase project configuration
│
├── models/
│   ├── game.dart                      # Game model with player scores and Firestore serialization
│   ├── player.dart                    # Player model
│   ├── player_score.dart              # PlayerScore, Scores, and WonderType models
│   └── user_profile.dart              # UserProfile model with permission levels
│
├── providers/
│   ├── provider_auth.dart             # Authentication state management
│   ├── provider_user_profile.dart     # User profile state and cloud sync
│   ├── provider_games.dart            # Games list (Riverpod Notifier + Firestore stream)
│   └── provider_players.dart          # Players list (Riverpod Notifier + Firestore stream)
│
├── firestore_repositories/
│   ├── game_repository.dart           # Firestore CRUD for games
│   ├── player_repository.dart         # Firestore CRUD for players
│   └── db_user_profile.dart           # Firestore/Cloud Storage operations for user profiles
│
├── screens/
│   ├── auth/
│   │   ├── screen_auth.dart           # Login / signup screen
│   │   ├── screen_login_validation.dart  # Auth state router (splash → login → home)
│   │   ├── screen_splash.dart         # Splash screen shown on app launch
│   │   ├── screen_unverified_email.dart  # Email verification prompt
│   │   └── screen_profile_setup.dart  # Onboarding profile setup
│   ├── general/
│   │   ├── screen_home.dart           # Games list (home tab)
│   │   ├── screen_alternate.dart      # Players list (players tab)
│   │   ├── alter_game.dart            # Create / edit a game
│   │   ├── view_game.dart             # View game details and scores
│   │   └── player_information_screen.dart  # Individual player stats
│   └── settings/
│       ├── screen_settings.dart       # App settings
│       └── screen_profile_edit.dart   # Edit user profile
│
├── widgets/
│   ├── general/
│   │   ├── widget_annotated_loading.dart      # Loading animation with timeout
│   │   ├── widget_edit_player_score.dart       # Score entry widget per player
│   │   ├── widget_password_strength_indicator.dart  # Password strength meter
│   │   ├── widget_profile_avatar.dart          # Profile image / initials avatar
│   │   └── widget_scrollable_background.dart   # Scrollable container widget
│   └── navigation/
│       ├── widget_primary_scaffold.dart        # Main scaffold with bottom nav
│       ├── widget_primary_app_bar.dart         # Reusable app bar
│       └── widget_app_drawer.dart              # Navigation drawer
│
├── theme/
│   ├── theme.dart                     # Light and dark theme definitions
│   └── colors.dart                    # Custom color palette
│
├── util/
│   ├── logging/
│   │   └── app_logger.dart            # Logger wrapper
│   ├── message_display/
│   │   ├── snackbar.dart              # Snackbar utility
│   │   └── popup_dialogue.dart        # Alert dialog utility
│   ├── file/
│   │   └── util_file.dart             # File utility helpers
│   ├── time/
│   │   └── util_time.dart             # Date/time utility helpers
│   └── secure_storage/
│       ├── secure_storage.dart        # Secure storage wrapper
│       └── secure_storage_keys.dart   # Storage key constants
│
└── db_helpers/
    └── firestore_keys.dart            # Firestore collection name constants
```

## Scoring Model

Each player's score in a game is broken down into seven categories:

| Category | Card Color | Description |
|----------|-----------|-------------|
| Military | Red | War victory/defeat points |
| Treasury | — | Coins (every 3 coins = 1 point) |
| Wonders | — | Points from wonder stages |
| Civilian | Blue | Civic structure points |
| Commerce | Yellow | Commercial structure points |
| Guilds | Purple | Guild card points |
| Science | Green | Science set collection (compass, gear, tablet) |

## Getting Started

### Prerequisites

- Flutter SDK (≥ 3.22.0)
- Dart SDK (≥ 3.9.2)
- Firebase project with Auth, Firestore, and Storage enabled
- Android Studio or VS Code with Flutter extensions

### Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase using FlutterFire CLI or replace `firebase_options.dart` with your own project credentials
4. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

Key packages used in this project:

- `flutter_riverpod` — State management
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` — Firebase suite
- `go_router` — Declarative routing
- `font_awesome_flutter` — Icons
- `image_picker` — Profile photo selection
- `flutter_secure_storage` — Secure local storage
- `lottie` — Loading animations
- `intl` — Date formatting
- `carousel_slider` — Image carousels
- `graphic` — Data visualization
- `flutter_gemini` — Gemini AI integration
