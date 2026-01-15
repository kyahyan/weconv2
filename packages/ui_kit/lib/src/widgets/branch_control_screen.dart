import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:image_picker/image_picker.dart';
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
  late Branch _currentBranch; // Local state for immediate updates

  @override
  void initState() {
    super.initState();
    _currentBranch = widget.branch; // Initialize
    _checkPermissions();
    _fetchMembers();
  }

  // ... (rest of class)



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
      final rawMembers = await _orgRepo.getBranchMembers(widget.organization.id, widget.branch.id);
      final members = rawMembers.where((m) => m['user_id'] != widget.organization.ownerId).toList();
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
    // 1. Compile Suggestions (Defaults + Used Roles in this Branch)
    final Set<String> allRoles = {
      'Attender', 'Leader', 'Musician', 'Ushering', 'Multimedia', 
      'Kids Teacher', 'Worship Leader', 'Singer', 'Greeter',
      'Organizer', 'Operator'
    };
    
    // Add roles currently used by other members
    for (var m in _members) {
      if (m['ministry_roles'] != null) {
        for (var r in m['ministry_roles']) {
          allRoles.add(r.toString());
        }
      }
    }
    final List<String> suggestions = allRoles.toList()..sort();

    // 2. Current Member Roles
    List<String> currentRoles = [];
    if (member['ministry_roles'] != null) {
      currentRoles = List<String>.from(member['ministry_roles']);
    }

    // Input Controller
    String currentInput = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            return AlertDialog(
              title: Text('Assign Roles: ${member['profile']?['username'] ?? ''}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Special Checkbox for Musician
                    CheckboxListTile(
                      title: const Text('Musician'),
                      subtitle: const Text('Assign to Worship Team'),
                      value: currentRoles.contains('Musician'),
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            if (!currentRoles.contains('Musician')) {
                              currentRoles.add('Musician');
                            }
                          } else {
                            currentRoles.remove('Musician');
                          }
                        });
                      },
                      activeColor: Colors.deepPurple,
                      dense: true,
                       controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const Divider(),
                    // Operator & Organizer Checkboxes
                    CheckboxListTile(
                      title: const Text('Operator'),
                      subtitle: const Text('Assign for Presentation App Access'),
                      value: currentRoles.contains('Operator'),
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            if (!currentRoles.contains('Operator')) {
                              currentRoles.add('Operator');
                            }
                          } else {
                            currentRoles.remove('Operator');
                          }
                        });
                      },
                      activeColor: Colors.deepPurple,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Organizer'),
                      subtitle: const Text('Assign for Planning App Access'),
                      value: currentRoles.contains('Organizer'),
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            if (!currentRoles.contains('Organizer')) {
                              currentRoles.add('Organizer');
                            }
                          } else {
                            currentRoles.remove('Organizer');
                          }
                        });
                      },
                      activeColor: Colors.deepPurple,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Usher'),
                      subtitle: const Text('Assign to Ushering Team'),
                      value: currentRoles.contains('Ushering'),
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            if (!currentRoles.contains('Ushering')) {
                              currentRoles.add('Ushering');
                            }
                          } else {
                            currentRoles.remove('Ushering');
                          }
                        });
                      },
                      activeColor: Colors.deepPurple,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const Divider(),
                     // Input
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        currentInput = textEditingValue.text;
                        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                        return suggestions.where((option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        if (!currentRoles.contains(selection)) {
                          setStateDialog(() {
                            currentRoles.add(selection);
                            currentInput = '';
                          });
                        }
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Add Role',
                            hintText: 'Select or type new role',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.add_circle_outline),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (val) => currentInput = val,
                          onSubmitted: (val) {
                             if (val.trim().isNotEmpty && !currentRoles.contains(val.trim())) {
                               setStateDialog(() {
                                 currentRoles.add(val.trim());
                                 textEditingController.clear();
                                 currentInput = '';
                               });
                             }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Selected Roles:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    
                    // Chips
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: currentRoles.map((role) {
                        return Chip(
                          label: Text(role),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          labelStyle: TextStyle(color: Colors.blue.shade800),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setStateDialog(() {
                              currentRoles.remove(role);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    if (currentRoles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No roles assigned', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    // Safety: Add whatever is in the input box if they forgot to press enter
                    if (currentInput.trim().isNotEmpty && !currentRoles.contains(currentInput.trim())) {
                      currentRoles.add(currentInput.trim());
                    }

                    Navigator.pop(dialogContext); // Close UI first

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
                      
                      if (mounted) { // Check if the SCREEN is still mounted (not the dialog)
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                           content: Text('Roles Updated'),
                           duration: Duration(seconds: 1),
                         ));
                      }
                    } catch(e) {
                      debugPrint('Error updating roles: $e');
                      // Revert/Fix state on error
                      if(mounted) _fetchMembers(); 
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

  // ... inside _fetchMembers ...

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentBranch.name),
              const Text('Branch Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Members'),
              Tab(icon: Icon(Icons.info), text: 'Info'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Members
            Column(
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
                             // ... existing dashboard buttons ...
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
                                      ownerId: widget.organization.ownerId,
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
                            
                            String role = member['role'] as String;
                            if (memberUserId == widget.organization.ownerId) {
                               role = 'owner';
                            }
                            final isManager = role == 'manager';
                            final isOwner = role == 'owner';
                            final username = profile['username'] ?? 'Unknown User';
                            final ministryRoles = (member['ministry_roles'] as List<dynamic>?)?.join(', ') ?? '';
                            final membershipId = member['id'];
                            final isMe = memberUserId == _currentUserId;

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
                                  if (_isCurrentUserOrgAdmin && !isMe)
                                    ElevatedButton(
                                      onPressed: () => _promoteToManager(membershipId, role),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isManager ? Colors.redAccent : Colors.teal,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(isManager ? 'Demote' : 'Promote', style: const TextStyle(fontSize: 12)),
                                    ),
                                    
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

            // Tab 2: Info (Edit Branch)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _BranchInfoForm(
                organization: widget.organization,
                branch: _currentBranch,
                canEdit: _canManageRoles, 
                orgRepo: _orgRepo,
                onBranchUpdated: (updated) => setState(() => _currentBranch = updated),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchInfoForm extends StatefulWidget {
  final Organization organization;
  final Branch branch;
  final bool canEdit;
  final OrganizationRepository orgRepo;
  final Function(Branch) onBranchUpdated;

  const _BranchInfoForm({
    required this.organization,
    required this.branch,
    required this.canEdit,
    required this.orgRepo,
    required this.onBranchUpdated,
  });

  @override
  State<_BranchInfoForm> createState() => _BranchInfoFormState();
}

class _BranchInfoFormState extends State<_BranchInfoForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _acronymCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _landlineCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _facebookCtrl;
  late TextEditingController _websiteCtrl;
  
  bool _isSaving = false;
  String? _displayAvatarUrl; // Local state for avatar

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.branch.name);
    _acronymCtrl = TextEditingController(text: widget.branch.acronym);
    _mobileCtrl = TextEditingController(text: widget.branch.contactMobile);
    _landlineCtrl = TextEditingController(text: widget.branch.contactLandline);
    _addressCtrl = TextEditingController(text: widget.branch.address);
    
    final social = widget.branch.socialMediaLinks ?? {};
    _facebookCtrl = TextEditingController(text: social['Facebook'] ?? '');
    _websiteCtrl = TextEditingController(text: social['Website'] ?? '');
    
    _displayAvatarUrl = widget.branch.avatarUrl;
  }

  // ... dispose ...

  Future<void> _save() async {
    if (!widget.canEdit) return;
    setState(() => _isSaving = true);

    try {
       final socialLinks = {
        if (_facebookCtrl.text.isNotEmpty) 'Facebook': _facebookCtrl.text.trim(),
        if (_websiteCtrl.text.isNotEmpty) 'Website': _websiteCtrl.text.trim(),
      };

      final updatedBranch = Branch(
        id: widget.branch.id,
        organizationId: widget.branch.organizationId,
        name: _nameCtrl.text.trim(),
        createdAt: widget.branch.createdAt,
        acronym: _acronymCtrl.text.trim(),
        contactMobile: _mobileCtrl.text.trim(),
        contactLandline: _landlineCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        avatarUrl: widget.branch.avatarUrl,
        socialMediaLinks: socialLinks.isEmpty ? null : socialLinks, 
      );

      await widget.orgRepo.updateBranchDetails(updatedBranch);

      if (mounted) {
        widget.onBranchUpdated(updatedBranch); // Update parent
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch details saved!')));
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ... _pickAndUploadAvatar ...

  Future<void> _pickAndUploadAvatar() async {
    if (!widget.canEdit) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
      
      if (image == null) return;

      setState(() => _isSaving = true);
      
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      
      // Upload returns the base URL
      final url = await widget.orgRepo.uploadBranchAvatar(widget.branch.id, bytes, ext);
      
      // Cache Busting: Append timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueUrl = '$url?t=$timestamp';

      // Create updated branch object
      final socialLinks = {
        if (_facebookCtrl.text.isNotEmpty) 'Facebook': _facebookCtrl.text.trim(),
        if (_websiteCtrl.text.isNotEmpty) 'Website': _websiteCtrl.text.trim(),
      };

      final updatedBranch = Branch(
        id: widget.branch.id,
        organizationId: widget.branch.organizationId,
        name: _nameCtrl.text.trim(),
        createdAt: widget.branch.createdAt,
        acronym: _acronymCtrl.text.trim(),
        contactMobile: _mobileCtrl.text.trim(),
        contactLandline: _landlineCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        avatarUrl: uniqueUrl, // Use unique URL for DB to persist the "version" or just URL? 
        // Supabase storage URL is static. If we save "url?t=..." to DB, next fetch will have it. 
        // This is good.
        socialMediaLinks: socialLinks.isEmpty ? null : socialLinks, 
      );

      await widget.orgRepo.updateBranchDetails(updatedBranch);

      if (mounted) {
        widget.onBranchUpdated(updatedBranch); // Update parent
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated!')));
        setState(() {
           _isSaving = false;
           _displayAvatarUrl = uniqueUrl; // Update local state for immediate feedback
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Center(
           child: Stack(
             children: [
               CircleAvatar(
                 radius: 50,
                 backgroundColor: Colors.grey.shade200,
                 backgroundImage: _displayAvatarUrl != null 
                    ? NetworkImage(_displayAvatarUrl!) 
                    : null,
                 child: _displayAvatarUrl == null 
                    ? Text(widget.branch.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 40))
                    : null,
               ),
               if (widget.canEdit)
                 Positioned(
                   bottom: 0,
                   right: 0,
                   child: CircleAvatar(
                     radius: 18,
                     backgroundColor: Colors.deepPurple,
                     child: IconButton(
                       icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                       onPressed: _isSaving ? null : _pickAndUploadAvatar,
                     ),
                   ),
                 ),
             ],
           ),
         ),
        const SizedBox(height: 16),
        
        Text('Parent Org: ${widget.organization.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        // ... rest of form
        const Divider(),
        const SizedBox(height: 16),

        TextField(
          controller: _nameCtrl,
          enabled: widget.canEdit,
          decoration: const InputDecoration(labelText: 'Branch Name', border: OutlineInputBorder()),
        ),
// ... keeping rest same ...
        const SizedBox(height: 16),
        
        TextField(
          controller: _acronymCtrl,
          enabled: widget.canEdit,
          decoration: const InputDecoration(labelText: 'Acronym (e.g. WFIM)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),

        const Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mobileCtrl,
                enabled: widget.canEdit,
                decoration: const InputDecoration(labelText: 'Mobile', prefixIcon: Icon(Icons.smartphone), border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _landlineCtrl,
                enabled: widget.canEdit,
                decoration: const InputDecoration(labelText: 'Landline', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _addressCtrl,
          enabled: widget.canEdit,
          decoration: const InputDecoration(labelText: 'Location / Address', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        
         const Text('Social Media', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _facebookCtrl,
          enabled: widget.canEdit,
          decoration: const InputDecoration(labelText: 'Facebook URL', prefixIcon: Icon(Icons.facebook), border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _websiteCtrl,
          enabled: widget.canEdit,
          decoration: const InputDecoration(labelText: 'Website URL', prefixIcon: Icon(Icons.language), border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),

        if (widget.canEdit)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
            ),
          ),
      ],
    );
  }
}
