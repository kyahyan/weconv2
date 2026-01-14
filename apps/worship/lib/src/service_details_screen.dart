import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';


class ServiceDetailsScreen extends StatefulWidget {
  final Service service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final _serviceRepo = ServiceRepository();
  final _orgRepo = OrganizationRepository();
  
  List<ServiceItem> _programItems = [];
  List<ServiceAssignment> _assignments = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final results = await Future.wait([
        _serviceRepo.getServiceItems(widget.service.id),
        _serviceRepo.getServiceAssignments(widget.service.id),
      ]);

      if (mounted) {
        setState(() {
          _programItems = results[0] as List<ServiceItem>;
          _assignments = results[1] as List<ServiceAssignment>;
        });
        
        // Fetch members if we have the branch ID (which is in Service object)
        if (widget.service.branchId != null) {
          _fetchMembers(widget.service.branchId!);
        } else {
           setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching service details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchMembers(String branchId) async {
    try {
      final members = await _orgRepo.getBranchMembersHelper(branchId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching members: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.service.title, style: const TextStyle(fontSize: 18)),
              Text(
                DateFormat('MMM dd, yyyy - h:mm a').format(widget.service.date),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Program'),
              Tab(text: 'Roster'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildProgramTab(),
                  _buildRosterTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgramTab() {
    // ... (unchanged)
    if (_programItems.isEmpty) {
      return const Center(child: Text('No program items found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _programItems.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = _programItems[index];
        
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
