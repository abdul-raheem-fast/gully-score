# Gully Score

Flutter cricket scoring & analytics app with **Player** and **Admin** prototype flows.

## Features (current)

- **Auth + role selection** (Player/Admin)
- **Player app**: Home, Matches, Stats, Profile (prototype UI)
- **Admin panel**: Dashboard, Users, Matches, Teams, Reports, Settings (prototype UI)
- In-memory demo data (no backend yet)

## Demo credentials

From `lib/state/app_store.dart`:

- **Player**: `player@gmail.com` / `Player@123`
- **Admin**: `admin@gmail.com` / `Admin@123`

## Run

From the folder that contains `pubspec.yaml`:

```bash
flutter pub get
flutter run
```

Web:

```bash
flutter run -d chrome
```

Admin-only entry:

```bash
flutter run -t lib/main_admin.dart
```

## Documentation

See `PROJECT_STATUS.md` for a full “what’s built so far” snapshot.
