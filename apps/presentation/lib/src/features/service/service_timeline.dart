import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'service_model.dart';

class ServiceTimeline extends StatefulWidget {
  final List<ServiceItem> items;
  final Function(List<ServiceItem>) onReorder;
  final Function(ServiceItem) onAddItem;
  final String? selectedItemId;
  final Function(String) onItemSelected;

  const ServiceTimeline({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onAddItem,
    this.selectedItemId,
    required this.onItemSelected,
  });

  @override
  State<ServiceTimeline> createState() => _ServiceTimelineState();
}

class _ServiceTimelineState extends State<ServiceTimeline> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header / Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF2D2D2D),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order of Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _showAddItemDialog,
              ),
            ],
          ),
        ),
        
        // List (Grouped View)
        Expanded(
          child: widget.items.isEmpty
              ? const Center(child: Text('Empty Service. Add an item!', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _groupedItems.length,
                  itemBuilder: (context, index) {
                     final item = _groupedItems[index];
                     final isSelected = item.id == widget.selectedItemId || (item.id == widget.selectedItemId); // Simplified check
                     
                     // Calculate display number (skip worship sets)
                     int? displayNumber;
                     if (item.type != 'worship_set') {
                       int count = 0;
                       for (var i = 0; i <= index; i++) {
                         if (_groupedItems[i].type != 'worship_set') {
                           count++;
                         }
                       }
                       displayNumber = count;
                     }

                     return Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       decoration: BoxDecoration(
                         color: isSelected ? Colors.blue.withOpacity(0.1) : const Color(0xFF2D2D2D),
                         borderRadius: BorderRadius.circular(8),
                         border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.5)) : Border.all(color: Colors.transparent),
                       ),
                       child: InkWell(
                         onTap: () => widget.onItemSelected(item.id),
                         borderRadius: BorderRadius.circular(8),
                         child: Padding(
                           padding: const EdgeInsets.all(12),
                           child: Row(
                             children: [
                               // Number Badge or Icon
                               Container(
                                 width: 36, 
                                 height: 36,
                                 decoration: BoxDecoration(
                                   color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.1),
                                   shape: BoxShape.circle,
                                 ),
                                 alignment: Alignment.center,
                                 child: displayNumber != null 
                                   ? Text(
                                       '$displayNumber', 
                                       style: TextStyle(
                                         color: isSelected ? Colors.white : Colors.blue, 
                                         fontWeight: FontWeight.bold,
                                         fontSize: 16,
                                       )
                                     )
                                   : Icon(
                                       LucideIcons.listMusic, 
                                       size: 18, 
                                       color: isSelected ? Colors.white : Colors.blue
                                     ),
                               ),
                               const SizedBox(width: 16),
                               
                               // Content
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       item.title, 
                                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                     ),
                                     const SizedBox(height: 4),
                                     if (item.type == 'worship_set')
                                        const Text('Songs Group', style: TextStyle(color: Colors.grey, fontSize: 12))
                                     else
                                        Row(
                                          children: [
                                            Icon(LucideIcons.user, size: 14, color: isSelected ? Colors.blue.shade200 : Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.assigneeName ?? 'Unassigned', 
                                              style: TextStyle(color: isSelected ? Colors.blue.shade200 : Colors.blue, fontSize: 12)
                                            ),
                                          ],
                                        )
                                   ],
                                 ),
                               ),
                               
                               // Drag Handle (Visual)
                               if (isSelected)
                                 const Icon(LucideIcons.chevronRight, color: Colors.blue, size: 16),
                             ],
                           ),
                         ),
                       ),
                     );
                  },
                ),
        ),
      ],
    );
  }

  List<ServiceItem> get _groupedItems {
    // Filter out songs and headers from the program view (they are managed in "Line Up" tab)
    return widget.items.where((item) => item.type != 'song' && item.type != 'header').toList();
  }

  Icon _getIconForType(String type) {
    switch (type) {
      case 'song':
        return const Icon(LucideIcons.music, color: Colors.blue);
      case 'scripture':
        return const Icon(LucideIcons.bookOpen, color: Colors.amber);
      case 'media':
        return const Icon(LucideIcons.video, color: Colors.green);
      case 'header':
        return const Icon(LucideIcons.heading, color: Colors.white);
      default:
        return const Icon(LucideIcons.circle, color: Colors.grey);
    }
  }

  Future<void> _showAddItemDialog() async {
    String title = '';
    String type = '';
    String assignedTo = '';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            title: const Text('Add Service Item', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                  onChanged: (val) => title = val,
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Type (e.g. prayer, announcement)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                  onChanged: (val) => type = val,
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Assigned To',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                  onChanged: (val) => assignedTo = val,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  if (title.isNotEmpty) {
                    final newItem = ServiceItem(
                      id: const Uuid().v4(),
                      title: title,
                      type: type.isEmpty ? 'other' : type.toLowerCase(),
                      assigneeName: assignedTo.isEmpty ? null : assignedTo,
                    );
                    widget.onAddItem(newItem);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }
}
