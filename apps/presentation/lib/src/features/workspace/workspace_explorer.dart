import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'file_system_provider.dart';
import '../editor/editor_provider.dart';

class WorkspaceExplorer extends ConsumerStatefulWidget {
  const WorkspaceExplorer({super.key});

  @override
  ConsumerState<WorkspaceExplorer> createState() => _WorkspaceExplorerState();
}

class _WorkspaceExplorerState extends ConsumerState<WorkspaceExplorer> {
  // Track expanded paths
  final Set<String> _expandedPaths = {};
  String? _selectedNodePath; // Tracks UI selection (highlight)

  @override
  Widget build(BuildContext context) {
    // Use the renamed provider
    final fileSystem = ref.watch(workspaceControllerProvider);
    // We still watch activeFileProvider to sync back if needed, but local selection drives highlight?
    // Actually, let's keep it simple: Local selection drives highlight.
    // Sync to provider if file.
    
    return Container(
      color: Colors.transparent, // Replaces ShadCard
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF2D2D2D),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Workspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                     // Create Project Button
                     IconButton(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(LucideIcons.plus, color: Colors.white70),
                        onPressed: _showCreateProjectDialog,
                        tooltip: 'New Project',
                     ),
                     const SizedBox(width: 4),
                     // Delete Button
                     IconButton(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(LucideIcons.trash2, 
                          color: _selectedNodePath != null ? Colors.red[300] : Colors.white24
                        ),
                        onPressed: _selectedNodePath != null 
                          ? () => _delete(FileSystemNode(path: _selectedNodePath!, name: p.basename(_selectedNodePath!), isDirectory: false)) // Hack: reconstruction just for delete check
                          : null,
                        tooltip: 'Delete Selected',
                     ),
                     const SizedBox(width: 4),
                     // Refresh button
                     IconButton(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(LucideIcons.refreshCw, color: Colors.white70),
                        onPressed: () => ref.read(workspaceControllerProvider.notifier).refresh(),
                        tooltip: 'Refresh',
                     ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: fileSystem.when(
              data: (nodes) {
                if (nodes.isEmpty) {
                  return const Center(
                    child: Text('No Projects Found', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(4),
                  children: nodes.map((node) => _buildNode(node, 0)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(FileSystemNode node, int depth) {
    final isExpanded = _expandedPaths.contains(node.path);
    final isSelected = _selectedNodePath == node.path;
    final hasChildren = node.children != null && node.children!.isNotEmpty;

    // Determine Icon
    IconData icon;
    if (node.isDirectory) {
      icon = isExpanded ? LucideIcons.folderOpen : LucideIcons.folder;
    } else {
      final ext = p.extension(node.path);
      if (ext == '.wc_service') {
        icon = LucideIcons.calendar;
      } else if (ext == '.wc_lineup') {
        icon = LucideIcons.listMusic;
      } else {
        icon = LucideIcons.file;
      }
    }

    Widget content = GestureDetector(
       onSecondaryTapUp: (details) {
         _showContextMenu(context, details.globalPosition, node);
       },
       onDoubleTap: () {
         if (!node.isDirectory) {
           debugPrint('Opening file: ${node.path}');
           _selectNode(node);
         } else {
           setState(() {
              if (isExpanded) {
                _expandedPaths.remove(node.path);
              } else {
                _expandedPaths.add(node.path);
              }
           });
         }
       },
       onTap: () {
          _selectNode(node);
          debugPrint('Selected ${node.name}');
       },
       child: Container(
         color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
         padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
         child: Row(
           children: [
             SizedBox(width: depth * 16.0),
             // Expand Arrow
             if (node.isDirectory)
               InkWell(
                 onTap: () {
                   setState(() {
                     if (isExpanded) {
                       _expandedPaths.remove(node.path);
                     } else {
                       _expandedPaths.add(node.path);
                     }
                   });
                 },
                 child: Icon(
                   isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                   size: 16,
                   color: Colors.white70,
                 ),
               )
             else
               const SizedBox(width: 16),
             
             const SizedBox(width: 4),
             Icon(icon, size: 16, color: node.isDirectory ? Colors.blue[200] : Colors.white),
             const SizedBox(width: 8),
             Expanded(
               child: Text(
                 node.name,
                 style: const TextStyle(color: Colors.white, fontSize: 13),
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           ],
         ),
       ),
    );

    if (node.isDirectory && isExpanded && node.children != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          ...node.children!.map((child) => _buildNode(child, depth + 1)),
        ],
      );
    }
    
    return content;
  }

  void _selectNode(FileSystemNode node) {
    setState(() {
      _selectedNodePath = node.path;
    });
    
    if (!node.isDirectory) {
      ref.read(activeFileProvider.notifier).state = File(node.path);
    } else {
      // Clear active file if folder selected
      ref.read(activeFileProvider.notifier).state = null;
    }
  }

  void _showContextMenu(BuildContext context, Offset position, FileSystemNode node) async {
    // Ensure the right-clicked item is selected
    _selectNode(node);
    
    final RelativeRect positionRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    );

    final result = await showMenu<String>(
      context: context,
      position: positionRect,
      color: const Color(0xFF2D2D2D),
      elevation: 8,
      items: [
        if (node.isDirectory) ...[
          const PopupMenuItem(
            value: 'new_folder',
            child: Text('New Folder', style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuItem(
            value: 'new_service',
            child: Text('New Service', style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuItem(
            value: 'new_lineup',
            child: Text('New Lineup', style: TextStyle(color: Colors.white)),
          ),
          const PopupMenuDivider(),
        ],
        const PopupMenuItem(
          value: 'rename',
          child: Text('Rename', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
    
    if (result == null) return;
    
    switch (result) {
      case 'new_folder':
        _createNew(node.path, 'New Folder', isFolder: true);
        break;
      case 'new_service':
        _createNew(node.path, 'Service', ext: '.wc_service');
        break;
      case 'new_lineup':
        _createNew(node.path, 'Lineup', ext: '.wc_lineup');
        break;
      case 'rename':
        _rename(node);
        break;
      case 'delete':
        _delete(node);
        break;
    }
  }

  Future<void> _createNew(String parentPath, String defaultName, {bool isFolder = false, String? ext}) async {
    final controller = TextEditingController(text: defaultName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(isFolder ? 'New Folder' : 'New File', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
             enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
             focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (isFolder) {
        ref.read(workspaceControllerProvider.notifier).createFolder(parentPath, result);
      } else {
        // Create with valid initial content
        String initialContent = '{}';
        if (ext == '.wc_service') {
           initialContent = '{"title": "$result", "items": []}';
        }
        ref.read(workspaceControllerProvider.notifier).createFile(parentPath, result, ext!, initialContent);
      }
    }
  }
  
  Future<void> _showCreateProjectDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('New Project', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
             labelText: 'Project Name',
             labelStyle: TextStyle(color: Colors.white70),
             enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
             focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      ref.read(workspaceControllerProvider.notifier).createProject(result);
    }
  }

  Future<void> _rename(FileSystemNode node) async {
    final controller = TextEditingController(text: node.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Rename', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
           decoration: const InputDecoration(
             enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
             focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Rename')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != node.name) {
      ref.read(workspaceControllerProvider.notifier).renameEntity(node.path, result);
    }
  }

  Future<void> _delete(FileSystemNode node) async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Delete', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${node.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      ref.read(workspaceControllerProvider.notifier).deleteEntity(node.path);
    }
  }
}
