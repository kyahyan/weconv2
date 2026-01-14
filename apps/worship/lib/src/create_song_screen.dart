import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:uuid/uuid.dart';

class CreateSongScreen extends StatefulWidget {
  const CreateSongScreen({super.key});

  @override
  State<CreateSongScreen> createState() => _CreateSongScreenState();
}

class _CreateSongScreenState extends State<CreateSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _keyController = TextEditingController(); // Or dropdown
  final _contentController = TextEditingController();
  
  final _songRepo = SongRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _keyController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveSong() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newSong = Song(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        key: _keyController.text.trim(),
        content: _contentController.text,
      );

      await _songRepo.createSong(newSong);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving song: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Song'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Song Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: 'Artist',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter an artist' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Key (e.g., C, G, Em)',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a key' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Lyrics / Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              validator: (value) => value == null || value.isEmpty ? 'Please enter content' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSong,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Save Song'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
