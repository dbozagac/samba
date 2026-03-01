# Samba Mobile (Flutter)

## Prerequisites
- Flutter SDK
- Firebase project

## Configure
1. Add platform files via `flutterfire configure`.
2. Pass env values with `--dart-define`.

Example:
```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=...
```

> Android emulator için host API adresi `10.0.2.2` kullanılır.
