import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'services/notification_service.dart'; // Added
import 'profile/worship_profile_dashboard.dart'; // Added
import 'musician_dashboard.dart';
import 'branch_details_screen.dart';
import 'service_details_screen.dart';
import 'create_line_up_screen.dart'; // Added

import 'create_song_screen.dart';

import 'song_detail_screen.dart';

class WorshipHomeScreen extends StatefulWidget {
  const WorshipHomeScreen({super.key});

  @override
  State<WorshipHomeScreen> createState() => _WorshipHomeScreenState();
}

class _WorshipHomeScreenState extends State<WorshipHomeScreen> {
  // ... existing state ...
  int _currentIndex = 1; 
  final _orgRepo = OrganizationRepository();
  final _authService = AuthService();
  final _profileRepo = ProfileRepository();
  final _songRepo = SongRepository();
  final _serviceRepo = ServiceRepository(); // Added ServiceRepo
  
  List<Organization> _userOrgs = [];
  Organization? _selectedOrg;
  UserProfile? _profile;
  List<Song> _songs = [];
  bool _isLoadingOrg = true;
  bool _isLoadingSongs = true;

  @override
  void initState() {
    super.initState();
    _fetchOrgs();
    _fetchProfile();
    _fetchSongs();
    NotificationService().saveTokenToDatabase();
  }
  
  // ... other methods ...

  Future<void> _handleNotificationTap(BuildContext context, UserNotification notification) async {
    print("DEBUG: Tapped notification ${notification.id}, type: ${notification.type}, relatedId: ${notification.relatedId}");
    
    if (notification.type == 'assignment' && notification.relatedId != null) {
      // Check if this is a Worship Leader assignment
      // We check the body for "Worship Leader" as a simple heuristic since backend puts role in body.
      final isWorshipLeader = notification.body.toLowerCase().contains('worship leader');

      if (isWorshipLeader) {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateLineUpScreen(serviceId: notification.relatedId!)
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(serviceId: notification.relatedId)
          ),
        );
      }
    } else {
      print("DEBUG: Notification type not handled or relatedId null");
    }
  }

  Future<void> _fetchSongs() async {
    try {
      final songs = await _songRepo.searchSongs('');
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSongs = false);
    }
  }

  Future<void> _fetchProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _profileRepo.getProfile(user.id);
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    }
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSongScreen()),
    );
    _fetchSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worship'),
        centerTitle: false,
        actions: [
          // Contributor / Create Song Action
           if (_profile?.songContributorStatus == 'approved')
             IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create Song',
              onPressed: _showCreateSongDialog,
            )
           else if (_profile != null && _profile!.songContributorStatus != 'approved')
              IconButton(
                icon: const Icon(Icons.lock_outline, color: Colors.grey),
                tooltip: 'Restricted Access',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Song creation is restricted to approved contributors.')),
                  );
                },
              ),
          
          // Notifications
          NotificationBell(onNotificationTap: _handleNotificationTap),

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
                MaterialPageRoute(builder: (_) => const WorshipProfileDashboard()),
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
    if (_isLoadingSongs) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No songs found.'),
            if (_profile?.songContributorStatus == 'approved')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _showCreateSongDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Song'),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(song.key.isNotEmpty ? song.key.substring(0, 1) : '?'),
            ),
            title: Text(song.title),
            subtitle: Text(song.artist),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
               );
            },
          ),
        );
      },
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
                  // Organization Details removed as per request

                  
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
                        spacing: 20.0,
                        runSpacing: 16.0,
                        children: branches.map((branch) => InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () => _showBranchDetails(branch, displayOrg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (branch.avatarUrl != null)
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(branch.avatarUrl!),
                                )
                              else
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: Text(
                                    branch.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 20, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                branch.name,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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

  Future<List<Branch>> _fetchMyBranches(String orgId) async {
    try {
      final joinedIds = await _orgRepo.getJoinedBranchIds(orgId);
      if (joinedIds.isEmpty) return [];
      
      final allBranches = await _orgRepo.getBranches(orgId);
      return allBranches.where((b) => joinedIds.contains(b.id)).toList();
    } catch (e) {
      debugPrint('Error fetching my branches: $e');
      return [];
    }
  }

  void _showBranchDetails(Branch branch, Organization org) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchDetailsScreen(
          branch: branch,
          organization: org,
        ),
      ),
    );
  }
}
