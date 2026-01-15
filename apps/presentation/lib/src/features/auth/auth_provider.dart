import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Real Auth Controller using Supabase
class AuthController extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthController() : super(const AsyncData(null)) {
    // Check initial session
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
       await _fetchProfile(session.user.id);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _fetchProfile(response.user!.id);
      } else {
        state = const AsyncError('Login failed: No user returned', StackTrace.empty);
      }
    } on AuthException catch (e) {
      state = AsyncError(e.message, StackTrace.empty);
    } catch (e) {
      state = AsyncError('An unexpected error occurred: $e', StackTrace.empty);
    }
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      // Check for Operator Role
      final memberships = await Supabase.instance.client
          .from('organization_members')
          .select('ministry_roles')
          .eq('user_id', userId);

      bool isOperator = false;
      for (var m in memberships) {
        final roles = List<String>.from(m['ministry_roles'] ?? []);
        if (roles.contains('Operator')) {
          isOperator = true;
          break;
        }
      }

      if (!isOperator) {
        // If strictly required, fail here.
        // We ensure we sign out if access is denied to prevent "stuck" session.
        await Supabase.instance.client.auth.signOut();
        throw 'Access Denied: You must have the "Operator" role to login.';
      }

      final userProfile = UserProfile.fromJson(data);
      state = AsyncData(userProfile);
    } catch (e) {
      if (e.toString().contains('Access Denied')) {
         state = AsyncError(e, StackTrace.empty);
      } else {
         state = AsyncError('Failed to load profile: $e', StackTrace.empty);
      }
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = const AsyncData(null);
  }
}

final authProvider = StateNotifierProvider<AuthController, AsyncValue<UserProfile?>>((ref) {
  return AuthController();
});
