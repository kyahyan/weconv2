import 'package:uuid/uuid.dart';
import '../service/service_model.dart';
import 'package:flutter/material.dart';

class LyricsParser {
  static const Uuid _uuid = Uuid();

  /// Parses raw lyrics text into a list of [PresentationSlide]s.
  /// Splits content into chunks of 3 lines max.
  /// Detects sections like [Verse 1], [Chorus] to apply labels.
  static List<PresentationSlide> parse(String rawLyrics) {
    print('DEBUG: Parsing lyrics. Length: ${rawLyrics.length}');
    if (rawLyrics.isEmpty) return [];

    final slides = <PresentationSlide>[];
    final lines = rawLyrics.split('\n');
    
    String currentLabel = '';
    int currentColor = 0xFF333333;
    List<String> currentChunk = [];

    void flushChunk() {
      if (currentChunk.isEmpty) return;
      
      slides.add(PresentationSlide(
        id: _uuid.v4(),
        content: currentChunk.join('\n'),
        label: currentLabel,
        color: currentColor,
      ));
      currentChunk = [];
    }

    for (var i = 0; i < lines.length; i++) {
       String line = lines[i].trim();
       if (line.isEmpty) {
         // Empty lines can force a flush if we want to respect paragraph breaks
         if (currentChunk.isNotEmpty) flushChunk();
         continue;
       }

       // Check for header
       // e.g. "Verse 1", "[Chorus]", "Bridge:"
       if (_isHeader(line)) {
          flushChunk(); // Start new section
          _SectionInfo info = _parseHeader(line);
          currentLabel = info.label;
          currentColor = info.color;
          continue; // Don't add header itself to lyrics
       }

       currentChunk.add(line);

       // Max lines per slide
       if (currentChunk.length >= 3) {
          flushChunk();
       }
    }

    // flushing remaining
    flushChunk();

    print('DEBUG: Generated ${slides.length} slides from lyrics.');
    return slides;
  }

  static bool _isHeader(String line) {
     // Naive heuristic: short line, maybe brackets, common words
     final l = line.toLowerCase();
     if (l.startsWith('[') && l.endsWith(']')) return true;
     if (l.endsWith(':')) return true;
     
     // Common keywords
     const keywords = ['verse', 'chorus', 'bridge', 'outro', 'pre-chorus', 'intro', 'refrain'];
     for (var k in keywords) {
        if (l.startsWith(k)) return true;
     }

     return false;
  }

  static _SectionInfo _parseHeader(String line) {
     String clean = line.replaceAll(RegExp(r'[\[\]\:]'), '').trim();
     
     int color = 0xFF333333; // Default Dark Gray
     
     final l = clean.toLowerCase();
     if (l.contains('verse')) color = Colors.blue.value;
     else if (l.contains('chorus')) color = Colors.red.value;
     else if (l.contains('bridge')) color = Colors.purple.value;
     else if (l.contains('outro')) color = Colors.orange.value;
     else if (l.contains('pre')) color = Colors.teal.value;
     
     return _SectionInfo(clean, color);
  }
}

class _SectionInfo {
  final String label;
  final int color;
  _SectionInfo(this.label, this.color);
}
