import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'src/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        title: 'WeConnect Planning',
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

        if (snapshot.hasData) {
          // Check for permission logic
          return FutureBuilder<bool>(
            future: OrganizationRepository().canAccessPlanning(),
            builder: (context, permSnapshot) {
               if(permSnapshot.connectionState == ConnectionState.waiting) {
                 return const Scaffold(body: Center(child: CircularProgressIndicator()));
               }
               
               if(permSnapshot.data == true) {
                 return const DashboardScreen();
               }

               return Scaffold(
                 body: Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Text("Access Denied", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 16),
                       const Text("You must have the 'Secretary' Ministry Role to access this app."),
                       const SizedBox(height: 32),
                       ElevatedButton(
                         onPressed: () => _authService.signOut(),
                         child: const Text('Sign Out'),
                       ),
                     ],
                   ),
                 ),
               );
            },
          );
        }

        return LoginScreen(
          title: 'Planning App Login',
          onLogin: (email, password) async {
            await _authService.signIn(email: email, password: password);
          },
          onSignUp: (email, password) async {
            await _authService.signUp(email: email, password: password);
          },
        );
      },
    );
  }
}
