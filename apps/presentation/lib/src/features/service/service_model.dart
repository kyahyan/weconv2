import 'dart:convert';

/// Represents a styled range of text within a slide.
class TextStyleRange {
  final int start;
  final int end;
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;
  final int? highlightColor; // ARGB int, null = no highlight
  final int? textColor; // ARGB int, null = default color
  final String? fontFamily; // Font family name, null = default
  final double? fontSize; // Font size in pixels, null = default (8-72 range)

  const TextStyleRange({
    required this.start,
    required this.end,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.highlightColor,
    this.textColor,
    this.fontFamily,
    this.fontSize,
  });

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderlined': isUnderlined,
    'highlightColor': highlightColor,
    'textColor': textColor,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
  };

  factory TextStyleRange.fromJson(Map<String, dynamic> json) => TextStyleRange(
    start: json['start'] as int,
    end: json['end'] as int,
    isBold: json['isBold'] as bool? ?? false,
    isItalic: json['isItalic'] as bool? ?? false,
    isUnderlined: json['isUnderlined'] as bool? ?? false,
    highlightColor: json['highlightColor'] as int?,
    textColor: json['textColor'] as int?,
    fontFamily: json['fontFamily'] as String?,
    fontSize: (json['fontSize'] as num?)?.toDouble(),
  );

  TextStyleRange copyWith({
    int? start,
    int? end,
    bool? isBold,
    bool? isItalic,
    bool? isUnderlined,
    int? highlightColor,
    int? textColor,
    String? fontFamily,
    double? fontSize,
  }) => TextStyleRange(
    start: start ?? this.start,
    end: end ?? this.end,
    isBold: isBold ?? this.isBold,
    isItalic: isItalic ?? this.isItalic,
    isUnderlined: isUnderlined ?? this.isUnderlined,
    highlightColor: highlightColor ?? this.highlightColor,
    textColor: textColor ?? this.textColor,
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
  );
}

class PresentationSlide {
  final String id;
  final String content;
  final String label;
  final int color; // ARGB int
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;
  final int alignment; // 0=left, 1=center, 2=right
  final List<TextStyleRange> styledRanges; // Per-character style ranges

  PresentationSlide({
    required this.id,
    required this.content,
    required this.label,
    required this.color,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.alignment = 1, // Default Center
    this.styledRanges = const [],
  });

  PresentationSlide copyWith({
    String? id,
    String? content,
    String? label,
    int? color,
    bool? isBold,
    bool? isItalic,
    bool? isUnderlined,
    int? alignment,
    List<TextStyleRange>? styledRanges,
  }) {
    return PresentationSlide(
      id: id ?? this.id,
      content: content ?? this.content,
      label: label ?? this.label,
      color: color ?? this.color,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderlined: isUnderlined ?? this.isUnderlined,
      alignment: alignment ?? this.alignment,
      styledRanges: styledRanges ?? this.styledRanges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'label': label,
      'color': color,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderlined': isUnderlined,
      'alignment': alignment,
      'styledRanges': styledRanges.map((r) => r.toJson()).toList(),
    };
  }

  factory PresentationSlide.fromJson(Map<String, dynamic> json) {
    return PresentationSlide(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: json['color'] as int? ?? 0xFF000000,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderlined: json['isUnderlined'] as bool? ?? false,
      alignment: json['alignment'] as int? ?? 1,
      styledRanges: (json['styledRanges'] as List<dynamic>?)
          ?.map((r) => TextStyleRange.fromJson(r as Map<String, dynamic>))
          .toList() ?? const [],
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
