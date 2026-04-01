import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    const configuredValue = String.fromEnvironment('API_BASE_URL');
    final trimmed = configuredValue.trim();
    if (trimmed.isNotEmpty) return trimmed;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://127.0.0.1:8080';
  }

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseWebAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const firebaseIosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const firebaseAndroidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const firebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static String get selectedFirebaseAppId {
    if (kIsWeb) {
      final value = firebaseWebAppId.trim();
      if (value.isNotEmpty) return value;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final value = firebaseAndroidAppId.trim();
      if (value.isNotEmpty) return value;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final value = firebaseIosAppId.trim();
      if (value.isNotEmpty) return value;
    }

    return firebaseAppId.trim();
  }

  static bool get hasFirebaseEnvValues =>
      firebaseApiKey.trim().isNotEmpty &&
      selectedFirebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.trim().isNotEmpty &&
      firebaseProjectId.trim().isNotEmpty;

  static bool get hasValidFirebaseAppIdFormat {
    final appId = selectedFirebaseAppId;

    if (kIsWeb) {
      return RegExp(r'^\d+:\d+:web:[a-zA-Z0-9]+$').hasMatch(appId);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return RegExp(r'^\d+:\d+:ios:[a-zA-Z0-9]+$').hasMatch(appId);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return RegExp(r'^\d+:\d+:android:[a-zA-Z0-9]+$').hasMatch(appId);
    }

    return RegExp(r'^\d+:\d+:[a-z]+:[a-zA-Z0-9]+$').hasMatch(appId);
  }

  static String get firebaseConfigurationHint {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS için FIREBASE_IOS_APP_ID (veya FIREBASE_APP_ID) değeri 1:...:ios:... formatında olmalı.';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android için FIREBASE_ANDROID_APP_ID (veya FIREBASE_APP_ID) değeri 1:...:android:... formatında olmalı.';
    }

    if (kIsWeb) {
      return 'Web için FIREBASE_WEB_APP_ID (veya FIREBASE_APP_ID) değeri 1:...:web:... formatında olmalı.';
    }

    return 'FIREBASE_APP_ID değeri zorunludur ve 1:...:<platform>:... formatında olmalı.';
  }

  static bool get canInitializeFirebase =>
      hasFirebaseEnvValues && hasValidFirebaseAppIdFormat;

  static String? get googleClientIdOrNull {
    final platformClientId = defaultTargetPlatform == TargetPlatform.iOS
        ? googleIosClientId.trim()
        : '';
    if (platformClientId.isNotEmpty) return platformClientId;

    final fallbackWebClientId = googleWebClientId.trim();
    return fallbackWebClientId.isNotEmpty ? fallbackWebClientId : null;
  }

  static String? get googleServerClientIdOrNull {
    final value = googleWebClientId.trim();
    return value.isNotEmpty ? value : null;
  }

  static String get googleSignInConfigurationHint {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS için GOOGLE_IOS_CLIENT_ID ve GOOGLE_WEB_CLIENT_ID (Web OAuth client) önerilir.';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android için GOOGLE_WEB_CLIENT_ID (Web OAuth client) önerilir; idToken üretimi için gereklidir.';
    }

    return 'Google Sign-In için client ID değerlerini ortam değişkenlerinde tanımlayın.';
  }
}
