import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _orgRepo = OrganizationRepository();
  final _adminRepo = AdminRepository();
  
  List<Organization> _pendingOrgs = [];
  List<Organization> _allOrgs = [];
  List<Map<String, dynamic>> _allUsers = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final pendingRaw = await _orgRepo.getPendingOrganizations();
      final allOrgsRaw = await _adminRepo.getAllOrganizations();
      final allUsersRaw = await _adminRepo.getAllProfiles(); // Note: Profiles table needs to be populated correctly

      if (mounted) {
        setState(() {
          _pendingOrgs = pendingRaw;
          _allOrgs = allOrgsRaw;
          _allUsers = allUsersRaw;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String orgId, String status) async {
    try {
      if (status == 'rejected') {
        await _orgRepo.rejectAndDeletionOrganization(orgId);
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Organization Rejected & Deleted. User email freed.')),
             );
        }
      } else {
        await _orgRepo.updateOrganizationStatus(orgId, status);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Organization $status')),
            );
        }
      }
      _fetchAllData(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending), text: 'Pending'),
            Tab(icon: Icon(Icons.business), text: 'Organizations'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Pending Approvals
                _buildPendingList(),
                
                // Tab 2: All Organizations
                _buildAllOrgsList(),
                
                // Tab 3: All Users
                _buildAllUsersList(),
              ],
            ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingOrgs.isEmpty) {
      return const Center(child: Text('No pending organizations.'));
    }
    return ListView.builder(
      itemCount: _pendingOrgs.length,
      itemBuilder: (context, index) {
        final org = _pendingOrgs[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(org.name),
            subtitle: Text('ID: ${org.id}\nStatus: ${org.status}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _updateStatus(org.id, 'approved'),
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _updateStatus(org.id, 'rejected'),
                  tooltip: 'Reject & Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllOrgsList() {
    if (_allOrgs.isEmpty) {
      return const Center(child: Text('No organizations found.'));
    }
    return ListView.builder(
      itemCount: _allOrgs.length,
      itemBuilder: (context, index) {
        final org = _allOrgs[index];
        return ListTile(
          leading: const Icon(Icons.business),
          title: Text(org.name),
          subtitle: Text('Owner: ${org.ownerId}\nStatus: ${org.status}'),
          trailing: org.status == 'approved' 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.hourglass_empty, color: Colors.orange),
        );
      },
    );
  }

  Widget _buildAllUsersList() {
    if (_allUsers.isEmpty) {
      return const Center(child: Text('No users found.'));
    }
    return ListView.builder(
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        final username = user['username'] ?? 'No Username';
        final isSuperAdmin = user['is_superadmin'] == true;
        
        return ListTile(
          leading: CircleAvatar(child: Text(username[0].toUpperCase())),
          title: Text(username),
          subtitle: Text('ID: ${user['id']}'),
          trailing: isSuperAdmin 
              ? const Chip(label: Text('Admin'), backgroundColor: Colors.amber)
              : null,
        );
      },
    );
  }
}
