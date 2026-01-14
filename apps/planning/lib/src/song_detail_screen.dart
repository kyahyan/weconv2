import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:core/core.dart'; // Added for SongRepository

class SongDetailScreen extends StatefulWidget {
  final Song? song;
  final String? songId;

  const SongDetailScreen({
    super.key, 
    this.song,
    this.songId,
  }) : assert(song != null || songId != null, 'Either song or songId must be provided');

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  final _songRepo = SongRepository(); 
  Song? _song;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    if (_song != null) {
      _isLoading = false;
    } else {
      _fetchSong();
    }
  }

  Future<void> _fetchSong() async {
    try {
      final song = await _songRepo.getSongById(widget.songId!);
      if (mounted) {
        setState(() {
          _song = song;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Could show error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Song not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_song!.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _song!.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_song!.artist.isNotEmpty)
              Text(
                'Artist: ${_song!.artist}',
                style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 8),
            Chip(label: Text('Key: ${_song!.key}')),
            const Divider(height: 32),
            Text(
              _song!.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
