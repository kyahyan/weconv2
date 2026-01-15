import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../service/service_model.dart';
import 'editor_provider.dart';
import 'service_editor.dart';
import 'song_lineup_editor.dart';

class MainEditorArea extends ConsumerWidget {
  const MainEditorArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(activeFileProvider);

    if (activeFile == null) {
      return const Center(
        child: Text('Select a file', style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }

    final ext = p.extension(activeFile.path);

    if (ext == '.wc_service') {
      return ServiceEditor(file: activeFile); // Key will be auto-updated by widget logic
    } else if (ext == '.wc_lineup') {
      // Create a logical item for the file
      final dummyItem = ServiceItem(
        id: 'file-mode',
        title: p.basenameWithoutExtension(activeFile.path),
        type: 'song',
      );
      return SongLineupEditor(activeItem: dummyItem, allItems: [dummyItem]);
    } else {
      return Center(
        child: Text('Unknown file type: $ext', style: const TextStyle(color: Colors.white54)),
      );
    }
  }
}
