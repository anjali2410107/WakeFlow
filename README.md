# ⏰ Wakeflow

Wakeflow is a premium, beautifully designed, and highly reliable Flutter alarm clock application featuring an offline-first architecture, real-time Cloud Firestore synchronization, and precise time-zone scheduling.

Built with modern Flutter design practices and the BLoC pattern, Wakeflow ensures your alarms always fire on time, sync across all your devices, and work seamlessly even when your device is offline.

---

## ✨ Features

- 🌟 **Premium Dark Aesthetics:** A stunning user interface built with vibrant gradients, neon highlights, and glassmorphic widgets.
- ☁️ **Real-time Firestore Sync:** Instantly syncs your alarms across devices under the `users/{uid}/alarms` collection path when connected to the internet.
- 📴 **Offline-First Architecture:** Keeps a local cache of your alarms via `SharedPreferences`. Any modifications made while offline are queued and synchronized to Cloud Firestore as soon as internet connection is restored.
- ⏰ **Insistent Alarms:** Built-in Android alarm configuration that plays your default system ringtone continuously in a loop until you dismiss it.
- 🌍 **Timezone-Aware Scheduling:** Automatically detects the device's native IANA timezone identifier and schedules alarms precisely using the `timezone` database, preventing timing offsets when traveling.
- ⚙️ **State Management:** Fully reactive UI powered by Flutter BLoC, separating business logic from presentation.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [Flutter BLoC](https://pub.dev/packages/flutter_bloc)
- **Local Database & Cache:** [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Cloud Backend:** [Firebase Core](https://pub.dev/packages/firebase_core) & [Cloud Firestore](https://pub.dev/packages/cloud_firestore)
- **Authentication:** [Firebase Auth](https://pub.dev/packages/firebase_auth) (Email/Password registration and login)
- **Alarm Scheduling:** [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- **Timezone Database:** [Timezone](https://pub.dev/packages/timezone) & [Flutter Timezone](https://pub.dev/packages/flutter_timezone)

```
lib/
├── blocs/               # BLoC Architecture (Auth, Alarms)
│   ├── alarm/           # Alarm state & event logic
│   └── auth/            # Authentication logic
├── models/              # Data models (Alarm, AppUser)
├── screens/             # UI views (Home, Login, Register, Add/Edit Alarm)
├── services/            # Infrastructure services (Firestore, Auth, Notifications)
├── widgets/             # Reusable UI component widgets
├── firebase_options.dart # Generated Firebase configuration options
└── main.dart            # App entry point & initialization logic
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0` or higher)
- [Android Studio / SDK](https://developer.android.com/studio) (configured for Android build tools)
- A Firebase Project (with Email/Password Authentication and Firestore Database enabled)

### Installation & Run

1. Clone the repository and navigate to the project directory:
   ```bash
   git clone https://github.com/your-username/wakeflow.git
   cd wakeflow
   ```

2. Fetch all dependencies:
   ```bash
   flutter pub get
   ```

3. Ensure you have set up your native Firebase configuration:
   - Run `flutterfire configure` to generate/update the [firebase_options.dart](lib/firebase_options.dart) file, or download the `google-services.json` file to `android/app/google-services.json`.

4. Run the app in debug mode on a connected device/emulator:
   ```bash
   flutter run
   ```

---

## ⚙️ Core Platform Configurations (Android)

Wakeflow is pre-configured with critical native settings to ensure alarms are scheduled precisely and trigger reliably:

### 1. Core Library Desugaring
To support modern Java 8+ APIs (such as the `java.time` APIs utilized by timezone and notification plugins) on older API levels, desugaring is enabled inside [build.gradle.kts](android/app/build.gradle.kts):
```kotlin
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

### 2. Precise Alarm & Notification Permissions
Declared in the [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) file to permit boot persistence, notification alerts, and exact clock-timed wakeups:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

And the background broadcast receivers required by `flutter_local_notifications` are correctly registered inside the `<application>` tag:
```xml
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" android:exported="false" />
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
