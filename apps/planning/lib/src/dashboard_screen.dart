import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:models/models.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ui_kit/ui_kit.dart';
import 'service_detail_screen.dart';
import 'activity_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _serviceRepo = ServiceRepository();
  List<Service> _services = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    // Fetch for the whole month (simplification)
    final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    try {
      final services = await _serviceRepo.getServices(start, end);
      setState(() {
        _services = services;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching services: $e')),
      );
    }
  }

  List<Service> _getServicesForDay(DateTime day) {
    return _services.where((s) => isSameDay(s.date, day)).toList();
  }

  @override

  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planning Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService().signOut(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: 'Services'),
              Tab(icon: Icon(Icons.campaign), text: 'Announcements'),
              Tab(icon: Icon(Icons.event_available), text: 'Activities'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildServicesTab(),
            _buildAnnouncementsTab(),
            _buildActivitiesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
           final result = await Navigator.push(
             context,
             MaterialPageRoute(builder: (_) => const ActivityDetailScreen()),
           );
           if (result == true) {
             setState(() {}); 
           }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Activity>>(
        future: ActivityRepository().getActivities(
          DateTime(_focusedDay.year, _focusedDay.month, 1), 
          DateTime(_focusedDay.year, _focusedDay.month + 1, 0)
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          final activities = snapshot.data ?? [];
          
          if (activities.isEmpty) {
            return const Center(child: Text("No activities for this month."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ActivityDetailScreen(activity: activity)),
                    );
                    setState((){});
                  },
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activity.imageUrl != null)
                            Image.network(
                              activity.imageUrl!, 
                              height: 150, 
                              width: double.infinity, 
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => Container(height: 150, color: Colors.grey[800], child: const Icon(Icons.broken_image)),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Text(activity.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                     if (activity.isRegistrationRequired)
                                        const Chip(label: Text("Registration", style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                                   ],
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   '${DateFormat('MMM d, h:mm a').format(activity.startTime.toLocal())} • ${activity.location ?? 'No Location'}',
                                   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                 ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Activity?'),
                                  content: Text('Are you sure you want to delete "${activity.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await ActivityRepository().deleteActivity(activity.id);
                                  setState(() {}); // Refresh
                                  if (context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Activity deleted")));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildServicesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateServiceDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<Service>(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            eventLoader: _getServicesForDay,
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchServices();
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _getServicesForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final service = _getServicesForDay(_selectedDay!)[index];
                return Dismissible(
                  key: ValueKey(service.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Service?'),
                        content: Text('Are you sure you want to delete "${service.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    try {
                      await _serviceRepo.deleteService(service.id);
                      setState(() {
                        _services.remove(service);
                      });
                      if (context.mounted) {
                        ShadToaster.of(context).show(
                          const ShadToast(
                            title: Text('Deleted'),
                            description: Text('Service deleted successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                         ShadToaster.of(context).show(
                           ShadToast.destructive(
                             title: const Text('Error'),
                             description: Text('Error deleting service: $e'),
                           ),
                         );
                      }
                      // Refresh list if failed
                       _fetchServices();
                    }
                  },
                  child: ListTile(
                    title: Text(service.title),
                    subtitle: Text(DateFormat('h:mm a').format(service.date.toLocal()) + 
                       (service.endTime != null ? ' - ${DateFormat('h:mm a').format(service.endTime!.toLocal())}' : '')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailScreen(service: service),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateServiceDialog() async {
    final titleController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);

    // Get services for the selected day for local validation
    final date = _selectedDay ?? DateTime.now();
    final existingServices = _getServicesForDay(date);

    bool checkConflict(TimeOfDay start, TimeOfDay end) {
      final s = DateTime(date.year, date.month, date.day, start.hour, start.minute);
      final e = DateTime(date.year, date.month, date.day, end.hour, end.minute);
      
      for (final service in existingServices) {
         // Convert service times to Local for comparison (since selection is local)
         final sDate = service.date.toLocal();
         final sEnd = service.endTime?.toLocal() ?? sDate.add(const Duration(hours: 2));

         if (sDate.isBefore(e) && sEnd.isAfter(s)) {
           return true; 
         }
      }
      return false;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final hasConflict = checkConflict(startTime, endTime);

          return AlertDialog(
            title: const Text('New Service'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Service Title'),
                ),
                const SizedBox(height: 16),
                if (existingServices.isNotEmpty) ...[
                   const Text("Occupied Times:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                   const SizedBox(height: 4),
                   Wrap(
                     spacing: 4,
                     children: existingServices.map((s) {
                       final st = s.date.toLocal();
                       final et = s.endTime?.toLocal() ?? st.add(const Duration(hours: 2));
                       return Chip(
                         label: Text(
                           '${DateFormat('h:mm a').format(st)} - ${DateFormat('h:mm a').format(et)}',
                           style: const TextStyle(fontSize: 10),
                         ),
                         backgroundColor: Colors.red.withOpacity(0.1),
                         side: BorderSide.none,
                         padding: EdgeInsets.zero,
                         visualDensity: VisualDensity.compact,
                       );
                     }).toList(),
                   ),
                   const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Start Time", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          TextButton(
                            onPressed: () async {
                              final t = await showTimePicker(context: context, initialTime: startTime);
                              if (t != null) setStateDialog(() => startTime = t);
                            },
                            child: Text(
                                startTime.format(context), 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hasConflict ? Colors.red : null)
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("End Time", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          TextButton(
                            onPressed: () async {
                              final t = await showTimePicker(context: context, initialTime: endTime);
                              if (t != null) setStateDialog(() => endTime = t);
                            },
                            child: Text(
                                endTime.format(context), 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hasConflict ? Colors.red : null)
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasConflict)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Times overlap with an existing service.",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: hasConflict ? null : () async {
                  if (titleController.text.isEmpty) return;

                  final date = _selectedDay ?? DateTime.now();
                  
                  // Construct full DateTime objects (UTC for saving)
                  final startDateTime = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
                  final endDateTime = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

                  // 1. Basic Validation
                  if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
                     ShadToaster.of(ctx).show(
                       const ShadToast.destructive(
                         title: Text('Invalid Time Range'),
                         description: Text('End time must be after start time'),
                       ),
                     );
                     return;
                  }

                  try {
                    // Local validation already passed (button enabled). 
                    // Proceed to save.
                    await _serviceRepo.createService(
                      date: startDateTime, // createService converts to UTC
                      title: titleController.text,
                      endTime: endDateTime, // createService converts to UTC
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      _fetchServices();
                    }
                  } catch (e) {
                    ShadToaster.of(ctx).show(
                      ShadToast.destructive(
                        title: const Text('Error'),
                        description: Text(e.toString()),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                   backgroundColor: hasConflict ? Colors.grey : null,
                ),
                child: const Text('Create'),
              ),
            ],
          );
        }
      ),
    );
  }


  Widget _buildAnnouncementsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
         onPressed: () {
           final titleController = TextEditingController();
           final contentController = TextEditingController();
           showDialog(
             context: context,
             builder: (ctx) => AlertDialog(
               title: const Text('New Announcement'),
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   TextField(
                     controller: titleController,
                     decoration: const InputDecoration(labelText: 'Title'),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: contentController,
                     decoration: const InputDecoration(labelText: 'Content'),
                     maxLines: 3,
                   ),
                 ],
               ),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                 ElevatedButton(
                   onPressed: () async {
                      if (titleController.text.isEmpty || contentController.text.isEmpty) return;
                      await AnnouncementRepository().createAnnouncement(
                        titleController.text,
                        contentController.text,
                      );
                      if (context.mounted) Navigator.pop(ctx);
                      setState(() {});
                   },
                   child: const Text('Post'),
                 ),
               ],
             ),
           );
         },
         child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Announcement>>(
        future: AnnouncementRepository().getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          final list = snapshot.data ?? [];
          
          if (list.isEmpty) return const Center(child: Text("No announcements yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                child: ListTile(
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.content),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await AnnouncementRepository().deleteAnnouncement(item.id);
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
