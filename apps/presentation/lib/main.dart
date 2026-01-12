import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/projection_control_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presentation',
      theme: AppTheme.darkTheme, // Default to dark for presentation
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        
        // Also check if current user is already logged in (for initial load)
        final currentUser = Supabase.instance.client.auth.currentUser;

        if (session != null || currentUser != null) {
          return const ProjectionControlScreen();
        }

        return LoginScreen(
          onLogin: (email, password) async {
             await AuthService().signIn(email: email, password: password);
          },
          onSignUp: (email, password) async {
             await AuthService().signUp(email: email, password: password);
          },
        );
      },
    );
  }
}
