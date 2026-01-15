import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'file_system_provider.dart';
import '../editor/editor_provider.dart';

// Add this provider at the top of the file or near other providers
final selectedPathProvider = StateProvider<String?>((ref) => null);

class WorkspaceExplorer extends ConsumerStatefulWidget {
  const WorkspaceExplorer({super.key});

  @override
  ConsumerState<WorkspaceExplorer> createState() => _WorkspaceExplorerState();
}

class _WorkspaceExplorerState extends ConsumerState<WorkspaceExplorer> {
  // Track expanded paths
  final Set<String> _expandedPaths = {};

  @override
  Widget build(BuildContext context) {
    // Use the renamed provider
    final fileSystemState = ref.watch(workspaceControllerProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: const Color(0xFF1E1E1E),
          child: Row(
            children: [
              const Text('Workspace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => _showCreateProjectDialog(), icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white70)),
              Consumer(
                builder: (context, ref, child) {
                  final selectedPath = ref.watch(selectedPathProvider);
                  return IconButton(
                    onPressed: selectedPath != null 
                        ? () => _deletePath(selectedPath) 
                        : null, 
                    icon: Icon(
                      LucideIcons.trash2, 
                      size: 16, 
                      color: selectedPath != null ? Colors.white70 : Colors.white24
                    )
                  );
                },
              ),
              IconButton(
                onPressed: () => ref.read(workspaceControllerProvider.notifier).refresh(), 
                icon: const Icon(LucideIcons.refreshCcw, size: 16, color: Colors.white70)
              ),
            ],
          ),
        ),
        Expanded(
          child: fileSystemState.when(
            data: (nodes) {
              if (nodes.isEmpty) {
                return const Center(
                  child: Text('No Projects Found', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView(
                padding: EdgeInsets.zero, // Remove default padding
                children: nodes.map((node) => _buildNode(node, 0)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }

  Widget _buildNode(FileSystemNode node, int depth) {
    final isExpanded = _expandedPaths.contains(node.path);
    final selectedPath = ref.watch(selectedPathProvider);
    final isSelected = selectedPath == node.path;
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

    // Display Name Logic
    final displayName = node.isDirectory ? node.name : p.basenameWithoutExtension(node.name);

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
                 displayName, // Use display name here
                 style: const TextStyle(color: Colors.white, fontSize: 13),
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           ],
         ),
       ),
    );

    // FIX: Wrap logic for directories - ensure we render DragTarget AND recursive children
    Widget nodeWidget = content;
    
    if (node.isDirectory) {
      nodeWidget = DragTarget<String>(
        onWillAccept: (data) {
          if (data == null) return false;
          // node.path is target path
          if (data == node.path) return false;
          // IMPORTANT: Allow dragging into folder, checking strictly parent is different
          final parent = p.dirname(data);
          if (parent == node.path) return false; // Already in this folder
          
          return true; 
        },
        onAccept: (data) {
          // data is NOT null here because onWillAccept filtered it
          ref.read(workspaceControllerProvider.notifier).moveEntity(data!, node.path);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
             decoration: isHovering 
               ? BoxDecoration(
                   color: Colors.blue.withOpacity(0.3),
                   border: Border.all(color: Colors.blueAccent),
                   borderRadius: BorderRadius.circular(4)
                 )
               : null,
             child: content // content is the header row
          );
        },
      );
    } else {
      // File Draggable Logic
      nodeWidget = Draggable<String>(
        data: node.path,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(icon, size: 16, color: Colors.white),
                 const SizedBox(width: 8),
                 Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 13)), 
               ],
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: content,
        ),
        child: content,
      );
    }
    
    if (node.isDirectory && isExpanded && node.children != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nodeWidget, // The header
          ...node.children!.map((child) => _buildNode(child, depth + 1)),
        ],
      );
    }
    
    return nodeWidget;
  }

  void _selectNode(FileSystemNode node) {
    ref.read(selectedPathProvider.notifier).state = node.path;
    
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
      // Check if we are deleting the currently open file
      final activeFile = ref.read(activeFileProvider);
      if (activeFile != null && activeFile.path == node.path) {
          ref.read(activeFileProvider.notifier).state = null;
          ref.read(activeProjectProvider.notifier).state = null;
          ref.read(activeEditorItemProvider.notifier).state = null;
      }
      
      ref.read(workspaceControllerProvider.notifier).deleteEntity(node.path);
    }
  }

  Future<void> _deletePath(String path) async {
     final name = p.basename(path);
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Delete', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$name"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      // Check active file match
      final activeFile = ref.read(activeFileProvider);
      if (activeFile != null && activeFile.path == path) {
          ref.read(activeFileProvider.notifier).state = null;
          ref.read(activeProjectProvider.notifier).state = null;
          ref.read(activeEditorItemProvider.notifier).state = null;
      }

      // Clear selection if deleting selected item
      if (ref.read(selectedPathProvider) == path) {
         ref.read(selectedPathProvider.notifier).state = null;
         // activeFileProvider is handled above, but good to be safe
         ref.read(activeFileProvider.notifier).state = null;
      }
      ref.read(workspaceControllerProvider.notifier).deleteEntity(path);
    }
  }
}
