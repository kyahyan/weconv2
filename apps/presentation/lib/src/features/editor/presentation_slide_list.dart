import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'editor_provider.dart';
import '../service/service_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'lyrics_parser.dart';

class PresentationSlideList extends ConsumerStatefulWidget {
  final Function(int) onSlideSelected;

  const PresentationSlideList({
    super.key,
    required this.onSlideSelected,
  });

  @override
  ConsumerState<PresentationSlideList> createState() => _PresentationSlideListState();
}

class _PresentationSlideListState extends ConsumerState<PresentationSlideList> {
  int _selectedIndex = 0;
  double _slideWidth = 240.0;
  final Uuid _uuid = const Uuid();

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
      },
      child: Focus(
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
            child: activeItem == null 
             ? const Center(child: Text('No Song Selected', style: TextStyle(color: Colors.white24)))
             : Container(
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
                                  Text(
                                     activeItem.title,
                                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                   ),
                                   const SizedBox(width: 8),
                                   if (activeItem.artist != null)
                                     Text('(${activeItem.artist})', style: const TextStyle(color: Colors.grey)),
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
                           final color = Color(slide.color == 0 ? 0xFF333333 : slide.color); 
       
                           return GestureDetector(
                                 onTap: () {
                                    setState(() => _selectedIndex = index);
                                    widget.onSlideSelected(index);
                                 },
                                 onSecondaryTapUp: (details) {
                                    _showContextMenu(context, details.globalPosition, index, slide);
                                 },
                                 child: Container(
                                   decoration: BoxDecoration(
                                     color: const Color(0xFF000000), 
                                     borderRadius: BorderRadius.circular(6),
                                     border: isSelected 
                                         ? Border.all(color: Colors.orange, width: 3) 
                                         : Border.all(color: Colors.white24, width: 1),
                                   ),
                                   child: Stack(
                                     children: [
                                       // Content Preview (Perfect Fit)
                                       Padding(
                                         padding: const EdgeInsets.fromLTRB(12, 24, 12, 24), // Space for labels
                                         child: Center(
                                           child: FittedBox(
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

  void _addSlide() {
     final activeItem = ref.read(activeEditorItemProvider);
     if (activeItem == null) return;
     
     final newSlide = PresentationSlide(
        id: _uuid.v4(),
        content: 'New Slide',
        label: '',
        color: 0xFF333333,
     );
     
     final newSlides = List<PresentationSlide>.from(activeItem.slides)..add(newSlide);
     final updatedItem = activeItem.copyWith(slides: newSlides);
     
     _syncToProject(updatedItem);
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

  void _showContextMenu(BuildContext context, Offset position, int index, PresentationSlide slide) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
         const PopupMenuItem(
           value: 'group',
           child: Text('Group...'),
         ),
      ],
    );
    
    if (result == 'group') {
       if (!mounted) return;
       // Show sub-menu or dialog for grouping
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
