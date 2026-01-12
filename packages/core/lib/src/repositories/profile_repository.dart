import 'dart:typed_data';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle to avoid exception if not found
      
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      // Log error if needed
      return null;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').update(profile.toJson()).eq('id', profile.id);
  }

  Future<String> uploadAvatar(String userId, List<int> fileBytes, String fileExtension) async {
    final fileName = '$userId/avatar.$fileExtension';
    await _client.storage.from('avatars').uploadBinary(
      fileName,
      Uint8List.fromList(fileBytes),
      fileOptions: const FileOptions(upsert: true),
    );
    return _client.storage.from('avatars').getPublicUrl(fileName);
  }
}
