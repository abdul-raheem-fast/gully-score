# Gully Score

Flutter cricket scoring, analytics, and AI assistant app with **Player** and
**Admin** experiences.

## Features (current)

- **Auth + role selection** (Player/Admin)
- **Player app**: Home, Matches, Stats, Profile, **Broskie AI chat**
- **Admin panel**: Dashboard, Users, Matches, Teams, Players, Inbox, Reports,
  Settings, **Broskie AI**
- **Supabase-backed data** (matches, teams, rosters, memberships, reports)
- **Groq-powered chatbot** via Supabase Edge Function (`gully-ai-chat`)

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

## Edge functions (Supabase)

The app uses two edge functions:

- `gully-ai-chat` for Broskie AI
- `admin-manage` for admin actions (role change, block/unblock, delete team)

Deploy both functions:

```bash
supabase functions deploy gully-ai-chat
supabase functions deploy admin-manage
```

Web note: `admin-manage` includes CORS handling so Flutter web can call it.

## Broskie AI setup (Groq + Supabase)

The app calls Supabase Edge Function `gully-ai-chat`, which then calls Groq.

1. Set edge secrets (do not hardcode API keys in Flutter code):

```bash
supabase secrets set GROQ_API_KEY=your_groq_api_key
supabase secrets set GROQ_MODEL=llama-3.3-70b-versatile
```

2. Deploy the function:

```bash
supabase functions deploy gully-ai-chat
```

3. Ensure the client is logged in (function uses auth context and Supabase RLS).

Security note: if an API key was ever shared publicly, rotate it immediately and
replace the secret in Supabase.
