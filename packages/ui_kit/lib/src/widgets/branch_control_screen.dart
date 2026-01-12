import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class BranchControlScreen extends StatefulWidget {
  final Organization organization;
  final Branch branch;

  const BranchControlScreen({
    super.key, 
    required this.organization,
    required this.branch,
  });

  @override
  State<BranchControlScreen> createState() => _BranchControlScreenState();
}

class _BranchControlScreenState extends State<BranchControlScreen> {
  final _orgRepo = OrganizationRepository();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isCurrentUserOrgAdmin = false; // "Owner" or high-level admin
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchMembers();
  }

  Future<void> _checkPermissions() async {
    // Only Org Admin (Owner) can assign Managers.
    final isAdmin = await _orgRepo.isOrgAdmin(); 
    // We also need to know if I AM a manager of this branch to show the "Assign Roles" UI.
    // Ideally we fetch my role for this specific branch.
    // For now, let's assume if I can land here, I have some rights, but let's separate them.
    // But 'isOrgAdmin' checks if I am the OWNER usually.
    
    _currentUserId = _orgRepo.currentUser?.id;

    if (mounted) {
      setState(() {
        _isCurrentUserOrgAdmin = isAdmin;
      });
    }
  }

  Future<void> _fetchMembers() async {
    try {
      final members = await _orgRepo.getBranchMembers(widget.organization.id, widget.branch.id);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error: $e');
      }
    }
  }

  Future<void> _promoteToManager(String membershipId, String currentRole) async {
    try {
      final newRole = currentRole == 'manager' ? 'member' : 'manager'; // Toggle
      await _orgRepo.updateMemberRole(membershipId, newRole);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newRole == 'manager' ? 'Promoted to Manager' : 'Demoted to Member')
        ));
        _fetchMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showRoleDialog(Map<String, dynamic> member) async {
    // Available Roles
    final List<String> availableRoles = ['Attender', 'Leader', 'Instrumentalist', 'Ushering', 'Multimedia', 'Kids Teacher'];
    
    // Current Roles (ensure it's a List<String>)
    List<String> currentRoles = [];
    if (member['ministry_roles'] != null) {
      currentRoles = List<String>.from(member['ministry_roles']);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Assign Roles: ${member['profile']?['username'] ?? ''}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableRoles.map((role) {
                    final isSelected = currentRoles.contains(role);
                    return CheckboxListTile(
                      title: Text(role),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            currentRoles.add(role);
                          } else {
                            currentRoles.remove(role);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close UI first

                    // Optimistic Update: Update UI immediately before DB confirms
                    setState(() {
                      final index = _members.indexWhere((m) => m['id'] == member['id']);
                      if (index != -1) {
                        final updated = Map<String, dynamic>.from(_members[index]);
                        updated['ministry_roles'] = currentRoles;
                        _members[index] = updated;
                      }
                    });

                    try {
                      await _orgRepo.updateMinistryRoles(member['id'], currentRoles);
                      // Re-fetch to ensure consistency, but user already sees change
                      _fetchMembers();
                      
                      if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                           content: Text('Roles Updated'),
                           duration: Duration(seconds: 1),
                         ));
                      }
                    } catch(e) {
                      debugPrint('Error updating roles: $e');
                      // Revert/Fix state on error
                      _fetchMembers(); 
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.branch.name),
            const Text('Branch Control', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isCurrentUserOrgAdmin)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.blueGrey.withOpacity(0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blueAccent),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'As an Owner, you can Assign Managers. Managers can then assign ministry roles.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _members.isEmpty
                      ? const Center(child: Text('No members in this branch yet.'))
                      : ListView.builder(
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final profile = member['profile'] ?? {};
                            final role = member['role'] as String;
                            final isManager = role == 'manager';
                            final username = profile['username'] ?? 'Unknown User';
                            final ministryRoles = (member['ministry_roles'] as List<dynamic>?)?.join(', ') ?? '';
                            final membershipId = member['id'];
                            final memberUserId = member['user_id'];
                            
                            // Am I looking at myself?
                            final isMe = memberUserId == _currentUserId;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isManager ? Colors.amber : Colors.grey,
                                child: Icon(isManager ? Icons.star : Icons.person, color: Colors.white),
                              ),
                              title: Text(username, style: TextStyle(fontWeight: isManager ? FontWeight.bold : null)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isManager ? 'Manager' : 'Member'),
                                  if (ministryRoles.isNotEmpty)
                                    Text('Roles: $ministryRoles', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Owner Action: Make Manager (If not me)
                                  if (_isCurrentUserOrgAdmin && !isMe)
                                    ElevatedButton(
                                      onPressed: () => _promoteToManager(membershipId, role),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isManager ? Colors.redAccent : Colors.teal,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(isManager ? 'Demote' : 'Promote', style: const TextStyle(fontSize: 12)),
                                    ),
                                    
                                  // 2. Manager Action: Assign Roles (If I am a Manager OR Owner, and target is NOT me)
                                  // Actually, can I assign roles to myself? Usually yes.
                                  // Only show if I have permission. 
                                  // For simplicity: If I am Admin OR (I am Manager), I can edit roles.
                                  // We'll rely on RLS to fail if I'm not allowed, 
                                  // but generally: Owner -> Can do everything. Manager -> Can edit roles of Members (and themselves).
                                  IconButton(
                                    icon: const Icon(Icons.edit_note),
                                    onPressed: () => _showRoleDialog(member),
                                    tooltip: 'Assign Ministry Roles',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
