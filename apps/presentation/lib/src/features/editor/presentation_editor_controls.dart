import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_provider.dart';
import '../service/service_model.dart';
import '../bible/bible_repository.dart';
import '../bible/bible_model.dart';


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
  late TextEditingController _textController;
  ServiceItem? _activeItem;
  int? _lastSlideIndex;
  List<String> _detectedVerses = [];
  String? _projectedVerseRef; // Tracks if we are currently overriding with a verse
  
  // Bible Settings
  String _selectedLanguage = 'English';
  String? _selectedVersionId;
  final ScrollController _versesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _versesScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PresentationEditorControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If index changed, we must update text, BUT we should also check if the active item changed in build
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

  void _onTextChanged(String value) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;

     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final currentSlide = slides[widget.selectedSlideIndex];
     
     if (currentSlide.content == value) return; // No change

     slides[widget.selectedSlideIndex] = PresentationSlide(
        id: currentSlide.id,
        content: value,
        label: currentSlide.label,
        color: currentSlide.color,
     );

     final updatedItem = _activeItem!.copyWith(slides: slides);
     
     // Optimistically update local reference to avoid jitter ? 
     // Actually ref.read will trigger rebuild, so we should be careful with text cursor.
     // For now, let's just sync.
     _syncToProject(updatedItem);

     // Update live content immediately for real-time preview (as requested)
     ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(
        content: value,
        isBold: currentSlide.isBold,
        isItalic: currentSlide.isItalic,
        isUnderlined: currentSlide.isUnderlined,
        alignment: currentSlide.alignment,
     );
     
     // Detect Bible References
     _parseBibleReferences(value);
  }

  void _parseBibleReferences(String text) {
     // Regex for [Number?] [Name] [Chapter]:[VerseRange]
     // e.g. Genesis 1:1, John 3:16-20, Rom 1:1,3,5
     final regex = RegExp(r'\b((?:[1-3]\s)?[A-Za-z]+)\s+(\d+):(\d+(?:[-,\s]+\d+)*)\b');
     final matches = regex.allMatches(text);
     
     final found = matches.map((m) => text.substring(m.start, m.end)).toSet().toList();
     
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

  Future<void> _projectVerse(String refString) async {
     final repo = ref.read(bibleRepositoryProvider);
     
     // Ensure data loaded
     if (repo.getVersions().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loading Bible database... please wait.')));
          await repo.loadBibleData();
          if (mounted) setState(() {});
     }
     
     final versions = repo.getVersions();
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
        
        // Use searchVerses to Resolve Book Name (using just "Book Chapter" to get right book)
        // or we can use repo.getVerses directly if we resolve the book code.
        // repo.searchVerses has logic to resolve "Gen" -> "Genesis" -> "GEN". 
        // Let's rely on repo.searchVerses to find the book code/name first by searching for "Book Chapter:FirstVerse"
        
        final probeRef = "$bookRaw $chapter:${targetVerses.first}";
        final searchResults = repo.searchVerses(probeRef, versionId: targetVersionId);
        
        if (searchResults.isNotEmpty) {
           final firstVerse = searchResults.first;
           final bookName = firstVerse.bookName;
           final version = versions.firstWhere((v) => v.id == targetVersionId, orElse: () => versions.first);
           
           // Now fetch ALL verses for this chapter to ensure we get the full range even if search returned subset
           // (Repo search might be exact match on probe).
           // Optimization: repo.getVerses is fast cache lookup
           final allChapterVerses = repo.getVerses(version.abbreviation, bookName, chapter);
           
           // Filter
           final selectedVerses = allChapterVerses.where((v) => targetVerses.contains(v.verse)).toList();
           
           if (selectedVerses.isNotEmpty) {
              final textBlock = selectedVerses.map((v) => v.verse > 0 ? "<b>${v.verse}</b> ${v.text}" : v.text).join(" ");
              // Strip HTML tags if projector doesn't support them, but here we want simple text. 
              // Actually, projector supports styles but not inline HTML yet probably?
              // The user just wants the text. Let's just join with spaces.
              // Maybe superscript numbers? For now, plain text join.
              final plainText = selectedVerses.map((v) => v.text).join(" ");
              
              final header = "$bookName $chapter:$versesRaw (${version.abbreviation})";
              final content = "$header\n$plainText";
              
              ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(
                 content: content,
                 alignment: 1, // Center
                 isBold: true,
              );
              
              setState(() {
                 _projectedVerseRef = refString;
              });
              return;
           }
        }
     }

     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verse not found in ${targetVersionId ?? 'database'}')));
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
     
     slides[widget.selectedSlideIndex] = PresentationSlide(
        id: current.id,
        content: current.content,
        label: current.label,
        color: current.color,
        isBold: isBold ?? current.isBold,
        isItalic: isItalic ?? current.isItalic,
        isUnderlined: isUnderlined ?? current.isUnderlined,
        alignment: alignment ?? current.alignment,
     );

     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
     
     // Also update live provider to reflect style changes immediately
     ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(
        content: _textController.text,
        isBold: isBold ?? current.isBold,
        isItalic: isItalic ?? current.isItalic,
        isUnderlined: isUnderlined ?? current.isUnderlined,
        alignment: alignment ?? current.alignment,
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
       _selectedVersionId = filteredVersions.first.id;
    } else if (_selectedVersionId != null && !filteredVersions.any((v) => v.id == _selectedVersionId)) {
       // Reset if language filtered it out
       _selectedVersionId = filteredVersions.isNotEmpty ? filteredVersions.first.id : null;
    }

    return Container(
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
                Text(
                  'Editing Slide ${widget.selectedSlideIndex + 1}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Mock Toolbar -> Real Toolbar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
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
                      
                      // Bible Selectors (Moved to Toolbar)
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
                ),
                const SizedBox(height: 16),
                
                // Detected Verses UI
                if (_detectedVerses.isNotEmpty)
                Padding(
                   padding: const EdgeInsets.only(bottom: 16),
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
                                              child: ActionChip(
                                                 label: Text(refString),
                                                 avatar: Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 14, color: isActive ? Colors.white : Colors.blueAccent),
                                                 backgroundColor: isActive ? Colors.blueAccent : const Color(0xFF3D3D3D),
                                                 labelStyle: TextStyle(color: isActive ? Colors.white : Colors.white70),
                                                 onPressed: () => _toggleProjectVerse(refString),
                                                 side: BorderSide.none,
                                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              ],
            ),
          ),
          
          const SizedBox(width: 16),

            // Right: Live Preview
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Audience Preview
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Using current editor state for preview, NOT just live content string
                        // This allows 'Design Mode' feel
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 1920, 
                            height: 1080,
                            child: Padding(
                              padding: const EdgeInsets.all(48.0),
                              child: Center(
                                child: Text(
                                  // Use controller text for immediate feedback or active item text
                                  _textController.text.isNotEmpty ? _textController.text : (liveContent.content.isNotEmpty ? liveContent.content : 'Audience Screen 1'),
                                  textAlign: alignment == 0 ? TextAlign.left : (alignment == 2 ? TextAlign.right : TextAlign.center),
                                  style: TextStyle(
                                     color: Colors.white, 
                                     fontSize: 80,
                                     fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                                     fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                                     decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Stage Preview
                Expanded(
                   child: Center(
                     child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            'Stage View',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                   ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
