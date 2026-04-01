import 'package:flutter_test/flutter_test.dart';

import 'package:samba_mobile/main.dart';
import 'package:samba_mobile/src/services/api_service.dart';

void main() {
  testWidgets('shows firebase config message when auth is unavailable', (WidgetTester tester) async {
    await tester.pumpWidget(
      SambaApp(
        apiService: ApiService(baseUrl: 'http://localhost:8080'),
        auth: null,
        authInitializationError: 'Firebase yapılandırması eksik.',
      ),
    );

    expect(find.text('Firebase yapılandırması eksik.'), findsOneWidget);
  });
}
