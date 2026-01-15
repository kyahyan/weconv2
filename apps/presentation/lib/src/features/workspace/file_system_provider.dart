import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Provider for the root directory path
final rootDirectoryProvider = FutureProvider<Directory>((ref) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final rootDir = Directory(p.join(docsDir.path, 'WeConnect'));
  
  if (!await rootDir.exists()) {
    await rootDir.create(recursive: true);
  }
  return rootDir;
});

// Model for File System Nodes
class FileSystemNode {
  final String path;
  final bool isDirectory;
  final String name;
  final List<FileSystemNode>? children; // Null if not a directory or not loaded

  FileSystemNode({
    required this.path,
    required this.isDirectory,
    required this.name,
    this.children,
  });
}

// State for the explorer (AsyncValue of list of root nodes)
class WorkspaceController extends AsyncNotifier<List<FileSystemNode>> {
  @override
  Future<List<FileSystemNode>> build() async {
    final rootDir = await ref.watch(rootDirectoryProvider.future);
    return _loadDirectory(rootDir);
  }

  Future<List<FileSystemNode>> _loadDirectory(Directory dir) async {
    if (!await dir.exists()) return [];
    
    final entities = await dir.list().toList();
    // Sort: Folders first, then files. Alphabetical.
    entities.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
    });

    final nodes = <FileSystemNode>[];
    for (final entity in entities) {
      final isDir = entity is Directory;
      final name = p.basename(entity.path);
      
      List<FileSystemNode>? children;
      if (isDir) {
        children = await _loadDirectory(entity as Directory);
      }

      nodes.add(FileSystemNode(
        path: entity.path,
        isDirectory: isDir,
        name: name,
        children: children,
      ));
    }
    return nodes;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final rootDir = await ref.read(rootDirectoryProvider.future);
      return _loadDirectory(rootDir);
    });
  }

  Future<void> createFolder(String parentPath, String name) async {
    // If parentPath is null or empty, use root? actually UI passes path.
    // If creating a project at root, parentPath should be rootDir.path
    
    // Logic fix: Ensure we are joining correctly.
    final newDir = Directory(p.join(parentPath, name));
    if (!await newDir.exists()) {
      await newDir.create();
      await refresh();
    }
  }

  Future<void> createProject(String name) async {
     final rootDir = await ref.read(rootDirectoryProvider.future);
     await createFolder(rootDir.path, name);
  }

  Future<void> createFile(String parentPath, String name, String extension, String content) async {
    final fileName = name.endsWith(extension) ? name : '$name$extension';
    final newFile = File(p.join(parentPath, fileName));
    if (!await newFile.exists()) {
      await newFile.writeAsString(content);
      await refresh();
    }
  }

  Future<void> deleteEntity(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else if (type == FileSystemEntityType.file) {
      await File(path).delete();
    }
    await refresh();
  }

  Future<void> renameEntity(String path, String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return;

    final oldEntity =  await FileSystemEntity.type(path) == FileSystemEntityType.directory
       ? Directory(path)
       : File(path);
    
    final parentPath = p.dirname(path);
    final newPath = p.join(parentPath, cleanName);
    
    await oldEntity.rename(newPath);
    await refresh();
  }

  Future<void> moveEntity(String sourcePath, String targetParentPath) async {
    final sourceEntity = await FileSystemEntity.type(sourcePath) == FileSystemEntityType.directory
        ? Directory(sourcePath)
        : File(sourcePath);
        
    final fileName = p.basename(sourcePath);
    final newPath = p.join(targetParentPath, fileName);
    
    // Prevent moving into itself or same directory
    if (sourcePath == newPath || p.dirname(sourcePath) == targetParentPath) return;

    await sourceEntity.rename(newPath);
    await refresh();
  }
}

final workspaceControllerProvider = AsyncNotifierProvider<WorkspaceController, List<FileSystemNode>>(WorkspaceController.new);
