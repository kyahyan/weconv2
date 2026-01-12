import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SongRepository {
  SongRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Song>> searchSongs(String query) async {
    final response = await _client
        .from('songs')
        .select()
        .ilike('title', '%$query%')
        .limit(20);

    return (response as List).map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Song>> getSongsForService(String serviceId) async {
    final response = await _client
        .from('service_songs')
        .select('*, song:songs(*)')
        .eq('service_id', serviceId)
        .order('order');

    // Supabase returns nested data for joins. 
    // We map the 'song' field to a Song object.
    return (response as List).map((e) {
      final songData = e['song'] as Map<String, dynamic>;
      return Song.fromJson(songData);
    }).toList();
  }
  
  Future<void> addSongToService({
    required String serviceId, 
    required String songId, 
    required int order,
  }) async {
    await _client.from('service_songs').insert({
      'service_id': serviceId,
      'song_id': songId,
      'order': order,
    });
  }
}
