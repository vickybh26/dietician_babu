# Dietician Babu

A comprehensive Flutter-based health and nutrition management platform. It features a dual-interface system catering to both clients (diet plans, progress tracking, health onboarding) and administrators (client management, diet plan creation, sales analytics).

---

## 📋 Prerequisites

- **Flutter SDK** (^3.6.0)
- **Dart SDK**
- **Firebase Account** (Firestore, Auth, Storage)
- **Gemini API Key** (for AI diet plan generation)

## 🛠️ Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vickybh26/dietician_babu.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Place `google-services.json` in `android/app/`.
   - Place `GoogleService-Info.plist` in `ios/Runner/`.
   - *Note: These files are gitignored for security.*

4. **Environment Variables:**
   The client accepts only the public Firebase web configuration through
   `--dart-define=FIREBASE_API_KEY=...`. The Gemini key is server-only and is
   configured in Firebase Functions with `firebase functions:secrets:set GEMINI_API_KEY`.

---

## 🚀 Running the App

The app uses `--dart-define-from-file` to inject secrets.

**CLI:**
```bash
flutter run --dart-define=FIREBASE_API_KEY=your_firebase_web_key
```

**VS Code (`launch.json`):**
```json
{
    "args": ["--dart-define=FIREBASE_API_KEY=your_firebase_web_key"]
}
```

---

## 🔍 Troubleshooting (Common Issues)

### 1. Firestore "databaseId" Mismatch
If data isn't loading, check `lib/services/firebase_service.dart`. 
- **Fix:** Ensure `databaseId` matches your Firebase Console (usually `(default)` or `dieticianbabu`).

### 2. Authentication Failures (SHA-1)
If Google Sign-In or Phone Auth fails on Android:
- **Fix:** Add your machine's **SHA-1** and **SHA-256** certificates to the Firebase Console.

### 3. Pedometer Permissions
On Android 10+, physical activity tracking requires **runtime permissions**.
- **Fix:** The app uses `permission_handler` to request `ACTIVITY_RECOGNITION`. Ensure this is allowed in your phone settings.

---

## 📁 Project Structure

```
dietician_babu/
├── lib/
│   ├── core/           # Constants, App Themes, and Tags
│   ├── data/           # Models and Repositories (Planned)
│   ├── presentation/   # UI Screens (Divided into Admin/Client)
│   ├── routes/         # Environment-aware Routing (Web vs Mobile)
│   ├── services/       # Firebase & AI Service Logic
│   └── main.dart       # Entry Point
├── assets/             # Images and Branding
└── env.json            # App Secrets (Manual Setup Required)
```

---

## 📈 Optimization Roadmap

1. **State Management:** Transition from `setState` to **Riverpod** or **Provider** for better scalability.
2. **Background Tasks:** Integrate `workmanager` to keep the step counter active when the app is minimized.
3. **Security:** Implement strict Firestore Security Rules to protect user health data.
4. **Caching:** Enable offline persistence for diet plans.

---

## 📦 Deployment & Versioning

### Production Build
```bash
# Android
flutter build apk --release --split-per-abi --dart-define-from-file=env.json

# Web (Admin Dashboard)
flutter build web --dart-define-from-file=env.json
```

### Versioning
Current: `1.3.0+4` (Update in `pubspec.yaml`).
- Increment the `+4` (build number) for every store upload.

---

## 🙏 Acknowledgments
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design
- AI assistance by Google Gemini

Built with ❤️ for Dietician Babu
