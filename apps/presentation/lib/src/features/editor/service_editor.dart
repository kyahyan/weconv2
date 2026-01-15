import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../service/service_model.dart';
import '../service/service_timeline.dart';
import 'song_lineup_editor.dart';

class ServiceEditor extends StatefulWidget {
  final File file;

  const ServiceEditor({super.key, required this.file});

  @override
  State<ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends State<ServiceEditor> {
  ServiceProject? _project;
  bool _isLoading = true;
  String? _error;
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _loadFile();
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
        setState(() {
            _project = ServiceProject(title: 'New Service', items: []);
           _isLoading = false;
        });
        return;
      }
      
      try {
          final json = jsonDecode(content);
          setState(() {
            _project = ServiceProject.fromJson(json);
            _isLoading = false;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }
    
    if (_project == null) return const SizedBox.shrink();

    final fullLineUpItem = ServiceItem(
      id: 'full-line-up', 
      title: 'Full Service Lineup', 
      type: 'worship_set', 
    );

    return DefaultTabController(
      length: 2,
      child: Container(
        color: const Color(0xFF1E1E1E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editor Header with Title and Tabs
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
                    const TabBar(
                      isScrollable: true,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.white60,
                      indicatorColor: Colors.blue,
                      dividerColor: Colors.transparent,
                      tabAlignment: TabAlignment.start, 
                      tabs: [
                        Tab(text: "Program"),
                        Tab(text: "Line Up"),
                      ]
                    ),
                 ],
               ),
            ),
            
            Expanded(
              child: TabBarView( 
                children: [
                  // Tab 1: Program (Split View)
                  Row( 
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

                  // Tab 2: Line Up (Full Song List)
                  Container(
                    color: const Color(0xFF1E1E1E), // Ensure background matches
                    child: SongLineupEditor(
                      activeItem: fullLineUpItem, 
                      allItems: _project!.items,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemSelected(String id) {
    setState(() {
      _selectedItemId = id;
    });
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
