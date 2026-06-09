import 'package:flutter_test/flutter_test.dart';
import 'package:wakeflow/main.dart';
import 'package:wakeflow/services/auth_service.dart';
import 'package:wakeflow/services/database_service.dart';

void main() {
  testWidgets('App compiles and instantiates', (WidgetTester tester) async {
    final authService = AuthService();
    final databaseService = DatabaseService();
    
    final app = MyApp(
      authService: authService,
      databaseService: databaseService,
    );
    
    expect(app.authService, authService);
    expect(app.databaseService, databaseService);
  });
}
