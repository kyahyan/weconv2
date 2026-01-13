import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';
import 'music_stand_screen.dart';
import 'musician_dashboard.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _serviceRepo = ServiceRepository();
  List<Service> _services = [];
  bool _isLoading = true;
  bool _isMusician = false;
  final _orgRepo = OrganizationRepository();

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    // Determine date range: e.g., next 30 days and past 7 days
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final end = now.add(const Duration(days: 30));

    // Check roles
    _checkRole();

    try {
      final services = await _serviceRepo.getServices(start, end);
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching services: $e')),
        );
      }
    }
  }

  Future<void> _checkRole() async {
    // We need to check if ANY of the user's memberships have 'Musician' role
    final org = await _orgRepo.getUserOrganization();
    if (org != null) {
      final memberships = await _orgRepo.getUserBranchData(org.id);
      
      bool hasMusicianRole = false;
      for (var m in memberships) {
        final roles = List<String>.from(m['ministry_roles'] ?? []);
        if (roles.contains('Musician')) {
          hasMusicianRole = true;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _isMusician = hasMusicianRole;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worship Setlists'),
        actions: [
          if (_isMusician)
            IconButton(
              icon: const Icon(Icons.piano, color: Colors.deepPurple),
              tooltip: 'Musician Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MusicianDashboard()),
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
          : _services.isEmpty
              ? const Center(child: Text('No upcoming services.'))
              : ListView.builder(
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return ListTile(
                      title: Text(service.title),
                      subtitle: Text(DateFormat('EEEE, MMM d @ h:mm a').format(service.date)),
                      trailing: const Icon(Icons.music_note),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MusicStandScreen(service: service),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
