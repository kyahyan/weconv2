import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../service/service_model.dart'; // Import ServiceItem

class SongLineupEditor extends StatelessWidget {
  final ServiceItem activeItem;
  final List<ServiceItem> allItems;

  const SongLineupEditor({
    super.key, 
    required this.activeItem,
    required this.allItems,
  });

  @override
  Widget build(BuildContext context) {
    // Filter for songs and headers in the lineup
    final displayItems = allItems.where((i) => i.type == 'song' || i.type == 'header').toList();
    // Items are already ordered in the list as preserved from JSON/ServiceProject
    
    final isGroup = activeItem.type == 'worship_set';
    final songCount = displayItems.where((i) => i.type == 'song').length;

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detailed view of the selected item (Header)
          Row(
            children: [
              Icon(_getIconForType(activeItem.type), color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activeItem.title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isGroup 
              ? '$songCount Songs • 15:00' 
              : '${activeItem.type.toUpperCase()} • 5:00 ${activeItem.artist != null ? '• ${activeItem.artist}' : ''}', 
            style: const TextStyle(color: Colors.grey)
          ),
          const Divider(color: Colors.white10, height: 32),
          
          // Lineup List (Only for Worship Set)
          if (isGroup && displayItems.isNotEmpty) ...[
             const Text('Line Up', style: TextStyle(color: Colors.white70, fontSize: 16)),
             const SizedBox(height: 16),
             Expanded(
               child: ListView.builder(
                 itemCount: displayItems.length,
                 itemBuilder: (context, index) {
                   final item = displayItems[index];
                   if (item.type == 'header') {
                      return Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Center(
                          child: Text(
                            item.title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                   }
                   final isActive = item.id == activeItem.id;
                   return _buildSongItem(item, isActive);
                 },
               ),
             ),
          ] else ...[
             const Expanded(child: Center(child: Text('No songs in this service', style: TextStyle(color: Colors.white24)))),
          ]
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'song': return LucideIcons.music;
      case 'worship_set': return LucideIcons.listMusic;
      case 'scripture': return LucideIcons.bookOpen;
      case 'media': return LucideIcons.video;
      case 'header': return LucideIcons.heading;
      default: return LucideIcons.circle;
    }
  }

  Widget _buildSongItem(ServiceItem item, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.withOpacity(0.2) : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
        border: isActive ? Border.all(color: Colors.blueAccent.withOpacity(0.5)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                if (item.artist != null)
                  Text(item.artist!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (item.originalKey != null)
            Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
               child: Text('Key: ${item.originalKey}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
