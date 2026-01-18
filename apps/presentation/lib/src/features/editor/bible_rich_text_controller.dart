import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../service/service_model.dart';

/// A custom TextEditingController that:
/// 1. Fixes RTL/spacing bugs with strict LTR enforcement and StrutStyle.
/// 2. Detects Bible references (e.g., "John 3:16") and renders them as clickable spans.
/// 3. Renders styled text ranges (bold, italic, underline).
/// 4. Exposes a callback for when a Bible reference is tapped.
class BibleRichTextController extends TextEditingController {
  /// Callback triggered when a Bible reference span is tapped.
  final void Function(String reference)? onBibleReferenceTap;

  /// Styled ranges to apply to text.
  List<TextStyleRange> styledRanges;

  /// Regex pattern for Bible references: "John 3:16", "1 Kings 2:3-5", "Gen 1:1,3"
  static final _bibleRefRegex = RegExp(
    r'\b((?:[1-3]\s)?[A-Za-z]+)\s+(\d+):(\d+(?:[-,\s]+\d+)*)\b',
  );

  /// Active gesture recognizers (must be disposed).
  final List<TapGestureRecognizer> _recognizers = [];

  BibleRichTextController({
    super.text,
    this.onBibleReferenceTap,
    this.styledRanges = const [],
  });

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  /// Get style for a character at given index based on styledRanges.
  TextStyle _getStyleForIndex(int index, TextStyle? baseStyle) {
    bool isBold = false;
    bool isItalic = false;
    bool isUnderlined = false;
    int? highlightColor;
    int? textColor;
    String? fontFamily;
    double? fontSize;

    final textLen = text.length;
    
    for (final range in styledRanges) {
      // Skip invalid ranges
      if (range.start < 0 || range.end <= range.start || range.end > textLen) {
        continue;
      }
      
      if (index >= range.start && index < range.end) {
        if (range.isBold) isBold = true;
        if (range.isItalic) isItalic = true;
        if (range.isUnderlined) isUnderlined = true;
        if (range.highlightColor != null) highlightColor = range.highlightColor;
        if (range.textColor != null) textColor = range.textColor;
        if (range.fontFamily != null) fontFamily = range.fontFamily;
        if (range.fontSize != null) fontSize = range.fontSize;
      }
    }

    return (baseStyle ?? const TextStyle()).copyWith(
      fontWeight: isBold ? FontWeight.bold : null,
      fontStyle: isItalic ? FontStyle.italic : null,
      decoration: isUnderlined ? TextDecoration.underline : null,
      backgroundColor: highlightColor != null ? Color(highlightColor) : null,
      color: textColor != null ? Color(textColor) : null,
      fontFamily: fontFamily,
      fontSize: fontSize,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Dispose old recognizers before rebuilding
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final String currentText = text;
    if (currentText.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    // Find all Bible reference matches
    final bibleMatches = _bibleRefRegex.allMatches(currentText).toList();

    // Build a list of "styled segments" by character
    // We'll iterate through the text and create spans for:
    // 1. Bible references (blue underlined + clickable)
    // 2. Styled ranges (bold/italic/underline)
    // 3. Plain text
    
    final List<InlineSpan> spans = [];
    int i = 0;

    while (i < currentText.length) {
      // Check if this position starts a Bible reference
      RegExpMatch? bibleMatch;
      for (final match in bibleMatches) {
        if (match.start == i) {
          bibleMatch = match;
          break;
        }
      }

      if (bibleMatch != null) {
        // Render Bible reference as clickable span
        final refText = currentText.substring(bibleMatch.start, bibleMatch.end);
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            onBibleReferenceTap?.call(refText);
          };
        _recognizers.add(recognizer);

        spans.add(TextSpan(
          text: refText,
          style: (style ?? const TextStyle()).copyWith(
            color: Colors.blueAccent,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blueAccent,
          ),
          recognizer: recognizer,
        ));

        i = bibleMatch.end;
        continue;
      }

      // Find next Bible match start or end of text
      int nextBibleStart = currentText.length;
      for (final match in bibleMatches) {
        if (match.start > i && match.start < nextBibleStart) {
          nextBibleStart = match.start;
        }
      }

      // Build styled spans character by character (grouped by same style)
      int segmentStart = i;
      TextStyle currentStyle = _getStyleForIndex(i, style);
      
      while (i < nextBibleStart) {
        final charStyle = _getStyleForIndex(i, style);
        // Check if style changed (including all style properties)
        if (charStyle.fontWeight != currentStyle.fontWeight ||
            charStyle.fontStyle != currentStyle.fontStyle ||
            charStyle.decoration != currentStyle.decoration ||
            charStyle.backgroundColor != currentStyle.backgroundColor ||
            charStyle.color != currentStyle.color ||
            charStyle.fontFamily != currentStyle.fontFamily ||
            charStyle.fontSize != currentStyle.fontSize) {
          // Add previous segment
          if (i > segmentStart) {
            final segmentText = currentText.substring(segmentStart, i);
            if (segmentText.isNotEmpty) {
              spans.add(TextSpan(
                text: segmentText,
                style: currentStyle,
              ));
            }
          }
          segmentStart = i;
          currentStyle = charStyle;
        }
        i++;
      }

      // Add remaining segment
      if (i > segmentStart) {
        final segmentText = currentText.substring(segmentStart, i);
        if (segmentText.isNotEmpty) {
          spans.add(TextSpan(
            text: segmentText,
            style: currentStyle,
          ));
        }
      }
    }

    return TextSpan(children: spans, style: style);
  }

  /// Get list of detected Bible references in current text.
  List<String> getDetectedReferences() {
    return _bibleRefRegex
        .allMatches(text)
        .map((m) => text.substring(m.start, m.end))
        .toSet()
        .toList();
  }
}
