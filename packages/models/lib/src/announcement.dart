import 'package:equatable/equatable.dart';

class Announcement extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String organizationId;
  final String? branchId;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.organizationId,
    this.branchId,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      organizationId: json['organization_id'] as String,
      branchId: json['branch_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'organization_id': organizationId,
      'branch_id': branchId,
    };
  }

  @override
  List<Object?> get props => [id, title, content, createdAt, organizationId, branchId];
}
