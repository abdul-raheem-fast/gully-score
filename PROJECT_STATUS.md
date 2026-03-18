# Gully Score — Project Documentation (Current Status)

**Tech stack:** Flutter + Dart  \n
**Platforms:** Android, iOS, Web, Windows (Flutter template folders present)  \n
**Repo:** `abdul-raheem-fast/gully-score`

---

## 1) What’s implemented so far

### A) Authentication + role flow (Prototype)
- **Splash** → **Onboarding** → **Role Selection** → **Login / Signup**
- **Roles supported**: Player, Admin
- **Demo credentials (hardcoded)** (see `lib/state/app_store.dart`):
  - **Player**: `player@gmail.com` / `Player@123`
  - **Admin**: `admin@gmail.com` / `Admin@123`
- **Data persistence**: not implemented (in-memory state only)

### B) Player app (Prototype)
Player navigation is a bottom-tab layout (Home/Matches/Stats/Profile).
- **Player Home**: dashboard-style UI + cards + quick actions (prototype)
- **Player Matches**: matches list UI (prototype)
- **Player Stats**: stats / leaderboard-like UI (prototype)
- **Player Profile**: profile UI (prototype)

### C) Admin panel (Prototype)
Admin navigation starts from `/admin` with sidebar + responsive layout.
- **Admin Dashboard**: overview tiles + navigation
- **Admin Users**: user list (dummy data)
- **Admin Matches**: tabbed (All/Live/Upcoming/Completed) using in-memory demo matches
- **Admin Teams**: searchable list using in-memory demo teams
- **Admin Reports**: reports list + filters (dummy data)
- **Admin Settings**: platform toggles (maintenance, auto-approve, notifications) (prototype)

---

## 2) Routes (current)

Central route definitions:
- `lib/route_paths.dart`
- `lib/routes.dart`

Core routes:
- `/` splash
- `/onboarding`
- `/role-select`
- `/login`
- `/signup`
- `/home` (Player home shell)

Admin routes:
- `/admin`
- `/admin/users`
- `/admin/matches`
- `/admin/teams`
- `/admin/reports`
- `/admin/settings`

---

## 3) Project structure (key folders)

```
gully_score/
├─ lib/
│  ├─ main.dart                 # Main app entry
│  ├─ main_admin.dart           # Admin-only entry (optional)
│  ├─ route_paths.dart          # Route name constants
│  ├─ routes.dart               # Route builder map + transitions
│  ├─ state/app_store.dart      # In-memory state + demo users + demo admin data
│  ├─ theme/app_theme.dart      # Design tokens / Theme
│  ├─ models/                   # Admin + player models
│  ├─ screens/
│  │  ├─ auth_screens.dart
│  │  ├─ splash_screen.dart
│  │  ├─ onboarding_screen.dart
│  │  ├─ admin/                 # Admin pages
│  │  └─ player/                # Player pages
│  └─ widgets/widgets.dart      # Shared UI widgets
└─ pubspec.yaml
```

---

## 4) How to run

### A) Android (emulator/phone)
From the folder that contains `pubspec.yaml`:

```bash
cd "C:\Users\Abdul Raheem\Desktop\Gully Score (SE Project)\gully_score"
flutter pub get
flutter run
```

### B) Web (Chrome)

```bash
flutter run -d chrome
```

### C) Admin-only entry (optional)

```bash
flutter run -t lib/main_admin.dart
```

---

## 5) What is *not* implemented yet (next steps)

- **Backend / database** (Firebase/REST): not integrated
- **Real-time live scoring engine**: UI only / placeholder
- **CRUD operations** (Admin): forms + actual data persistence
- **Role-based access protection**: basic route availability only
- **Testing**: only default widget test exists
- **Deployment**: no release builds configured

---

## 6) Notes for Sprint evaluation

- This is a **working prototype** focused on UI flows and navigation.
- Data is **dummy/in-memory** and suitable for Sprint-1 demonstration.

