import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/alarm/alarm_bloc.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0E17),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await FirebaseService.initialize();
  
  final authService = AuthService();
  await authService.init();

  final databaseService = DatabaseService();
  
  await NotificationService.initialize();

  runApp(
    MyApp(
      authService: authService,
      databaseService: databaseService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final DatabaseService databaseService;

  const MyApp({
    super.key,
    required this.authService,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<DatabaseService>.value(value: databaseService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(authService: authService)..add(AuthCheckRequested()),
          ),
          BlocProvider<AlarmBloc>(
            create: (context) => AlarmBloc(databaseService: databaseService),
          ),
        ],
        child: MaterialApp(
          title: 'Wakeflow',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0E17),
            primaryColor: const Color(0xFF6C63FF),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              secondary: Color(0xFFE285FF),
              surface: Color(0xFF16152B),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Roboto', color: Colors.white70),
              titleLarge: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
            ),
          ),
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
              ),
            ),
          );
        } else if (state is Authenticated) {
          return HomeScreen(user: state.user);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
