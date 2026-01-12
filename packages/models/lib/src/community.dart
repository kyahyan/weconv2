import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'community.g.dart';

@JsonSerializable()
class Profile extends Equatable {
  const Profile({
    required this.id,
    this.username,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  final String id;
  final String? username;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  @override
  List<Object?> get props => [id, username, avatarUrl];
}

@JsonSerializable()
class Post extends Equatable {
  const Post({
    required this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
    this.profile,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  final String id;
  final String content;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  // Create profile from 'profiles' key in JSON (Supabase join)
  @JsonKey(readValue: _readProfile)
  final Profile? profile;

  static Map<String, dynamic>? _readProfile(Map map, String key) {
    if (map['profiles'] != null) {
      return map['profiles'] as Map<String, dynamic>;
    }
    return null;
  }

  Map<String, dynamic> toJson() => _$PostToJson(this);

  @override
  List<Object?> get props => [id, content, userId, createdAt, profile];
}

@JsonSerializable()
class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.profile,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  final String id;
  @JsonKey(name: 'post_id')
  final String postId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(readValue: _readProfile)
  final Profile? profile;

   static Map<String, dynamic>? _readProfile(Map map, String key) {
    if (map['profiles'] != null) {
      return map['profiles'] as Map<String, dynamic>;
    }
    return null;
  }

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  @override
  List<Object?> get props => [id, postId, userId, content, createdAt, profile];
}
