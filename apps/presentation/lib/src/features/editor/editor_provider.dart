import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/service_model.dart';

final activeFileProvider = StateProvider<File?>((ref) => null);
final activeProjectProvider = StateProvider<ServiceProject?>((ref) => null);
final activeEditorItemProvider = StateProvider<ServiceItem?>((ref) => null);

/// Display mode for the audience screen: slide content or Bible overlay.
enum DisplayMode { slideContent, bibleOverlay }

/// Provider for current display mode.
final displayModeProvider = StateProvider<DisplayMode>((ref) => DisplayMode.slideContent);

/// Provider for currently projected Bible reference (if in bibleOverlay mode).
final projectedBibleRefProvider = StateProvider<String?>((ref) => null);

class LiveSlideData {
  final String content;
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;
  final int alignment;

  const LiveSlideData({
    required this.content,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.alignment = 1,
  });
  
  Map<String, dynamic> toJson() => {
    'content': content,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderlined': isUnderlined,
    'alignment': alignment,
  };

  factory LiveSlideData.fromJson(Map<String, dynamic> json) => LiveSlideData(
    content: json['content'] as String? ?? '',
    isBold: json['isBold'] as bool? ?? false,
    isItalic: json['isItalic'] as bool? ?? false,
    isUnderlined: json['isUnderlined'] as bool? ?? false,
    alignment: json['alignment'] as int? ?? 1,
  );
}

final liveSlideContentProvider = StateProvider<LiveSlideData>((ref) => const LiveSlideData(content: ''));
