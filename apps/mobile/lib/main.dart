import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'src/app_config.dart';
import 'src/screens/home_screen.dart';
import 'src/services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
    ),
  );

  runApp(SambaApp(apiService: ApiService(baseUrl: AppConfig.apiBaseUrl)));
}

class SambaApp extends StatelessWidget {
  const SambaApp({super.key, required this.apiService});

  final ApiService apiService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samba Mobile',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final currentUser = snapshot.data;
          if (currentUser == null) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signInAnonymously();
                  },
                  child: const Text('Geçici Giriş (Firebase)'),
                ),
              ),
            );
          }

          return HomeScreen(apiService: apiService, user: currentUser);
        },
      ),
    );
  }
}
