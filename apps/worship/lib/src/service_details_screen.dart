import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';
import 'song_detail_screen.dart'; // Added import


class ServiceDetailsScreen extends StatefulWidget {
  final Service? service;
  final String? serviceId;

  const ServiceDetailsScreen({
    super.key, 
    this.service, 
    this.serviceId
  }) : assert(service != null || serviceId != null, 'Either service or serviceId must be provided');

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final _serviceRepo = ServiceRepository();
  final _orgRepo = OrganizationRepository();
  final _songRepo = SongRepository();
  
  Service? _service;
  List<ServiceItem> _programItems = [];
  List<ServiceAssignment> _assignments = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    print("DEBUG: _fetchDetails started");
    try {
      // 1. Fetch Service if needed
      if (_service == null && widget.serviceId != null) {
         print("DEBUG: Fetching service object by ID: ${widget.serviceId}");
         _service = await _serviceRepo.getServiceById(widget.serviceId!);
         if (_service == null) {
           print("DEBUG: Service not found for ID: ${widget.serviceId}");
           if (mounted) setState(() => _isLoading = false);
           return; 
         }
      }

      final serviceId = _service!.id;

      print("DEBUG: _fetchDetails waiting for service items/assignments for $serviceId");
      final results = await Future.wait([
        _serviceRepo.getServiceItems(serviceId),
        _serviceRepo.getServiceAssignments(serviceId),
      ]);
      print("DEBUG: _fetchDetails items/assignments fetched");

      if (mounted) {
        setState(() {
          _programItems = results[0] as List<ServiceItem>;
          _assignments = results[1] as List<ServiceAssignment>;
        });
        
        // Fetch members if variable
        if (_service!.branchId != null) {
          print("DEBUG: _fetchDetails calling _fetchMembers");
          await _fetchMembers(_service!.branchId!);
          print("DEBUG: _fetchDetails _fetchMembers completed");
        } else {
           print("DEBUG: _fetchDetails no branchId");
        }
      } else {
        print("DEBUG: _fetchDetails not mounted after fetch");
      }
    } catch (e, stack) {
      debugPrint('Error fetching service details: $e');
      debugPrint(stack.toString());
    } finally {
      print("DEBUG: _fetchDetails finally block entered. Mounted: $mounted");
      if (mounted) {
        setState(() {
          print("DEBUG: Setting _isLoading = false");
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMembers(String branchId) async {
    try {
      final members = await _orgRepo.getBranchMembersHelper(branchId);
      if (mounted) {
        setState(() {
          _members = members;
        });
      }
    } catch (e) {
      debugPrint('Error fetching members: $e');
    }
  }

  void _openSong(ServiceItem item) {
    if (item.songId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SongDetailScreen(songId: item.songId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_service == null) {
       return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Service not found.")),
       );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_service!.title, style: const TextStyle(fontSize: 18)),
              Text(
                DateFormat('MMM dd, yyyy - h:mm a').format(_service!.date),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Program'),
              Tab(text: 'Roster'),
              Tab(text: 'Line Up'), 
            ],
          ),
        ),
        body: TabBarView(
            children: [
              _buildProgramTab(),
              _buildRosterTab(),
              _buildLineUpTab(),
            ],
          ),
      ),
    );
  }

  Widget _buildLineUpTab() {
    final songItems = _programItems.where((i) => i.type == 'song').toList();
    
    if (songItems.isEmpty) {
      return const Center(child: Text("No songs in line up."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songItems.length,
      itemBuilder: (context, index) {
        final item = songItems[index];
        return Card(
           child: ListTile(
            leading: const Icon(Icons.music_note, color: Colors.deepPurple),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Tap to view lyrics'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openSong(item),
          ),
        );
      },
    );
  }

  Widget _buildProgramTab() {
    // Filter out songs for the Program tab
    final displayItems = _programItems.where((i) => i.type != 'song').toList();

    if (displayItems.isEmpty) {
      return const Center(child: Text('No program items found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: displayItems.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = displayItems[index];
        
        // Find assigned member name
        String? assigneeName;
        if (item.assignedTo != null) {
          final member = _members.firstWhere(
            (m) => m['id'] == item.assignedTo, 
            orElse: () => {}
          );
          assigneeName = member['profile']?['full_name'] ?? member['profile']?['username'];
        }

        return ListTile(
          leading: CircleAvatar(
             backgroundColor: Colors.blue.shade50,
             child: Text('${index + 1}'),
          ),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.description != null && item.description!.isNotEmpty)
                Text(item.description!),
              if (assigneeName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        assigneeName,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: item.durationSeconds != null 
              ? Text('${(item.durationSeconds! / 60).round()}m')
              : null,
        );
      },
    );
  }

  Widget _buildRosterTab() {
    if (_assignments.isEmpty) {
      return const Center(child: Text('No roster assignments found.'));
    }

    // Group by Team Name
    final Map<String, List<ServiceAssignment>> grouped = {};
    for (var a in _assignments) {
      grouped.putIfAbsent(a.teamName, () => []).add(a);
    }

    return ListView(
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
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
                 color: Theme.of(context).cardColor,
                 margin: const EdgeInsets.only(bottom: 8),
                 child: ListTile(
                   leading: CircleAvatar(
                     backgroundColor: Colors.deepPurple.shade100,
                     child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                   ),
                   title: Text(assignment.roleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                   subtitle: Text(name), 
                   trailing: assignment.confirmed 
                       ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                       : const Icon(Icons.help_outline, color: Colors.orange, size: 20),
                 ),
               );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}
