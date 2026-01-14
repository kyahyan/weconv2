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
  List<ServiceItem> _songs = [];    // Display only songs
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
          // Filter only songs for this screen
          _songs = _allItems.where((i) => i.type == 'song').toList();
          // Sort songs by orderIndex just in case
          _songs.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
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

  Future<void> _addServiceItem(Song song) async {
    // Determine new order index: Max of all items + 1
    final maxOrder = _allItems.fold(-1, (max, item) => item.orderIndex > max ? item.orderIndex : max);
    
    final newItem = ServiceItem(
      id: '', // DB generates
      serviceId: widget.serviceId,
      title: song.title,
      type: 'song',
      songId: song.id,
      orderIndex: maxOrder + 1,
      durationSeconds: null, 
    );

    // Optimistic update
    setState(() {
      _allItems.add(newItem);
      _songs.add(newItem);
    });

    try {
      await _serviceRepo.createServiceItem(newItem);
      _fetchData(); // Refresh to get real IDs
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding song: $e')));
      _fetchData(); // Revert
    }
  }

  Future<void> _deleteItem(ServiceItem item) async {
    final indexAll = _allItems.indexOf(item);
    final indexSong = _songs.indexOf(item);
    
    setState(() {
      _allItems.remove(item);
      _songs.remove(item);
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
         if(indexSong != -1) _songs.insert(indexSong, item);
      });
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // 1. Get the list of orderIndices currently occupied by songs
    // We assume _songs is sorted by display order, which should match orderIndex order roughly
    // BUT since we are reordering, we need the "slots" available.
    final songSlots = _songs.map((s) => s.orderIndex).toList()..sort();
    
    // 2. Move the item in the _songs list
    final item = _songs.removeAt(oldIndex);
    _songs.insert(newIndex, item);

    // 3. Re-assign orderIndices from the sorted "slots" to the new song order
    // This ensures we only swap positions among songs and don't overwrite non-song indices
    final updates = <ServiceItem>[];
    for (int i = 0; i < _songs.length; i++) {
      if (i < songSlots.length) {
        final newOrder = songSlots[i];
        if (_songs[i].orderIndex != newOrder) {
          _songs[i] = _songs[i].copyWith(orderIndex: newOrder);
          updates.add(_songs[i]);
          
          // Update in _allItems as well
          final allIndex = _allItems.indexWhere((x) => x.id == _songs[i].id);
          if (allIndex != -1) {
            _allItems[allIndex] = _songs[i];
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
                    itemCount: _songs.length,
                    onReorder: _reorder,
                    itemBuilder: (context, index) {
                      final item = _songs[index];
                      // Use a ValueKey that is unique. If id is empty (optimistic), use index.
                      final key = item.id.isNotEmpty ? ValueKey(item.id) : ValueKey('temp_$index');
                      
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSong,
        icon: const Icon(Icons.add),
        label: const Text('Add Song'),
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
