import 'package:supabase_flutter/supabase_flutter.dart';

class UserRoles {
  static Future<bool> isSuperAdmin() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('is_superadmin')
          .eq('id', user.id)
          .single();
      
      return response['is_superadmin'] == true;
    } catch (_) {
      return false;
    }
  }
}
