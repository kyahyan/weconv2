import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'attendance_detail_screen.dart';
import 'attendance_statistics_screen.dart';

class UsheringDashboard extends StatelessWidget {
  final String branchId;
  final String branchName;
  final String ownerId;

  const UsheringDashboard({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ushering Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Attendance', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Members', icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // Prevent swipe to avoid conflict with inner tabs
          children: [
            _AttendanceSection(branchId: branchId, ownerId: ownerId),
            _MembersSection(branchId: branchId, ownerId: ownerId),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION 1: ATTENDANCE (Nested TabController)
// -----------------------------------------------------------------------------
class _AttendanceSection extends StatelessWidget {
  final String branchId;
  final String ownerId;
  const _AttendanceSection({required this.branchId, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: const TabBar(
              labelColor: Colors.purple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple,
              tabs: [
                Tab(text: 'Take Attendance'),
                Tab(text: 'History'),
                Tab(text: 'Statistics'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TakeAttendanceTab(branchId: branchId, ownerId: ownerId),
                _HistoryTab(branchId: branchId, ownerId: ownerId),
                AttendanceStatisticsScreen(branchId: branchId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUB-TAB: TAKE ATTENDANCE (Refactored from original)
// -----------------------------------------------------------------------------
class _TakeAttendanceTab extends StatefulWidget {
  final String branchId;
  final String ownerId;
  const _TakeAttendanceTab({required this.branchId, required this.ownerId});

  @override
  State<_TakeAttendanceTab> createState() => _TakeAttendanceTabState();
}

class _TakeAttendanceTabState extends State<_TakeAttendanceTab> {
  final _orgRepo = OrganizationRepository();
  final _attendanceRepo = AttendanceRepository();

  DateTime _selectedDate = DateTime.now();
  String _selectedServiceType = 'Sunday Service';
  List<Map<String, dynamic>> _members = [];
  Map<String, String> _attendanceStatus = {};
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _serviceTypes = [
    'Sunday Service', 'Midweek Service', 'Youth Service', 'Anniversary', 'Special Event'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rawMembers = await _orgRepo.getBranchMembersHelper(widget.branchId);
      final members = rawMembers.where((m) => m['user_id'] != widget.ownerId).toList();
      print("DEBUG: Fetched ${members.length} members (filtered). Sample tags: ${members.isNotEmpty ? members.first['tags'] : 'N/A'}");
      final existingRecords = await _attendanceRepo.getAttendanceForService(
          widget.branchId, _selectedDate, _selectedServiceType);

      final statusMap = <String, String>{};
      for (var record in existingRecords) {
        statusMap[record.userId] = record.category;
      }
      
      if (mounted) {
        setState(() {
          _members = members;
          _attendanceStatus = statusMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      int successCount = 0;
      for (var member in _members) {
        final userId = member['user_id'];
        final status = _attendanceStatus[userId];
        if (status == 'Absent') {
           await _attendanceRepo.deleteAttendance(widget.branchId, userId, _selectedDate, _selectedServiceType);
        } else if (status != null && status.isNotEmpty) {
           await _attendanceRepo.recordAttendance(Attendance(
             id: '', 
             branchId: widget.branchId,
             userId: userId,
             serviceDate: _selectedDate,
             serviceType: _selectedServiceType,
             category: status,
             createdAt: DateTime.now(),
           ));
           successCount++;
        }
      }
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created: $successCount present')));
         setState(() => _isSaving = false);
      }
    } catch (e) {
       if (mounted) setState(() => _isSaving = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    return _members.where((m) {
      final profile = m['profile'] ?? {};
      final name = (profile['full_name'] ?? profile['username'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
          // Controls
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(text: _selectedServiceType),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return _serviceTypes;
                        return _serviceTypes.where((o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (val) {
                         setState(() => _selectedServiceType = val);
                         _loadData();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Service Type', border: OutlineInputBorder()),
                          onChanged: (val) => _selectedServiceType = val,
                          onSubmitted: (val) {
                            setState(() => _selectedServiceType = val);
                            _loadData();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) {
                        setState(() => _selectedDate = d);
                        _loadData();
                      }
                    },
                  ),
                  Text("${_selectedDate.toLocal()}".split(' ')[0]),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search Members', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          
          if (_isLoading) const LinearProgressIndicator(),

          Expanded(
            child: ListView.separated(
              itemCount: _filteredMembers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final m = _filteredMembers[index];
                final userId = m['user_id'];
                final profile = m['profile'] ?? {};
                final displayName = profile['full_name'] ?? profile['username'] ?? 'Unknown';
                final String? avatarUrl = profile['avatar_url'];
                final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                // Parse tags safely
                final rawTags = m['tags'] as List?;
                final List<String> tags = rawTags?.map((e) => e.toString()).toList() ?? [];

                final status = _attendanceStatus[userId];
                final isPresent = status != null && status != 'Absent';
                final isNew = status == 'New Attender';
                final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: !hasAvatar ? Text(initial) : null,
                  ),
                  title: Text(displayName),
                  subtitle: tags.isNotEmpty 
                    ? Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3))
                          ),
                          child: Text(t, style: TextStyle(fontSize: 9, color: Colors.blue.shade800)),
                        )).toList(),
                      )
                    : Text(m['role'] ?? 'Member', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('New', style: TextStyle(fontSize: 12)),
                      Checkbox(
                        value: isNew,
                        onChanged: isPresent ? (val) => setState(() {
                           _attendanceStatus[userId] = (val == true) ? 'New Attender' : 'Attender';
                        }) : null,
                      ),
                      const VerticalDivider(),
                      const Text('Present', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Checkbox(
                        value: isPresent,
                        activeColor: Colors.green,
                        onChanged: (val) => setState(() {
                           _attendanceStatus[userId] = (val == true) ? 'Attender' : 'Absent';
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: _isSaving ? null : _saveAttendance,
                 icon: _isSaving ? const CircularProgressIndicator() : const Icon(Icons.check),
                 label: const Text('Create Attendance'),
               ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SUB-TAB: HISTORY (Existing)
// -----------------------------------------------------------------------------
class _HistoryTab extends StatefulWidget {
  final String branchId;
  final String ownerId;
  const _HistoryTab({required this.branchId, required this.ownerId});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final _attendanceRepo = AttendanceRepository();
  final _orgRepo = OrganizationRepository();
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _sessionsFuture = _attendanceRepo.getAttendanceSessions(widget.branchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No records.'));
        
        // Deduplicate
        final sessions = <String>{};
        final list = <Map<String, dynamic>>[];
        for(var item in snapshot.data!) {
           final key = "${item['service_date']}|${item['service_type']}";
           if(sessions.add(key)) list.add(item);
        }

        if (list.isEmpty) return const Center(child: Text('No records.'));

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final s = list[index];
            return ListTile(
              title: Text('${s['service_date']} - ${s['service_type']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Session?'),
                          content: const Text('This will delete all attendance records for this service. This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true), 
                              child: const Text('Delete')
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                         try {
                           await _attendanceRepo.deleteSession(widget.branchId, DateTime.parse(s['service_date']), s['service_type']);
                           _refresh(); // Refresh list after delete
                         } catch (e) {
                           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                         }
                      }
                    },
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () async {
                final rawMembers = await _orgRepo.getBranchMembersHelper(widget.branchId);
                final members = rawMembers.where((m) => m['user_id'] != widget.ownerId).toList();
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceDetailScreen(
                    branchId: widget.branchId,
                    date: DateTime.parse(s['service_date']),
                    serviceType: s['service_type'],
                    allMembers: members,
                  )));
                }
              },
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION 2: MEMBERS (New)
// -----------------------------------------------------------------------------
class _MembersSection extends StatefulWidget {
  final String branchId;
  final String ownerId;
  const _MembersSection({required this.branchId, required this.ownerId});

  @override
  State<_MembersSection> createState() => _MembersSectionState();
}

class _MembersSectionState extends State<_MembersSection> {
  final _orgRepo = OrganizationRepository();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final rawMembers = await _orgRepo.getBranchMembersHelper(widget.branchId);
    final members = rawMembers.where((m) => m['user_id'] != widget.ownerId).toList();
    if (mounted) setState(() { _members = members; _isLoading = false; });
  }

  Future<void> _showEditDialog(Map<String, dynamic> member) async {
    final memberId = member['id'];
    // 1. Fetch suggestions (all used tags)
    final existingTags = await _orgRepo.getBranchTags(widget.branchId);
    final defaultTags = ['Children', 'Youth', 'Elder', "Men's", "Women's", 'Choir', 'Usher'];
    final allSuggestions = {...defaultTags, ...existingTags}.toList();

    // Track current input to handle "forgot to press enter" case
    String currentTagInput = '';
    
    // 2. Local state for the dialog
    List<String> currentTags = List<String>.from(member['tags'] ?? []);
    final notesController = TextEditingController(text: member['notes'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit: ${member['profile']['full_name'] ?? member['profile']['username']}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notes
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes', 
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Needs transport, visitor',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tags
                    const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        currentTagInput = textEditingValue.text; // Update tracker
                        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                        return allSuggestions.where((option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        if (!currentTags.contains(selection)) {
                          setDialogState(() {
                            currentTags.add(selection);
                            currentTagInput = ''; // Reset
                          });
                        }
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Add Tag',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.add),
                            hintText: 'Type and press Enter'
                          ),
                          onChanged: (val) {
                             currentTagInput = val;
                          },
                          onSubmitted: (val) {
                             if (val.isNotEmpty && !currentTags.contains(val)) {
                               setDialogState(() {
                                 currentTags.add(val);
                                 textEditingController.clear();
                                 currentTagInput = '';
                               });
                             }
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0, 
                      children: currentTags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setDialogState(() {
                              currentTags.remove(tag);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Safety check: if user typed something but didn't press enter, add it now
                    if (currentTagInput.trim().isNotEmpty && !currentTags.contains(currentTagInput.trim())) {
                       currentTags.add(currentTagInput.trim());
                    }

                    try {
                       await _orgRepo.updateMemberTags(memberId, currentTags);
                       await _orgRepo.updateMemberNotes(memberId, notesController.text);
                       
                       if (mounted) {
                          Navigator.pop(context); 
                          _loadMembers(); 
                       }
                    } catch (e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_members.isEmpty) {
       return const Center(child: Text('No members found.'));
    }

    return ListView.separated(
      itemCount: _members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
         final m = _members[index];
         final profile = m['profile'] ?? {};
         // Safely cast tags
         final rawTags = m['tags'] as List?;
         final List<String> tags = rawTags?.map((e) => e.toString()).toList() ?? [];
         final notes = m['notes'] as String?;
         
         final String? avatarUrl = profile['avatar_url'];
         final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
         
         return ListTile(
           leading: CircleAvatar(
             backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
             child: !hasAvatar ? Text( (profile['username']?[0] ?? '?').toUpperCase() ) : null,
           ),
           title: Text(profile['full_name'] ?? profile['username'] ?? 'Unknown'),
           subtitle: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               if (tags.isNotEmpty) 
                 Padding(
                   padding: const EdgeInsets.only(top: 4.0),
                   child: Wrap(
                     spacing: 4,
                     runSpacing: 4,
                     children: tags.map((t) => Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.purple.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.purple.withOpacity(0.3))
                       ),
                       child: Text(t, style: TextStyle(fontSize: 10, color: Colors.purple.shade700)),
                     )).toList(),
                   ),
                 ),
               if (notes != null && notes.isNotEmpty)
                 Padding(
                   padding: const EdgeInsets.only(top: 2.0),
                   child: Text(notes, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
                 ),
             ],
           ),
           trailing: IconButton(
             icon: const Icon(Icons.edit, color: Colors.blue),
             onPressed: () => _showEditDialog(m),
           ),
         );
      },
    );
  }
}


