import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';
import 'package:intl/intl.dart';

class CreateLineUpScreen extends StatefulWidget {
  final String serviceId;

  const CreateLineUpScreen({super.key, required this.serviceId});

  @override
  State<CreateLineUpScreen> createState() => _CreateLineUpScreenState();
}

class _CreateLineUpScreenState extends State<CreateLineUpScreen> {
  final _serviceRepo = ServiceRepository();
  final _songRepo = SongRepository(); 
  
  Service? _service;
  List<ServiceItem> _allItems = []; // Keep all items to maintain structure
  List<ServiceItem> _displayItems = [];    // Display songs and headers
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _serviceRepo.getServiceById(widget.serviceId),
        _serviceRepo.getServiceItems(widget.serviceId),
      ]);

      if (mounted) {
        setState(() {
          _service = results[0] as Service?;
          _allItems = results[1] as List<ServiceItem>;
          // Filter songs and headers for this screen
          _displayItems = _allItems.where((i) => i.type == 'song' || i.type == 'header').toList();
          // Sort by orderIndex
          _displayItems.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading: $e')));
    }
  }

  Future<void> _addSong() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SongSearchSheet(
        onSongSelected: (song) async {
          Navigator.pop(context); // Close sheet
          _addServiceItem(song);
        },
      ),
    );
  }

  Future<void> _addHeader() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Header'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Header Title (e.g. Praise, Worship)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text), 
            child: const Text('Add')
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
       _createServiceItem(result, 'header');
    }
  }

  Future<void> _addServiceItem(Song song) async {
    await _createServiceItem(song.title, 'song', songId: song.id);
  }

  Future<void> _createServiceItem(String title, String type, {String? songId}) async {
    // Determine new order index: Max of all items + 1
    final maxOrder = _allItems.fold(-1, (max, item) => item.orderIndex > max ? item.orderIndex : max);
    
    final newItem = ServiceItem(
      id: '', // DB generates
      serviceId: widget.serviceId,
      title: title,
      type: type,
      songId: songId,
      orderIndex: maxOrder + 1,
      durationSeconds: null, 
    );

    // Optimistic update
    setState(() {
      _allItems.add(newItem);
      _displayItems.add(newItem);
    });

    try {
      await _serviceRepo.createServiceItem(newItem);
      _fetchData(); // Refresh to get real IDs
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
      _fetchData(); // Revert
    }
  }

  Future<void> _deleteItem(ServiceItem item) async {
    final indexAll = _allItems.indexOf(item);
    final indexDisplay = _displayItems.indexOf(item);
    
    setState(() {
      _allItems.remove(item);
      _displayItems.remove(item);
    });

    try {
      if (item.id.isNotEmpty) {
        await _serviceRepo.deleteServiceItem(item.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
      // Revert
      setState(() {
         if(indexAll != -1) _allItems.insert(indexAll, item);
         if(indexDisplay != -1) _displayItems.insert(indexDisplay, item);
      });
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // 1. Get the list of orderIndices currently occupied by displayed items
    // This allows reordering ONLY relative to other displayed items, preserving gaps if any (though unlikely here)
    final displaySlots = _displayItems.map((s) => s.orderIndex).toList()..sort();
    
    // 2. Move the item in the list
    final item = _displayItems.removeAt(oldIndex);
    _displayItems.insert(newIndex, item);

    // 3. Re-assign orderIndices
    final updates = <ServiceItem>[];
    for (int i = 0; i < _displayItems.length; i++) {
      if (i < displaySlots.length) {
        final newOrder = displaySlots[i];
        if (_displayItems[i].orderIndex != newOrder) {
          _displayItems[i] = _displayItems[i].copyWith(orderIndex: newOrder);
          updates.add(_displayItems[i]);
          
          // Update in _allItems as well
          final allIndex = _allItems.indexWhere((x) => x.id == _displayItems[i].id);
          if (allIndex != -1) {
            _allItems[allIndex] = _displayItems[i];
          }
        }
      }
    }
    
    setState(() {});

    if (updates.isNotEmpty) {
      try {
        await _serviceRepo.updateServiceItemsOrder(updates);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reordering: $e')));
        _fetchData(); // Revert
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Line Up'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _service == null
          ? const Center(child: Text('Service not found'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Line Up for ${_service!.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: _displayItems.length,
                    onReorder: _reorder,
                    itemBuilder: (context, index) {
                      final item = _displayItems[index];
                      // Use a ValueKey that is unique. If id is empty (optimistic), use index.
                      final key = item.id.isNotEmpty ? ValueKey(item.id) : ValueKey('temp_${item.title}_$index');
                      
                      if (item.type == 'header') {
                        return ListTile(
                          key: key,
                          leading: const Icon(Icons.drag_handle),
                          tileColor: Colors.grey[200],
                          title: Center(
                            child: Text(
                              item.title.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                letterSpacing: 1.2
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(item), 
                          ),
                        );
                      }

                      return ListTile(
                        key: key, 
                        leading: const Icon(Icons.drag_handle),
                        title: Text(item.title),
                        subtitle: const Text('Song'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(item), 
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
           FloatingActionButton.extended(
            heroTag: 'add_header',
            onPressed: _addHeader,
            icon: const Icon(Icons.title),
            label: const Text('Add Header'),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add_song',
            onPressed: _addSong,
            icon: const Icon(Icons.music_note),
            label: const Text('Add Song'),
          ),
        ],
      ),
    );
  }
}

class _SongSearchSheet extends StatefulWidget {
  final Function(Song) onSongSelected;
  const _SongSearchSheet({required this.onSongSelected});

  @override
  State<_SongSearchSheet> createState() => _SongSearchSheetState();
}

class _SongSearchSheetState extends State<_SongSearchSheet> {
  final _songRepo = SongRepository();
  List<Song> _results = [];
  bool _searching = false;
  
  void _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final songs = await _songRepo.searchSongs(query);
      if (mounted) setState(() => _results = songs);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Search Songs',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => _search(val),
          ),
          const SizedBox(height: 16),
          if (_searching)
            const LinearProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final song = _results[index];
                  return ListTile(
                    title: Text(song.title),
                     // song.artist or key if available in model
                    onTap: () => widget.onSongSelected(song),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
