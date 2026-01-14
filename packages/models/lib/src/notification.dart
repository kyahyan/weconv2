import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class UserNotification extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String title;
  final String body;
  final String type;
  @JsonKey(name: 'related_id')
  final String? relatedId;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) =>
      _$UserNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$UserNotificationToJson(this);

  UserNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return UserNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, body, type, relatedId, isRead, createdAt];
}
