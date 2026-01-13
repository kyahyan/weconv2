import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnnouncementRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Announcement>> getAnnouncements() async {
    final response = await _client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Announcement.fromJson(json)).toList();
  }

  Future<void> createAnnouncement(String title, String content) async {
    await _client.from('announcements').insert({
      'title': title,
      'content': content,
      // organization_id is handled by default if auth.uid() matches, 
      // but strictly we should pass it or let RLS/default handle it. 
      // The migration I wrote uses default auth.uid() if not passed? 
      // Wait, my migration has 'organization_id uuid not null default auth.uid()'.
      // So I don't strictly need to pass it if the user is logged in.
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from('announcements').delete().eq('id', id);
  }
}
