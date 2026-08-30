# Reunite — Flutter mobile

Privacy-first lost-and-found recovery app (Material 3). Covers the Flutter screen inventory in `DOCUMENTATION.md` (F00–F75).

## Requirements

- Flutter **3.22.x** / Dart **3.4.x**
- Packages are pinned for Dart 3.4 (Riverpod **2.5**, not Riverpod 3)

## Run

```bash
cd mobile
flutter pub get
flutter run
```

Default data source is the **in-app mock repository** (`kUseMockApi = true` in `lib/core/constants/app_constants.dart`). The app is usable without Laravel.

### Demo accounts

| Role | Email | Password |
|---|---|---|
| Owner | `owner@reunite.test` | `password` |
| Hub staff | `staff@reunite.test` | `password` |
| Unverified | `new@reunite.test` | `password` |

Guests can browse teasers from Welcome → **Browse as guest**.

### Live API

1. Set `kUseMockApi` to `false` in `lib/core/constants/app_constants.dart`.
2. Start Laravel so `/api/v1` is reachable.
3. Base URL:
   - iOS / desktop / web: `http://127.0.0.1:8000/api/v1`
   - Android emulator: `http://10.0.2.2:8000/api/v1`

Auth uses Sanctum bearer tokens via Dio interceptors (`lib/core/network/api_client.dart`).

## Architecture

```
lib/
  main.dart
  app.dart
  core/theme, router, network, storage, constants, widgets, i18n
  models/
  data/mock, repositories, providers.dart
  features/
    onboarding/ auth/ home/ search/ reports/
    claims/ activity/ profile/ hub/ tags/ cms/ system/
```

Swap mock → live by flipping one flag. Both implement `AppRepository`.

## Navigation

Bottom nav: **Home · Search · (FAB Report) · Activity · Profile**

Deep-link stubs: `/teaser/:id`, `/verify`

Push notifications are stubbed in v1 (prefs persist; no Firebase).

## Analyze

```bash
dart analyze
```
