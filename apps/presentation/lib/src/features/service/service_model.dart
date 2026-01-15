import 'dart:convert';

class PresentationSlide {
  final String id;
  final String content;
  final String label;
  final int color; // ARGB int

  PresentationSlide({
    required this.id,
    required this.content,
    required this.label,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'label': label,
      'color': color,
    };
  }

  factory PresentationSlide.fromJson(Map<String, dynamic> json) {
    return PresentationSlide(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: json['color'] as int? ?? 0xFF000000,
    );
  }
}

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
  final List<PresentationSlide> slides;

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
    this.slides = const [],
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
      'slides': slides.map((e) => e.toJson()).toList(),
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
      slides: (json['slides'] as List<dynamic>?)
              ?.map((e) => PresentationSlide.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  ServiceItem copyWith({
    String? id,
    String? title,
    String? type,
    Duration? duration,
    String? songId,
    String? description,
    String? artist,
    String? originalKey,
    String? assigneeName,
    List<PresentationSlide>? slides,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      songId: songId ?? this.songId,
      description: description ?? this.description,
      artist: artist ?? this.artist,
      originalKey: originalKey ?? this.originalKey,
      assigneeName: assigneeName ?? this.assigneeName,
      slides: slides ?? this.slides,
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
