# Pitakap — Your Wallet, Tracked

A personal money tracker that puts your complete spending picture in one app: log daily expenses in seconds, keep every subscription and bill in one place, and get reminded before renewals hit your account.

> *Pitaka* is Tagalog for wallet. Pitakap = Pitaka + App.

## Features

- 🔐 Authentication — Email/Password + Google Sign-In (Firebase Auth)
- 💳 Subscription tracking — full CRUD with billing cycles and due-date math
- 🧾 Daily expense logging — two-tap entry, per-day view with date strip
- 📊 Dashboard & stats — spent today, monthly commitments, category donut chart
- 🔔 Due-date reminders — scheduled local notifications, 100% serverless
- 🌙 Dark mode — light/dark/system, persisted
- 📡 Offline-first — Firestore offline persistence, syncs when back online

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter · Dart |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| State management | Riverpod (AsyncNotifier + sealed states) |
| Architecture | Clean Architecture (`core/` + `feature/<name>/data · domain · presentation`) |
| Notifications | flutter_local_notifications + timezone |
| Charts | fl_chart |
| Navigation | go_router |

## Architecture

```
pitakapflutter/
└── lib/
    ├── core/          shared infrastructure (error, usecase, resources, router, theme, providers)
    └── feature/       vertical slices, each split into data / domain / presentation
```

Presentation → domain ← data. External services (Firestore, notifications) are only ever touched inside datasources. Errors surface as sealed `Failure` types, caught by `AsyncValue.guard` in controllers, rendered from sealed state classes.

## Testing

**622 tests, 89.2% line coverage** — no Firebase emulator and no device required; the whole suite runs on `flutter test`.

```
cd pitakapflutter
flutter test
flutter test --coverage    # writes coverage/lcov.info
```

| Layer | Line coverage | Lines |
|---|---|---|
| `presentation/` | **96.7%** | 1736 / 1795 |
| `core/` | **94.5%** | 580 / 614 |
| `domain/` | **92.7%** | 291 / 314 |
| `data/` | **52.9%** | 238 / 450 |
| **Overall** | **89.2%** | 2853 / 3200 |

66 of 104 files are at 100%.

**Why `data/` is the outlier, deliberately.** The uncovered lines are almost entirely the Firestore and platform-channel datasources — `auth_remote_datasource.dart`, `subscription_remote_datasource.dart`, `expense_remote_datasource.dart` — plus generated `firebase_options.dart`. Exercising those needs a live Firebase SDK, so instead the *contract* around them is tested: every repository is verified against a mocked datasource, and every error path is asserted to surface as a sealed `Failure` with no platform detail leaking into a user-facing message.

That split is the point of the architecture. Domain logic — due-date math across four billing cycles, reminder scheduling and id hashing, category breakdowns, spending summaries — is pure and clock-injected, so it is tested without touching Firebase at all.

## Decisions & Tradeoffs

_To be filled in as the project progresses._

## Getting Started

The Flutter app lives in [`pitakapflutter/`](pitakapflutter).

```
cd pitakapflutter
flutter pub get
flutter run
```

Requires a configured Firebase project (`flutterfire configure`).
