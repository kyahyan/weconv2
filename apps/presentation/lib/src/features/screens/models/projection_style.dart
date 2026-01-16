
import 'package:flutter/material.dart';

enum ScaleMode {
  fixed,
  fitToScreen,
  textDown, // Scales down if too large, but respects max size
}

class ProjectionStyle {
  final String fontFamily;
  final double fontSize;
  final TextAlign align;
  final Color fontColor;
  final ScaleMode scaleMode;
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;

  const ProjectionStyle({
    this.fontFamily = 'Roboto',
    this.fontSize = 80.0,
    this.align = TextAlign.center,
    this.fontColor = Colors.white,
    this.scaleMode = ScaleMode.textDown,
    this.isBold = true,
    this.isItalic = false,
    this.isUnderlined = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'align': align.index,
      'fontColor': fontColor.value,
      'scaleMode': scaleMode.index,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderlined': isUnderlined,
    };
  }

  factory ProjectionStyle.fromJson(Map<String, dynamic> json) {
    return ProjectionStyle(
      fontFamily: json['fontFamily'] ?? 'Roboto',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 80.0,
      align: TextAlign.values[json['align'] ?? 2],
      fontColor: Color(json['fontColor'] ?? 0xFFFFFFFF),
      scaleMode: ScaleMode.values[json['scaleMode'] ?? 2],
      isBold: json['isBold'] ?? true,
      isItalic: json['isItalic'] ?? false,
      isUnderlined: json['isUnderlined'] ?? false,
    );
  }

  ProjectionStyle copyWith({
    String? fontFamily,
    double? fontSize,
    TextAlign? align,
    Color? fontColor,
    ScaleMode? scaleMode,
    bool? isBold,
    bool? isItalic,
    bool? isUnderlined,
  }) {
    return ProjectionStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      align: align ?? this.align,
      fontColor: fontColor ?? this.fontColor,
      scaleMode: scaleMode ?? this.scaleMode,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderlined: isUnderlined ?? this.isUnderlined,
    );
  }
}
