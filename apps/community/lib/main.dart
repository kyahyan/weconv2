import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'src/feed_screen.dart';
import 'src/profile_screen.dart';

import 'package:windows_single_instance/windows_single_instance.dart';

import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  // Ensure single instance on Windows
  await WindowsSingleInstance.ensureSingleInstance(args, "weconnect_community_app_v2", onSecondWindow: (args) {
    // This callback runs in the FIRST instance when a second instance tries to open
    print("Second instance launched with args: $args");
    
    // Bring window to front
    windowManager.show();
    windowManager.focus();

    // Find the custom protocol url in args
    for (final arg in args) {
       if (arg.contains('io.supabase.flutter://')) {
          try {
             Supabase.instance.client.auth.getSessionFromUrl(Uri.parse(arg));
          } catch (e) {
             print("Error parsing deep link: $e");
          }
       }
    }
  });

  await SupabaseConfig.init();
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
        title: 'WeConnect Community',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
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
          return const FeedScreen();
        }

        return LoginScreen(
          title: 'Community App Login',
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: const Center(child: Text('Welcome to Community App!')),
    );
  }
}
