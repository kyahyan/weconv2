import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'editor_provider.dart';
import '../service/service_model.dart';
import '../online/online_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'lyrics_parser.dart';
import '../bible/bible_model.dart';
import '../bible/bible_repository.dart'; // For full book name resolution if needed

class PresentationSlideList extends ConsumerStatefulWidget {
  final Function(int) onSlideSelected;
  final Function(int)? onSlideGoLive;
  final int? liveIndex;

  const PresentationSlideList({
    super.key,
    required this.onSlideSelected,
    this.onSlideGoLive,
    this.liveIndex,
  });

  @override
  ConsumerState<PresentationSlideList> createState() => _PresentationSlideListState();
}

class _PresentationSlideListState extends ConsumerState<PresentationSlideList> {
  int _selectedIndex = 0;
  double _slideWidth = 240.0;
  final Uuid _uuid = const Uuid();
  final Set<int> _selectedSlides = {}; // Multi-select
  bool _isMultiSelectMode = false;
  List<PresentationSlide> _clipboard = []; // For copy/paste
  final FocusNode _focusNode = FocusNode();
  int? _anchorIndex; // For Shift+Click range selection

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = ref.watch(activeEditorItemProvider);
    final activeProject = ref.watch(activeProjectProvider);

    // Listen for file changes and load the project
    ref.listen<File?>(activeFileProvider, (previous, next) async {
      if (next != null && (previous == null || next.path != previous.path)) {
        await _loadFile(next);
      }
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveProject,
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): _copySelectedSlides,
        const SingleActivator(LogicalKeyboardKey.keyX, control: true): _cutSelectedSlides,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _pasteSlides,
        const SingleActivator(LogicalKeyboardKey.delete): _deleteCurrentSlide,
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Container(
          color: const Color(0xFF1E1E1E),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar: Song List
              if (activeProject != null)
                GestureDetector(
                  onSecondaryTapUp: (details) => _showSidebarMenu(context, details.globalPosition),
                  child: Container(
                    width: 220,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white10)),
                  color: Color(0xFF252525),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Service Lineup', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: activeProject.items.where((i) => i.type == 'song' || i.type == 'header').length,
                      itemBuilder: (context, index) {
                         final displayItems = activeProject.items.where((i) => i.type == 'song' || i.type == 'header').toList();
                         final item = displayItems[index];

                         if (item.type == 'header') {
                            return GestureDetector(
                              onSecondaryTapUp: (details) => _showItemMenu(context, details.globalPosition, item),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  item.title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            );
                         }

                         final song = item;
                         final isActive = activeItem?.id == song.id;
                         
                         return InkWell(
                           onTap: () {
                              ref.read(activeEditorItemProvider.notifier).state = song;
                              setState(() {
                                _selectedIndex = 0;
                              });
                              widget.onSlideSelected(0);
                           },
                           onSecondaryTapUp: (details) {
                                  _showItemMenu(context, details.globalPosition, song);
                           },
                           onDoubleTap: () {
                              // Manual trigger parse
                              if (song.description != null && song.slides.isEmpty) {
                                  final slides = LyricsParser.parse(song.description!);
                                  if (slides.isNotEmpty) {
                                     final updated = song.copyWith(slides: slides);
                                     ref.read(activeEditorItemProvider.notifier).state = updated;
                                     // Sync project
                                     // Note: reusing the internal _syncToProject if possible or duplicate logic
                                     // Since we can't easily access _syncToProject from here (different scope in builder), 
                                     // we'll just update the provider and let the user save or it will be lost on reload for now.
                                     // Better: Use a callback or move this logic. 
                                     // For now, simple visual update:
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lyrics Parsed!')));
                                  } else {
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No lyrics found to parse.')));
                                  }
                              } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Slides exist or no description. Desc Len: ${song.description?.length}')));
                              }
                           },
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             color: isActive ? Colors.blue.withOpacity(0.2) : null,
                             child: Row(
                               children: [
                                 const Icon(LucideIcons.music, size: 14, color: Colors.white54),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     song.title,
                                     style: TextStyle(
                                       color: isActive ? Colors.white : Colors.white70,
                                       fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                                     ),
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Slide Area
          Expanded(
            child: Container(
                 padding: const EdgeInsets.all(8),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Padding(
                       padding: const EdgeInsets.only(bottom: 8.0, right: 16.0),
                       child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  // Search Songs Button
                                  IconButton(
                                    icon: const Icon(LucideIcons.search, size: 18, color: Colors.white70),
                                    tooltip: 'Search Songs to Add',
                                    onPressed: () => _showSongSearchDialog(context),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  if (activeItem != null) ...[
                                    Text(
                                       activeItem.title,
                                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                     ),
                                     const SizedBox(width: 8),
                                     if (activeItem.artist != null)
                                       Text('(${activeItem.artist})', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ],
                              ),
                            ),
                             // Zoom Slider
                             Row(
                               children: [
                                 const Icon(Icons.zoom_out, size: 16, color: Colors.white24),
                                 SizedBox(
                                   width: 150,
                                   child: SliderTheme(
                                     data: SliderTheme.of(context).copyWith(
                                       thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                       overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                       trackHeight: 2,
                                     ),
                                     child: Slider(
                                       value: _slideWidth,
                                       min: 150,
                                       max: 500,
                                       activeColor: Colors.white54,
                                       inactiveColor: Colors.white10,
                                       onChanged: (val) => setState(() => _slideWidth = val),
                                     ),
                                   ),
                                 ),
                                 const Icon(Icons.zoom_in, size: 16, color: Colors.white24),
                               ],
                             ),
                          ],
                       ),
                     ),
                     Expanded(
                       child: activeItem == null
                        ? const Center(child: Text('No Song Selected', style: TextStyle(color: Colors.white24)))
                        : DragTarget<List<BibleVerse>>(
                           onWillAccept: (data) => data != null && data.isNotEmpty,
                           onAccept: (verses) => _handleDroppedVerses(verses),
                           builder: (context, candidateData, rejectedData) {
                             return Container(
                               decoration: candidateData.isNotEmpty 
                                  ? BoxDecoration(border: Border.all(color: Colors.blueAccent, width: 2), borderRadius: BorderRadius.circular(8))
                                  : null,
                               child: GridView.builder(
                                 padding: const EdgeInsets.all(8),
                                 gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                   maxCrossAxisExtent: _slideWidth,
                                   childAspectRatio: 1.5,
                                   crossAxisSpacing: 8,
                                   mainAxisSpacing: 8,
                                 ),
                                 itemCount: activeItem.slides.length + 1,
                                 itemBuilder: (context, index) {
                                   // 1. Add Slide Button (Last Item)
                                   if (index == activeItem.slides.length) {
                                     return GestureDetector(
                                       onTap: _addSlide,
                                       child: Container(
                                         decoration: BoxDecoration(
                                           color: const Color(0xFF1E1E1E),
                                           borderRadius: BorderRadius.circular(6),
                                           border: Border.all(color: Colors.white10),
                                           boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                         ),
                                         child: const Center(
                                           child: Column(
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
                                                Icon(Icons.add, color: Colors.white54, size: 32),
                                                SizedBox(height: 8),
                                                Text('Add Slide', style: TextStyle(color: Colors.white24)),
                                             ],
                                           ),
                                         ),
                                       ),
                                     );
                                   }
                                   
                                   // 2. Real Slide
                                   final slide = activeItem.slides[index];
                                   final isSelected = _selectedIndex == index;
                                   final isLive = widget.liveIndex == index;
                                   final isMultiSelected = _selectedSlides.contains(index);
                                   final color = Color(slide.color == 0 ? 0xFF333333 : slide.color); 
               
                                   return GestureDetector(
                                         onTap: () {
                                            // Request focus to enable keyboard shortcuts
                                            _focusNode.requestFocus();
       
                                            final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
                                            final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                                            
                                            if (isShiftPressed && _anchorIndex != null) {
                                               // Range selection (For Editing)
                                               final start = _anchorIndex! < index ? _anchorIndex! : index;
                                               final end = _anchorIndex! < index ? index : _anchorIndex!;
                                               
                                               setState(() {
                                                  _selectedSlides.clear();
                                                  for (int i = start; i <= end; i++) {
                                                     _selectedSlides.add(i);
                                                  }
                                                  _selectedIndex = index; // Update active edit slide
                                               });
                                               widget.onSlideSelected(index);
                                            } else if (isCtrlPressed) {
                                               // Toggle selection (For Editing)
                                               setState(() {
                                                  if (_selectedSlides.contains(index)) {
                                                     _selectedSlides.remove(index);
                                                  } else {
                                                     _selectedSlides.add(index);
                                                  }
                                                  _anchorIndex = index;
                                                  _selectedIndex = index;
                                               });
                                               widget.onSlideSelected(index);
                                            } else {
                                               // Single Click -> GO LIVE (Do NOT select for edit)
                                               if (widget.onSlideGoLive != null) {
                                                   widget.onSlideGoLive!(index);
                                               }
                                               
                                               ref.read(liveSlideContentProvider.notifier).state = LiveSlideData(
                                                   content: slide.content,
                                                   isBold: slide.isBold,
                                                   isItalic: slide.isItalic,
                                                   isUnderlined: slide.isUnderlined,
                                                   alignment: slide.alignment,
                                               );
                                            }
                                         },
                                         onDoubleTap: () {
                                            // Double Click -> SELECT FOR EDITING (Do NOT Go Live)
                                            _selectedSlides.clear();
                                            _selectedSlides.add(index);
                                            _anchorIndex = index;
                                            setState(() => _selectedIndex = index);
                                            
                                            widget.onSlideSelected(index);
                                         },
                                         onSecondaryTapUp: (details) {
                                            // Add to selection if not already
                                            if (!_selectedSlides.contains(index)) {
                                               setState(() => _selectedSlides.add(index));
                                            }
                                            _showContextMenu(context, details.globalPosition, index, slide);
                                         },
                                         child: Container(
                                           decoration: BoxDecoration(
                                             color: const Color(0xFF000000), 
                                             borderRadius: BorderRadius.circular(6),
                                             border: isLive 
                                                 ? Border.all(color: Colors.redAccent, width: 4) // Live
                                                 : isSelected
                                                     ? Border.all(color: Colors.orange, width: 2) // Editing
                                                     : isMultiSelected
                                                       ? Border.all(color: Colors.blue, width: 2)
                                                       : Border.all(color: Colors.white24, width: 1),
                                           ),
                                           child: Stack(
                                             children: [
                                               // Content Preview (Perfect Fit)
                                               Padding(
                                                 padding: const EdgeInsets.fromLTRB(12, 24, 12, 24), // Space for labels
                                                 child: Center(
                                                   child: slide.content.isEmpty
                                                     ? const Text(
                                                         '(Empty Slide)',
                                                         style: TextStyle(color: Colors.white24, fontSize: 14, fontStyle: FontStyle.italic),
                                                       )
                                                     : FittedBox(
                                                         fit: BoxFit.contain,
                                                         child: ConstrainedBox(
                                                            constraints: const BoxConstraints(maxWidth: 400),
                                                            child: Text(
                                                              slide.content,
                                                              textAlign: TextAlign.center,
                                                              style: const TextStyle(color: Colors.white, fontSize: 24, height: 1.2),
                                                            ),
                                                         ),
                                                       ),
                                                 ),
                                               ),
                                               
                                               // Label Badge (Top Left)
                                               if (slide.label.isNotEmpty)
                                               Positioned(
                                                 top: 4,
                                                 left: 4,
                                                 child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: color.withOpacity(0.9),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      slide.label, 
                                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                       );
                                 },
                               ),
                             );
                           },
                         ),
                     ),
                   ],
                 ),
               ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProject() async {
    final activeFile = ref.read(activeFileProvider);
    final activeProject = ref.read(activeProjectProvider);
    
    if (activeFile == null || activeProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected to save to')),
      );
      return;
    }
    
    try {
      final json = jsonEncode(activeProject.toJson());
      await activeFile.writeAsString(json);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved!'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _loadFile(File file) async {
    try {
      final content = await file.readAsString();
      if (content.isEmpty) {
        // New empty file
        final newProject = ServiceProject(title: 'New Service', items: []);
        ref.read(activeProjectProvider.notifier).state = newProject;
        ref.read(activeEditorItemProvider.notifier).state = null;
        return;
      }
      
      final json = jsonDecode(content);
      final loadedProject = ServiceProject.fromJson(json);
      ref.read(activeProjectProvider.notifier).state = loadedProject;
      
      // Clear stale selection if item doesn't exist in this project
      final currentItem = ref.read(activeEditorItemProvider);
      if (currentItem != null && !loadedProject.items.any((i) => i.id == currentItem.id)) {
        ref.read(activeEditorItemProvider.notifier).state = null;
      }
      
      // Auto-select first song if no valid selection
      if (ref.read(activeEditorItemProvider) == null) {
        final firstSong = loadedProject.items.firstWhere(
          (i) => i.type == 'song', 
          orElse: () => ServiceItem(id: '', title: '', type: '')
        );
        if (firstSong.id.isNotEmpty) {
          ref.read(activeEditorItemProvider.notifier).state = firstSong;
        }
      }
    } catch (e) {
      debugPrint('Error loading file: $e');
    }
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

  Future<List<OnlineSong>> _loadLocalSongs() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final songsFile = File(p.join(docsDir.path, 'WeConnect', 'Assets', 'songs.json'));
      
      if (!await songsFile.exists()) {
        return [];
      }
      
      final content = await songsFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => OnlineSong.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading local songs: $e');
      return [];
    }
  }

  Future<void> _showSongSearchDialog(BuildContext context) async {
    final songs = await _loadLocalSongs();
    
    if (songs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No songs found. Sync songs from Online tab first.')),
        );
      }
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _SongSearchDialog(
        songs: songs,
        onSongSelected: (song) => _addSongToService(song),
      ),
    );
  }

  void _addSongToService(OnlineSong song) {
    final currentProject = ref.read(activeProjectProvider);
    if (currentProject == null) return;

    // Parse lyrics to create slides
    final slides = LyricsParser.parse(song.content);

    final newItem = ServiceItem(
      id: _uuid.v4(),
      title: song.title,
      type: 'song',
      artist: song.artist,
      slides: slides,
    );

    final updatedItems = [...currentProject.items, newItem];
    final updatedProject = ServiceProject(title: currentProject.title, items: updatedItems);
    
    ref.read(activeProjectProvider.notifier).state = updatedProject;
    ref.read(activeEditorItemProvider.notifier).state = newItem;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${song.title}" to service')),
    );
  }

  void _addSlide() {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null) return;
     
     final newSlide = PresentationSlide(
        id: _uuid.v4(),
        content: '',
        label: '',
        color: 0xFF333333,
     );
     
     final newSlides = List<PresentationSlide>.from(activeItem.slides)..add(newSlide);
     final updatedItem = activeItem.copyWith(slides: newSlides);
     
     _syncToProject(updatedItem);
  }

  void _copySelectedSlides() {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null) return;
     
     final indicesToCopy = _selectedSlides.isNotEmpty 
        ? (_selectedSlides.toList()..sort())
        : [_selectedIndex];
     
     _clipboard = indicesToCopy
        .where((i) => i >= 0 && i < activeItem.slides.length)
        .map((i) => activeItem.slides[i])
        .toList();
     
     if (_clipboard.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Copied ${_clipboard.length} slide(s)'), duration: const Duration(seconds: 1)),
        );
     }
  }

  void _handleDroppedVerses(List<BibleVerse> verses) async {
     if (verses.isEmpty) return;

     if (verses.length == 1) {
        // Just add single slide
        _addSlideWithContent(verses.first);
     } else {
        // Multiple: Ask user
        final choice = await showDialog<String>(
           context: context,
           builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF333333),
              title: const Text('Import Verses', style: TextStyle(color: Colors.white)),
              content: Text('You dropped ${verses.length} verses. How would you like to add them?', style: const TextStyle(color: Colors.white70)),
              actions: [
                 TextButton(
                    onPressed: () => Navigator.pop(context, 'one'),
                    child: const Text('As One Slide'),
                 ),
                 ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: () => Navigator.pop(context, 'separate'),
                    child: const Text('Separate Slides'),
                 ),
              ],
           ),
        );

        if (choice == 'one') {
           _addCombinedSlide(verses);
        } else if (choice == 'separate') {
           for (final v in verses) {
              _addSlideWithContent(v);
           }
        }
     }
  }

  void _addSlideWithContent(BibleVerse verse) {
      final activeItem = ref.read(activeEditorItemProvider);
      if (activeItem == null) return;
      
      final repo = ref.read(bibleRepositoryProvider);
      final fullBookName = repo.getBookFullName(verse.bookName); // Potentially async or cached? Method seems synchronous in previous usage.
      final refText = "$fullBookName ${verse.chapter}:${verse.verse}";
      
      final newSlide = PresentationSlide(
         id: _uuid.v4(),
         content: "$refText\n${verse.text}",
         label: 'Scripture',
         color: 0xFF8B0000, // Dark Red for Scripture
      );
      
      final newSlides = List<PresentationSlide>.from(activeItem.slides)..add(newSlide);
      final updatedItem = activeItem.copyWith(slides: newSlides);
      _syncToProject(updatedItem);
  }

  void _addCombinedSlide(List<BibleVerse> verses) {
      final activeItem = ref.read(activeEditorItemProvider);
      if (activeItem == null) return;
      
      final repo = ref.read(bibleRepositoryProvider);
      
      final contentBuffer = StringBuffer();
      // Heuristic: If same chapter, just range? "John 3:16-18"
      // For now, keep it simple: List references, then text? Or Interleaved?
      // Usually: Ref range at top, then text block.
      
      // Let's try to detect range.
      final first = verses.first;
      final last = verses.last;
      
      // Full range string
      String refString = "${repo.getBookFullName(first.bookName)} ${first.chapter}:${first.verse}";
      if (verses.length > 1) {
         if (first.bookName == last.bookName && first.chapter == last.chapter) {
             refString += "-${last.verse}";
         } else {
             // Different books/chapters: "John 3:16 - Rom 1:1" (Simple)
             refString += " - ${repo.getBookFullName(last.bookName)} ${last.chapter}:${last.verse}";
         }
      }
      
      contentBuffer.writeln(refString);
      for (final v in verses) {
          // contentBuffer.writeln("[${v.verse}] ${v.text}"); 
          // User typically wants just text flow, maybe with verse numbers.
          contentBuffer.write("${v.verse} ${v.text} "); 
      }
      
      final newSlide = PresentationSlide(
         id: _uuid.v4(),
         content: contentBuffer.toString().trim(),
         label: 'Scripture',
         color: 0xFF8B0000,
      );
      
      final newSlides = List<PresentationSlide>.from(activeItem.slides)..add(newSlide);
      final updatedItem = activeItem.copyWith(slides: newSlides);
      _syncToProject(updatedItem);
  }

  void _cutSelectedSlides() {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null) return;
     
     _copySelectedSlides();
     
     if (_selectedSlides.isNotEmpty) {
        _deleteSelectedSlides();
     } else {
        _deleteSlide(_selectedIndex);
     }
  }

  void _pasteSlides() {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null || _clipboard.isEmpty) return;
     
     final slides = List<PresentationSlide>.from(activeItem.slides);
     final insertAt = _selectedIndex + 1;
     
     for (final original in _clipboard) {
        final newSlide = PresentationSlide(
           id: _uuid.v4(),
           content: original.content,
           label: original.label,
           color: original.color,
           isBold: original.isBold,
           isItalic: original.isItalic,
           isUnderlined: original.isUnderlined,
           alignment: original.alignment,
           styledRanges: List.from(original.styledRanges),
        );
        slides.insert(insertAt, newSlide);
     }
     
     final updatedItem = activeItem.copyWith(slides: slides);
     _syncToProject(updatedItem);
     
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pasted ${_clipboard.length} slide(s)'), duration: const Duration(seconds: 1)),
     );
  }

  void _deleteCurrentSlide() {
     if (_selectedSlides.isNotEmpty) {
        _deleteSelectedSlides();
     } else {
        _deleteSlide(_selectedIndex);
     }
  }

  void _updateSlideGroup(int index, String label, int color) {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null) return;
     
     final slides = List<PresentationSlide>.from(activeItem.slides);
     final slide = slides[index];
     
     slides[index] = PresentationSlide(
        id: slide.id,
        content: slide.content,
        label: label,
        color: color,
     );
     
     final updatedItem = activeItem.copyWith(slides: slides);
     _syncToProject(updatedItem);
  }

  void _deleteSlide(int index) {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null || activeItem.slides.isEmpty) return;
     
     final slides = List<PresentationSlide>.from(activeItem.slides);
     if (index < 0 || index >= slides.length) return;
     
     slides.removeAt(index);
     final updatedItem = activeItem.copyWith(slides: slides);
     _syncToProject(updatedItem);
     
     // Adjust selection
     if (_selectedIndex >= slides.length) {
        setState(() => _selectedIndex = slides.isNotEmpty ? slides.length - 1 : 0);
     }
     _selectedSlides.clear();
  }

  void _deleteSelectedSlides() {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null) return;
     
     final slides = List<PresentationSlide>.from(activeItem.slides);
     final toRemove = _selectedSlides.toList()..sort((a, b) => b.compareTo(a)); // Descending
     for (final idx in toRemove) {
        if (idx >= 0 && idx < slides.length) {
           slides.removeAt(idx);
        }
     }
     
     final updatedItem = activeItem.copyWith(slides: slides);
     _syncToProject(updatedItem);
     _selectedSlides.clear();
     setState(() => _selectedIndex = slides.isNotEmpty ? 0 : 0);
  }

  void _duplicateSlide(int index) {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null) return;
     if (index < 0 || index >= activeItem.slides.length) return;
     
     final slides = List<PresentationSlide>.from(activeItem.slides);
     final original = slides[index];
     final duplicate = PresentationSlide(
        id: _uuid.v4(),
        content: original.content,
        label: original.label,
        color: original.color,
        isBold: original.isBold,
        isItalic: original.isItalic,
        isUnderlined: original.isUnderlined,
        alignment: original.alignment,
        styledRanges: List.from(original.styledRanges),
     );
     
     slides.insert(index + 1, duplicate);
     final updatedItem = activeItem.copyWith(slides: slides);
     _syncToProject(updatedItem);
  }

  void _duplicateSelectedSlides() {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null) return;
     
     final slides = List<PresentationSlide>.from(activeItem.slides);
     final indices = _selectedSlides.toList()..sort(); // Ascending
     
     int offset = 0;
     for (final idx in indices) {
        final insertAt = idx + offset + 1;
        if (idx >= 0 && idx < activeItem.slides.length) {
           final original = activeItem.slides[idx];
           final duplicate = PresentationSlide(
              id: _uuid.v4(),
              content: original.content,
              label: original.label,
              color: original.color,
              isBold: original.isBold,
              isItalic: original.isItalic,
              isUnderlined: original.isUnderlined,
              alignment: original.alignment,
              styledRanges: List.from(original.styledRanges),
           );
           slides.insert(insertAt, duplicate);
           offset++;
        }
     }
     
     final updatedItem = activeItem.copyWith(slides: slides);
     _syncToProject(updatedItem);
     _selectedSlides.clear();
  }

  void _showContextMenu(BuildContext context, Offset position, int index, PresentationSlide slide) async {
    final isMulti = _selectedSlides.length > 1 && _selectedSlides.contains(index);
    final count = isMulti ? _selectedSlides.length : 1;
    
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
         PopupMenuItem(
           value: 'delete',
           child: Row(
             children: [
               const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
               const SizedBox(width: 8),
               Text('Delete${isMulti ? ' ($count slides)' : ''}', style: const TextStyle(color: Colors.redAccent)),
             ],
           ),
         ),
         const PopupMenuItem(
           value: 'duplicate',
           child: Row(
             children: [
               Icon(LucideIcons.copy, size: 16, color: Colors.white70),
               SizedBox(width: 8),
               Text('Duplicate'),
             ],
           ),
         ),
         const PopupMenuItem(
           value: 'group',
           child: Row(
             children: [
               Icon(LucideIcons.tag, size: 16, color: Colors.white70),
               SizedBox(width: 8),
               Text('Group...'),
             ],
           ),
         ),
      ],
    );
    
    if (result == 'delete') {
       if (isMulti) {
         _deleteSelectedSlides();
       } else {
         _deleteSlide(index);
       }
    } else if (result == 'duplicate') {
       if (isMulti) {
         _duplicateSelectedSlides();
       } else {
         _duplicateSlide(index);
       }
    } else if (result == 'group') {
       if (!mounted) return;
       _showGroupDialog(context, index);
    }
  }

  void _showGroupDialog(BuildContext context, int index) {
     showDialog(
       context: context,
       builder: (context) {
          return SimpleDialog(
             title: const Text('Select Group'),
             children: [
                _groupOption(context, index, 'Verse 1', Colors.blue),
                _groupOption(context, index, 'Verse 2', Colors.blue),
                _groupOption(context, index, 'Chorus', Colors.red),
                _groupOption(context, index, 'Bridge', Colors.purple),
                _groupOption(context, index, 'Outro', Colors.orange),
                _groupOption(context, index, 'None', Colors.grey),
             ],
          );
       }
     );
  }
  
  Widget _groupOption(BuildContext context, int index, String label, MaterialColor color) {
     return SimpleDialogOption(
        onPressed: () {
           _updateSlideGroup(index, label, color.value);
           Navigator.pop(context);
        },
        child: Row(
           children: [
              Container(width: 16, height: 16, color: color, margin: const EdgeInsets.only(right: 8)),
              Text(label),
           ],
        ),
     );
  }

  void _showSidebarMenu(BuildContext context, Offset position) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
         const PopupMenuItem(
           value: 'header',
           child: Row(
             children: [
               Icon(LucideIcons.heading, size: 16, color: Colors.white54),
               SizedBox(width: 8),
               Text('Create New Header'),
             ],
           ),
         ),
         const PopupMenuItem(
           value: 'empty_slide',
           child: Row(
             children: [
               Icon(LucideIcons.filePlus, size: 16, color: Colors.white54),
               SizedBox(width: 8),
               Text('Create Empty Slide'),
             ],
           ),
         ),
      ],
    );

    if (result == 'header') {
      _addHeader();
    } else if (result == 'empty_slide') {
      _addEmptySlideItem();
    }
  }

  void _addHeader() async {
    final activeProject = ref.read(activeProjectProvider);
    if (activeProject == null) return;

    final title = await _showNameInputDialog(context, 'New Header', '');
    if (title == null || title.isEmpty) return;

    final newHeader = ServiceItem(
      id: _uuid.v4(),
      title: title,
      type: 'header',
      duration: Duration.zero,
    );

    final newItems = List<ServiceItem>.from(activeProject.items)..add(newHeader);
    final updatedProject = ServiceProject(title: activeProject.title, items: newItems);
    
    // Update Provider
    ref.read(activeProjectProvider.notifier).state = updatedProject;
  }

  void _addEmptySlideItem() async {
    final activeProject = ref.read(activeProjectProvider);
    if (activeProject == null) return;

    final title = await _showNameInputDialog(context, 'New Slide Title', '');
    if (title == null || title.isEmpty) return;

    final newSlide = PresentationSlide(
      id: _uuid.v4(),
      content: 'New Slide Text',
      label: 'Slide 1',
      color: 0xFF333333,
    );

    final newItem = ServiceItem(
      id: _uuid.v4(),
      title: title,
      type: 'song',
      slides: [newSlide],
    );

    final newItems = List<ServiceItem>.from(activeProject.items)..add(newItem);
    final updatedProject = ServiceProject(title: activeProject.title, items: newItems);
    
    // Update Provider
    ref.read(activeProjectProvider.notifier).state = updatedProject;
    // Auto-select
    ref.read(activeEditorItemProvider.notifier).state = newItem;
    widget.onSlideSelected(0);
    setState(() => _selectedIndex = 0);
  }

  void _showItemMenu(BuildContext context, Offset position, ServiceItem item) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
         const PopupMenuItem(
           value: 'rename',
           child: Row(
             children: [
               Icon(LucideIcons.pencil, size: 16, color: Colors.white54),
               SizedBox(width: 8),
               Text('Rename'),
             ],
           ),
         ),
         const PopupMenuItem(
           value: 'delete',
           child: Row(
             children: [
               Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
               SizedBox(width: 8),
               Text('Delete', style: TextStyle(color: Colors.redAccent)),
             ],
           ),
         ),
      ],
    );

    if (result == 'rename') {
      _renameItem(item);
    } else if (result == 'delete') {
      _deleteItem(item);
    }
  }

  void _renameItem(ServiceItem item) async {
     final newTitle = await _showNameInputDialog(context, 'Rename Item', item.title);
     if (newTitle == null || newTitle.isEmpty || newTitle == item.title) return;

     final activeProject = ref.read(activeProjectProvider);
     if (activeProject == null) return;

     final newItems = activeProject.items.map((i) {
        if (i.id == item.id) {
           return i.copyWith(title: newTitle);
        }
        return i;
     }).toList();

     final updatedProject = ServiceProject(title: activeProject.title, items: newItems);
     ref.read(activeProjectProvider.notifier).state = updatedProject;
     
     // Also update active item if it's the one renamed
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem?.id == item.id) {
        ref.read(activeEditorItemProvider.notifier).state = activeItem!.copyWith(title: newTitle);
     }
  }

  void _deleteItem(ServiceItem item) {
     final activeProject = ref.read(activeProjectProvider);
     if (activeProject == null) return;

     final newItems = activeProject.items.where((i) => i.id != item.id).toList();
     final updatedProject = ServiceProject(title: activeProject.title, items: newItems);
     ref.read(activeProjectProvider.notifier).state = updatedProject;

     // Clear selection if deleted
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem?.id == item.id) {
        ref.read(activeEditorItemProvider.notifier).state = null;
        setState(() => _selectedIndex = 0);
     }
  }

  Future<String?> _showNameInputDialog(BuildContext context, String title, [String? initialValue]) async {
    String? value = initialValue;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252525),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
               hintText: 'Enter title...',
               hintStyle: TextStyle(color: Colors.white24),
               enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
               focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            ),
            controller: TextEditingController(text: initialValue),
            onChanged: (val) => value = val,
            onSubmitted: (val) => Navigator.pop(context, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text('Save', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}

class _SongSearchDialog extends StatefulWidget {
  final List<OnlineSong> songs;
  final Function(OnlineSong) onSongSelected;

  const _SongSearchDialog({
    required this.songs,
    required this.onSongSelected,
  });

  @override
  State<_SongSearchDialog> createState() => _SongSearchDialogState();
}

class _SongSearchDialogState extends State<_SongSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<OnlineSong> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _filteredSongs = widget.songs;
  }

  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = widget.songs;
      } else {
        _filteredSongs = widget.songs.where((song) {
          final titleMatch = song.title.toLowerCase().contains(query.toLowerCase());
          final artistMatch = song.artist.toLowerCase().contains(query.toLowerCase());
          return titleMatch || artistMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      title: const Text('Search Songs', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by title or artist...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF383838),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterSongs,
            ),
            const SizedBox(height: 16),
            // Song Count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredSongs.length} songs found',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            // Songs List
            Expanded(
              child: _filteredSongs.isEmpty
                  ? const Center(
                      child: Text('No songs match your search', style: TextStyle(color: Colors.white38)),
                    )
                  : ListView.builder(
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = _filteredSongs[index];
                        return ListTile(
                          leading: const Icon(LucideIcons.music, color: Colors.blue, size: 20),
                          title: Text(
                            song.title,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSongSelected(song);
                          },
                          hoverColor: Colors.white10,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
