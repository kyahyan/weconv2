import 'dart:io';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Activity>> getActivities(DateTime start, DateTime end, {List<String>? orgIds, String? branchId}) async {
    var query = _client
        .from('activities')
        .select()
        .gte('start_time', start.toIso8601String())
        .lte('start_time', end.toIso8601String());

    if (orgIds != null && orgIds.isNotEmpty) {
      query = query.filter('organization_id', 'in', orgIds);
    }
    
    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final response = await query.order('start_time', ascending: true);
    
    return (response as List).map((json) => Activity.fromJson(json)).toList();
  }

  Future<void> createActivity(Activity activity, File? imageFile, {String? orgId, String? branchId}) async {
    String? imageUrl = activity.imageUrl;

    if (imageFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split(Platform.pathSeparator).last}';
      await _client.storage.from('activity_images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      imageUrl = _client.storage.from('activity_images').getPublicUrl(fileName);
    }

    await _client.from('activities').insert({
      'title': activity.title,
      'description': activity.description,
      'start_time': activity.startTime.toUtc().toIso8601String(),
      'end_time': activity.endTime.toUtc().toIso8601String(),
      'location': activity.location,
      'image_url': imageUrl,
      'is_registration_required': activity.isRegistrationRequired,
      'form_config': activity.formConfig?.toJson(),
      if (orgId != null) 'organization_id': orgId,
      if (branchId != null) 'branch_id': branchId,
    });
  }

  Future<void> updateActivity(Activity activity, File? imageFile) async {
    String? imageUrl = activity.imageUrl;

    if (imageFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split(Platform.pathSeparator).last}';
      await _client.storage.from('activity_images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      imageUrl = _client.storage.from('activity_images').getPublicUrl(fileName);
    }

    await _client.from('activities').update({
      'title': activity.title,
      'description': activity.description,
      'start_time': activity.startTime.toUtc().toIso8601String(),
      'end_time': activity.endTime.toUtc().toIso8601String(),
      'location': activity.location,
      'image_url': imageUrl,
      'is_registration_required': activity.isRegistrationRequired,
      'form_config': activity.formConfig?.toJson(),
    }).eq('id', activity.id);
  }

  Future<void> deleteActivity(String id) async {
    await _client.from('activities').delete().eq('id', id);
  }

  // -----------------------------------------------------------------------------
  // Registrations
  // -----------------------------------------------------------------------------

  Future<List<ActivityRegistration>> getRegistrations(String activityId) async {
    final response = await _client
        .from('activity_registrations')
        .select()
        .eq('activity_id', activityId)
        .order('created_at', ascending: false);
        
    return (response as List).map((json) => ActivityRegistration.fromJson(json)).toList();
  }

  Future<void> createRegistration(ActivityRegistration registration) async {
    await _client.from('activity_registrations').insert(registration.toJson());
  }

  Future<void> updateRegistrationStatus(String registrationId, String status) async {
    await _client
        .from('activity_registrations')
        .update({'status': status})
        .eq('id', registrationId);
  }

  Future<ActivityRegistration?> getUserRegistration(String activityId, String userId) async {
    final response = await _client
        .from('activity_registrations')
        .select()
        .eq('activity_id', activityId)
        .eq('user_id', userId)
        .maybeSingle();
    
    return response != null ? ActivityRegistration.fromJson(response) : null;
  }


}
