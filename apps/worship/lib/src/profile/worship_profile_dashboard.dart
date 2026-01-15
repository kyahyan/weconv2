import '../service_list_screen.dart'; // Added
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import '../create_line_up_screen.dart';

class WorshipProfileDashboard extends StatefulWidget {
  const WorshipProfileDashboard({super.key});

  @override
  State<WorshipProfileDashboard> createState() => _WorshipProfileDashboardState();
}

class _WorshipProfileDashboardState extends State<WorshipProfileDashboard> {
  final _authService = AuthService();
  final _profileRepo = ProfileRepository();
  final _orgRepo = OrganizationRepository();
  
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isWorshipLeader = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final profile = await _profileRepo.getProfile(user.id);
        
        // precise logic for worship leader verification
        // Check all org memberships for "Worship Leader" role or ministry role
        bool isLeader = false;
        final orgs = await _orgRepo.getUserOrganizations();
        
        for (var org in orgs) {
           final members = await _orgRepo.getUserBranchData(org.id);
           for (var member in members) {
              final role = member['role'] as String? ?? '';
              final ministryRoles = List.from(member['ministry_roles'] ?? []);
              
              print('DEBUG: Checking member in org ${org.name}: Role=$role, MinistryRoles=$ministryRoles');

              final roleShort = role.toLowerCase();
              final ministryRolesLower = ministryRoles.map((r) => r.toString().toLowerCase()).toList();
              
              if (['admin', 'manager', 'worship leader'].contains(roleShort) || 
                  ministryRolesLower.contains('worship leader') ||
                  ministryRolesLower.contains('leader')) {
                isLeader = true;
                break;
              }
           }
           if (isLeader) break;
        }

        if (mounted) {
          setState(() {
            _profile = profile;
            _isWorshipLeader = isLeader;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading profile data: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommonProfileScreen()),
    ).then((_) => _loadData()); // Reload after return
  }

  void _navigateToManageLineup() {
    Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => ServiceListScreen(
           onlyAssigned: true, // Only show assignments
           onServiceTap: (service) {
              // Navigate to CreateLineUpScreen (Editor)
              Navigator.push( 
                context,
                MaterialPageRoute(builder: (_) => CreateLineUpScreen(serviceId: service.id)),
              );
           },
         )
       ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToEditProfile,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundImage: (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(_profile!.avatarUrl!) 
                        : null,
                    child: (_profile?.avatarUrl == null || _profile!.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 50) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile?.fullName ?? 'No Name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    _profile?.username ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            
            // Worship Leader Section
            if (_isWorshipLeader) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Worship Leader Actions', 
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                icon: Icons.playlist_add,
                title: 'Create Line Up Song',
                subtitle: 'Add songs to your assigned service lineup',
                onTap: _navigateToManageLineup,
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _authService.signOut();
                if (mounted) {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
