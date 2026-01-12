import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postRepo = PostRepository();
  final _orgRepo = OrganizationRepository();
  
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isSuperAdmin = false;
  Organization? _userOrg;
  String? _orgStatus; // null = ok/no-org, 'pending', 'rejected'

  bool _isOrgAdmin = false; // Owner or Admin of their org

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      // 1. Check Role (Super Admin)
      final isSuperAdmin = await UserRoles.isSuperAdmin();
      
      // 2. Check Org Status & Role
      final org = await _orgRepo.getUserOrganization();
      bool isOrgAdmin = false;
      String? orgStatus;
      
      print("_checkAccess: UserOrg: $org");

      if (org != null) {
          orgStatus = org.status;
          print("_checkAccess: OrgStatus: $orgStatus");
          
          if (org.status == 'approved') {
               // Robust Check: Owner OR Admin/Manager Role
               final currentUserId = Supabase.instance.client.auth.currentUser?.id;
               final isOwner = currentUserId != null && org.ownerId == currentUserId;
               
               if (isOwner) {
                 print("_checkAccess: User is OWNER. Granting access.");
                 isOrgAdmin = true;
               } else {
                 isOrgAdmin = await _orgRepo.canAccessDashboard(); 
                 print("_checkAccess: isOrgAdmin (DB check): $isOrgAdmin");
               }
          }
      } else {
        print("_checkAccess: Organization is NULL for this user.");
      }

      if (mounted) {
        setState(() {
          _isSuperAdmin = isSuperAdmin;
          _userOrg = org;
          _orgStatus = (orgStatus == 'pending' || orgStatus == 'rejected') ? orgStatus : null; // Only block if pending/rejected
          _isOrgAdmin = isOrgAdmin;
          _isLoading = false;
        });
        
        if (_orgStatus == null) {
            _fetchFeed();
        }
      }
    } catch (e) {
      print("_checkAccess: Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _fetchFeed();
      }
    }
  }

  Future<void> _fetchFeed() async {
    try {
      final posts = await _postRepo.getFeed();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching feed: $e')),
        );
      }
    }
  }

  Future<void> _showCreatePostDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "What's on your mind?",
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await _postRepo.createPost(content: controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    _fetchFeed(); // Refresh feed
                  }
                } catch (e) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to post: $e')),
                    );
                   }
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orgStatus != null) {
      return OrganizationStatusScreen(
        status: _orgStatus!,
        onRefresh: () {
            setState(() {
                _isLoading = true;
                _orgStatus = null;
            });
            _checkAccess();
        },
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Feed', icon: Icon(Icons.dynamic_feed)),
              Tab(text: 'Churches', icon: Icon(Icons.church)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            if (_isSuperAdmin)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                tooltip: 'Super Admin',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SuperAdminDashboard()),
                  );
                },
              ),
  
            if (_userOrg != null && _isOrgAdmin) // Owner, Admin, or Manager
               IconButton(
                icon: const Icon(Icons.business_center),
                tooltip: 'Organization Dashboard',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrganizationAdminDashboard(organization: _userOrg!)),
                  );
                },
              ),
  
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService().signOut(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Feed
                  RefreshIndicator(
                    onRefresh: _fetchFeed,
                    child: _posts.isEmpty 
                      ? const Center(child: Text('No posts yet.'))
                      : ListView.separated(
                        itemCount: _posts.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          final username = post.profile?.username ?? 'Unknown User';
                          final date = DateFormat.yMMMd().add_Hm().format(post.createdAt);
        
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(username[0].toUpperCase()),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            date,
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(post.content),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.comment_outlined),
                                        onPressed: () {
                                          // TODO: Navigate to Post Details for comments
                                        },
                                      ),
                                      const Text('Comments'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ),
                  
                  // Tab 2: Churches (Organizations)
                  const OrganizationListScreen(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreatePostDialog,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}

