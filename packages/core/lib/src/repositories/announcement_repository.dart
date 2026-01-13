import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnnouncementRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Announcement>> getAnnouncements({List<String>? orgIds, String? branchId}) async {
    var query = _client.from('announcements').select();

    if (orgIds != null && orgIds.isNotEmpty) {
      query = query.filter('organization_id', 'in', orgIds);
    }
    
    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final response = await query.order('created_at', ascending: false);
    
    return (response as List).map((json) => Announcement.fromJson(json)).toList();
  }

  Future<void> createAnnouncement(String title, String content, {String? orgId, String? branchId}) async {
    await _client.from('announcements').insert({
      'title': title,
      'content': content,
      if (orgId != null) 'organization_id': orgId,
      if (branchId != null) 'branch_id': branchId,
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from('announcements').delete().eq('id', id);
  }
}
