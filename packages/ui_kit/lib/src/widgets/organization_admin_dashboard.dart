import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'branch_control_screen.dart';
import 'organization_info_form.dart';

class OrganizationAdminDashboard extends StatefulWidget {
  final Organization organization;
  
  const OrganizationAdminDashboard({super.key, required this.organization});

  @override
  State<OrganizationAdminDashboard> createState() => _OrganizationAdminDashboardState();
}

class _OrganizationAdminDashboardState extends State<OrganizationAdminDashboard> {
  final _orgRepo = OrganizationRepository();
  late Organization _organization;
  List<Branch> _branches = [];
  bool _isLoading = true;

  bool _canEditOrg = false;

  @override
  void initState() {
    super.initState();
    _organization = widget.organization;
    _checkRole();
    _fetchBranches();
  }

  Future<void> _checkRole() async {
    final isAdmin = await _orgRepo.isOrgAdmin();
    if (mounted) setState(() => _canEditOrg = isAdmin);
  }

  Future<void> _fetchBranches() async {
    try {
      final allBranches = await _orgRepo.getBranches(_organization.id);
      
      List<Branch> visibleBranches = [];

      if (_canEditOrg) {
        // Owner/Admin sees all
        visibleBranches = allBranches;
      } else {
        // Managers only see branches where they are 'manager'
        final userBranchData = await _orgRepo.getUserBranchData(_organization.id);
        
        final managedBranchIds = userBranchData
            .where((data) => data['role'] == 'manager')
            .map((data) => data['branch_id'] as String?)
            .whereType<String>()
            .toSet();
            
        visibleBranches = allBranches.where((b) => managedBranchIds.contains(b.id)).toList();
      }

      if (mounted) {
        setState(() {
          _branches = visibleBranches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showCreateBranchDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Branch'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Branch Name',
            hintText: 'e.g. North Campus',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await _orgRepo.createBranch(_organization.id, controller.text.trim());
                  _fetchBranches();
                  if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch Created!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final tabs = <Widget>[];
    final children = <Widget>[];

    // Tab 1: Info (Only for Admins/Owners)
    if (_canEditOrg) {
      tabs.add(const Tab(icon: Icon(Icons.info), text: 'Info'));
      children.add(OrganizationInfoForm(
        organization: _organization,
        isLoading: false,
        onSave: (updatedOrg) async {
          setState(() => _isLoading = true);
          try {
            await _orgRepo.updateOrganizationDetails(updatedOrg);
            if (mounted) {
              setState(() {
                _organization = updatedOrg;
                _isLoading = false; 
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Details Updated Successfully!')),
              );
            }
          } catch (e) {
              if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
          }
        },
        onUploadAvatar: (bytes, ext) async {
            setState(() => _isLoading = true);
            try {
              final url = await _orgRepo.uploadOrganizationAvatar(_organization.id, bytes, ext);
              final updatedOrg = Organization(
                  id: _organization.id,
                  name: _organization.name,
                  ownerId: _organization.ownerId,
                  createdAt: _organization.createdAt,
                  status: _organization.status,
                  acronym: _organization.acronym,
                  contactMobile: _organization.contactMobile,
                  contactLandline: _organization.contactLandline,
                  location: _organization.location,
                  website: _organization.website,
                  socialMediaLinks: _organization.socialMediaLinks,
                  avatarUrl: url, 
              );
              await _orgRepo.updateOrganizationDetails(updatedOrg);

              if (mounted) {
                setState(() {
                    _organization = updatedOrg; 
                    _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Avatar Updated Successfully!')),
                );
              }
            } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
                }
            }
        },
      ));
    }

    // Tab 2: Branches (Everyone)
    tabs.add(const Tab(icon: Icon(Icons.store), text: 'Branches'));
    children.add(ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_branches.isEmpty) 
          const Text('No branches found.')
        else
          ..._branches.map((branch) => Card(
            child: ListTile(
              leading: const Icon(Icons.store),
              title: Text(branch.name),
              subtitle: Text('ID: ${branch.id.substring(0, 8)}...'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BranchControlScreen(
                          organization: _organization,
                          branch: branch,
                        ),
                      ),
                    ).then((_) => _fetchBranches());
              },
            ),
          )),
      ],
    ));

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_organization.name),
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(children: children),
        floatingActionButton: _canEditOrg ? FloatingActionButton(
          onPressed: _showCreateBranchDialog,
          tooltip: 'Add Branch',
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }
}
