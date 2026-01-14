import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.service});

  final Service service;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {

  final _serviceRepo = ServiceRepository();
  final _songRepo = SongRepository();
  final _orgRepo = OrganizationRepository();
  
  List<ServiceItem> _items = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _fetchMembers();
    _fetchAssignments();
  }
  
  Future<void> _fetchMembers() async {
    // 1. Get current User's active branch info to know which members to fetch
    // Since we are in the Planning App (Secretary view), we assume they are managing their own branch's service.
    // We can get the user's organization/branch from their profile/membership.
    try {
       // Just pick the first branch found for the logged in user as a best effort default 
       // (User likely only has one active branch context in this app flow)
       final org = await _orgRepo.getUserOrganization();
       if (org != null) {
          final branches = await _orgRepo.getJoinedBranchIds(org.id);
          if (branches.isNotEmpty) {
             final branchId = branches.first;
             final members = await _orgRepo.getBranchMembersHelper(branchId);
             
             // Filter out Owners and Admins as requested
             final filteredMembers = members.where((m) {
                final role = m['role'] as String?;
                return role != 'owner' && role != 'admin';
             }).toList();

             if (mounted) {
               setState(() {
                 _members = filteredMembers;
               });
             }
          }
       }
    } catch (e) {
      debugPrint("Error fetching members: $e");
    }
  }

  Future<void> _fetchItems() async {
    try {
      final items = await _serviceRepo.getServiceItems(widget.service.id);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      
      // Update local objects with new order index
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(orderIndex: i);
      }
    });

    // Save to DB
    try {
       await _serviceRepo.updateServiceItemsOrder(_items);
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving order: $e')));
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'song': return Icons.music_note;
      case 'sermon': return Icons.book;
      case 'prayer': return Icons.spa; 
      case 'reading': return Icons.menu_book;
      case 'generic': 
      default: return Icons.info_outline;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'song': return Colors.purple.shade100;
      case 'sermon': return Colors.orange.shade100;
      case 'prayer': return Colors.blue.shade100;
      case 'reading': return Colors.green.shade100;
      default: return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.service.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Plan'),
              Tab(text: 'Roster'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlanTab(),
            _buildRosterTab(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // We can use a Builder to check current index, or just show different FABs based on visible tab?
    // Actually, DefaultTabController doesn't easily expose index to setState.
    // However, since we might want FABs in both tabs, let's keep it simple.
    // We can check the TabController if we make it explicit, but simpler is to let each Tab have its own FAB 
    // IF we structure it as separate Widgets. But Scaffold has one FAB location.
    // Workaround: Use a custom listener on TabController or put FABs inside the TabBarView pages (using Scaffold inside).
    // Or easier: Just show a SpeedDial or similar?
    // Let's assume the user wants access to add items in Plan and add members in Roster.
    // I will put a "Speed Dial" style or simplified FAB that changes context, but that requires state.
    // Alternative: Put FAB inside the Tab content (using Stack or nested Scaffold).
    // I'll use nested Scaffold/Stack approach inside the simplified tab methods for cleaner separation.
    return SizedBox.shrink(); 
  }

  Widget _buildPlanTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "add_item",
        onPressed: () => _showAddItemDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy - h:mm a').format(widget.service.date.toLocal()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.service.worshipLeaderId != null) 
                   Padding(
                     padding: const EdgeInsets.only(top: 4),
                     child: Text("Leader: ...", style: Theme.of(context).textTheme.bodySmall), 
                   ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Order of Service',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                  ? const Center(child: Text('No items added yet.'))
                  : ReorderableListView(
                      onReorder: _onReorder,
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        for (int i = 0; i < _items.length; i++)
                          _buildItemCard(_items[i]),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  // ROSTER TAB
  List<ServiceAssignment> _assignments = [];

  Future<void> _fetchAssignments() async {
    try {
      final data = await _serviceRepo.getServiceAssignments(widget.service.id);
      if (mounted) setState(() => _assignments = data);
    } catch (e) {
      debugPrint("Error fetching assignments: $e");
    }
  }

  // Call this in initState
  // ...

  Widget _buildRosterTab() {
    if (_assignments.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: "add_roster",
          onPressed: _showAddRosterDialog,
          child: const Icon(Icons.person_add),
        ),
        body: const Center(child: Text("No roster created yet.")),
      );
    }

    // Group by Team Name
    final Map<String, List<ServiceAssignment>> grouped = {};
    for (var a in _assignments) {
      grouped.putIfAbsent(a.teamName, () => []).add(a);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "add_roster",
        onPressed: _showAddRosterDialog,
        child: const Icon(Icons.person_add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          final teamName = entry.key;
          final assignments = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                child: Text(
                  teamName.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...assignments.map((assignment) {
                 final member = _members.firstWhere(
                   (m) => m['id'] == assignment.memberId, 
                   orElse: () => {'profile': {'full_name': 'Unknown Member'}}
                 );
                 final name = member['profile']?['full_name'] ?? member['profile']?['username'] ?? 'Unknown';

                 return Card(
                   child: ListTile(
                     leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                     title: Text(assignment.roleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                     subtitle: Text(name),
                     trailing: IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: () async {
                          await _serviceRepo.deleteServiceAssignment(assignment.id);
                          _fetchAssignments();
                       },
                     ),
                   ),
                 );
              }),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showAddRosterDialog() async {
    String? selectedMemberId;
    String roleName = '';
    String teamName = 'General';
    bool isWorshipLeader = false;

    
    // Roles suggestions
    final kRoles = ['Worship Leader', 'Backup Singer', 'Guitarist', 'Drummer', 'Keyboardist', 'Bassist', 'Usher', 'Multimedia', 'Sound Engineer', 'Camera Operator'];
    // Team suggestions
    final kTeams = ['Praise & Worship', 'Media', 'Ushering', 'Tech', 'Hospitality', 'General'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add to Roster'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMemberId,
                    decoration: const InputDecoration(labelText: 'Member', border: OutlineInputBorder()),
                    items: _members.map((m) => DropdownMenuItem<String>(
                      value: m['id'],
                      child: Text(m['profile']?['full_name'] ?? m['profile']?['username'] ?? 'Unknown'),
                    )).toList(),
                    onChanged: (val) => setStateDialog(() => selectedMemberId = val),
                  ),
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 16),
                  
                  // Team Selection with Autocomplete
                  Autocomplete<String>(
                    optionsBuilder: (text) {
                      if (text.text.isEmpty) return kTeams;
                      return kTeams.where((t) => t.toLowerCase().contains(text.text.toLowerCase()));
                    },
                    onSelected: (val) => teamName = val,
                    fieldViewBuilder: (context, controller, focus, onSubmitted) {
                      if (controller.text.isEmpty) controller.text = teamName;
                      controller.addListener(() { teamName = controller.text; });
                      return TextField(
                        controller: controller,
                        focusNode: focus,
                        decoration: const InputDecoration(labelText: 'Team', border: OutlineInputBorder()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  Autocomplete<String>(
                    optionsBuilder: (text) => kRoles.where((r) => r.toLowerCase().contains(text.text.toLowerCase())),
                    onSelected: (val) {
                      if (!isWorshipLeader) roleName = val;
                    },
                    fieldViewBuilder: (context, controller, focus, onSubmitted) {
                      // If it's worship leader, force the text
                      if (isWorshipLeader && controller.text != 'Worship Leader') {
                        controller.text = 'Worship Leader';
                        roleName = 'Worship Leader';
                      }
                      
                      controller.addListener(() { 
                        if (!isWorshipLeader) {
                          roleName = controller.text; 
                        }
                      });
                      
                      return TextField(
                        controller: controller,
                        focusNode: focus,
                        readOnly: isWorshipLeader, // Disable input if worship leader
                        decoration: InputDecoration(
                          labelText: 'Role', 
                          border: const OutlineInputBorder(),
                          filled: isWorshipLeader,
                          fillColor: isWorshipLeader ? Colors.grey.shade200 : null,
                        ),
                      );
                    },
                  ),

                  // Worship Leader Checkbox
                  StatefulBuilder(
                    builder: (context, setStateCheckbox) {
                      return CheckboxListTile(
                        title: const Text("Is this the Worship Leader?"),
                        value: isWorshipLeader,
                        onChanged: (val) {
                          setStateCheckbox(() {
                             isWorshipLeader = val ?? false;
                             if (isWorshipLeader) {
                               teamName = 'Praise & Worship'; 
                               roleName = 'Worship Leader';
                             } else {
                               // Optional: Clear role if unchecked? kept for now.
                             }
                          });
                          // Force UI update for the text field above
                          setStateDialog(() {}); 
                        },
                      );
                    }
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                   if (selectedMemberId == null || roleName.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Please select a member and enter a role.')),
                     );
                     return;
                   }
                   try {
                     await _serviceRepo.createServiceAssignment(ServiceAssignment(
                       id: '',
                       serviceId: widget.service.id,
                       memberId: selectedMemberId!,
                       roleName: roleName,
                       teamName: teamName,
                     ));

                     if (isWorshipLeader) {
                       // Find the actual user_id (profile id) for the selected member
                       final memberObj = _members.firstWhere(
                         (m) => m['id'] == selectedMemberId, 
                         orElse: () => {}
                       );
                       final userId = memberObj['user_id'] as String?;

                       if (userId != null) {
                         final updatedService = Service(
                           id: widget.service.id, 
                           date: widget.service.date, 
                           title: widget.service.title,
                           worshipLeaderId: userId, // Use user_id, not membership id
                           endTime: widget.service.endTime,
                           organizationId: widget.service.organizationId,
                           branchId: widget.service.branchId
                         );
                         await _serviceRepo.updateService(updatedService);
                       }
                     }

                     if (mounted) {
                       Navigator.pop(context);
                       _fetchAssignments();
                     }
                   } catch(e) {
                      if (mounted) {
                        ShadToaster.of(context).show(ShadToast.destructive(title: const Text("Error"), description: Text(e.toString())));
                      }
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

  // _buildItemCard and other helpers remain below...
  Widget _buildItemCard(ServiceItem item) {
    // ... existing content ...
    // Find assigned member details if any
    Map<String, dynamic>? assignedMember;
    if (item.assignedTo != null && _members.isNotEmpty) {
       assignedMember = _members.firstWhere((m) => m['id'] == item.assignedTo, orElse: () => {});
    }

    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getColorForType(item.type),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getIconForType(item.type), size: 20, color: Colors.black54),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            if (assignedMember != null && assignedMember.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      assignedMember['profile']?['full_name'] ?? assignedMember['profile']?['username'] ?? 'Unknown',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showAddItemDialog(existingItem: item),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddItemDialog({ServiceItem? existingItem}) async {
    // ... existing content ...
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final descController = TextEditingController(text: existingItem?.description ?? '');
    // Default to 'generic' if null
    String selectedType = existingItem?.type ?? 'generic';
    String? selectedMemberId = existingItem?.assignedTo;

    // Standard types
    const List<String> kServiceTypes = ['GENERIC', 'SONG', 'SERMON', 'PRAYER', 'READING', 'ANNOUNCEMENT'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // Prepare sorted member list: Roster members first with Role
          final List<DropdownMenuItem<String>> memberItems = [
            const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
          ];

          // 1. Identify Roster Members
          final rosterMemberIds = _assignments.map((a) => a.memberId).toSet();
          
          // 2. Sort members: Roster first, then others
          final sortedMembers = List<Map<String, dynamic>>.from(_members);
          sortedMembers.sort((a, b) {
            final aInRoster = rosterMemberIds.contains(a['id']);
            final bInRoster = rosterMemberIds.contains(b['id']);
            if (aInRoster && !bInRoster) return -1;
            if (!aInRoster && bInRoster) return 1;
            return 0;
          });

          for (final m in sortedMembers) {
            final name = m['profile']?['full_name'] ?? m['profile']?['username'] ?? 'Unknown';
            
            // Check if in roster to append role
            String label = name;
            final assignment = _assignments.where((a) => a.memberId == m['id']).firstOrNull;
            if (assignment != null) {
               label = '$name (${assignment.roleName})'; 
            }

            memberItems.add(DropdownMenuItem<String>(
              value: m['id'],
              child: Text(label, style: assignment != null ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null),
            ));
          }

          return AlertDialog(
            title: Text(existingItem == null ? 'Add Service Item' : 'Edit Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  
                  // Autocomplete for Type
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: selectedType.toUpperCase()),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                       if (textEditingValue.text == '') {
                         return kServiceTypes;
                       }
                       return kServiceTypes.where((String option) {
                         return option.contains(textEditingValue.text.toUpperCase());
                       });
                    },
                    onSelected: (String selection) {
                      setStateDialog(() {
                        selectedType = selection; // Store as is (likely uppercased by list)
                      });
                    },
                    fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        onChanged: (val) {
                           selectedType = val; // Capture free text
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          // Use a constrained width or match the text field width roughly
                          // In a dialog, hardcoding width or using context size is tricky.
                          // Let's use a standard width of 250 or so, or let it shrink wrap.
                          child: SizedBox(
                            width: 250, 
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  // ... inside build ...
                  DropdownButtonFormField<String>(
                    value: selectedMemberId,
                    decoration: const InputDecoration(labelText: 'Assign To', border: OutlineInputBorder()),
                    items: memberItems,
                    onChanged: (val) {
                      setStateDialog(() => selectedMemberId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
               if (existingItem != null)
                 TextButton(
                   onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Item?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        )
                      );
                      if (confirm == true) {
                         await _serviceRepo.deleteServiceItem(existingItem.id);
                         if (mounted) {
                           Navigator.pop(ctx);
                           _fetchItems();
                         }
                      }
                   },
                   child: const Text('Delete', style: TextStyle(color: Colors.red)),
                 ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  
                  try {
                    if (existingItem == null) {
                      final newItem = ServiceItem(
                        id: '', // unused
                        serviceId: widget.service.id,
                        title: titleController.text,
                        type: selectedType, // Save whatever string
                        description: descController.text,
                        orderIndex: _items.length,
                        assignedTo: selectedMemberId,
                      );
                      await _serviceRepo.createServiceItem(newItem);
                    } else {
                       final updated = existingItem.copyWith(
                         title: titleController.text,
                         type: selectedType,
                         description: descController.text,
                         assignedTo: selectedMemberId,
                       );
                       await _serviceRepo.updateServiceItem(updated);
                    }
                    if (mounted) {
                      Navigator.pop(ctx);
                      _fetchItems();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddSongDialog() async {
    showDialog(
      context: context,
      builder: (context) => _SongSearchDialog(
        onSongSelected: (song) async {
           // Create a ServiceItem of type 'song' linked to this song
           try {
             final newItem = ServiceItem(
               id: '',
               serviceId: widget.service.id,
               title: song.title, // Use song title as item title default
               type: 'song',
               description: song.artist, // Use artist as description
               songId: song.id,
               orderIndex: _items.length,
             );
             await _serviceRepo.createServiceItem(newItem);
             if (mounted) {
               Navigator.pop(context);
               _fetchItems();
             }
           } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding song: $e')));
           }
        },
      ),
    );
  }
}

class _SongSearchDialog extends StatefulWidget {
  const _SongSearchDialog({required this.onSongSelected});
  final Function(Song) onSongSelected;

  @override
  State<_SongSearchDialog> createState() => _SongSearchDialogState();
}

class _SongSearchDialogState extends State<_SongSearchDialog> {
  final _songRepo = SongRepository();
  List<Song> _searchResults = [];
  final _searchController = TextEditingController();

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    final results = await _songRepo.searchSongs(query);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Song'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Songs',
                suffixIcon: Icon(Icons.search),
                hintText: 'Title or lyrics...',
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _searchResults.isEmpty 
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Search to find songs from the library', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_,__) => const Divider(),
                      itemBuilder: (context, index) {
                        final song = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          onTap: () => widget.onSongSelected(song),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
