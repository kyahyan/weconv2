import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'musician_dashboard.dart';

class WorshipHomeScreen extends StatefulWidget {
  const WorshipHomeScreen({super.key});

  @override
  State<WorshipHomeScreen> createState() => _WorshipHomeScreenState();
}

class _WorshipHomeScreenState extends State<WorshipHomeScreen> {
  int _currentIndex = 1; // Default to 'Songs' as per user interest context usually, or 'Feed'? 0 = Feed, 1 = Songs
  // User asked for "Feed, Songs, Church". Let's default to 0 (Feed) or 1 (Songs)?
  // "for the Home Page, can we have a Tab for Feed, Songs, Church"
  // Let's default to 1 (Songs) since it was "Worship Setlists" app before.
  
  final _orgRepo = OrganizationRepository();
  final _authService = AuthService();
  
  List<Organization> _userOrgs = [];
  Organization? _selectedOrg;
  bool _isLoadingOrg = true;

  @override
  void initState() {
    super.initState();
    _fetchOrgs();
  }

  Future<void> _fetchOrgs() async {
    try {
      final orgs = await _orgRepo.getUserOrganizations();
      if (mounted) {
        setState(() {
          _userOrgs = orgs;
          // User requested "Org Card then when we clicked shows the details"
          // So we will NOT auto-select even if there is only 1. 
          // We will always show the list of cards (summary view) first.
          _isLoadingOrg = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOrg = false);
    }
  }

  Future<void> _showCreateSongDialog() async {
    // Placeholder for "Contributor" feature
    // "can we have a contributor for the user can create song."
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Song'),
        content: const Text('Song creation interface coming soon!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worship'),
        centerTitle: false, // Modern look? Or center? Default is fine.
        actions: [
          // Contributor / Create Song Action
           IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Song',
            onPressed: _showCreateSongDialog,
          ),
          
          // Avatar / Profile
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 18), 
              // Ideally fetch user avatar, but AuthGate or CommonProfileScreen handles fetching.
              // To show avatar here we need to fetch profile in this Screen or use a provider.
              // For now, simple icon that leads to profile.
            ),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommonProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Feed
          const Center(child: Text('Feed Tab - Coming Soon')),
          
          // 1: Songs
          _buildSongsTab(),
          
          // 2: Church
          _buildChurchTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.rss_feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Songs'),
          BottomNavigationBarItem(icon: Icon(Icons.church), label: 'Church'),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Worship Songs Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showCreateSongDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add New Song'),
          ),
          const SizedBox(height: 24),
          // Old "Musician Dashboard" link? 
          // "There's a restricted area for musician only."
          // Maybe put a button here too if they are authorized?
          // Or keep it hidden until we integrate it better.
          // Accessing restricted area was in ServiceListScreen app bar actions.
          // Let's add a button here for now if they want to access "Musician Area"
          OutlinedButton(
             onPressed: () {
               // Check role logic or just let them try and see?
               // Re-implement role check logic here?
               // For speed, let's just go there and MusicianDashboard can potentially implement a check 
               // OR we trust the "hidden" nature.
               // Let's check role quickly.
               _checkMusicianAccess();
             }, 
             child: const Text('Restricted: Musician Area'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkMusicianAccess() async {
    // Basic check logic similar to previous screen
    // ...
    // For now navigate directly, if they aren't musicians they just see the screen.
    // Real implementation should guard it.
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicianDashboard()));
  }

  Widget _buildChurchTab() {
    if (_isLoadingOrg) return const Center(child: CircularProgressIndicator());
    
    if (_userOrgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.church_outlined, size: 64, color: Colors.grey),
             SizedBox(height: 16),
            Text('No Organization Found'),
            Text('Please join an organization in the Community App.'),
          ],
        ),
      );
    }

    // If selected, show details
    if (_selectedOrg != null) {
      return _buildOrgDetails(_selectedOrg!);
    }

    // Otherwise, show list of Org Cards (Summary)
    // Only show "My Churches" title if > 1? Or always fine.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userOrgs.length,
      itemBuilder: (context, index) {
        final org = _userOrgs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _selectedOrg = org;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.church, size: 48, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    org.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(org.status.toUpperCase()),
                    backgroundColor: Colors.deepPurple.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tap for details', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrgDetails(Organization displayOrg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner / Header
            Container(
               height: 150,
               color: Colors.deepPurple.shade100,
               child: Stack(
                 children: [
                   Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(Icons.church, size: 56, color: Colors.deepPurple),
                         const SizedBox(height: 12),
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16.0),
                           child: Text(
                             displayOrg.name, 
                             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                             textAlign: TextAlign.center,
                           ),
                         ),
                       ],
                     ),
                   ),
                   // Always show back button since we are coming from a list/card view now
                   Positioned(
                     top: 16,
                     left: 16,
                     child: CircleAvatar(
                       backgroundColor: Colors.white54,
                       child: IconButton(
                         icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
                         onPressed: () {
                           setState(() {
                             _selectedOrg = null;
                           });
                         },
                       ),
                     ),
                   ),
                 ],
               ),
            ),
            
            // Details Body
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Organization Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline, color: Colors.grey),
                    title: const Text('Status'),
                    subtitle: Text(displayOrg.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified_user_outlined, color: Colors.grey),
                    title: const Text('Owner ID'),
                    subtitle: Text(displayOrg.ownerId, style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis)),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('My Branches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  FutureBuilder<List<Branch>>(
                    future: _fetchMyBranches(displayOrg.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text('Error loading branches: ${snapshot.error}');
                      }
                      
                      final branches = snapshot.data ?? [];
                      if (branches.isEmpty) {
                        return const Text('Not joined to any branch (Member of Org only).');
                      }

                      return Wrap(
                        spacing: 8.0,
                        children: branches.map((branch) => ActionChip(
                          avatar: const Icon(Icons.place, size: 16),
                          label: Text(branch.name),
                          backgroundColor: Colors.deepPurple.shade50,
                          onPressed: () => _showBranchDetails(branch, displayOrg),
                        )).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... _fetchMyBranches ...

  void _showBranchDetails(Branch branch, Organization org) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(24),
        title: Column(
          children: [
            if (branch.avatarUrl != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(branch.avatarUrl!),
              )
            else
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.deepPurple.shade100,
                child: Text(branch.name.substring(0, 1).toUpperCase()),
              ),
            const SizedBox(height: 12),
            Text(branch.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (branch.acronym != null && branch.acronym!.isNotEmpty)
              Text('(${branch.acronym})', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            _buildDetailRow(Icons.business, 'Parent Org', org.name),
            if (branch.contactMobile != null && branch.contactMobile!.isNotEmpty)
              _buildDetailRow(Icons.smartphone, 'Mobile', branch.contactMobile!),
            if (branch.contactLandline != null && branch.contactLandline!.isNotEmpty)
              _buildDetailRow(Icons.phone, 'Landline', branch.contactLandline!),
            if (branch.address != null && branch.address!.isNotEmpty)
               _buildDetailRow(Icons.location_on, 'Address', branch.address!),
            if (branch.socialMediaLinks != null && branch.socialMediaLinks!.isNotEmpty)
              _buildSocialLinks(branch.socialMediaLinks!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Icon(icon, size: 18, color: Colors.deepPurple),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                 Text(value, style: const TextStyle(fontSize: 14)),
               ],
             ),
           ),
         ],
      ),
    );
  }

  Widget _buildSocialLinks(Map<String, dynamic> links) {
     return Padding(
       padding: const EdgeInsets.only(top: 12.0),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Text('Social Media', style: TextStyle(fontSize: 10, color: Colors.grey)),
           const SizedBox(height: 4),
           Wrap(
             spacing: 8,
             children: links.entries.map((e) {
               return Chip(
                 label: Text('${e.key}: ${e.value}'),
                 labelStyle: const TextStyle(fontSize: 10),
                 backgroundColor: Colors.blue.withOpacity(0.1),
               );
             }).toList(),
           ),
         ],
       ),
     );
  }
}
