import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../service/service_model.dart';
import '../service/service_timeline.dart';
import 'song_lineup_editor.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editor_provider.dart';
import 'lyrics_parser.dart';

class ServiceEditor extends ConsumerStatefulWidget {
  final File file;

  const ServiceEditor({super.key, required this.file});

  @override
  ConsumerState<ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends ConsumerState<ServiceEditor> {
  ServiceProject? _project;
  bool _isLoading = true;
  String? _error;
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _loadFile();
    
    // Restore selection if provider has it (e.g. returning from another tab)
    final initialItem = ref.read(activeEditorItemProvider);
    if (initialItem != null) {
       _selectedItemId = initialItem.id;
    }
  }

  @override
  void didUpdateWidget(covariant ServiceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await widget.file.readAsString();
      if (content.isEmpty) {
        // New empty file
        final newProject = ServiceProject(title: 'New Service', items: []);
        setState(() {
            _project = newProject;
           _isLoading = false;
        });
        // Sync to provider and clear stale item selection
        Future.microtask(() {
          ref.read(activeProjectProvider.notifier).state = newProject;
          ref.read(activeEditorItemProvider.notifier).state = null;
        });
        return;
      }
      
      try {
          final json = jsonDecode(content);
          final loadedProject = ServiceProject.fromJson(json);
          setState(() {
            _project = loadedProject;
            _isLoading = false;
          });
          // Sync to provider
          Future.microtask(() async {
             var projectToSync = loadedProject;
             bool projectUpdated = false;

             print('DEBUG: Processing ${projectToSync.items.length} items for auto-parsing.');

             // Identify items needing fetch
             final itemsToFetch = <String, String>{}; // map item.id -> song.id
             for (var item in projectToSync.items) {
                 if (item.type == 'song' && item.slides.isEmpty && (item.description == null || item.description!.isEmpty)) {
                     if (item.songId != null && item.songId!.isNotEmpty) {
                         itemsToFetch[item.id] = item.songId!;
                     }
                 }
             }

             if (itemsToFetch.isNotEmpty) {
                  print('DEBUG: Found ${itemsToFetch.length} items needing lyrics fetch from Supabase.');
                  // Fetch from Supabase
                  try {
                     final response = await Supabase.instance.client
                         .from('songs')
                         .select('id, content')
                         .inFilter('id', itemsToFetch.values.toList());
                     
                     final fetchedContent = {
                        for (var row in (response as List)) 
                           row['id'] as String: row['content'] as String?
                     };
                     
                     // Update project logic
                     final updatedItems = projectToSync.items.map((item) {
                        // Case 1: Just fetched content
                        if (itemsToFetch.containsKey(item.id)) {
                           final songId = itemsToFetch[item.id];
                           final content = fetchedContent[songId];
                           if (content != null && content.isNotEmpty) {
                               print('DEBUG: Fetched content for "${item.title}". Parsing...');
                               final slides = LyricsParser.parse(content);
                               if (slides.isNotEmpty) {
                                  projectUpdated = true;
                                  return item.copyWith(slides: slides, description: content);
                               }
                           }
                        }
                        
                        // Case 2: Already had content but needed parsing (Previous logic)
                        if (item.type == 'song' && item.slides.isEmpty && (item.description?.isNotEmpty ?? false)) {
                           print('DEBUG: Parsing existing description for "${item.title}"...');
                           final slides = LyricsParser.parse(item.description!);
                           if (slides.isNotEmpty) {
                              projectUpdated = true;
                              return item.copyWith(slides: slides);
                           }
                        }
                        return item;
                     }).toList();

                     if (projectUpdated) {
                        projectToSync = ServiceProject(title: projectToSync.title, items: updatedItems);
                        ref.read(activeProjectProvider.notifier).state = projectToSync;
                        if (mounted) {
                           setState(() {
                              _project = projectToSync;
                           });
                        }
                     }
                  } catch (e) {
                      print('DEBUG: Error fetching lyrics from Supabase: $e');
                  }
             } else {
                 // Standard auto-parse loop if no fetch needed
                 final updatedItems = projectToSync.items.map((item) {
                    if (item.type == 'song' && item.slides.isEmpty && (item.description?.isNotEmpty ?? false)) {
                       final slides = LyricsParser.parse(item.description!);
                       if (slides.isNotEmpty) {
                          projectUpdated = true;
                          return item.copyWith(slides: slides);
                       }
                    }
                    return item;
                 }).toList();

                 if (projectUpdated) {
                    projectToSync = ServiceProject(title: projectToSync.title, items: updatedItems);
                    ref.read(activeProjectProvider.notifier).state = projectToSync;
                    if (mounted) setState(() => _project = projectToSync);
                 }
             }
             
             // Ensure provider is set at least once if not updated above
             if (!projectUpdated) {
                ref.read(activeProjectProvider.notifier).state = projectToSync;
             }
             
             // Clear stale selection if item doesn't exist in this project
             final currentItem = ref.read(activeEditorItemProvider);
             if (currentItem != null && !projectToSync.items.any((i) => i.id == currentItem.id)) {
                ref.read(activeEditorItemProvider.notifier).state = null;
             }
             
             // Auto-select first song if no valid selection
             if (ref.read(activeEditorItemProvider) == null) {
                final firstSong = projectToSync.items.firstWhere((i) => i.type == 'song', orElse: () => ServiceItem(id: '', title: '', type: ''));
                if (firstSong.id.isNotEmpty) {
                   ref.read(activeEditorItemProvider.notifier).state = firstSong;
                   if (mounted) setState(() => _selectedItemId = firstSong.id);
                }
             }
          });
      } catch (e) {
           setState(() {
            _error = 'Invalid JSON: $e';
            _isLoading = false;
          });
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_project == null) return;
    try {
      final json = jsonEncode(_project!.toJson());
      await widget.file.writeAsString(json);
      // Optional: Show snackbar or visual indicator? 
      // For now silent auto-save is fine or debug print
      debugPrint('Saved service to ${widget.file.path}');
    } catch (e) {
      debugPrint('Error saving: $e');
    }
  }

  void _onReorder(List<ServiceItem> newItems) {
    setState(() {
      _project = ServiceProject(title: _project!.title, items: newItems);
    });
    _save();
  }

  void _onAddItem(ServiceItem item) {
    setState(() {
      final newItems = List<ServiceItem>.from(_project!.items)..add(item);
      _project = ServiceProject(title: _project!.title, items: newItems);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to project provider changes and auto-save
    ref.listen<ServiceProject?>(activeProjectProvider, (previous, next) {
      if (next != null && previous != null && next != previous) {
        _project = next;
        _save();
      }
    });

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }
    
    if (_project == null) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editor Header with Title
          Container(
             padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Text(
                    _project!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
               ],
             ),
          ),
          
          // Single view: Program (Split View)
          Expanded(
            child: Row( 
              children: [
                // Left: Timeline List
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white10)),
                    ),
                    child: ServiceTimeline(
                      items: _project!.items,
                      onReorder: _onReorder,
                      onAddItem: _onAddItem,
                      selectedItemId: _selectedItemId,
                      onItemSelected: _onItemSelected,
                    ),
                  ),
                ),
                
                // Right: Detail View
                Expanded(
                  flex: 2,
                  child: _buildDetailView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onItemSelected(String id) {
    setState(() {
      _selectedItemId = id;
    });
    
    // Find the item and update provider ONLY for song/header types (not program items)
    if (_project != null) {
       final item = _project!.items.firstWhere((i) => i.id == id, orElse: () => ServiceItem(id: '', title: '', type: 'unknown'));
       if (item.id.isNotEmpty && (item.type == 'song' || item.type == 'header')) {
          ref.read(activeEditorItemProvider.notifier).state = item;
       }
    }
  }

  Widget _buildDetailView() {
    if (_selectedItemId == null) {
      return const Center(child: Text('Select an item to view details', style: TextStyle(color: Colors.white24)));
    }

    ServiceItem? selectedItem;
    List<ServiceItem> filteredItems = _project!.items;

    if (_selectedItemId != null && _selectedItemId!.startsWith('worship-set-')) {
      final firstSongId = _selectedItemId!.replaceFirst('worship-set-', '');
      
      selectedItem = ServiceItem(
        id: _selectedItemId!,
        title: 'Worship Set', 
        type: 'worship_set',
      );
      
      // Filter songs for this specific block
      final List<ServiceItem> blockSongs = [];
      bool capturing = false;
      for (var item in _project!.items) {
         if (item.id == firstSongId) {
            capturing = true;
         }
         
         if (capturing) {
            if (item.type == 'song') {
               blockSongs.add(item);
            } else {
               break; // End of block
            }
         }
      }
      filteredItems = blockSongs;
      
    } else {
        selectedItem = _project!.items.firstWhere(
          (item) => item.id == _selectedItemId,
          orElse: () => ServiceItem(id: '', title: '', type: 'unknown'), 
        );
    }

    if (selectedItem.id.isEmpty) {
       return const Center(child: Text('Item not found', style: TextStyle(color: Colors.white24)));
    }
    
    // Switch based on type (Currently mainly supporting Song Lineup)
    if (selectedItem.type == 'song' || selectedItem.type == 'worship_set') {
      return SongLineupEditor(activeItem: selectedItem, allItems: filteredItems);
    } 
    
    // Generic/Mock view for other types for now
    return SongLineupEditor(activeItem: selectedItem, allItems: filteredItems); // Reuse for now as it handles 'else' cases logic too
  }
}
