import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'src/worship_home_screen.dart';
import 'src/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SupabaseConfig.init();
  await NotificationService().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      theme: ShadcnAppTheme.lightTheme,
      darkTheme: ShadcnAppTheme.darkTheme,
      home: MaterialApp(
        title: 'Worship App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user != null) {
          return const WorshipHomeScreen();
        }

        return LoginScreen(
          title: 'Worship App Login',
          onLogin: (email, password) async {
            await _authService.signIn(email: email, password: password);
          },
          onSignUp: (email, password) async {
            await _authService.signUp(email: email, password: password);
          },
          onGoogleSignIn: () async {
            await _authService.signInWithGoogle();
          },
        );
      },
    );
  }
}
