import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:models/models.dart';

class AttendanceRepository {
  final SupabaseClient _client;

  AttendanceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // Record attendance for a single user
  Future<void> recordAttendance(Attendance attendance) async {
    // Delete potential duplicate first to simulate upsert (simpler for now if we don't have UPSERT function)
    /* 
    await _client.from('attendance').delete().match({
      'branch_id': attendance.branchId,
      'user_id': attendance.userId,
      'service_date': attendance.serviceDate.toIso8601String().substring(0, 10),
      'service_type': attendance.serviceType,
    });
    */
    // Actually, let's keep it simple: Try Insert. 
    // But for "Unchecking", we need explicit delete.
    
    await _client.from('attendance').upsert({
      'branch_id': attendance.branchId,
      'user_id': attendance.userId,
      'service_date': attendance.serviceDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'service_type': attendance.serviceType,
      'category': attendance.category,
      'recorded_by': _client.auth.currentUser?.id,
    }, onConflict: 'branch_id, user_id, service_date, service_type'); 
  }

  Future<void> deleteAttendance(String branchId, String userId, DateTime date, String serviceType) async {
     await _client.from('attendance').delete().match({
      'branch_id': branchId,
      'user_id': userId,
      'service_date': date.toIso8601String().substring(0, 10),
      'service_type': serviceType,
    });
  }
  
  // Bulk record/update attendance could be useful, but start with single for now or a loop in UI.

  // Get attendance records for a specific service at a branch
  Future<List<Attendance>> getAttendanceForService(String branchId, DateTime date, String serviceType) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    
    final response = await _client
        .from('attendance')
        .select()
        .eq('branch_id', branchId)
        .eq('service_date', dateStr)
        .eq('service_type', serviceType);
        
    return (response as List).map((e) => Attendance.fromJson(e)).toList();
  }
  
  // Get member history
  Future<List<Attendance>> getMemberAttendanceHistory(String userId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .order('service_date', ascending: false);
        
    return (response as List).map((e) => Attendance.fromJson(e)).toList();
  }
  // Get unique sessions (Date + Service Type) for history listing
  // Returns List of {service_date, service_type}
  Future<List<Map<String, dynamic>>> getAttendanceSessions(String branchId) async {
    final response = await _client
        .from('attendance')
        .select('service_date, service_type')
        .eq('branch_id', branchId)
        .order('service_date', ascending: false)
        .limit(200); // Limit to last 200 records (not sessions, raw rows. We need better distinct later)
    
    // Client-side distinct
    // Or use .csv() ? No. 
    // Ideally we use an RPC for "select distinct service_date, service_type ..."
    // For now, fetch many and dedup.
    
    return List<Map<String, dynamic>>.from(response);
  }
  Future<Map<String, dynamic>> getStatistics(String branchId) async {
    try {
      final response = await _client.rpc('get_attendance_stats', params: {'branch_uuid': branchId});
      return response as Map<String, dynamic>;
    } catch (e) {
      // Fallback or empty if RPC fails (e.g. migration not applied)
      print("Error fetching stats: $e");
      return {};
    }
  }

  Future<void> deleteSession(String branchId, DateTime date, String serviceType) async {
    await _client.rpc('delete_attendance_session', params: {
      'p_branch_id': branchId,
      'p_date': date.toIso8601String().split('T')[0],
      'p_service_type': serviceType,
    });
  }
}
