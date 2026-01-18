import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_provider.dart';
import 'bible_rich_text_controller.dart';
import '../service/service_model.dart';
import '../bible/bible_repository.dart';
import '../bible/bible_model.dart';
import '../screens/models/screen_model.dart';
import '../screens/repositories/screen_repository.dart';
import '../screens/services/projection_window_manager.dart';


class PresentationEditorControls extends ConsumerStatefulWidget {
  final int selectedSlideIndex;

  const PresentationEditorControls({
    super.key,
    required this.selectedSlideIndex,
  });

  @override
  ConsumerState<PresentationEditorControls> createState() => _PresentationEditorControlsState();
}

class _PresentationEditorControlsState extends ConsumerState<PresentationEditorControls> {
  late BibleRichTextController _textController;
  ServiceItem? _activeItem;
  int? _lastSlideIndex;
  List<String> _detectedVerses = [];
  String? _projectedVerseRef; // Tracks if we are currently overriding with a verse
  
  // Undo/Redo History
  final List<_EditorState> _undoStack = [];
  final List<_EditorState> _redoStack = [];
  bool _isUndoRedoAction = false;
  final FocusNode _editorFocusNode = FocusNode();
  
  // Bible Settings
  String _selectedLanguage = 'English';
  String? _selectedVersionId;
  final ScrollController _versesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController = BibleRichTextController(
      onBibleReferenceTap: _onBibleReferenceTap,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _versesScrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PresentationEditorControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If index changed, we must update text, BUT we should also check if the active item changed in build
  }

  /// Callback for when a Bible reference is tapped in the text field.
  void _onBibleReferenceTap(String reference) {
    _toggleProjectVerse(reference);
  }

  void _syncToProject(ServiceItem updatedItem) {
     // Update the item provider
     ref.read(activeEditorItemProvider.notifier).state = updatedItem;
     
     // Update the project provider
     final currentProject = ref.read(activeProjectProvider);
     if (currentProject != null) {
        final newItems = currentProject.items.map((item) {
           return item.id == updatedItem.id ? updatedItem : item;
        }).toList();
        
        final updatedProject = ServiceProject(title: currentProject.title, items: newItems);
        ref.read(activeProjectProvider.notifier).state = updatedProject;
     }
  }

  void _pushUndoState(String content, List<TextStyleRange> ranges) {
     _undoStack.add(_EditorState(
        content: content,
        styledRanges: List.from(ranges),
     ));
     if (_undoStack.length > 50) _undoStack.removeAt(0);
     _redoStack.clear();
  }

  void _undo() {
     if (_undoStack.isEmpty || _activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final current = _activeItem!.slides[widget.selectedSlideIndex];
     _redoStack.add(_EditorState(content: current.content, styledRanges: List.from(current.styledRanges)));
     
     final prevState = _undoStack.removeLast();
     _isUndoRedoAction = true;
     _textController.text = prevState.content;
     _textController.styledRanges = prevState.styledRanges;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     slides[widget.selectedSlideIndex] = current.copyWith(content: prevState.content, styledRanges: prevState.styledRanges);
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     _isUndoRedoAction = false;
     setState(() {});
  }

  void _redo() {
     if (_redoStack.isEmpty || _activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final current = _activeItem!.slides[widget.selectedSlideIndex];
     _undoStack.add(_EditorState(content: current.content, styledRanges: List.from(current.styledRanges)));
     
     final nextState = _redoStack.removeLast();
     _isUndoRedoAction = true;
     _textController.text = nextState.content;
     _textController.styledRanges = nextState.styledRanges;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     slides[widget.selectedSlideIndex] = current.copyWith(content: nextState.content, styledRanges: nextState.styledRanges);
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     _isUndoRedoAction = false;
     setState(() {});
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
     if (event is KeyDownEvent) {
        final isCtrl = HardwareKeyboard.instance.isControlPressed;
        final isShift = HardwareKeyboard.instance.isShiftPressed;
        
        if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
           if (isShift) {
              _redo();
           } else {
              _undo();
           }
           return KeyEventResult.handled;
        }
        if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) {
           _redo();
           return KeyEventResult.handled;
        }
     }
     return KeyEventResult.ignored;
  }

  void _onTextChanged(String value) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;

     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final currentSlide = slides[widget.selectedSlideIndex];
     
     if (currentSlide.content == value) return; // No change
     
     // Push to undo stack (unless this is an undo/redo action)
     if (!_isUndoRedoAction) {
        _pushUndoState(currentSlide.content, currentSlide.styledRanges);
     }

     final oldText = currentSlide.content;
     final newText = value;
     final lengthDiff = newText.length - oldText.length;
     
     // Determine where the change occurred based on cursor position
     final cursorPos = _textController.selection.baseOffset;
     // The change point is where the cursor was before the change
     // For insertion: cursor - lengthDiff is where text was inserted
     // For deletion: cursor is where text was deleted
     final changePoint = lengthDiff > 0 ? cursorPos - lengthDiff : cursorPos;
     
     List<TextStyleRange> adjustedRanges = [];
     
     for (final range in currentSlide.styledRanges) {
        int newStart = range.start;
        int newEnd = range.end;
        
        if (lengthDiff > 0) {
           // Text was inserted
           if (changePoint <= range.start) {
              // Insertion before range - shift entire range
              newStart += lengthDiff;
              newEnd += lengthDiff;
           } else if (changePoint > range.start && changePoint <= range.end) {
              // Insertion inside range (or at end) - expand range
              newEnd += lengthDiff;
           }
           // Insertion after range - no change needed
        } else if (lengthDiff < 0) {
           // Text was deleted
           final deleteStart = changePoint;
           final deleteEnd = changePoint - lengthDiff; // -lengthDiff is positive
           
           if (deleteEnd <= range.start) {
              // Deletion before range - shift entire range
              newStart += lengthDiff;
              newEnd += lengthDiff;
           } else if (deleteStart >= range.end) {
              // Deletion after range - no change needed
           } else {
              // Deletion overlaps with range
              if (deleteStart <= range.start && deleteEnd >= range.end) {
                 // Entire range was deleted
                 newStart = 0;
                 newEnd = 0;
              } else if (deleteStart <= range.start) {
                 // Delete from before range into range
                 newStart = deleteStart;
                 newEnd = range.end + lengthDiff;
              } else if (deleteEnd >= range.end) {
                 // Delete from inside range to after
                 newEnd = deleteStart;
              } else {
                 // Delete entirely within range
                 newEnd = range.end + lengthDiff;
              }
           }
        }
        
        // Clamp to valid bounds
        newStart = newStart.clamp(0, newText.length);
        newEnd = newEnd.clamp(0, newText.length);
        
        // Only keep valid ranges
        if (newStart < newEnd) {
           adjustedRanges.add(TextStyleRange(
              start: newStart,
              end: newEnd,
              isBold: range.isBold,
              isItalic: range.isItalic,
              isUnderlined: range.isUnderlined,
              highlightColor: range.highlightColor,
              textColor: range.textColor,
              fontFamily: range.fontFamily,
              fontSize: range.fontSize,
           ));
        }
     }

     slides[widget.selectedSlideIndex] = PresentationSlide(
        id: currentSlide.id,
        content: value,
        label: currentSlide.label,
        color: currentSlide.color,
        styledRanges: adjustedRanges,
     );

     final updatedItem = _activeItem!.copyWith(slides: slides);
     
     // Update controller's styledRanges immediately
     _textController.styledRanges = adjustedRanges;
     
     
     _syncToProject(updatedItem);
     
     
      // Detect Bible References
      _parseBibleReferences(updatedItem);
   }

  void _parseBibleReferences([ServiceItem? item]) {
     // Use provided item or fall back to active
     final targetItem = item ?? _activeItem;
     if (targetItem == null) return;

     // Aggregate text from all slides
     final allText = targetItem.slides.map((s) => s.content).join('\n');

     // Regex for [Number?] [Name] [Chapter]:[VerseRange]
     // e.g. Genesis 1:1, John 3:16-20, Rom 1:1,3,5
     final regex = RegExp(r'\b((?:[1-3]\s)?[A-Za-z]+)\s+(\d+):(\d+(?:[-,\s]+\d+)*)\b');
     final matches = regex.allMatches(allText);
     
     final found = matches.map((m) => allText.substring(m.start, m.end)).toSet().toList();
     
     if (found.length != _detectedVerses.length || !found.every((e) => _detectedVerses.contains(e))) {
        setState(() {
           _detectedVerses = found;
        });
        
        // Auto-load data if we found verses and data is missing
        if (found.isNotEmpty) {
           final repo = ref.read(bibleRepositoryProvider);
           if (repo.getVersions().isEmpty) {
              repo.loadBibleData().then((_) {
                 if (mounted) setState(() {}); // Refresh to populate dropdowns
              });
           }
        }
     }
  }

  // Helper to parse "1-3, 5" into [1, 2, 3, 5]
  List<int> _parseVerseList(String verseString) {
     final result = <int>{};
     final parts = verseString.split(RegExp(r'[,;]'));
     
     for (var part in parts) {
        part = part.trim();
        if (part.isEmpty) continue;
        
        if (part.contains('-')) {
           final range = part.split('-');
           if (range.length == 2) {
              final start = int.tryParse(range[0].trim()) ?? 0;
              final end = int.tryParse(range[1].trim()) ?? 0;
              if (start > 0 && end >= start) {
                 for (var i = start; i <= end; i++) result.add(i);
              }
           }
        } else {
           final val = int.tryParse(part);
           if (val != null) result.add(val);
        }
     }
     return result.toList()..sort();
  }

  Future<void> _restoreSlide() async {
     final currentText = _textController.text;
     if (_activeItem != null && widget.selectedSlideIndex >= 0) {
        final s = _activeItem!.slides[widget.selectedSlideIndex];
        ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(
           content: currentText,
           isBold: s.isBold,
           isItalic: s.isItalic,
           isUnderlined: s.isUnderlined,
           alignment: s.alignment,
        );
     } else {
        ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(content: currentText); 
     }
     
     setState(() {
        _projectedVerseRef = null;
     });
  }

  Future<String?> _resolveVerseContent(String refString) async {
     final repo = ref.read(bibleRepositoryProvider);
     
     // Ensure data loaded
     if (repo.getVersions().isEmpty) {
          // If we are resolving content, we need to wait or fail if data isn't there.
          // Since this might be called from context menu, let's try to load if missing.
          await repo.loadBibleData();
          if (mounted) setState(() {});
     }
     
     final versions = repo.getVersions();
     if (versions.isEmpty) return null; // Failed to load
     
     final targetVersionId = _selectedVersionId ?? 
        (versions.isNotEmpty ? versions.firstWhere((v) => v.language == _selectedLanguage, orElse: () => versions.first).id : null);
        
     // Parse refString locally to handle ranges
     final regex = RegExp(r'\b((?:[1-3]\s)?[A-Za-z]+)\s+(\d+):(\d+(?:[-,\s]+\d+)*)\b');
     final match = regex.firstMatch(refString);
     
     if (match != null) {
        final bookRaw = match.group(1)!;
        final chapter = int.parse(match.group(2)!);
        final versesRaw = match.group(3)!;
        final targetVerses = _parseVerseList(versesRaw);
        
        final probeRef = "$bookRaw $chapter:${targetVerses.first}";
        final searchResults = repo.searchVerses(probeRef, versionId: targetVersionId);
        
        if (searchResults.isNotEmpty) {
           final firstVerse = searchResults.first;
           final bookName = firstVerse.bookName;
           final version = versions.firstWhere((v) => v.id == targetVersionId, orElse: () => versions.first);
           final fullBookName = repo.getBookFullName(bookName);
           
           final allChapterVerses = repo.getVerses(version.abbreviation, bookName, chapter);
           final selectedVerses = allChapterVerses.where((v) => targetVerses.contains(v.verse)).toList();
           
           if (selectedVerses.isNotEmpty) {
              final plainText = selectedVerses.map((v) => v.text).join(" ");
              final header = "$fullBookName $chapter:$versesRaw (${version.abbreviation})";
              return "$header\n$plainText";
           }
        }
     }
     return null;
  }

  Future<void> _projectVerse(String refString) async {
     final content = await _resolveVerseContent(refString);
     if (content != null) {
        ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(
           content: content,
           alignment: 1, // Center
           isBold: true,
        );
        
        setState(() {
           _projectedVerseRef = refString;
        });
     } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verse not found in database')));
     }
  }

  Future<void> _toggleProjectVerse(String refString) async {
     if (_projectedVerseRef == refString) {
        await _restoreSlide();
     } else {
        await _projectVerse(refString);
     }
  }

  void _splitSlide() {
     if (_activeItem == null || widget.selectedSlideIndex < 0) return;
     
     final text = _textController.text;
     final selection = _textController.selection;
     
     if (selection.baseOffset < 0 || selection.baseOffset >= text.length) {
        // No selection/cursor? Just assume split at end? Or do nothing?
        // Let's do nothing if no cursor.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place cursor where you want to split.')));
        return;
     }

     final splitIndex = selection.baseOffset;
     final textBefore = text.substring(0, splitIndex).trim();
     final textAfter = text.substring(splitIndex).trim();
     
     if (textAfter.isEmpty) return; // Nothing to move to new slide

     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final currentSlide = slides[widget.selectedSlideIndex];
     
     // Update current slide
     slides[widget.selectedSlideIndex] = PresentationSlide(
        id: currentSlide.id,
        content: textBefore,
        label: currentSlide.label,
        color: currentSlide.color,
     );
     
     // Create new slide
     // For ID, we need uuid. Importing Uuid package or just using random if not available.
     // Assuming Uuid is available since used elsewhere, but need import.
     // If import missing, I'll use simple datetime fallback or need to add import.
     // Let's rely on standard import or duplicate Uuid logic.
     // Actually, let's use a simpler unique generator or assume Uuid is imported.
     // I'll check imports first.
     // Adding import locally in replacement if needed? 
     // I'll use standard DateTime for now to avoid import mess in this tool call, 
     // OR better, I will include the import in this same multi_replace.
     
     final newSlide = PresentationSlide(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID
        content: textAfter,
        label: currentSlide.label, // Inherit label
        color: currentSlide.color, // Inherit color
     );
     
     slides.insert(widget.selectedSlideIndex + 1, newSlide);
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
  }

  void _toggleBold() => _updateStyle((s) => s.copyWith(isBold: !s.isBold));
  void _toggleItalic() => _updateStyle((s) => s.copyWith(isItalic: !s.isItalic));
  void _toggleUnderline() => _updateStyle((s) => s.copyWith(isUnderlined: !s.isUnderlined));
  void _setAlignment(int align) => _updateStyle((s) => s.copyWith(alignment: align));

  void _updateStyle(PresentationSlide Function(PresentationSlide) updater) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;

     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     slides[widget.selectedSlideIndex] = updater(slides[widget.selectedSlideIndex]);

     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
  }

  // Helper extension for copyWith on Slide since we added fields but maybe didn't generate copyWith in model?
  // Wait, service_model.dart used manual JSON. Does it have copyWith?
  // I need to check service_model.dart again or just construct new instance.
  // Actually service_model.dart has NO copyWith for PresentationSlide. I must construct it manually.
  // Let's implement _updateStyle using manual construction to be safe.
  
  // Re-implementing _updateStyle properly without copyWith on Slide
  /*
  void _updateStyle(PresentationSlide Function(PresentationSlide) updater) { ... }
  */
  // Actually, let's redefine updater to just take current and return new.
  // But since I can't call copyWith on PresentationSlide, I'll do it manually inside helper.
  
  void _updateSlideStyle({bool? isBold, bool? isItalic, bool? isUnderlined, int? alignment}) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;

     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final current = slides[widget.selectedSlideIndex];
     
     // If alignment is being set, apply to entire slide (not per-range)
     if (alignment != null) {
        slides[widget.selectedSlideIndex] = current.copyWith(alignment: alignment);
        final updatedItem = _activeItem!.copyWith(slides: slides);
        _syncToProject(updatedItem);
        return;
     }
     
     // Check if text is selected
     final selection = _textController.selection;
     
     if (selection.isCollapsed || selection.start == selection.end) {
        // No selection - apply style to entire slide (fallback behavior)
        slides[widget.selectedSlideIndex] = current.copyWith(
           isBold: isBold ?? current.isBold,
           isItalic: isItalic ?? current.isItalic,
           isUnderlined: isUnderlined ?? current.isUnderlined,
        );
     } else {
        // Text is selected - toggle style on the TextStyleRange
        final start = selection.start;
        final end = selection.end;
        
        // Check if there's an existing range that exactly matches this selection
        final existingIdx = current.styledRanges.indexWhere((r) => r.start == start && r.end == end);
        
        List<TextStyleRange> updatedRanges;
        
        if (existingIdx >= 0) {
           // Range exists - toggle the specific style
           final existing = current.styledRanges[existingIdx];
           final toggledRange = TextStyleRange(
              start: start,
              end: end,
              isBold: isBold != null ? !existing.isBold : existing.isBold,
              isItalic: isItalic != null ? !existing.isItalic : existing.isItalic,
              isUnderlined: isUnderlined != null ? !existing.isUnderlined : existing.isUnderlined,
           );
           
           // If all styles are now false, remove the range entirely
           if (!toggledRange.isBold && !toggledRange.isItalic && !toggledRange.isUnderlined) {
              updatedRanges = List<TextStyleRange>.from(current.styledRanges)..removeAt(existingIdx);
           } else {
              updatedRanges = List<TextStyleRange>.from(current.styledRanges);
              updatedRanges[existingIdx] = toggledRange;
           }
        } else {
           // No exact match - create new range with the requested style
           final newRange = TextStyleRange(
              start: start,
              end: end,
              isBold: isBold ?? false,
              isItalic: isItalic ?? false,
              isUnderlined: isUnderlined ?? false,
           );
           updatedRanges = List<TextStyleRange>.from(current.styledRanges)..add(newRange);
        }
        
        slides[widget.selectedSlideIndex] = current.copyWith(styledRanges: updatedRanges);
        
        // Update controller's styledRanges immediately for visual feedback
        _textController.styledRanges = updatedRanges;
     }

     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     
     // Force rebuild to show styled text
     setState(() {});
  }

  void _applyHighlight(int colorValue) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final selection = _textController.selection;
     if (selection.isCollapsed || selection.start == selection.end) return;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final current = slides[widget.selectedSlideIndex];
     final start = selection.start;
     final end = selection.end;
     
     // Check for existing range at this position
     final existingIdx = current.styledRanges.indexWhere((r) => r.start == start && r.end == end);
     
     List<TextStyleRange> updatedRanges;
     
     if (existingIdx >= 0) {
        // Range exists - update or toggle highlight
        final existing = current.styledRanges[existingIdx];
        if (colorValue == 0) {
           // Remove highlight but keep other styles
           final updatedRange = TextStyleRange(
              start: existing.start,
              end: existing.end,
              isBold: existing.isBold,
              isItalic: existing.isItalic,
              isUnderlined: existing.isUnderlined,
              highlightColor: null,
           );
           // If no styles left, remove range
           if (!updatedRange.isBold && !updatedRange.isItalic && !updatedRange.isUnderlined) {
              updatedRanges = List<TextStyleRange>.from(current.styledRanges)..removeAt(existingIdx);
           } else {
              updatedRanges = List<TextStyleRange>.from(current.styledRanges);
              updatedRanges[existingIdx] = updatedRange;
           }
        } else {
           updatedRanges = List<TextStyleRange>.from(current.styledRanges);
           updatedRanges[existingIdx] = existing.copyWith(highlightColor: colorValue);
        }
     } else {
        // No exact match - create new range with highlight
        if (colorValue == 0) return; // Nothing to do
        updatedRanges = List<TextStyleRange>.from(current.styledRanges)
           ..add(TextStyleRange(start: start, end: end, highlightColor: colorValue));
     }
     
     slides[widget.selectedSlideIndex] = current.copyWith(styledRanges: updatedRanges);
     _textController.styledRanges = updatedRanges;
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     setState(() {});
  }

  void _applyBulletStyle(String bulletType) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final current = slides[widget.selectedSlideIndex];
     final text = _textController.text;
     
     // Get selection - if collapsed, use entire text
     final selection = _textController.selection;
     int selStart = selection.isCollapsed ? 0 : selection.start;
     int selEnd = selection.isCollapsed ? text.length : selection.end;
     
     // Find all lines in selection
     final lines = text.split('\n');
     final newLines = <String>[];
     
     int charIdx = 0;
     int bulletNum = 1;
     
     for (final line in lines) {
        final lineEnd = charIdx + line.length;
        
        // Check if line overlaps with selection
        final lineInSelection = (charIdx < selEnd && lineEnd > selStart);
        
        if (lineInSelection) {
           // Remove any existing bullet prefix first
           String cleanLine = line;
           final bulletPatterns = [
              RegExp(r'^• '),
              RegExp(r'^\d+\. '),
              RegExp(r'^[IVXLCDM]+\. ', caseSensitive: false),
              RegExp(r'^[A-Z]\. '),
              RegExp(r'^[a-z]\. '),
           ];
           for (final pattern in bulletPatterns) {
              cleanLine = cleanLine.replaceFirst(pattern, '');
           }
           
           // Apply new bullet
           String prefix = '';
           switch (bulletType) {
              case 'bullet':
                 prefix = '• ';
                 break;
              case 'number':
                 prefix = '$bulletNum. ';
                 bulletNum++;
                 break;
              case 'roman':
                 prefix = '${_toRoman(bulletNum)}. ';
                 bulletNum++;
                 break;
              case 'ABC':
                 prefix = '${String.fromCharCode(64 + bulletNum)}. ';
                 bulletNum++;
                 break;
              case 'abc':
                 prefix = '${String.fromCharCode(96 + bulletNum)}. ';
                 bulletNum++;
                 break;
              case 'remove':
                 prefix = '';
                 break;
           }
           newLines.add(prefix + cleanLine);
        } else {
           newLines.add(line);
        }
        
        charIdx = lineEnd + 1; // +1 for newline
     }
     
     final newText = newLines.join('\n');
     _textController.text = newText;
     slides[widget.selectedSlideIndex] = current.copyWith(content: newText);
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     setState(() {});
  }

  String _toRoman(int num) {
     const romanNumerals = [
        (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'),
        (100, 'C'), (90, 'XC'), (50, 'L'), (40, 'XL'),
        (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I')
     ];
     var result = '';
     var remaining = num;
     for (final entry in romanNumerals) {
        while (remaining >= entry.$1) {
           result += entry.$2;
           remaining -= entry.$1;
        }
     }
     return result;
  }

  void _applyTextColor(int colorValue) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final selection = _textController.selection;
     if (selection.isCollapsed || selection.start == selection.end) return;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final current = slides[widget.selectedSlideIndex];
     final start = selection.start;
     final end = selection.end;
     
     final existingIdx = current.styledRanges.indexWhere((r) => r.start == start && r.end == end);
     
     List<TextStyleRange> updatedRanges;
     
     if (existingIdx >= 0) {
        final existing = current.styledRanges[existingIdx];
        if (colorValue == 0) {
           final updatedRange = TextStyleRange(
              start: existing.start,
              end: existing.end,
              isBold: existing.isBold,
              isItalic: existing.isItalic,
              isUnderlined: existing.isUnderlined,
              highlightColor: existing.highlightColor,
              textColor: null,
              fontFamily: existing.fontFamily,
           );
           updatedRanges = List<TextStyleRange>.from(current.styledRanges);
           updatedRanges[existingIdx] = updatedRange;
        } else {
           updatedRanges = List<TextStyleRange>.from(current.styledRanges);
           updatedRanges[existingIdx] = existing.copyWith(textColor: colorValue);
        }
     } else {
        if (colorValue == 0) return;
        updatedRanges = List<TextStyleRange>.from(current.styledRanges)
           ..add(TextStyleRange(start: start, end: end, textColor: colorValue));
     }
     
     slides[widget.selectedSlideIndex] = current.copyWith(styledRanges: updatedRanges);
     _textController.styledRanges = updatedRanges;
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     setState(() {});
  }

  void _applyFont(String fontName) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final selection = _textController.selection;
     if (selection.isCollapsed || selection.start == selection.end) return;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final current = slides[widget.selectedSlideIndex];
     final start = selection.start;
     final end = selection.end;
     
     final existingIdx = current.styledRanges.indexWhere((r) => r.start == start && r.end == end);
     
     List<TextStyleRange> updatedRanges;
     
     if (existingIdx >= 0) {
        final existing = current.styledRanges[existingIdx];
        if (fontName == 'reset') {
           final updatedRange = TextStyleRange(
              start: existing.start,
              end: existing.end,
              isBold: existing.isBold,
              isItalic: existing.isItalic,
              isUnderlined: existing.isUnderlined,
              highlightColor: existing.highlightColor,
              textColor: existing.textColor,
              fontFamily: null,
           );
           updatedRanges = List<TextStyleRange>.from(current.styledRanges);
           updatedRanges[existingIdx] = updatedRange;
        } else {
           updatedRanges = List<TextStyleRange>.from(current.styledRanges);
           updatedRanges[existingIdx] = existing.copyWith(fontFamily: fontName);
        }
     } else {
        if (fontName == 'reset') return;
        updatedRanges = List<TextStyleRange>.from(current.styledRanges)
           ..add(TextStyleRange(start: start, end: end, fontFamily: fontName));
     }
     
     slides[widget.selectedSlideIndex] = current.copyWith(styledRanges: updatedRanges);
     _textController.styledRanges = updatedRanges;
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     setState(() {});
  }

  void _applyFontSize(double size) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final selection = _textController.selection;
     if (selection.isCollapsed || selection.start == selection.end) return;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final current = slides[widget.selectedSlideIndex];
     final start = selection.start;
     final end = selection.end;
     
     final existingIdx = current.styledRanges.indexWhere((r) => r.start == start && r.end == end);
     
     List<TextStyleRange> updatedRanges;
     
     if (existingIdx >= 0) {
        final existing = current.styledRanges[existingIdx];
        if (size == 0.0) {
           final updatedRange = TextStyleRange(
              start: existing.start,
              end: existing.end,
              isBold: existing.isBold,
              isItalic: existing.isItalic,
              isUnderlined: existing.isUnderlined,
              highlightColor: existing.highlightColor,
              textColor: existing.textColor,
              fontFamily: existing.fontFamily,
              fontSize: null,
           );
           updatedRanges = List<TextStyleRange>.from(current.styledRanges);
           updatedRanges[existingIdx] = updatedRange;
        } else {
           updatedRanges = List<TextStyleRange>.from(current.styledRanges);
           updatedRanges[existingIdx] = existing.copyWith(fontSize: size);
        }
     } else {
        if (size == 0.0) return;
        updatedRanges = List<TextStyleRange>.from(current.styledRanges)
           ..add(TextStyleRange(start: start, end: end, fontSize: size));
     }
     
     slides[widget.selectedSlideIndex] = current.copyWith(styledRanges: updatedRanges);
     _textController.styledRanges = updatedRanges;
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     setState(() {});
  }

  void _increaseIndent() {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final current = slides[widget.selectedSlideIndex];
     final text = _textController.text;
     
     final selection = _textController.selection;
     int selStart = selection.isCollapsed ? 0 : selection.start;
     int selEnd = selection.isCollapsed ? text.length : selection.end;
     
     final lines = text.split('\n');
     final newLines = <String>[];
     
     int charIdx = 0;
     for (final line in lines) {
        final lineEnd = charIdx + line.length;
        final lineInSelection = (charIdx < selEnd && lineEnd > selStart);
        
        if (lineInSelection) {
           newLines.add('    $line'); // Add 4 spaces
        } else {
           newLines.add(line);
        }
        charIdx = lineEnd + 1;
     }
     
     final newText = newLines.join('\n');
     _textController.text = newText;
     slides[widget.selectedSlideIndex] = current.copyWith(content: newText);
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     setState(() {});
  }

  void _decreaseIndent() {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;
     
     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final current = slides[widget.selectedSlideIndex];
     final text = _textController.text;
     
     final selection = _textController.selection;
     int selStart = selection.isCollapsed ? 0 : selection.start;
     int selEnd = selection.isCollapsed ? text.length : selection.end;
     
     final lines = text.split('\n');
     final newLines = <String>[];
     
     int charIdx = 0;
     for (final line in lines) {
        final lineEnd = charIdx + line.length;
        final lineInSelection = (charIdx < selEnd && lineEnd > selStart);
        
        if (lineInSelection) {
           // Remove up to 4 leading spaces or 1 tab
           if (line.startsWith('    ')) {
              newLines.add(line.substring(4));
           } else if (line.startsWith('\t')) {
              newLines.add(line.substring(1));
           } else if (line.startsWith('  ')) {
              newLines.add(line.substring(2));
           } else if (line.startsWith(' ')) {
              newLines.add(line.substring(1));
           } else {
              newLines.add(line);
           }
        } else {
           newLines.add(line);
        }
        charIdx = lineEnd + 1;
     }
     
     final newText = newLines.join('\n');
     _textController.text = newText;
     slides[widget.selectedSlideIndex] = current.copyWith(content: newText);
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     setState(() {});
  }

  PopupMenuItem<int> _buildColorMenuItem(int color, String label) {
     return PopupMenuItem(
        value: color,
        child: Row(
           children: [
              Container(width: 16, height: 16, color: Color(color)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70)),
           ],
        ),
     );
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = ref.watch(activeEditorItemProvider);
    
    if (activeItem != _activeItem || widget.selectedSlideIndex != _lastSlideIndex) {
        _activeItem = activeItem;
        _lastSlideIndex = widget.selectedSlideIndex;
        
        String newText = '';
        if (activeItem != null && widget.selectedSlideIndex >= 0 && widget.selectedSlideIndex < activeItem.slides.length) {
           newText = activeItem.slides[widget.selectedSlideIndex].content;
        }
        
        if (_textController.text != newText) {
             _textController.text = newText;
             // Sync styled ranges from loaded slide
             if (activeItem != null && widget.selectedSlideIndex >= 0 && widget.selectedSlideIndex < activeItem.slides.length) {
                _textController.styledRanges = activeItem.slides[widget.selectedSlideIndex].styledRanges;
             } else {
                _textController.styledRanges = const [];
             }
             // Trigger detect when navigating/loading
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted && _activeItem != null) _parseBibleReferences(_activeItem);
             });
        }
    }

    final liveContent = ref.watch(liveSlideContentProvider);
    
    // Get current slide style for toolbar context
    bool isBold = false;
    bool isItalic = false;
    bool isUnderlined = false;
    int alignment = 1;

    if (_activeItem != null && widget.selectedSlideIndex >= 0 && widget.selectedSlideIndex < _activeItem!.slides.length) {
       final s = _activeItem!.slides[widget.selectedSlideIndex];
       isBold = s.isBold;
       isItalic = s.isItalic;
       isUnderlined = s.isUnderlined;
       alignment = s.alignment;
    }

    // Bible Dropdowns Data
    final repo = ref.watch(bibleRepositoryProvider);
    final versions = repo.getVersions();
    final languages = versions.map((v) => v.language).toSet().toList();
    if (!languages.contains(_selectedLanguage) && languages.isNotEmpty) {
       _selectedLanguage = languages.first;
    }
    
    final filteredVersions = versions.where((v) => v.language == _selectedLanguage).toList();
    if (_selectedVersionId == null && filteredVersions.isNotEmpty) {
       // Default to NLT if available
       final nlt = filteredVersions.where((v) => v.abbreviation == 'NLT').firstOrNull;
       _selectedVersionId = nlt?.id ?? filteredVersions.first.id;
    } else if (_selectedVersionId != null && !filteredVersions.any((v) => v.id == _selectedVersionId)) {
       // Reset if language filtered it out
       final nlt = filteredVersions.where((v) => v.abbreviation == 'NLT').firstOrNull;
       _selectedVersionId = filteredVersions.isNotEmpty ? (nlt?.id ?? filteredVersions.first.id) : null;
    }

    return Focus(
      focusNode: _editorFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Editor
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Real Toolbar
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                      // Undo/Redo
                      _buildToolbarButton(Icons.undo, _undo, isActive: _undoStack.isNotEmpty),
                      const SizedBox(width: 4),
                      _buildToolbarButton(Icons.redo, _redo, isActive: _redoStack.isNotEmpty),
                      const SizedBox(width: 16),
                      _buildToolbarButton(Icons.format_bold, () => _updateSlideStyle(isBold: !isBold), isActive: isBold),
                      const SizedBox(width: 8),
                      _buildToolbarButton(Icons.format_italic, () => _updateSlideStyle(isItalic: !isItalic), isActive: isItalic),
                      const SizedBox(width: 8),
                      // Underline often not supported directly in IconData or logic, but let's wire it
                      _buildToolbarButton(Icons.format_underlined, () => _updateSlideStyle(isUnderlined: !isUnderlined), isActive: isUnderlined),
                      const SizedBox(width: 16),
                      _buildToolbarButton(Icons.format_align_left, () => _updateSlideStyle(alignment: 0), isActive: alignment == 0),
                      const SizedBox(width: 8),
                      _buildToolbarButton(Icons.format_align_center, () => _updateSlideStyle(alignment: 1), isActive: alignment == 1),
                      const SizedBox(width: 8),
                      _buildToolbarButton(Icons.format_align_right, () => _updateSlideStyle(alignment: 2), isActive: alignment == 2),
                      const SizedBox(width: 16),
                      
                      // Highlight Color Picker
                      PopupMenuButton<int>(
                        icon: const Icon(Icons.highlight, color: Colors.white70, size: 20),
                        tooltip: 'Highlight Color',
                        color: const Color(0xFF333333),
                        onSelected: (color) => _applyHighlight(color),
                        itemBuilder: (context) => [
                          _buildColorMenuItem(0xFFFFFF00, 'Yellow'),
                          _buildColorMenuItem(0xFF00FF00, 'Green'),
                          _buildColorMenuItem(0xFF00FFFF, 'Cyan'),
                          _buildColorMenuItem(0xFFFF69B4, 'Pink'),
                          _buildColorMenuItem(0xFFFFB347, 'Orange'),
                          const PopupMenuItem(value: 0, child: Text('Remove Highlight', style: TextStyle(color: Colors.white70))),
                        ],
                      ),
                      const SizedBox(width: 8),
                      
                      // Text Color Picker
                      PopupMenuButton<int>(
                        icon: const Icon(Icons.format_color_text, color: Colors.white70, size: 20),
                        tooltip: 'Text Color',
                        color: const Color(0xFF333333),
                        onSelected: (color) => _applyTextColor(color),
                        itemBuilder: (context) => [
                          _buildColorMenuItem(0xFFFFFFFF, 'White'),
                          _buildColorMenuItem(0xFF000000, 'Black'),
                          _buildColorMenuItem(0xFFFF0000, 'Red'),
                          _buildColorMenuItem(0xFF00FF00, 'Green'),
                          _buildColorMenuItem(0xFF0000FF, 'Blue'),
                          _buildColorMenuItem(0xFFFFFF00, 'Yellow'),
                          _buildColorMenuItem(0xFFFF69B4, 'Pink'),
                          _buildColorMenuItem(0xFFFFA500, 'Orange'),
                          const PopupMenuItem(value: 0, child: Text('Reset Color', style: TextStyle(color: Colors.white70))),
                        ],
                      ),
                      const SizedBox(width: 8),
                      
                      // Font Selector
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.font_download, color: Colors.white70, size: 20),
                        tooltip: 'Font',
                        color: const Color(0xFF333333),
                        onSelected: (font) => _applyFont(font),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Roboto', child: Text('Roboto', style: TextStyle(color: Colors.white70, fontFamily: 'Roboto'))),
                          const PopupMenuItem(value: 'Arial', child: Text('Arial', style: TextStyle(color: Colors.white70, fontFamily: 'Arial'))),
                          const PopupMenuItem(value: 'Times New Roman', child: Text('Times New Roman', style: TextStyle(color: Colors.white70, fontFamily: 'Times New Roman'))),
                          const PopupMenuItem(value: 'Georgia', child: Text('Georgia', style: TextStyle(color: Colors.white70, fontFamily: 'Georgia'))),
                          const PopupMenuItem(value: 'Courier New', child: Text('Courier New', style: TextStyle(color: Colors.white70, fontFamily: 'Courier New'))),
                          const PopupMenuItem(value: 'reset', child: Text('Reset Font', style: TextStyle(color: Colors.white70))),
                        ],
                      ),
                      const SizedBox(width: 8),
                      
                      // Bullet Style Menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.format_list_bulleted, color: Colors.white70, size: 20),
                        tooltip: 'Bullet Style',
                        color: const Color(0xFF333333),
                        onSelected: (style) => _applyBulletStyle(style),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'bullet', child: Text('• Bullet', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 'number', child: Text('1. Numbered', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 'roman', child: Text('I. Roman', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 'ABC', child: Text('A. Uppercase', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 'abc', child: Text('a. Lowercase', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 'remove', child: Text('Remove Bullets', style: TextStyle(color: Colors.white70))),
                        ],
                      ),
                      const SizedBox(width: 8),
                      
                      // Font Size Menu (8-72 limited)
                      PopupMenuButton<double>(
                        icon: const Icon(Icons.format_size, color: Colors.white70, size: 20),
                        tooltip: 'Font Size',
                        color: const Color(0xFF333333),
                        onSelected: (size) => _applyFontSize(size),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 12.0, child: Text('12', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 14.0, child: Text('14', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 16.0, child: Text('16', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 18.0, child: Text('18', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 20.0, child: Text('20', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 24.0, child: Text('24', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 28.0, child: Text('28', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 32.0, child: Text('32', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 40.0, child: Text('40', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 48.0, child: Text('48', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 56.0, child: Text('56', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 64.0, child: Text('64', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 72.0, child: Text('72', style: TextStyle(color: Colors.white70))),
                          const PopupMenuItem(value: 0.0, child: Text('Reset Size', style: TextStyle(color: Colors.white70))),
                        ],
                      ),
                      const SizedBox(width: 8),
                      
                      // Indent Buttons
                      _buildToolbarButton(Icons.format_indent_increase, _increaseIndent),
                      const SizedBox(width: 4),
                      _buildToolbarButton(Icons.format_indent_decrease, _decreaseIndent),
                      const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ),
                      
                      // Bible Selectors (Fixed Right)
                      if (languages.isNotEmpty) ...[
                          Container(width: 1, height: 24, color: Colors.white24),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                             value: languages.contains(_selectedLanguage) ? _selectedLanguage : null,
                             dropdownColor: const Color(0xFF333333),
                             style: const TextStyle(color: Colors.white, fontSize: 12),
                             underline: Container(), 
                             icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                             items: languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                             onChanged: (v) {
                                 setState(() => _selectedLanguage = v!);
                                 final newVersions = repo.getVersions().where((ver) => ver.language == v).toList();
                                 if (newVersions.isNotEmpty) {
                                    setState(() => _selectedVersionId = newVersions.first.id);
                                 }
                                 if (_projectedVerseRef != null) _projectVerse(_projectedVerseRef!);
                             },
                          ),
                          const SizedBox(width: 8),
                      ],
                      
                      if (filteredVersions.isNotEmpty)
                      DropdownButton<String>(
                         value: filteredVersions.any((v) => v.id == _selectedVersionId) ? _selectedVersionId : null,
                         dropdownColor: const Color(0xFF333333),
                         style: const TextStyle(color: Colors.white, fontSize: 12),
                         underline: Container(),
                         icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                         items: filteredVersions.map((v) => DropdownMenuItem(value: v.id, child: Text(v.abbreviation))).toList(),
                         onChanged: (v) {
                             setState(() => _selectedVersionId = v!);
                             if (_projectedVerseRef != null) _projectVerse(_projectedVerseRef!);
                         },
                      ),
                    ],
                  ),

                const SizedBox(height: 16),
                
                 // Detected Verses UI MOVED DOWN


                // Text Field
                 Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _textController,
                      onChanged: _onTextChanged,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                     decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type your content here...',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                
                // Detected Verses UI (Bottom)
                if (_detectedVerses.isNotEmpty)
                Padding(
                   padding: const EdgeInsets.only(top: 16),
                   child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                         color: const Color(0xFF252525),
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            // Chips
                            Scrollbar(
                               controller: _versesScrollController,
                               thumbVisibility: true,
                               child: SingleChildScrollView(
                                  controller: _versesScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: Padding(
                                     padding: const EdgeInsets.only(bottom: 8.0), // Space for scrollbar
                                     child: Row(
                                        children: _detectedVerses.map((refString) {
                                           final isActive = _projectedVerseRef == refString;
                                           return Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: GestureDetector(
                                                onSecondaryTapUp: (details) => _showVerseContextMenu(context, details.globalPosition, refString),
                                                child: ActionChip(
                                                   label: Text(refString),
                                                   avatar: Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 14, color: isActive ? Colors.white : Colors.blueAccent),
                                                   backgroundColor: isActive ? Colors.blueAccent : const Color(0xFF3D3D3D),
                                                   labelStyle: TextStyle(color: isActive ? Colors.white : Colors.white70),
                                                   onPressed: () => _toggleProjectVerse(refString),
                                                   side: BorderSide.none,
                                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                ),
                                              ),
                                           );
                                        }).toList(),
                                     ),
                                  ),
                               ),
                            ),
                         ],
                      ),
                   ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),

            // Right: Live Preview
        ],
      ),
    ),
    );
  }

  Future<void> _addVerseAsSlide(String refString) async {
    final content = await _resolveVerseContent(refString);
    if (content == null || _activeItem == null) return;

    final slides = List<PresentationSlide>.from(_activeItem!.slides);
    final newSlide = PresentationSlide(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      label: 'Scripture',
      color: 0xFF2D2D2D, 
    );

    slides.add(newSlide);

    final updatedItem = _activeItem!.copyWith(slides: slides);
    _syncToProject(updatedItem);
    
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added slide: $refString')));
    }
  }

  void _showVerseContextMenu(BuildContext context, Offset position, String refString) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem(
          value: 'add_slide',
          child: Row(
            children: [
               Icon(Icons.add_to_photos, size: 18, color: Colors.white70),
               SizedBox(width: 8),
               Text('Add to Slide', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
      color: const Color(0xFF333333),
    ).then((value) {
      if (value == 'add_slide') {
        _addVerseAsSlide(refString);
      }
    });
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed, {bool isActive = false}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: isActive ? Colors.blueAccent : Colors.white70, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: isActive ? Colors.blueAccent.withOpacity(0.2) : const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }



  Widget _buildStatusToggle(String label, bool isOn, Color color) {
     return Column(
        children: [
           Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: Colors.transparent, // Fill transparent
                 border: Border.all(color: color, width: 2),
              ),
              child: isOn ? Center(
                 child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: color,
                    ),
                 ),
              ) : null,
           ),
           const SizedBox(height: 4),
           Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
     );
  }
}

/// Helper class to store editor state for undo/redo
class _EditorState {
  final String content;
  final List<TextStyleRange> styledRanges;
  
  _EditorState({required this.content, required this.styledRanges});
}
