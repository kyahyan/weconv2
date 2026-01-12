import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
// import 'package:ui_kit/ui_kit.dart'; // Optional if needed for theme

class MusicStandScreen extends StatefulWidget {
  const MusicStandScreen({super.key, required this.service});

  final Service service;

  @override
  State<MusicStandScreen> createState() => _MusicStandScreenState();
}

class _MusicStandScreenState extends State<MusicStandScreen> {
  final _songRepo = SongRepository();
  List<Song> _songs = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.service.title} (${_currentPage + 1}/${_songs.length})'),
        centerTitle: true,
      ),
      body: _songs.isEmpty
          ? const Center(child: Text('No songs in this service.'))
          : PageView.builder(
              controller: _pageController,
              itemCount: _songs.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final song = _songs[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            song.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Key: ${song.key} | Artist: ${song.artist}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Divider(height: 32),
                        Text(
                          song.content,
                          style: const TextStyle(
                            fontFamily: 'Courier', // Monospace for chords
                            fontSize: 18,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
