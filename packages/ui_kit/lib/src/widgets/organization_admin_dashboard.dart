import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'branch_control_screen.dart';

class OrganizationAdminDashboard extends StatefulWidget {
  final Organization organization;
  
  const OrganizationAdminDashboard({super.key, required this.organization});

  @override
  State<OrganizationAdminDashboard> createState() => _OrganizationAdminDashboardState();
}

class _OrganizationAdminDashboardState extends State<OrganizationAdminDashboard> {
  final _orgRepo = OrganizationRepository();
  List<Branch> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      final branches = await _orgRepo.getBranches(widget.organization.id);
      if (mounted) {
        setState(() {
          _branches = branches;
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
                  await _orgRepo.createBranch(widget.organization.id, controller.text.trim());
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.organization.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text('Admin Dashboard', style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Branches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
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
                               organization: widget.organization,
                               branch: branch,
                             ),
                           ),
                         );
                    },
                  ),
                )),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBranchDialog,
        tooltip: 'Add Branch',
        child: const Icon(Icons.add),
      ),
    );
  }
}
