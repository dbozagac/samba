# Samba Mobile (Flutter)

## Prerequisites

- Flutter SDK
- Firebase project

## Configure

1. Copy env template:

```bash
cp ../../.env.mobile.example .env.mobile
```

2. Fill Firebase and Google OAuth values in `apps/mobile/.env.mobile`.
3. Pass env values with `--dart-define-from-file`.

Example:

```bash
flutter run \
  --dart-define-from-file=.env.mobile
```

> iOS için `FIREBASE_IOS_APP_ID`, Android için `FIREBASE_ANDROID_APP_ID` kullanın.
> Geriye dönük uyumluluk için isterseniz tek `FIREBASE_APP_ID` de verebilirsiniz.
> Google Sign-In için `GOOGLE_WEB_CLIENT_ID` zorunluya yakındır; Android'de `idToken` üretimi için gerekir.
> iOS'ta `GOOGLE_IOS_CLIENT_ID` ekleyin.
> `API_BASE_URL` boş bırakılırsa Android için `http://10.0.2.2:8080`, iOS için `http://127.0.0.1:8080` varsayılır.
