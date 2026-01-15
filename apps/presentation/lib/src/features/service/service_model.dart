import 'dart:convert';

class ServiceItem {
  final String id;
  final String title;
  final String type; // 'song', 'scripture', 'media', 'header'
  final Duration duration;
  final String? songId;
  final String? description;
  final String? artist;
  final String? originalKey;
  final String? assigneeName;

  ServiceItem({
    required this.id,
    required this.title,
    required this.type,
    this.duration = const Duration(minutes: 5),
    this.songId,
    this.description,
    this.artist,
    this.originalKey,
    this.assigneeName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'duration_seconds': duration.inSeconds,
      'song_id': songId,
      'description': description,
      'artist': artist,
      'original_key': originalKey,
      'assignee_name': assigneeName,
    };
  }

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 300),
      songId: json['song_id'] as String?,
      description: json['description'] as String?,
      artist: json['artist'] as String?,
      originalKey: json['original_key'] as String?,
      assigneeName: json['assignee_name'] as String?,
    );
  }
}

class ServiceProject {
  final String title;
  final List<ServiceItem> items;

  ServiceProject({
    required this.title,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory ServiceProject.fromJson(Map<String, dynamic> json) {
    return ServiceProject(
      title: json['title'] as String? ?? 'Untitled Service',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
