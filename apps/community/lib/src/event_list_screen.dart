import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'event_detail_screen.dart';
import 'package:intl/intl.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _activityRepo = ActivityRepository();
  List<Activity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      // Fetch events starting from today for the next 3 months
      final activities = await _activityRepo.getActivities(
        startOfDay, 
        now.add(const Duration(days: 90))
      );
      
      if (mounted) {
        setState(() {
          _activities = activities.where((a) => 
            a.isRegistrationRequired && 
            a.endTime.toLocal().isAfter(DateTime.now())
          ).toList(); 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEvents,
         child: SingleChildScrollView(
           physics: const AlwaysScrollableScrollPhysics(),
           child: SizedBox(
             height: 400,
             child: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.event_available, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text("No upcoming events.", style: TextStyle(color: Colors.grey)),
                 ],
               ),
             ),
           ),
         ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final activity = _activities[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(activity: activity)));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activity.imageUrl != null)
                    Image.network(
                      activity.imageUrl!, 
                      height: 180, 
                      width: double.infinity, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.grey[800], child: const Icon(Icons.image_not_supported)),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(DateFormat.yMMMd().add_Hm().format(activity.startTime.toLocal())),
                          ],
                        ),
                        if (activity.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(activity.location!),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
