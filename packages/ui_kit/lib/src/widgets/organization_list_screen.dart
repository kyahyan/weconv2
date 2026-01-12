import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'organization_detail_screen.dart';

class OrganizationListScreen extends StatefulWidget {
  const OrganizationListScreen({super.key});

  @override
  State<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends State<OrganizationListScreen> {
  final _orgRepo = OrganizationRepository();
  List<Organization> _organizations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
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
        // Fail silently or show error in UI? For a tab, maybe just empty list or retry button
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_organizations.isEmpty) {
      return const Center(child: Text('No organizations found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchOrganizations,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _organizations.length,
        itemBuilder: (context, index) {
          final org = _organizations[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.church)),
              title: Text(org.name),
              subtitle: const Text('Organization'),
              trailing: const Icon(Icons.chevron_right),
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
    );
  }
}
