# Dietician Babu - Project Overview & Maintenance Guide

## 📌 Project Summary
**Dietician Babu** is a comprehensive Flutter-based health and nutrition management ecosystem. It bridges the gap between dieticians (Admins) and clients through a data-driven approach to health tracking, diet planning, and progress monitoring.

### 🚀 Core Modules
1.  **Onboarding & Health Profile:** A multi-step process to capture user goals, medical history, and dietary preferences.
2.  **Admin Dashboard:** Centralized control for managing clients, creating custom diet plans, and analyzing sales/revenue.
3.  **Client Dashboard:** Personalized view for users to track daily steps, view active diet plans, and log weekly check-ins.
4.  **AI Integration:** Leverages Google Gemini (Generative AI) to assist admins in drafting personalized diet plans based on client tags.
5.  **Payment System:** Integrated with Razorpay for subscription management.

---

## 🛠️ Technical Architecture
-   **Frontend:** Flutter (Dart)
-   **State Management:** Currently uses **plain setState**. There is no external state management library (like Bloc or Riverpod) implemented yet.
-   **Backend:** Firebase (Auth, Firestore, Storage).
-   **AI:** `google_generative_ai` (Gemini Pro) via `env.json`.
-   **UI Utilities:** `sizer` for responsive sizing (not state management) and `google_fonts` for typography.

---

## 🔍 Troubleshooting Firebase & Pedometer
If features are not working properly, check these common failure points:

### 1. Firestore "databaseId" Mismatch
In `lib/services/firebase_service.dart`, the Firestore instance is initialized with a specific database ID:
```dart
FirebaseFirestore get db => FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'dieticianbabu');
```
**Fix:** If you are using the default Firebase database, change this to `FirebaseFirestore.instance`.

### 2. Missing SHA-1 for Google Sign-In & Phone Auth
If authentication fails on Android:
**Fix:** Add your local machine's **SHA-1** and **SHA-256** certificates to the [Firebase Console](https://console.firebase.google.com/project/dietician-babu-31ka2/overview).

### 3. Google Services Configuration
The `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files are **gitignored**.
**Fix:** After a fresh clone, manually place `google-services.json` in `android/app/`.

### 4. Pedometer & Activity Recognition
The `pedometer` package requires the `ACTIVITY_RECOGNITION` permission.
**Fix:** On Android 10+, this must be requested at **runtime** using `permission_handler`, not just declared in the Manifest.

---

## 📈 Optimization & Improvements

### 1. Implement State Management
*   **Recommendation:** Move away from `setState` to a solution like **Provider** or **Riverpod**. This is critical for managing real-time Firebase streams and complex health data across multiple screens.

### 2. Security Rules
*   **Recommendation:** Deploy strict Firestore Security Rules. Ensure clients can only read/write their own profiles, and only the admin (`dieticianbabu@gmail.com`) can access `payments` and `sales`.

### 3. Background Tasks
*   **Recommendation:** Use `workmanager` to keep the pedometer active in the background, ensuring accurate step counts even when the app is minimized.

---

## 📦 Deployment & Maintenance

### Environment Variables
The Gemini API key is stored in `env.json`. This file **must** be passed during run and build:
```bash
# Debug Run
flutter run --dart-define-from-file=env.json

# Release Build (Android)
flutter build apk --release --split-per-abi --dart-define-from-file=env.json
```

### Versioning
Current Version: `1.3.0+4` (Found in `pubspec.yaml`).
To bump the version for a new release, update the `version:` line:
- `1.3.1` is the semantic version.
- `+5` is the build number (increment this for every Store upload).

### Firebase Console
Maintain the project here: [Firebase Console - Dietician Babu](https://console.firebase.google.com/project/dietician-babu-31ka2/overview)

### Maintenance Checklist
1. Sync dependencies: `flutter pub get`
2. Check for code issues: `flutter analyze`
3. Verify `env.json` is present before building.
