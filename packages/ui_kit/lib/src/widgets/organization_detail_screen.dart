import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:models/models.dart';
import 'branch_control_screen.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationDetailScreen({super.key, required this.organization});

  @override
  State<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  final _orgRepo = OrganizationRepository();
  bool _isLoading = true;
  List<Branch> _branches = []; // Restored
  Map<String, Map<String, dynamic>> _joinedBranchRoles = {};

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Branches separately (since Organization model doesn't hold them)
      final branches = await _orgRepo.getBranches(widget.organization.id);
      
      // 2. Fetch My Roles in this Org (Rich Data)
      final data = await _orgRepo.getUserBranchData(widget.organization.id);
      final roleMap = <String, Map<String, dynamic>>{};
      for (var item in data) {
         if (item['branch_id'] != null) {
           roleMap[item['branch_id']] = item;
         }
      }

      if (mounted) {
        setState(() {
          _branches = branches; // Use local list
          _joinedBranchRoles = roleMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _joinBranch(String branchId) async {
    try {
      await _orgRepo.joinBranch(widget.organization.id, branchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined branch!')));
        _fetchDetails(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error joining: $e')));
      }
    }
  }

  Future<void> _leaveBranch(String branchId) async {
    try {
      await _orgRepo.leaveBranch(widget.organization.id, branchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left branch.')));
        _fetchDetails(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error leaving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final org = widget.organization;

    return Scaffold(
      appBar: AppBar(title: Text(org.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            ShadCard(
              title: Text(org.name, style: ShadTheme.of(context).textTheme.h4),
              description: Text('ID: ${org.id}'),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.church, size: 60, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(org.status.toUpperCase(), 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),
              footer: ShadButton.secondary(
                width: double.infinity,
                onPressed: () {},
                icon: const Icon(Icons.people, size: 16),
                text: const Text('You are a member'),
              ),
            ),
            const SizedBox(height: 32),
            Text('Branches', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 16),
            
            if (_branches.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No branches available.'))),

              ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _branches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final branch = _branches[index];
                final roleData = _joinedBranchRoles[branch.id] ?? {};
                final userRole = roleData['role'];
                final ministryRoles = List<String>.from(roleData['ministry_roles'] ?? []);
                
                final isJoined = userRole != null;
                final isManager = userRole == 'manager';
                final isUsher = ministryRoles.contains('Ushering') || ministryRoles.contains('Usher'); // Check both spelling just in case
                
                // "Staff" access: Manager or Usher or Admin/Owner (from Org check)
                final hasDashboardAccess = isManager || isUsher;

                return ShadCard(
                  padding: const EdgeInsets.all(16),
                  content: Row(
                    children: [
                       ShadAvatar('https://github.com/shadcn.png'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(branch.name, style: ShadTheme.of(context).textTheme.large),
                            if (isManager) Text('Manager', style: ShadTheme.of(context).textTheme.small.copyWith(color: Colors.amber)),
                            if (isUsher) Text('Usher Team', style: ShadTheme.of(context).textTheme.small.copyWith(color: Colors.purple)),
                            if (!isManager && !isUsher && isJoined) Text('Member', style: ShadTheme.of(context).textTheme.muted),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasDashboardAccess)
                        ShadButton.outline(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(
                               builder: (_) => BranchControlScreen(organization: widget.organization, branch: branch),
                             ));
                          },
                          text: const Text('Dashboard'),
                        )
                      else if (isJoined)
                         ShadButton.destructive(
                            onPressed: () => _leaveBranch(branch.id),
                            text: const Text('Leave'),
                          )
                      else
                        ShadButton(
                          onPressed: () => _joinBranch(branch.id),
                          text: const Text('Join'),
                        )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
