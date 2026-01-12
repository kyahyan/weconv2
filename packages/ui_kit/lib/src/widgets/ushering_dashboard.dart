import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'attendance_detail_screen.dart';

class UsheringDashboard extends StatefulWidget {
  final String branchId;
  final String branchName; // Use this for display

  const UsheringDashboard({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  State<UsheringDashboard> createState() => _UsheringDashboardState();
}

class _UsheringDashboardState extends State<UsheringDashboard> {
  final _orgRepo = OrganizationRepository();
  final _attendanceRepo = AttendanceRepository();

  // State
  DateTime _selectedDate = DateTime.now();
  String _selectedServiceType = 'Sunday Service';
  List<Map<String, dynamic>> _members = []; // {profile: ..., membershipId: ...}
  Map<String, String> _attendanceStatus = {}; // userId -> status (new_attender, etc)
  String _searchQuery = '';
  
  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    return _members.where((m) {
      final profile = m['profile'] ?? {};
      final name = (profile['full_name'] ?? profile['username'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }
  
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _serviceTypes = [
    'Sunday Service',
    'Midweek Service',
    'Youth Service',
    'Anniversary',
    'Special Event'
  ];



  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Members
      final members = await _orgRepo.getBranchMembersHelper(widget.branchId);

      // 2. Fetch Existing Attendance for this Date/Service
      final existingRecords = await _attendanceRepo.getAttendanceForService(
          widget.branchId, _selectedDate, _selectedServiceType);

      // 3. Map records to local status
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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading: $e')));
      }
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      int successCount = 0;
      int deleteCount = 0;
      
      for (var member in _members) {
        final userId = member['user_id'];
        final status = _attendanceStatus[userId];
        
        // If status is 'Absent' -> DELETE record (User unchecked the box)
        if (status == 'Absent') {
           await _attendanceRepo.deleteAttendance(widget.branchId, userId, _selectedDate, _selectedServiceType);
           deleteCount++;
        }
        // If status is present (valuable string) -> UPSERT record
        else if (status != null && status.isNotEmpty) {
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
        // If null, do nothing (no change/no record)
      }

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Saved: $successCount present, $deleteCount removed.')
         ));
         setState(() => _isSaving = false);
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
         setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ushering - Attendance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Take Attendance'),
              Tab(text: 'History (Recent)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAttendanceTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return Column(
      children: [
          // 1. Controls (Date & Service)
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                   Row(
                     children: [
                       Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Autocomplete<String>(
                                initialValue: TextEditingValue(text: _selectedServiceType),
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                     // options to show when empty? maybe all?
                                     // The default behavior usually requires typing. 
                                     // Let's show all if empty (simulating dropdown)
                                     return _serviceTypes;
                                  }
                                  return _serviceTypes.where((String option) {
                                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                  });
                                },
                                onSelected: (String selection) {
                                   setState(() => _selectedServiceType = selection);
                                   _loadData();
                                },
                                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                  return TextField(
                                    controller: textEditingController,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Service Type',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.arrow_drop_down),
                                    ),
                                    onChanged: (val) {
                                      // Update local state without reloading DB yet to avoid spamming
                                      _selectedServiceType = val;
                                    },
                                    onSubmitted: (val) {
                                      setState(() => _selectedServiceType = val);
                                      _loadData();
                                    },
                                  );
                                },
                              );
                            }
                          ),
                        ),
                       const SizedBox(width: 16),
                       IconButton(
                         icon: const Icon(Icons.calendar_today),
                         onPressed: () async {
                           final d = await showDatePicker(
                             context: context, 
                             firstDate: DateTime(2020), 
                             lastDate: DateTime.now()
                           );
                           if (d != null) {
                             setState(() => _selectedDate = d);
                             _loadData();
                           }
                         },
                       ),
                       Text("${_selectedDate.toLocal()}".split(' ')[0]),
                     ],
                   ),
                ],
              ),
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Members',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase());
              },
            ),
          ),
          
          if (_isLoading)
            const LinearProgressIndicator(),

          // 2. Member List
          Expanded(
            child: ListView.separated(
              itemCount: _filteredMembers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final m = _filteredMembers[index];
                final userId = m['user_id'];
                final profile = m['profile'] ?? {};
                
                // Logic to get best display name: Full Name > Username > 'Unknown'
                String displayName = profile['full_name'] ?? '';
                if (displayName.isEmpty) {
                  displayName = profile['username'] ?? '';
                }
                if (displayName.isEmpty) {
                  displayName = 'Unknown Member';
                }
                
                final String? avatarUrl = profile['avatar_url'];
                final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                
                final status = _attendanceStatus[userId];
                // Present if status is in map and not 'Absent'
                final isPresent = status != null && status != 'Absent';
                // Is New?
                final isNew = status == 'New Attender';
                
                // Ensure initial is safe
                final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                    child: !hasAvatar ? Text(initial) : null,
                  ),
                  title: Text(displayName),
                  subtitle: Text(m['role'] ?? 'Member'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "New" Checkbox
                      Row(
                        children: [
                          const Text('New', style: TextStyle(fontSize: 12)),
                          Checkbox(
                            value: isNew,
                            onChanged: isPresent ? (val) {
                               setState(() {
                                 if (val == true) {
                                   _attendanceStatus[userId] = 'New Attender';
                                 } else {
                                   _attendanceStatus[userId] = 'Attender';
                                 }
                               });
                            } : null, // Disable if not present
                          ),
                        ],
                      ),
                      
                      const VerticalDivider(),
                      
                      // "Present" Checkbox
                      Row(
                        children: [
                          const Text('Present', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Checkbox(
                            value: isPresent,
                            activeColor: Colors.green,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  // Default to 'Attender' when first checked
                                  _attendanceStatus[userId] = 'Attender';
                                } else {
                                  // Mark Absent
                                  _attendanceStatus[userId] = 'Absent'; 
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: _isSaving ? null : _saveAttendance,
                 icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                 label: const Text('Create Attendance'),
               ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _attendanceRepo.getAttendanceSessions(widget.branchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
           return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final rawList = snapshot.data ?? [];
        // Dedup locally: Set<String> key = "$date|$type"
        final uniqueSessions = <String>{};
        final sessions = <Map<String, dynamic>>[];
        
        for (var item in rawList) {
           final key = "${item['service_date']}|${item['service_type']}";
           if (!uniqueSessions.contains(key)) {
             uniqueSessions.add(key);
             sessions.add(item);
           }
        }
        
        if (sessions.isEmpty) {
           return const Center(child: Text('No attendance records found yet.'));
        }
        
        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final s = sessions[index];
            final dateStr = s['service_date'];
            final type = s['service_type'];
            
            return ListTile(
              title: Text('$dateStr - $type'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceDetailScreen(
                      branchId: widget.branchId,
                      date: DateTime.parse(dateStr),
                      serviceType: type,
                      allMembers: _members, // Pass cached members to resolve names
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

