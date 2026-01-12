import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'ushering_dashboard.dart';

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
  bool _hasDashboardAccess = false; // Manager or Usher or Admin
  bool _canManageRoles = false; // Manager or Admin

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchMembers();
  }

  Future<void> _checkPermissions() async {
    bool isAdmin = await _orgRepo.isOrgAdmin(); 
    _currentUserId = _orgRepo.currentUser?.id;
    
    // Check specific branch role
    bool isStaff = false;
    if (_currentUserId != null) {
      final members = await _orgRepo.getBranchMembersHelper(widget.branch.id);
      final me = members.firstWhere(
        (m) => m['user_id'] == _currentUserId, 
        orElse: () => <String, dynamic>{}
      );
      
      if (me.isNotEmpty) {
        final role = me['role'];
        final ministryRoles = List<String>.from(me['ministry_roles'] ?? []);
        final isManager = role == 'manager';
        final isUsher = ministryRoles.contains('Ushering') || ministryRoles.contains('Usher');
        isStaff = isManager || isUsher;
        
        // canManageRoles: Admin or Manager
        if (isManager) _canManageRoles = true;
      }
    }
    
    // Explicitly check for Organization Owner
    if (_currentUserId == widget.organization.ownerId) {
       isAdmin = true;
    }

    // Admin always can
    if (isAdmin) _canManageRoles = true;

    if (mounted) {
      setState(() {
        _isCurrentUserOrgAdmin = isAdmin;
        _hasDashboardAccess = isAdmin || isStaff;
        // _canManageRoles is already updated on instance? No, it's a field I need to add.
        // Wait, I haven't added `bool _canManageRoles = false;` to the class yet.
        // I will do that in the next step or this replacement chunk if I can reach it.
        // Let's assume I add it to the setState block but I need to declare it first.
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
            const Text('Branch Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_hasDashboardAccess)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.blueGrey.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (_isCurrentUserOrgAdmin) ...[
                              const Row(
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
                              const SizedBox(height: 16),
                            ],
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => UsheringDashboard(
                                      branchId: widget.branch.id,
                                      branchName: widget.branch.name,
                                    ))
                                  );
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: const Text('Attendance Dashboard'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
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
                            final memberUserId = member['user_id'];
                            
                            // Override role if Owner
                            String role = member['role'] as String;
                            if (memberUserId == widget.organization.ownerId) {
                              role = 'owner';
                            }
                            
                            final isManager = role == 'manager';
                            final isOwner = role == 'owner';
                            final username = profile['username'] ?? 'Unknown User';
                            final ministryRoles = (member['ministry_roles'] as List<dynamic>?)?.join(', ') ?? '';
                            final membershipId = member['id'];
                            
                            // Am I looking at myself?
                            final isMe = memberUserId == _currentUserId;
                            
                            // Permission: Can Edit Roles? (Admin or Manager)
                            // We need to know if *current user* is manager. 
                            // Since _hasDashboardAccess is (Admin || Staff), and Staff includes Usher.
                            // We need more granular flag, or iterate permissions again.
                            // Let's assume we store _isCurrentUserManager in state?
                            
                            // Hack: Re-derive or assuming we added it? 
                            // I didn't add _isCurrentUserManager to state yet.
                            // Let's use _isCurrentUserOrgAdmin OR (Manager Check).
                            
                            // Actually, let's just use `_hasDashboardAccess` but that includes Ushers.
                            // Need to filter out Ushers.  
                            // Let's just fix it properly by checking role right here? 
                            // No, UI rebuilds. 
                            
                            // Let's add `_canManageRoles` to state.
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isOwner ? Colors.purple : (isManager ? Colors.amber : Colors.grey),
                                child: Icon(
                                  isOwner ? Icons.verified_user : (isManager ? Icons.star : Icons.person), 
                                  color: Colors.white
                                ),
                              ),
                              title: Text(username, style: TextStyle(fontWeight: (isManager || isOwner) ? FontWeight.bold : null)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isOwner ? 'Organization Owner' : (isManager ? 'Manager' : 'Member')),
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
                                    
                                  // 2. Manager Action: Assign Roles 
                                  // Show ONLY if I am Admin OR I am Manager (NOT just Usher)
                                  if (_canManageRoles) 
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
