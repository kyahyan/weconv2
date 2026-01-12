import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:models/models.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ui_kit/ui_kit.dart';
import 'service_detail_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
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
                return ListTile(
                  title: Text(service.title),
                  subtitle: Text(DateFormat('h:mm a').format(service.date)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailScreen(service: service),
                      ),
                    );
                  },
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
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Service'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Service Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final date = _selectedDay ?? DateTime.now();
                // We'll set the time to 10:00 AM by default for now
                final serviceDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  10,
                  0,
                );
                
                try {
                  await _serviceRepo.createService(
                    date: serviceDate,
                    title: titleController.text,
                  );
                  Navigator.pop(context);
                  _fetchServices();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
