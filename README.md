# Gully Score - Flutter App

Cricket scoring & performance analytics mobile app built with Flutter.

## Setup Instructions

### 1. Install Flutter SDK
Download from: https://docs.flutter.dev/get-started/install/windows/mobile

After installation, add Flutter to your PATH and run:
```
flutter doctor
```

### 2. Install Dependencies
```
cd gully_score
flutter pub get
```

### 3. Run the App
```
flutter run
```

For Chrome (web):
```
flutter run -d chrome
```

For Android emulator (make sure emulator is running):
```
flutter run -d emulator
```

## Project Structure
```
gully_score/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── config/
│   │   ├── theme.dart               # Colors, typography, theme
│   │   └── routes.dart              # Named routes & transitions
│   ├── screens/
│   │   ├── splash_screen.dart       # Animated splash
│   │   ├── onboarding_screen.dart   # Welcome screen
│   │   ├── login_screen.dart        # Email + password login
│   │   ├── signup_screen.dart       # Registration with role
│   │   ├── forgot_password_screen.dart
│   │   ├── home_screen.dart         # Dashboard with live match
│   │   ├── matches_list_screen.dart # All matches with filters
│   │   ├── match_setup_screen.dart  # New match configuration
│   │   ├── live_scoring_screen.dart # Ball-by-ball scoring
│   │   ├── scorecard_screen.dart    # Match summary
│   │   ├── match_feedback_screen.dart
│   │   ├── leaderboard_screen.dart  # Rankings
│   │   ├── player_analytics_screen.dart
│   │   └── profile_screen.dart      # User profile
│   ├── widgets/
│   │   ├── main_navigation.dart     # Bottom navigation bar
│   │   ├── gradient_button.dart     # Reusable gradient button
│   │   └── match_card.dart          # Match card component
│   └── models/                      # Data models (to add)
├── assets/images/                   # Image assets
├── pubspec.yaml                     # Dependencies
└── analysis_options.yaml            # Lint rules
```

## Screens (16 total)
1. Splash Screen
2. Onboarding
3. Login
4. Sign Up
5. Forgot Password
6. Home Dashboard
7. Matches List
8. Match Setup
9. Live Scoring
10. Scorecard
11. Match Feedback
12. Leaderboard
13. Player Analytics
14. Profile & Settings

## Design System
- Primary: #1B5E20 (Cricket Green)
- Accent: #FF6F00 (Orange)
- Font: Poppins (via Google Fonts)
- Border Radius: 14-20px
- Consistent spacing: 12-24px
