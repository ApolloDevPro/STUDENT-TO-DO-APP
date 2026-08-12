# Student To-Do App

A cross-platform Flutter application that helps students organize their academic life. It lets users track assignments and personal tasks, organize them by subject, visualize their progress, and receive local notifications when tasks are due — all wrapped in a clean Material 3 interface that supports light, dark, and system themes.

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Tech Stack](#tech-stack)
5. [Project Structure](#project-structure)
6. [Data Models](#data-models)
7. [State Management](#state-management)
8. [Authentication Flow](#authentication-flow)
9. [Screens in Detail](#screens-in-detail)
10. [Notifications](#notifications)
11. [Theming](#theming)
12. [Persistence](#persistence)
13. [Getting Started](#getting-started)
14. [Firebase Setup](#firebase-setup)
15. [Running the App](#running-the-app)
16. [Building](#building)
17. [Notes & Known Limitations](#notes--known-limitations)
18. [Future Improvements](#future-improvements)

---

## Overview

The app is aimed at students who juggle multiple courses and assignments. Rather than keeping a single flat todo list, it groups tasks under **subjects** (e.g., *CS101 – Introduction to Programming*) and enriches each task with a **priority**, a **status**, an optional **due date**, and an **assignment** flag. A dashboard summarizes how the student is doing at a glance, while dedicated Tasks and Subjects screens handle day-to-day management.

The entry point (`lib/main.dart`) initializes Firebase and the notification service, then builds a `MultiProvider` tree. An `AuthGate` widget decides whether to show the authenticated `MainScreen` (with bottom navigation) or the `LoginScreen` based on the Firebase auth state.

---

## Features

### Authentication
- **Email & password** sign up, sign in, and password reset (email link via Firebase).
- **Google Sign-In** using OAuth credentials.
- **Session-aware routing**: `AuthGate` listens to `authStateChanges` and routes logged-in users to the dashboard and others to login.
- **Display name** editing and **sign out**.

### Dashboard
- Greeting card showing the number of pending tasks.
- Stat cards for **Total**, **Completed**, **Pending**, and **Overdue** tasks.
- **Overall progress** bar computed from completion percentage.
- **Recent tasks** preview (up to 3), color-coded by subject with due-date indicators.
- **Search** (magnifying glass) that opens an in-app task search delegate.
- Quick links to **Tasks** and **Subjects**.

### Tasks
- Create, edit, delete, and toggle completion from the UI.
- Fields: title, description, subject, priority (low/medium/high), **status (pending/in progress/completed)**, due date, and assignment flag.
- **Filters**: All, Pending, In Progress, Completed, Assignments, Due Today, Upcoming.
- **Subject filter chips** for narrowing tasks by course.
- **Sorting**: default, due date, priority, or newest-first.
- **Swipe-to-delete** (dismiss to the left) **with an undo action**.
- **Priority indicator** (colored dot) and overdue highlighting (red dates).
- **Full-text search** across title and description — tapping a result opens that task for editing directly.

### Subjects
- Create, edit, and delete subjects with a **name**, **course code**, and a **custom color**.
- Deleting a subject asks for confirmation first.
- Subject color is reused everywhere (dashboard, task cards, filters) for visual grouping.
- One-tap access to edit via tapping a subject row.

### Reminders
- Local notifications scheduled for each task's due date.
- A **reminders toggle** in Profile that re-schedules or cancels all notifications globally.
- A **reminder lead time** setting (at due time, 15 min, 1 hour, 3 hours, 1 day, or 1 week before).
- **Tapping a notification opens the task** in a detail screen where it can be edited or deleted.
- Past-due and completed tasks are automatically skipped.

### Cloud Sync
- Tasks and subjects sync to **Cloud Firestore** under `users/{uid}/tasks` and `users/{uid}/subjects`.
- The app is local-first: everything still works offline via `shared_preferences`, and a **last-write-wins merge** (using each item's `updatedAt`) reconciles the two sides on startup/login. Data survives app reinstall as long as you're signed in.

### Theming
- Light, dark, and system theme modes via `ThemeProvider`.
- Material 3 design with a blue `colorSchemeSeed`.
- Theme choice persists across app restarts.

---

## Architecture

The app follows a **provider-based state management** architecture with a clear separation between models, providers (business logic + persistence), services (side effects like notifications), and screens (UI).

```
                 ┌─────────────────────────────────────┐
                 │              main.dart              │
                 │   Firebase init + Notification init  │
                 │        MultiProvider tree           │
                 └─────────────────────────────────────┘
                                │
            ┌───────────────────┼───────────────────────────────┐
            ▼                   ▼                                ▼
     ┌─────────────┐     ┌──────────────┐              ┌──────────────────┐
     │ AuthProvider│     │ ThemeProvider│              │ TaskProvider     │
     │ (Firebase)  │     │ (shared_prefs)│             │ (shared_prefs +  │
     └─────────────┘     └──────────────┘             │  notifications)  │
            │                                          └──────────────────┘
            │ (userId)                                  │        │
            ▼                                           ▼        ▼
   ┌────────────────────┐                     SubjectProvider  NotificationService
   │ TaskProvider /      │                     (shared_prefs)
   │ SubjectProvider via │
   │ ChangeNotifierProxy │
   └────────────────────┘

        AuthGate → (logged in?) → MainScreen (NavigationBar)
                                       ├── DashboardScreen
                                       ├── TasksScreen
                                       └── SubjectsScreen
        AuthGate → (logged out) → LoginScreen / RegisterScreen
        ProfileScreen reachable from Dashboard / anywhere via AppBar
```

Because `TaskProvider` and `SubjectProvider` depend on the current user, they are provided through `ChangeNotifierProxyProvider<AuthProvider, ...>`. When the signed-in user changes, the proxy rebuilds those providers with the new `userId`, so each user's data is stored under a separate `shared_preferences` key.

---

## Tech Stack

| Area | Package | Purpose |
| --- | --- | --- |
| UI framework | Flutter / Material 3 | Cross-platform UI |
| State management | `provider` (^6.1.5) | Dependency injection & reactive UI |
| Authentication | `firebase_core`, `firebase_auth`, `google_sign_in` | Email/password + Google sign-in |
| Local storage | `shared_preferences` | Persist tasks, subjects, theme, reminders (offline cache) |
| Cloud sync | `cloud_firestore` | Mirror tasks/subjects to Firestore per user |
| Notifications | `flutter_local_notifications`, `timezone` | Scheduled due-date reminders |
| Formatting | `intl` | Date/number formatting helpers |
| Icons | `cupertino_icons` | iOS-style icons |

> **Note:** `cloud_firestore` is used for optional cloud sync (see [Persistence](#persistence)); local storage remains the primary source of truth.

---

## Project Structure

```
lib/
├── main.dart                         # Entry point, providers, AuthGate, notification tap routing
├── models/
│   ├── task.dart                     # Task model, enums, JSON (de)serialization, sorting
│   └── subject.dart                  # Subject model with color, JSON (de)serialization
├── providers/
│   ├── auth_provider.dart            # Firebase auth + Google sign-in logic
│   ├── task_provider.dart            # Task CRUD, stats, search, filters, reminders, sync
│   ├── subject_provider.dart         # Subject CRUD + sync
│   └── theme_provider.dart           # Theme mode state + persistence
├── services/
│   ├── notification_service.dart     # Singleton wrapping local notifications
│   ├── cloud_sync_service.dart       # Firestore mirror (push + fetch)
│   └── sync_merge.dart               # Last-write-wins merge logic (pure, unit-tested)
├── screens/
│   ├── login_screen.dart             # Email/password + Google login
│   ├── register_screen.dart          # Email/password sign up
│   ├── main_screen.dart              # Bottom navigation host (IndexedStack)
│   ├── dashboard_screen.dart         # Stats, progress, search delegate
│   ├── tasks_screen.dart             # Task list, filters, sorting, create/edit dialog
│   ├── subjects_screen.dart          # Subject list, create/edit dialog
│   ├── task_detail_screen.dart       # Opened from notifications; edit/delete a task
│   └── profile_screen.dart           # Account, reminders, lead time, theme, sign out
├── theme/
│   └── custom_theme.dart
├── utils/
│   └── ids.dart                      # Collision-free id generation
└── widgets/
    ├── task_dialog.dart              # Shared create/edit task dialog (used everywhere)
    ├── empty_state.dart
    ├── fade_in.dart
    ├── glass_card.dart
    ├── gradient_app_bar.dart
    └── responsive_scaffold.dart
```

---

## Data Models

### `Task` (`lib/models/task.dart`)
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Unique; random hex id (see `lib/utils/ids.dart`). |
| `title` | `String` | Required. |
| `description` | `String?` | Optional. |
| `subjectId` | `String?` | Links to a `Subject` (nullable). |
| `priority` | `TaskPriority` | Enum: `low`, `medium` (default), `high`. |
| `status` | `TaskStatus` | Enum: `pending`, `inProgress`, `completed`. |
| `createdAt` | `DateTime` | Required. |
| `dueDate` | `DateTime?` | Optional; drives notifications & overdue logic. |
| `isAssignment` | `bool` | Defaults to `false`. |
| `updatedAt` | `DateTime` | Last-change timestamp; used for cloud merge. Falls back to `createdAt` for old records. |

`TaskPriority` and `TaskStatus` are stored as their enum index in JSON for compactness. `toJson()` / `fromJson()` handle (de)serialization, including ISO-8601 date strings. `Task.sortBy(list, mode)` provides the sort modes used on the Tasks screen.

### `Subject` (`lib/models/subject.dart`)
| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Unique. |
| `name` | `String` | Subject display name. |
| `code` | `String` | Course code, e.g. `CS101`. |
| `colorValue` | `int` | ARGB color stored as an integer; `color` getter returns a `Color`. |
| `updatedAt` | `DateTime` | Last-change timestamp; used for cloud merge. |

---

## State Management

The app uses `provider` with `ChangeNotifier`. Key points:

- **`AuthProvider`** wraps `FirebaseAuth`. It exposes `currentUser`, `isLoggedIn`, `isEmailVerified`, and a `Stream<User?>` (`authStateChanges`) that the `AuthGate` consumes. All auth methods return a `String?` error message (null = success), keeping UI logic simple.
- **`TaskProvider`** and **`SubjectProvider`** are created via `ChangeNotifierProxyProvider`, so they automatically receive the signed-in user's `uid`. Each persists data under a key like `tasks_<uid>` (or `tasks_guest` when no user) and pushes/pulls from Firestore through `CloudSyncService`.
- **`CloudSyncService`** is a singleton that mirrors local changes to Firestore and fetches the remote list. The merge is computed by `sync_merge.dart` (last-write-wins by `updatedAt`).
- **`ThemeProvider`** holds a `ThemeMode` and persists it as an integer.
- Screens mostly use `Consumer` / `Consumer2` widgets so only the relevant subtree rebuilds when state changes.

---

## Authentication Flow

1. App launches → `Firebase.initializeApp()` runs, then `NotificationService.instance.init()`.
2. `AuthGate` subscribes to `authProvider.authStateChanges`:
   - While waiting → shows a `CircularProgressIndicator`.
   - Has user → `MainScreen` (Dashboard/Tasks/Subjects).
   - No user → `LoginScreen`.
3. Users can sign in with email/password or Google. After success, the auth state stream fires and `AuthGate` swaps to the authenticated UI.
4. New users sign up, optionally set a display name, and are dropped into the dashboard.
5. Profile screen allows editing the display name, toggling reminders/theme, and signing out.

### Google Sign-In client ID

`lib/providers/auth_provider.dart` contains a placeholder that **must be replaced** before Google sign-in works:

```dart
static const String _googleWebClientId = 'REPLACE_WITH_WEB_CLIENT_ID';
```

This should be the **Web** client ID from Firebase Console → Authentication → Sign-in method → Google (it corresponds to `client_type 3` in `google-services.json`). This is required by the Credential Manager–based Google Sign-In v7 flow on Android.

---

## Screens in Detail

### `LoginScreen` / `RegisterScreen`
- Login supports email/password and a Google button. Includes a "Forgot password?" flow that calls `resetPassword(email)` and surfaces a success/error message.
- Register collects name, email, and password, then calls `signUp()` and updates the display name.
- A success message set on the provider is shown as a `SnackBar` on the dashboard after navigation.

### `MainScreen`
- Hosts three screens in an `IndexedStack` with a `NavigationBar`: **Dashboard**, **Tasks**, **Subjects**. `IndexedStack` keeps screen state alive while switching tabs.

### `DashboardScreen`
- Presents the welcome card, four stat cards, and a linear progress indicator (`completionPercentage`).
- "Quick Actions" navigate to Tasks and Subjects.
- Shows up to 3 recent tasks, each with a subject-colored avatar and due-date text (red if overdue).
- AppBar search launches `TaskSearchDelegate`, an in-app `SearchDelegate` that filters tasks by title/description via `taskProvider.searchTasks(query)`. Tapping a result opens that task for editing.

### `TasksScreen`
- Top filter menu (`PopupMenuButton`) with All / Pending / In Progress / Completed / Assignments / Due Today / Upcoming, plus a sort menu (default, due date, priority, newest).
- Horizontal `FilterChip` row for filtering by subject (only shown if subjects exist).
- Each task is a `Card` wrapped in a `Dismissible` (swipe left to delete, **undoable**). A `Checkbox` toggles completion; tapping the row opens the edit dialog.
- Priority is shown as a colored dot (red/orange/green). "In progress" tasks show a blue label. Assignments show a purple "Assignment" badge. Due dates turn red when overdue.
- The "New Task" FAB opens a dialog with title, description, subject dropdown, priority, **status**, assignment switch, and a date picker (past dates allowed; due date can be cleared).

### `SubjectsScreen`
- Lists subjects as cards with a color avatar (first letter of the code), name, and code.
- Tapping a row opens the edit dialog; the trash icon asks for confirmation before deleting.
- "New Subject" FAB opens a dialog with name, code, and a color picker (`Wrap` of `CircleAvatar` choices).

### `TaskDetailScreen`
- Reached by tapping a due-date notification (payload carries the task id).
- Shows full task details, an "Edit Task" button (opens the shared dialog), and a "Delete Task" button.

### `ProfileScreen`
- Shows avatar (initial of display name), name, and email.
- "Edit display name" dialog updates Firebase display name.
- **"Change password"** dialog updates the account password.
- **"Verify email"** (shown when unverified) sends a verification link.
- Switch for **due-date reminders** (`taskProvider.setRemindersEnabled`).
- **Reminder lead time** selector (at due time / 15 min / 1 hour / 3 hours / 1 day / 1 week).
- Switch for **dark theme** (`themeProvider.setThemeMode`).
- "Log Out" button calls `authProvider.signOut()`, which also signs out of Google.

---

## Notifications

`NotificationService` (`lib/services/notification_service.dart`) is a singleton that wraps `FlutterLocalNotificationsPlugin`:

- `init(onTaskTap:)` initializes time zones, sets up Android/iOS init settings, and requests permission. It uses `@mipmap/ic_launcher` for the Android icon. On web it's a no-op (local notifications aren't supported there).
- `scheduleForTask(task, leadMinutes:)` schedules a notification at `dueDate - leadMinutes` (converted to the local `tz.TZDateTime`) and sets the task id as the notification payload. It is skipped if the task is completed, has no due date, or the reminder time is in the past. `reminderDateTime(task, leadMinutes)` is a pure helper for this logic.
- `cancelForTask(taskId)` / `cancelAll()` remove scheduled notifications.
- Tapping a notification routes to `TaskDetailScreen` via the `onTaskTap` callback and the global `navigatorKey`.
- `TaskProvider` calls these whenever a task is added, updated, toggled, deleted, or when reminder settings change (`_rescheduleAll()`).

> The Android schedule mode is `AndroidScheduleMode.inexact`, meaning the system may deliver the reminder a few minutes around the due time to save battery.

---

## Theming

`ThemeProvider` stores a `ThemeMode` (`system` by default) and persists it as an integer in `shared_preferences`. `main.dart` reads `themeProvider.themeMode` to set `themeMode` on `MaterialApp`, with both light and dark `ThemeData` using `colorSchemeSeed: Colors.blue` and `useMaterial3: true`. The Profile screen toggles between light and dark.

---

## Persistence

All app data except authentication lives in `shared_preferences` (local device storage), and tasks/subjects are additionally mirrored to Cloud Firestore when signed in:

- **Tasks** → key `tasks_<uid>` (or `tasks_guest`), JSON list of `Task`.
- **Subjects** → key `subjects_<uid>` (or `subjects_guest`), JSON list of `Subject`.
- **Theme mode** → key `themeMode` (int).
- **Reminders enabled** → key `remindersEnabled` (bool).
- **Reminder lead time** → key `reminderLeadMinutes` (int).

### Cloud sync behaviour
- Writes go to the local store first (offline-safe), then `CloudSyncService` mirrors them to `users/{uid}/tasks` and `users/{uid}/subjects` in Firestore.
- On startup (or after login) the provider fetches the remote list and runs a **last-write-wins merge** keyed on each item's `updatedAt` (`lib/services/sync_merge.dart`). Newer remote items replace local ones; newer local items are pushed back.
- Because data is keyed per user, switching accounts isolates each user's tasks and subjects. Reinstalling the app no longer loses data as long as the user signs in again.

### Required Firestore security rules
Add a **Cloud Firestore** database to your Firebase project and set rules so users can only touch their own data:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) compatible with Dart `^3.12.2`.
- A Firebase project (free tier is fine).
- For Android: Android Studio / SDK. For iOS: macOS + Xcode.

### Firebase Setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Add an Android and/or iOS app and download the config files:
   - Android: place `google-services.json` in `android/app/`.
   - iOS: place `GoogleService-Info.plist` in `ios/Runner/`.
3. Enable **Authentication** providers: **Email/Password** and **Google**.
4. Create a **Cloud Firestore** database and paste the security rules from the [Persistence](#persistence) section.
5. Replace the Google Web client ID placeholder in `lib/providers/auth_provider.dart` (see [Authentication Flow](#authentication-flow)).

### Running the App
```bash
cd todo_app
flutter pub get
flutter run
```

### Building
```bash
flutter build apk       # Android APK
flutter build appbundle # Android App Bundle (Play Store)
flutter build ios       # iOS (requires macOS + Xcode)
flutter build web       # Web
```

---

## Notes & Known Limitations

- **Sync is pull-based on startup**: cloud changes made on another device appear after the next app launch/login, not in real time. The local store remains the source of truth while offline.
- **Merge is last-write-wins**: concurrent edits to the same task on two devices keep whichever was modified last; no field-level merging.
- **Guest mode**: If a user is somehow active without an account, data falls back to `tasks_guest` / `subjects_guest` keys (and isn't synced).
- **Inexact scheduling** on Android may shift reminder delivery slightly.
- **Web**: local notifications are not supported; the notification service is a no-op there.
- The Google Web client ID is a hard-coded constant that must be set before release.

---

## Future Improvements

- Real-time Firestore listeners for cross-device updates without restarting.
- **Recurring tasks** and **subtasks**.
- Add **categories/tags** beyond subjects.
- Support **biometric lock** for the app.
- Widget/UI tests for the screens (the provider/model/sync logic is covered today).
- App icon and splash-screen branding.

---

## License

This project is intended for educational and personal use.
