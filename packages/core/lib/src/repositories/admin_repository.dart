import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:models/models.dart';

class AdminRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Organization>> getAllOrganizations() async {
    final response = await _client
        .from('organizations')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => Organization.fromJson(e)).toList();
  }
}
