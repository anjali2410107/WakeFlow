# Wakeflow — Premium Alarm Clock App with Firebase & BLoC

Wakeflow is a highly responsive and visually stunning Flutter Alarm Clock application built using the **BLoC (Business Logic Component)** state management pattern, featuring real-time **Firebase Authentication**, **Cloud Firestore sync**, local offline fallback capability, and local exact alarm notifications.

---

## 🚀 Key Features

1. **Dual-Mode Architecture (Offline/Cloud Hybrid)**
   - **Firebase Connected Mode**: Real email/password registration, login, session persistence, and real-time Firestore database synchronization.
   - **Offline Demo Mode**: Fully functional local environment utilizing a mock auth database and local cache via `shared_preferences`. Runs immediately without requiring pre-setup Firebase configurations.
   - **Offline-to-Cloud Migration**: If a user runs the app in Offline Mode and then later registers or logs in with cloud connectivity, Wakeflow automatically migrates their local alarms to Firestore.

2. **Advanced Alarm Functionality**
   - Exact alarm scheduling using `flutter_local_notifications` and timezone database resolution (`timezone`, `flutter_timezone`).
   - Support for custom repeating days (e.g., repeating alarms on Mondays, Wednesdays, and Fridays).
   - Custom snooze settings (off, 5m, 9m, 15m).
   - Background restore: Alarms are automatically rescheduled when the device restarts.

3. **High-Fidelity UI/UX**
   - Premium dark-theme dashboard featuring neon accent highlights and glassmorphic card overlays.
   - Live-ticking digital clock showing date and timezone.
   - Countdown widget indicating hours/minutes remaining until the next active alarm triggers.
   - Swipe-to-dismiss deletion on alarm list items with snackbar recovery confirmations.

---

## 🛠️ Project Structure

```
lib/
├── main.dart
├── models/
│   ├── alarm.dart          # Alarm data model & map serialization
│   └── app_user.dart       # AppUser abstraction (Firebase / Mock)
├── services/
│   ├── firebase_service.dart     # Safe conditional Firebase Core init
│   ├── auth_service.dart         # Hybrid Firebase / Local auth provider
│   ├── database_service.dart     # Hybrid Firestore / Local storage sync
│   └── notification_service.dart # Local system notifications scheduler
├── blocs/
│   ├── auth/
│   │   ├── auth_bloc.dart        # Auth state engine
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   └── alarm/
│       ├── alarm_bloc.dart       # Alarm operations state engine
│       ├── alarm_event.dart
│       └── alarm_state.dart
├── screens/
│   ├── login_screen.dart         # Login UI with dynamic status badges
│   ├── register_screen.dart      # Registration UI
│   ├── home_screen.dart          # Main dashboard, live clock & alarm list
│   └── add_edit_alarm_screen.dart # Time selector, repeat days & snooze config
└── widgets/
    └── alarm_tile.dart           # Glassmorphic card display component
```

---

## 📦 Getting Started & Running the App

### 1. Prerequisites
Ensure you have the Flutter SDK installed on your machine (`v3.10.0+` recommended).

### 2. Fetch Dependencies
Navigate to the project root and run:
```bash
flutter pub get
```

### 3. Run the Application
Start the application on your target simulator or physical device:
```bash
flutter run
```
*Note: If no Firebase configuration is present, the app will display an orange status badge "**Offline Demo Mode**" and work fully in on-device local storage. You can immediately create, modify, test, and trigger alarms.*

---

## ⚡ Firebase Setup Steps (Optional for Cloud Sync)

To connect Wakeflow to your own Google Firebase project and enable real-time cloud sync:

### 1. Create a Firebase Project
- Go to the [Firebase Console](https://console.firebase.google.com/).
- Create a new project named **Wakeflow**.

### 2. Enable Authentication
- In the Firebase Console, navigate to **Build > Authentication**.
- Click **Get Started**, then select **Email/Password** as the sign-in provider, enable it, and save.

### 3. Enable Cloud Firestore
- Navigate to **Build > Firestore Database**.
- Click **Create Database** and set it up in **Test Mode** (or rules that allow authenticated users read/write access to `users/{uid}/alarms/{alarmId}`).

### 4. Register Platform Configurations

#### For Android:
- Click the Android icon to add an app.
- Package name: `com.example.wakeflow`.
- Download `google-services.json` and place it under `android/app/`.

#### For iOS:
- Add an iOS app in the console.
- Bundle ID: `com.example.wakeflow`.
- Download `GoogleService-Info.plist` and place it in `ios/Runner/` via Xcode.

### 5. Build/Run
Re-launch the app:
```bash
flutter run
```
*The status badge will now show a green "**Firebase Connected**" label, enabling cloud sync!*
