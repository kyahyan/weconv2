import 'package:core/core.dart';
import 'package:flutter/material.dart';
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
  Map<String, String> _joinedBranchRoles = {};

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
      
      // 2. Fetch My Roles in this Org
      final roles = await _orgRepo.getUserBranchRoles(widget.organization.id);

      if (mounted) {
        setState(() {
          _branches = branches; // Use local list
          _joinedBranchRoles = roles;
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
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.church, size: 60, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(org.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('ID: ${org.id}', style: Theme.of(context).textTheme.bodySmall),
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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.people),
                      label: const Text('You are a member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.withOpacity(0.2),
                        foregroundColor: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Branches', style: Theme.of(context).textTheme.titleLarge),
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
                final userRole = _joinedBranchRoles[branch.id];
                final isJoined = userRole != null;
                final isManager = userRole == 'manager';

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isManager ? Colors.amber : (isJoined ? Colors.green : Colors.grey.shade800),
                      child: Icon(
                        isManager ? Icons.star : (isJoined ? Icons.check : Icons.location_on), 
                        color: Colors.white
                      ),
                    ),
                    title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: isManager 
                      ? const Text('Manage Branch', style: TextStyle(color: Colors.amber))
                      : null,
                    
                    onTap: isManager ? () {
                       Navigator.push(context, MaterialPageRoute(
                         builder: (_) => BranchControlScreen(organization: widget.organization, branch: branch),
                       ));
                    } : null,

                    trailing: (isManager) 
                        ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber)
                        : (isJoined
                            ? ElevatedButton(
                                onPressed: () => _leaveBranch(branch.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                                  foregroundColor: Colors.redAccent,
                                  elevation: 0,
                                ),
                                child: const Text('Leave'),
                              )
                            : OutlinedButton(
                                onPressed: () => _joinBranch(branch.id),
                                child: const Text('Join'),
                              )
                          ),
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
