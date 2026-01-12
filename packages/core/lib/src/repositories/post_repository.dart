import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostRepository {
  PostRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Post>> getFeed() async {
    final response = await _client
        .from('posts')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<Post> createPost({required String content}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _client
        .from('posts')
        .insert({
          'content': content,
          'user_id': user.id,
        })
        .select('*, profiles(*)')
        .single();
    
    // Note: The insert might not return the joined profile immediately if the profile isn't fetched. 
    // Usually insert().select() returns the inserted row. 
    // We might need to handle the profile being null initially or fetch it separately. 
    // For simplicity, we trust Supabase or allow null profile in UI locally.
    return Post.fromJson(response);
  }
}
