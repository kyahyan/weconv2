import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  /// Manually notifies all members assigned to a service.
  /// Fetches assignments (Roster) AND Service Items (Plan) and inserts notifications.
  /// Sends granular notifications for each specific assignment.
  Future<int> notifyTeam(String serviceId, String serviceTitle, DateTime serviceDate) async {
    final formattedDate = DateFormat('MMM d, h:mm a').format(serviceDate.toLocal());

    // 1. Fetch all assignments for this service (ROSTER)
    final assignmentsResponse = await _client
        .from('service_assignments')
        .select('member_id, team_name, role_name')
        .eq('service_id', serviceId);
    
    final assignments = (assignmentsResponse as List).cast<Map<String, dynamic>>();
    final rosterMemberIds = assignments.map((a) => a['member_id'] as String).toSet();

    // 2. Fetch all service items with assignments (PLAN)
    final itemsResponse = await _client
        .from('service_items')
        .select('title, assigned_to')
        .eq('service_id', serviceId)
        .not('assigned_to', 'is', null);

    final planItems = (itemsResponse as List).cast<Map<String, dynamic>>(); // Need this for loop
    final planMemberIds = planItems.map((i) => i['assigned_to'] as String).toSet();

    // Combine unique member IDs for lookup
    final allMemberIds = {...rosterMemberIds, ...planMemberIds};

    if (allMemberIds.isEmpty) return 0;

    // 3. Resolve member_id -> user_id for ALL members
    final membersResponse = await _client
        .from('organization_members')
        .select('id, user_id')
        .filter('id', 'in', allMemberIds.toList());
        
    final members = (membersResponse as List).cast<Map<String, dynamic>>();
    
    // Create map for easy lookup
    final memberIdToUserId = {
      for (var m in members) m['id'] as String: m['user_id'] as String
    };

    // 4. Batch insert notifications
    final notificationsToInsert = <Map<String, dynamic>>[];

    // A. Roster Notifications
    for (var a in assignments) {
      final userId = memberIdToUserId[a['member_id']];
      if (userId != null) {
        notificationsToInsert.add({
           'user_id': userId,
           'title': 'New Service Assignment',
           'body': 'You have been assigned as ${a['role_name']} (${a['team_name']}) for $serviceTitle on $formattedDate.',
           'type': 'assignment',
           'related_id': serviceId,
           'is_read': false,
        });
      }
    }

    // B. Plan Item Notifications
    for (var item in planItems) {
      final userId = memberIdToUserId[item['assigned_to']];
      if (userId != null) {
        notificationsToInsert.add({
           'user_id': userId,
           'title': 'New Service Duty',
           'body': 'You have been assigned to "${item['title']}" for $serviceTitle on $formattedDate.',
           'type': 'assignment',
           'related_id': serviceId,
           'is_read': false,
        });
      }
    }

    if (notificationsToInsert.isNotEmpty) {
       await _client.from('notifications').insert(notificationsToInsert);
    }
    
    // Return count of unique members notified
    return allMemberIds.where((id) => memberIdToUserId.containsKey(id)).length;
  }
}
