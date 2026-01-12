import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:intl/intl.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.service});

  final Service service;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _songRepo = SongRepository();
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    try {
      final songs = await _songRepo.getSongsForService(widget.service.id);
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading songs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              DateFormat('MMMM d, yyyy - h:mm a').format(widget.service.date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Order of Service',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: _songs.isEmpty
                ? const Center(child: Text('No songs added yet.'))
                : ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      // TODO: Implement reorder logic in DB
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = _songs.removeAt(oldIndex);
                        _songs.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int i = 0; i < _songs.length; i++)
                        ListTile(
                          key: ValueKey(_songs[i].id),
                          leading: CircleAvatar(child: Text('${i + 1}')),
                          title: Text(_songs[i].title),
                          subtitle: Text('Key: ${_songs[i].key}'),
                          trailing: const Icon(Icons.drag_handle),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSongDialog,
        child: const Icon(Icons.music_note),
      ),
    );
  }

  Future<void> _showAddSongDialog() async {
    // Simple dialog to mock picking a song for now
    // In a real app, this would be a SearchDelegate or a separate screen
    // For now, let's just create a dummy song entry to verify the flow if database is empty 
    // OR search if we have data.
    
    // We will implement a simple search dialog
    showDialog(
      context: context,
      builder: (context) => _SongSearchDialog(
        onSongSelected: (song) async {
          // Add song to service
          try {
             // Basic order logic: add to end
            final order = _songs.length + 1;
            await _songRepo.addSongToService(
              serviceId: widget.service.id,
              songId: song.id,
              order: order,
            );
            Navigator.pop(context);
            _fetchSongs();
          } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add song: $e')),
            );
          }
        },
      ),
    );
  }
}

class _SongSearchDialog extends StatefulWidget {
  const _SongSearchDialog({required this.onSongSelected});

  final Function(Song) onSongSelected;

  @override
  State<_SongSearchDialog> createState() => _SongSearchDialogState();
}

class _SongSearchDialogState extends State<_SongSearchDialog> {
  final _songRepo = SongRepository();
  List<Song> _searchResults = [];
  final _searchController = TextEditingController();

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    final results = await _songRepo.searchSongs(query);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Song'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Songs',
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final song = _searchResults[index];
                  return ListTile(
                    title: Text(song.title),
                    subtitle: Text(song.artist),
                    onTap: () => widget.onSongSelected(song),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
