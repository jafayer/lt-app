# Language Transfer – Flutter

A Flutter translation of the [Language Transfer](https://www.languagetransfer.org/) React Native app.
Supports **Android**, **iOS**, and **Web** (including responsive desktop web layouts) from a single
codebase.

---

## Architecture

### State management – Riverpod

All app state is managed with [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod):

| Provider | What it manages |
|---|---|
| `settingsProvider` | Stream/download quality, Wi-Fi-only, auto-delete, metrics opt-in |
| `courseIndexProvider` | Remote course index (fetched + 7-day local cache) |
| `courseMetadataProvider` | Per-course lesson list (fetched on demand) |
| `lessonProgressProvider` | Position + finished flag for each lesson |
| `mostRecentCourseProvider` / `mostRecentLessonProvider` | Resume-last-played |
| `playerStateProvider` | Audio playback (position, playing, loading, current lesson) |
| `downloadSnapshotsProvider` | Download state for every lesson |

### Cross-platform storage – SharedPreferences

[`shared_preferences`](https://pub.dev/packages/shared_preferences) is used for **all** durable
state. It maps to:

| Platform | Backing store |
|---|---|
| Android | `SharedPreferences` (XML) |
| iOS | `NSUserDefaults` |
| **Web** | **`localStorage`** |

The key schema mirrors the original React Native app:

```
@activity/{course}/{lesson}           → LessonProgress JSON
@activity/most-recent-course         → course name string
@activity/{course}/most-recent-lesson → lesson index
@preferences/{name}                  → JSON-serialised value
@course-index/all                    → cached course index + timestamp
@download-intent/{course}/{lesson}   → bool
```

### Audio – just_audio + audio_service

- [`just_audio`](https://pub.dev/packages/just_audio) handles actual playback on all platforms
  (including Web via the HTML5 Audio API).
- [`audio_service`](https://pub.dev/packages/audio_service) wraps the player on Android/iOS to
  provide lock-screen controls and background playback (no-op on web).
- The custom `LtAudioHandler` extends `BaseAudioHandler` and implements play/pause/seek/rewind.

### Navigation – GoRouter

[`go_router`](https://pub.dev/packages/go_router) provides declarative URL-based routing. Deep
links work naturally on all platforms, including web.

Route structure:
```
/                                 Home (course selector)
/course/:courseName               Course home screen
/course/:courseName/lessons       All lessons list
/course/:courseName/listen/:idx   Audio player
/course/:courseName/data          Download management
/settings                         App settings
```

### Downloads

On **mobile** (Android/iOS), audio files are downloaded to the app's documents directory using
content-addressed storage (the same object-hash scheme as the React Native app):
```
{DocumentsDir}/objects/{objectHash}   ← final file
{DocumentsDir}/staging/{hash}.download ← in-progress (atomic rename on complete)
```

On **web**, downloads are not persisted to disk (browser sandbox). Lessons always stream from the
network. Download buttons on web immediately mark a lesson as "available" for streaming.

---

## Responsive Design

The app uses a single breakpoint system (`AppTheme`):

| Screen width | Layout |
|---|---|
| < 600 px | Mobile – full-screen stacked navigation, standard app bar |
| 600–1199 px | Tablet – wider content, navigation rail on left |
| ≥ 1200 px | Desktop – extended navigation rail with labels, constrained content width |

The `AppShell` widget switches between a bare scaffold (mobile) and a persistent navigation rail
(tablet/desktop) based on the current screen width.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.4.0 ([install](https://docs.flutter.dev/get-started/install))
- Android Studio / Xcode (for native builds)
- A web browser (for web builds)

### Run

```bash
# Enter the Flutter project directory
cd flutter/

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on Android emulator / device
flutter run -d android

# Run on iOS simulator / device
flutter run -d ios
```

### Build

```bash
# Android APK
flutter build apk

# Android App Bundle (Play Store)
flutter build appbundle

# iOS IPA (requires Mac + Xcode)
flutter build ios

# Web (outputs to build/web/)
flutter build web
```

### Lint & analyse

```bash
flutter analyze
```

---

## Project Layout

```
flutter/
├── lib/
│   ├── main.dart                 # Entry point – init services, run app
│   ├── app.dart                  # MaterialApp.router with dark theme
│   ├── core/
│   │   ├── constants/
│   │   │   ├── course_data.dart  # Static CourseInfo list + colour palettes
│   │   │   └── theme.dart        # AppTheme (colours, spacing, breakpoints)
│   │   ├── models/
│   │   │   ├── course.dart       # CourseName, CourseInfo, LessonData, CourseIndex…
│   │   │   ├── progress.dart     # LessonProgress
│   │   │   └── download.dart     # DownloadSnapshot, DownloadState
│   │   ├── providers/
│   │   │   ├── settings_provider.dart
│   │   │   ├── course_provider.dart
│   │   │   ├── progress_provider.dart
│   │   │   ├── audio_player_provider.dart
│   │   │   └── download_provider.dart
│   │   ├── services/
│   │   │   ├── storage_service.dart   # SharedPreferences wrapper
│   │   │   ├── course_api_service.dart # Remote course index + metadata
│   │   │   ├── audio_handler.dart     # just_audio + audio_service handler
│   │   │   └── download_manager.dart  # File downloads (mobile) / streaming (web)
│   │   └── router/
│   │       └── app_router.dart        # GoRouter configuration
│   ├── screens/
│   │   ├── home/home_screen.dart
│   │   ├── course/
│   │   │   ├── course_home_screen.dart
│   │   │   └── all_lessons_screen.dart
│   │   ├── player/player_screen.dart
│   │   ├── downloads/data_screen.dart
│   │   └── settings/settings_screen.dart
│   └── widgets/
│       ├── app_shell.dart        # Responsive shell (mobile / desktop)
│       ├── course_card.dart
│       ├── lesson_grid.dart
│       ├── loading_indicator.dart
│       └── error_view.dart
├── android/                      # Android platform files
├── ios/                          # iOS platform files
├── web/                          # Web platform files (index.html, manifest.json)
└── pubspec.yaml                  # Dependencies
```
