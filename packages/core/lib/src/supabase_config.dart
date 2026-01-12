import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://vmqpatdbutbcqmijclin.supabase.co';
  static const String anonKey = 'sb_publishable_89i7Mrn_pdOT5WPkRBCzdA_yzdktULF';

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
