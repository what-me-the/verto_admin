# Verto Admin

An admin panel for the **Verto** translation platform, built with Flutter. It provides administrators with tools to manage users, moderate content, view analytics, and monitor platform activity.

## Features

- **Authentication** — Secure admin login with "Remember Me" support via `shared_preferences`
- **Dashboard** — Overview of key platform metrics
- **User Management** — View, search, and manage platform users
- **Content Moderation** — Review and moderate user-submitted content
- **Analytics** — Charts and visualizations powered by `fl_chart`, with map-based data using `flutter_map`
- **Excel Export** — Export data reports using the `excel` package

## Tech Stack

| Concern | Package |
|---|---|
| Backend / Auth | `supabase_flutter` |
| State Management | `provider` |
| Routing | `go_router` |
| Typography | `google_fonts` |
| Charts | `fl_chart` |
| Maps | `flutter_map` + `latlong2` |
| Localisation / Dates | `intl` |
| Local Storage | `shared_preferences` |
| Form Validation | `email_validator` |
| Data Export | `excel` |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.10
- A [Supabase](https://supabase.com) project with the required tables and RLS policies

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd verto_admin

# Install dependencies
flutter pub get
```

### Configuration

The Supabase URL and anon key are set in `lib/core/services/supabase_service.dart`. Update the constants there to point to your own Supabase project before running:

```dart
static const String _supabaseUrl  = 'YOUR_SUPABASE_URL';
static const String _supabaseKey  = 'YOUR_SUPABASE_ANON_KEY';
```

### Running

```bash
# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Android / iOS (with a connected device or emulator)
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── router/      # go_router configuration
│   ├── services/    # Supabase service singleton
│   ├── theme/       # App theme
│   └── widgets/     # Shared widgets
└── features/
    ├── auth/        # Login screen & AuthViewModel
    ├── dashboard/   # Dashboard overview
    ├── analytics/   # Charts and map analytics
    ├── users/       # User management
    ├── moderation/  # Content moderation
    └── splash/      # Splash / loading screen
```

## Supported Platforms

- Web
- Windows
- Android
- iOS
- macOS
- Linux
                