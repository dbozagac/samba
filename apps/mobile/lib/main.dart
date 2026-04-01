import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'src/app_config.dart';
import 'src/screens/home_screen.dart';
import 'src/services/api_service.dart';

Future<FirebaseApp> _initializeFirebaseApp() async {
  if (Firebase.apps.isNotEmpty) {
    return Firebase.app();
  }

  return Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.selectedFirebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      authDomain: AppConfig.firebaseAuthDomain.trim().isEmpty
          ? null
          : AppConfig.firebaseAuthDomain.trim(),
    ),
  );
}

GoogleSignIn _createGoogleSignIn() {
  return GoogleSignIn(
    clientId: AppConfig.googleClientIdOrNull,
    serverClientId: AppConfig.googleServerClientIdOrNull,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseAuth? auth;
  GoogleSignIn? googleSignIn;
  String? authInitializationError;

  if (AppConfig.canInitializeFirebase) {
    try {
      final firebaseApp = await _initializeFirebaseApp();
      auth = FirebaseAuth.instanceFor(app: firebaseApp);
      googleSignIn = _createGoogleSignIn();
    } catch (error) {
      authInitializationError = 'Firebase başlatılamadı: $error\n'
          'Muhtemel neden: App ID ile platform uygulama kimliği eşleşmiyor.';
      debugPrint('Firebase initialization failed: $error');
    }
  } else {
    authInitializationError =
        'Firebase yapılandırması geçersiz veya eksik. Uygulama crash etmemesi için auth devre dışı bırakıldı.';
  }

  runApp(
    SambaApp(
      apiService: ApiService(baseUrl: AppConfig.apiBaseUrl),
      auth: auth,
      googleSignIn: googleSignIn,
      authInitializationError: authInitializationError,
    ),
  );
}

class SambaApp extends StatelessWidget {
  const SambaApp({
    super.key,
    required this.apiService,
    required this.auth,
    this.googleSignIn,
    required this.authInitializationError,
  });

  final ApiService apiService;
  final FirebaseAuth? auth;
  final GoogleSignIn? googleSignIn;
  final String? authInitializationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samba Mobile',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: auth == null || googleSignIn == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Samba Mobile')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authInitializationError ?? 'Firebase başlatılamadı.'),
                    const SizedBox(height: 12),
                    const Text(
                      'Lütfen şu dart-define değerlerini geçerli Firebase projesiyle verin:\n'
                      'FIREBASE_API_KEY\nFIREBASE_IOS_APP_ID / FIREBASE_ANDROID_APP_ID\nFIREBASE_MESSAGING_SENDER_ID\nFIREBASE_PROJECT_ID',
                    ),
                    const SizedBox(height: 8),
                    Text(AppConfig.firebaseConfigurationHint),
                    const SizedBox(height: 8),
                    Text(AppConfig.googleSignInConfigurationHint),
                  ],
                ),
              ),
            )
          : StreamBuilder<User?>(
              stream: auth!.authStateChanges(),
              builder: (context, snapshot) {
                final currentUser = snapshot.data;
                if (currentUser == null) {
                  return _LoginScreen(auth: auth!, googleSignIn: googleSignIn!);
                }

                return HomeScreen(
                  apiService: apiService,
                  auth: auth!,
                  googleSignIn: googleSignIn!,
                );
              },
            ),
    );
  }
}

/// Login screen with Google Sign-In (replaces anonymous auth).
class _LoginScreen extends StatefulWidget {
  const _LoginScreen({required this.auth, required this.googleSignIn});

  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final googleUser = await widget.googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow
        setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw Exception(
          'Google idToken alınamadı. ${AppConfig.googleSignInConfigurationHint}',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await widget.auth.signInWithCredential(credential);
    } catch (e) {
      setState(() => _error = 'Giriş başarısız: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Samba Mobile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Devam etmek için Google hesabınla giriş yap.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('Google ile Giriş'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
