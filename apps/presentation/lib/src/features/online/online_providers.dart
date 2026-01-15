import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../workspace/file_system_provider.dart';
import '../service/service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_provider.dart';
import '../service/service_timeline.dart'; // For ServiceItem if needed, or just standard model
import '../workspace/workspace_explorer.dart'; // For selectedPathProvider

class OnlineServiceItem {
  final String id;
  final String title;
  final DateTime date;
  final String author;

  OnlineServiceItem({
    required this.id,
    required this.title,
    required this.date,
    required this.author,
  });
}

final onlineServicesProvider = FutureProvider<List<OnlineServiceItem>>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.value;
  if (user == null) return [];

  final supabase = Supabase.instance.client;
  
  // 1. Get User's Branch IDs
  final memberRes = await supabase
      .from('organization_members')
      .select('branch_id')
      .eq('user_id', user.id);
  
  final branchIds = (memberRes as List)
      .map((m) => m['branch_id'] as String?)
      .where((id) => id != null)
      .toList();

  if (branchIds.isEmpty) return [];

  // 2. Fetch Upcoming Services for these branches
  // We join with branches to get the branch name for the "Author" field
  final response = await supabase
      .from('services')
      .select('*, branch:branches(name)')
      .inFilter('branch_id', branchIds)
      .gte('date', DateTime.now().toIso8601String())
      .order('date', ascending: true);

  // 3. Map to OnlineServiceItem
  return (response as List).map((data) {
    final date = DateTime.parse(data['date']);
    final branchName = data['branch']?['name'] ?? 'Unknown Branch';
    
    return OnlineServiceItem(
      id: data['id'],
      title: data['title'] ?? 'Untitled Service',
      date: date,
      author: branchName, 
    );
  }).toList();
});

class OnlineSong {
  final String id;
  final String title;
  final String artist;
  final String content; // Lyrics

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.content,
  });
}

final onlineSongsProvider = FutureProvider<List<OnlineSong>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.value == null) return [];

  final supabase = Supabase.instance.client;
  
  // Fetch songs with content
  final response = await supabase
      .from('songs')
      .select('id, title, artist, content') // content field holds lyrics usually
      .order('title', ascending: true);
      
  return (response as List).map((data) {
    return OnlineSong(
      id: data['id'],
      title: data['title'] ?? 'Untitled Song',
      artist: data['artist'] ?? 'Unknown Artist',
      content: data['content'] ?? '',
    );
  }).toList();
});

final onlineImportProvider = Provider((ref) => OnlineImportService(ref));

class OnlineImportService {
  final Ref ref;

  OnlineImportService(this.ref);

  Future<void> importService(OnlineServiceItem item) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      String targetPath = p.join(docsDir.path, 'WeConnect');
      
      // Determine target directory based on selection
      final selectedPath = ref.read(selectedPathProvider);
      if (selectedPath != null && selectedPath.startsWith(targetPath)) {
        if (await FileSystemEntity.isDirectory(selectedPath)) {
          targetPath = selectedPath;
        } else {
          targetPath = p.dirname(selectedPath);
        }
      }

      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Fetch Real Service Items from Supabase
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('service_items')
          .select('*, song:songs(artist, key)')
          .eq('service_id', item.id)
          .order('order_index', ascending: true); 

      // Manually fetch assignees to avoid FK issues
      final List<dynamic> rawItems = response as List<dynamic>;
      final assignedToIds = rawItems
          .map((i) => i['assigned_to'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      print('DEBUG: Found ${assignedToIds.length} unique assignee IDs: $assignedToIds');

      Map<String, String> assigneeNames = {};
      if (assignedToIds.isNotEmpty) {
        // Try to fetch from organization_members first (assuming assigned_to is member_id)
        final membersRes = await supabase
            .from('organization_members')
            .select('id, profile:profiles(full_name)')
            .inFilter('id', assignedToIds);
        
        for (var m in (membersRes as List)) {
           final profile = m['profile'];
           if (profile != null && profile is Map) {
             assigneeNames[m['id']] = profile['full_name'] as String? ?? 'Unknown';
           }
        }
        
        // If empty, maybe it WAS a profile ID? (Fallback or just print debug)
        print('DEBUG: Fetched ${assigneeNames.length} member names from organization_members.');
        
        if (assigneeNames.isEmpty) {
             print('DEBUG: organization_members fetch failed. Trying profiles table directly...');
             final profilesRes = await supabase
                .from('profiles')
                .select('id, full_name')
                .inFilter('id', assignedToIds);
             for (var p in (profilesRes as List)) {
                assigneeNames[p['id']] = p['full_name'] as String;
             }
             print('DEBUG: Fetched ${assigneeNames.length} profile names from profiles table.');
        }
      }

      final realItems = rawItems.map((data) {
        final songData = data['song']; // Map or null
        final assigneeId = data['assigned_to'] as String?;
        if (assigneeId != null && !assigneeNames.containsKey(assigneeId)) {
             print('DEBUG: Missing assignee info for ID $assigneeId');
        }
        
        return ServiceItem(
          id: data['id'],
          title: data['title'] ?? 'Untitled',
          type: data['type'] ?? 'header',
          duration: Duration(seconds: data['duration_seconds'] ?? 300),
          songId: data['song_id'],
          description: data['description'],
          artist: songData is Map ? songData['artist'] : null,
          originalKey: songData is Map ? songData['key'] : null,
          assigneeName: assigneeId != null ? assigneeNames[assigneeId] : null,
        );
      }).toList();

      // If no items found, maybe add a default welcome? Or just keep empty.
      if (realItems.isEmpty) {
        realItems.add(ServiceItem(id: const Uuid().v4(), title: 'Welcome', type: 'header'));
      }

      final project = ServiceProject(
        title: item.title,
        items: realItems,
      );

      final filename = '${item.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.wc_service';
      final file = File(p.join(targetDir.path, filename));
      
      await file.writeAsString(jsonEncode(project.toJson()));
      
      // Refresh workspace
      ref.read(workspaceControllerProvider.notifier).refresh();
      
    } catch (e) {
      throw Exception('Failed to import service: $e');
    }
  }
}
