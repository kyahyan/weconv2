import 'dart:io';
import 'package:file_selector/file_selector.dart'; // For picking files
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Define supported extensions
const _imageExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'};
const _videoExtensions = {'.mp4', '.mov', '.avi', '.mkv', '.webm'};

class MediaManagerController extends AsyncNotifier<List<FileSystemEntity>> {
  late Directory _assetsDir;
  late Directory _imagesDir;
  late Directory _videosDir;

  @override
  Future<List<FileSystemEntity>> build() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final rootDir = Directory(p.join(docsDir.path, 'WeConnect'));
    _assetsDir = Directory(p.join(rootDir.path, 'Assets'));
    _imagesDir = Directory(p.join(_assetsDir.path, 'Images'));
    _videosDir = Directory(p.join(_assetsDir.path, 'Videos'));

    await _ensureDirectories();
    return _loadAssets();
  }

  Future<void> _ensureDirectories() async {
    if (!await _imagesDir.exists()) await _imagesDir.create(recursive: true);
    if (!await _videosDir.exists()) await _videosDir.create(recursive: true);
  }

  Future<List<FileSystemEntity>> _loadAssets() async {
    final images = _imagesDir.listSync().toList();
    final videos = _videosDir.listSync().toList();
    // Return combined list, maybe sorted by date?
    final all = [...images, ...videos];
     all.sort((a, b) {
      // Sort by modified time descending (newest first)
      return b.statSync().modified.compareTo(a.statSync().modified);
    });
    return all;
  }

  Future<void> importMedia() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Media',
      extensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    
    if (file == null) return;

    final sourceFile = File(file.path);
    final ext = p.extension(sourceFile.path).toLowerCase();
    
    Directory targetDir;
    if (_imageExtensions.contains(ext)) {
      targetDir = _imagesDir;
    } else if (_videoExtensions.contains(ext)) {
      targetDir = _videosDir;
    } else {
      // Unsupported or handle as misc? For now ignore.
      return;
    }

    // Determine target path with conflict resolution
    String filename = p.basename(sourceFile.path);
    String targetPath = p.join(targetDir.path, filename);
    
    // Conflict resolution: File (1).jpg
    int counter = 1;
    while (await File(targetPath).exists()) {
      final nameWithoutExt = p.basenameWithoutExtension(filename);
      // Check if name already has (n) pattern? 
      // Simplest: just name_n.ext or name (n).ext
      // If we import "foo.jpg" and it exists, try "foo (1).jpg".
      // If "foo (1).jpg" exists, try "foo (2).jpg".
      
      // CAREFUL: If we are in the loop, 'filename' is the original one.
      // We need to construct a NEW filename based on original one each iter or just increment?
      // Better:
      final originalName = p.basenameWithoutExtension(sourceFile.path);
      final newName = '$originalName ($counter)$ext';
      targetPath = p.join(targetDir.path, newName);
      counter++;
    }

    // Perform Copy
    await sourceFile.copy(targetPath);
    
    // Check if we need to return the RELATIVE path as per requirements
    // relative path = Assets/Images/foo.jpg or Assets/Videos/bar.mp4
    // We update state regardless.
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadAssets());
  }
}

final mediaManagerProvider = AsyncNotifierProvider<MediaManagerController, List<FileSystemEntity>>(MediaManagerController.new);
