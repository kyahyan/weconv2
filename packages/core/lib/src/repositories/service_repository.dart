import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceRepository {
  ServiceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Service>> getServices(DateTime start, DateTime end) async {
    final response = await _client
        .from('services')
        .select()
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String())
        .order('date');

    return (response as List).map((e) => Service.fromJson(e)).toList();
  }

  Future<Service> createService({
    required DateTime date,
    required String title,
    String? worshipLeaderId,
  }) async {
    final response = await _client
        .from('services')
        .insert({
          'date': date.toIso8601String(),
          'title': title,
          'worship_leader_id': worshipLeaderId,
        })
        .select()
        .single();

    return Service.fromJson(response);
  }
}
