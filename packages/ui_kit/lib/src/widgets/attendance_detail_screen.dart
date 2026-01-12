import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:core/core.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final String branchId;
  final DateTime date;
  final String serviceType;
  final List<Map<String, dynamic>> allMembers; // Passed to resolve names

  const AttendanceDetailScreen({
    super.key,
    required this.branchId,
    required this.date,
    required this.serviceType,
    required this.allMembers,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final _attendanceRepo = AttendanceRepository();
  bool _isLoading = true;
  List<Attendance> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final records = await _attendanceRepo.getAttendanceForService(
        widget.branchId,
        widget.date,
        widget.serviceType,
      );
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Error handling?
      }
    }
  }

  String _getMemberName(String userId) {
    final member = widget.allMembers.firstWhere(
      (m) => m['user_id'] == userId,
      orElse: () => {},
    );
    if (member.isEmpty) return 'Unknown Member';
    
    final profile = member['profile'] ?? {};
    return profile['full_name'] ?? profile['username'] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    // Filter out 'Absent' just in case, though DB shouldn't return them if deleted
    final presentRecords = _records.where((r) => r.category != 'Absent').toList();
    final total = presentRecords.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.serviceType),
            Text(
              "${widget.date.toLocal()}".split(' ')[0], 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.blueGrey.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text('Total Attendees', style: TextStyle(fontSize: 14)),
                          Text('$total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const Divider(),
              
              Expanded(
                child: presentRecords.isEmpty 
                  ? const Center(child: Text('No attendance records found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: presentRecords.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final record = presentRecords[index];
                        final name = _getMemberName(record.userId);
                        final isNew = record.category == 'New Attender';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isNew ? Colors.green : Colors.blue,
                            child: Icon(isNew ? Icons.person_add : Icons.check, color: Colors.white, size: 16),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Text(
                            record.category, 
                            style: TextStyle(
                              color: isNew ? Colors.green : Colors.grey, 
                              fontWeight: isNew ? FontWeight.bold : null
                            )
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}
