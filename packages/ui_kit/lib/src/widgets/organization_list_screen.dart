import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'organization_detail_screen.dart';
import 'organization_admin_dashboard.dart';
import '../screens/notification_screen.dart';

class OrganizationListScreen extends StatefulWidget {
  const OrganizationListScreen({super.key});

  @override
  State<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends State<OrganizationListScreen> {
  final _orgRepo = OrganizationRepository();
  List<Organization> _organizations = [];
  bool _isLoading = true;
  Organization? _userOrg;
  bool _isOrgAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final org = await _orgRepo.getUserOrganization();
    bool isAdmin = false;
    if (org != null) {
      isAdmin = await _orgRepo.isOrgAdmin();
    }
    if (mounted) {
      setState(() {
        _userOrg = org;
        _isOrgAdmin = isAdmin;
      });
    }
  }

  Future<void> _fetchOrganizations() async {
    try {
      final orgs = await _orgRepo.getApprovedOrganizations();
      if (mounted) {
        setState(() {
          _organizations = orgs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_organizations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Communities'),
          actions: const [NotificationBell()],
        ),
        body: const Center(child: Text('No organizations found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchOrganizations();
          await _checkUserStatus();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _organizations.length,
          itemBuilder: (context, index) {
            final org = _organizations[index];
            // Check if this is the user's managed org
            final isManagedOrg = _isOrgAdmin && _userOrg?.id == org.id;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: org.avatarUrl != null ? NetworkImage(org.avatarUrl!) : null,
                  child: org.avatarUrl == null ? const Icon(Icons.church) : null,
                ),
                title: Text(org.name),
                subtitle: Text(org.location ?? 'Organization'),
                trailing: isManagedOrg 
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrganizationAdminDashboard(organization: org),
                            ),
                          );
                        },
                        child: const Text('Manage', style: TextStyle(fontSize: 12)),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrganizationDetailScreen(organization: org),
                      ),
                    );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
