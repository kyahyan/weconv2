import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'lyrics_view.dart';

class ProjectionControlScreen extends StatefulWidget {
  const ProjectionControlScreen({super.key});

  @override
  State<ProjectionControlScreen> createState() => _ProjectionControlScreenState();
}

class _ProjectionControlScreenState extends State<ProjectionControlScreen> {
  final _serviceRepo = ServiceRepository();
  final _songRepo = SongRepository();
  
  List<Service> _services = [];
  Service? _selectedService;
  List<Song> _songs = [];
  Song? _selectedSong;
  
  // In a real app, this would be a second window or a separate route on a second screen.
  // For this V2, we will simulate "Go Live" by navigating to a full screen view.
  
  @override
  void initState() {
    super.initState();
    _fetchServices();
  }
  
  Future<void> _fetchServices() async {
    final now = DateTime.now();
    // Fetch upcoming services
    final start = now.subtract(const Duration(days: 1));
    final end = now.add(const Duration(days: 14));
    
    final services = await _serviceRepo.getServices(start, end);
    if (mounted) {
      setState(() {
        _services = services;
        // Auto select first if available
        if (_services.isNotEmpty) {
          _onServiceSelected(_services.first);
        }
      });
    }
  }
  
  Future<void> _onServiceSelected(Service service) async {
    setState(() {
      _selectedService = service;
      _selectedSong = null;
    });
    
    final songs = await _songRepo.getSongsForService(service.id);
    if (mounted) {
      setState(() {
        _songs = songs;
      });
    }
  }

  void _goLive() {
    if (_selectedSong == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LyricsView(text: _selectedSong!.content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presentation Controller'),
        actions: [
            IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Pane: Services & Songs
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Service Selector
                DropdownButton<Service>(
                  value: _selectedService,
                  hint: const Text('Select Service'),
                  isExpanded: true,
                  items: _services.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.title),
                    );
                  }).toList(),
                  onChanged: (s) => _onServiceSelected(s!),
                ),
                const Divider(),
                // Song List
                Expanded(
                  child: ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      final isSelected = song == _selectedSong;
                      return ListTile(
                        selected: isSelected,
                        title: Text(song.title),
                        onTap: () {
                          setState(() {
                            _selectedSong = song;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right Pane: Preview
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _selectedSong?.content ?? 'Select a song to preview',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _selectedSong != null ? _goLive : null,
                    icon: const Icon(Icons.tv),
                    label: const Text('GO LIVE (Fullscreen)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
}
