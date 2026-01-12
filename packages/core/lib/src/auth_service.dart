import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<User?> get userStream => _client.auth.onAuthStateChange.map((event) => event.session?.user);

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<bool> signInWithGoogle() async {
    try {
      // For Windows and Web, this will launch the browser.
      // Make sure you have configured the redirect URL in Supabase dashboard.
      // Default bundle ID for windows is usually sufficient if deep linking is set up,
      // but strictly for "easy" windows dev, often the browser handles it.
      // We will simpler use signInWithOAuth.
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://callback', // Common default, adjust if needed
      );
      return response;
    } catch (e) {
      // Handle error or rethrow
      rethrow;
    }
  }
}
