import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:intl/intl.dart';
import 'event_detail_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> _announcements = [];
  List<Activity> _ongoingActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final now = DateTime.now();
      
      // 1. Fetch Announcements
      final announcements = await AnnouncementRepository().getAnnouncements();

      // 2. Fetch Activities for today (and filter for ongoing)
      // We fetch a broad range to be safe, filtering in memory often easier for small datasets
      final startOfDay = DateTime(now.year, now.month, now.day);
      final activities = await ActivityRepository().getActivities(
          startOfDay, 
          now.add(const Duration(days: 7)) // Fetch next 7 days just in case
      );
      
      // Filter for ONGOING: StartTime <= Now <= EndTime
      final ongoing = activities.where((a) {
         final start = a.startTime.toLocal();
         final end = a.endTime.toLocal();
         return now.isAfter(start) && now.isBefore(end);
      }).toList();

      if (mounted) {
        setState(() {
          _announcements = announcements;
          _ongoingActivities = ongoing;
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

    if (_announcements.isEmpty && _ongoingActivities.isEmpty) {
       return RefreshIndicator(
         onRefresh: _fetchData,
         child: SingleChildScrollView(
           physics: const AlwaysScrollableScrollPhysics(),
           child: SizedBox(
             height: 500,
             child: const Center(child: Text("No announcements at this time.")),
           ),
         ),
       );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Ongoing Activities Section
          if (_ongoingActivities.isNotEmpty) ...[
             const Padding(
               padding: EdgeInsets.only(bottom: 8.0),
               child: Row(
                 children: [
                   Icon(Icons.live_tv, color: Colors.red, size: 20),
                   SizedBox(width: 8),
                   Text("HAPPENING NOW", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 1.2)),
                 ],
               ),
             ),
             ..._ongoingActivities.map((activity) => Card(
               color: Colors.red.withOpacity(0.05),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.withOpacity(0.3))),
               margin: const EdgeInsets.only(bottom: 16),
               child: InkWell(
                 onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(activity: activity)));
                 },
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     if (activity.imageUrl != null)
                       ClipRRect(
                         borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                         child: Image.network(
                           activity.imageUrl!,
                           height: 150,
                           width: double.infinity,
                           fit: BoxFit.cover,
                         ),
                       ),
                     Padding(
                       padding: const EdgeInsets.all(12),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text("Ends at ${DateFormat('h:mm a').format(activity.endTime.toLocal())}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            if (activity.location != null) 
                               Text("📍 ${activity.location}", style: const TextStyle(color: Colors.grey)),
                         ],
                       ),
                     )
                   ],
                 ),
               ),
             )),
             const Divider(height: 32),
          ],
          
          // 2. Announcements List
          if (_announcements.isNotEmpty) ...[
             const Text("Announcements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 12),
             ..._announcements.map((item) => Card(
               margin: const EdgeInsets.only(bottom: 12),
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         Text(
                           DateFormat('MMM d').format(item.createdAt.toLocal()),
                           style: const TextStyle(fontSize: 12, color: Colors.grey),
                         ),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Text(item.content, style: const TextStyle(fontSize: 14)),
                   ],
                 ),
               ),
             )),
          ]
        ],
      ),
    );
  }
}
