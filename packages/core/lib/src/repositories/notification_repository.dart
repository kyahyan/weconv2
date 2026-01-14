import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<UserNotification>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => UserNotification.fromJson(e)).toList();
  }
  
  // Stream for real-time updates (Bonus)
  Stream<List<UserNotification>> getNotificationsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => UserNotification.fromJson(json)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({
      'is_read': true,
    }).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false); // Only update unread ones
  }

  /// Manually notifies all members assigned to a service.
  /// Fetches assignments and inserts notifications for each member's user_id.
  Future<int> notifyTeam(String serviceId, String serviceTitle) async {
    // 1. Fetch all assignments for this service
    final assignmentsResponse = await _client
        .from('service_assignments')
        .select('member_id, team_name, role_name')
        .eq('service_id', serviceId);
    
    final assignments = (assignmentsResponse as List).cast<Map<String, dynamic>>();
    if (assignments.isEmpty) return 0;

    int successCount = 0;

    // 2. For each assignment, resolve member_id -> user_id
    // This could be optimized safely with a single join query if we had backend access,
    // but client-side we do N lookups or 1 batch lookup if possible.
    // Let's do batch lookup: get all member_ids.
    final memberIds = assignments.map((a) => a['member_id']).toList();
    
    // Fetch user_ids for these members
    if (memberIds.isEmpty) return 0;
    
    final membersResponse = await _client
        .from('organization_members')
        .select('id, user_id')
        .filter('id', 'in', memberIds);
        
    final members = (membersResponse as List).cast<Map<String, dynamic>>();
    final memberIdToUserId = {
      for (var m in members) m['id'] as String: m['user_id'] as String
    };

    // 3. Batch insert notifications
    final notificationsToInsert = <Map<String, dynamic>>[];

    for (final assignment in assignments) {
       final memberId = assignment['member_id'];
       final userId = memberIdToUserId[memberId];
       if (userId == null) continue;

       final teamName = assignment['team_name'];
       final roleName = assignment['role_name'];

       notificationsToInsert.add({
         'user_id': userId,
         'title': 'New Service Assignment',
         'body': 'You have been assigned to $teamName as $roleName for $serviceTitle.',
         'type': 'assignment',
         'related_id': serviceId,
         'is_read': false,
       });
       successCount++;
    }

    if (notificationsToInsert.isNotEmpty) {
       await _client.from('notifications').insert(notificationsToInsert);
    }
    
    return successCount;
  }
}
