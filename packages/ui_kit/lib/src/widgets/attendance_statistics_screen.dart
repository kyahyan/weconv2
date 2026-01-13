import 'package:flutter/material.dart';
import 'package:core/core.dart';

class AttendanceStatisticsScreen extends StatefulWidget {
  final String branchId;
  const AttendanceStatisticsScreen({super.key, required this.branchId});

  @override
  State<AttendanceStatisticsScreen> createState() => _AttendanceStatisticsScreenState();
}

class _AttendanceStatisticsScreenState extends State<AttendanceStatisticsScreen> {
  final _attendanceRepo = AttendanceRepository();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final stats = await _attendanceRepo.getStatistics(widget.branchId);
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    final total = _stats['total_attendance'] ?? 0;
    final byType = _stats['by_type'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Card
        Card(
          color: Colors.deepPurple.shade900,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('Total Records', style: TextStyle(color: Colors.white70)),
                Text('$total', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Time-based breakdown
        Row(
          children: [
            Expanded(child: _buildStatCard('This Week', _stats['weekly_attendance'] ?? 0, Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('This Month', _stats['monthly_attendance'] ?? 0, Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('This Year', _stats['yearly_attendance'] ?? 0, Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('By Service Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...byType.entries.map((e) => Card(
          child: ListTile(
            title: Text(e.key),
            trailing: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        )),
        const SizedBox(height: 24),
        
        // Members by Tag
        const Text('Records by Tag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
             final byTag = _stats['by_tag'] as Map<String, dynamic>? ?? {};
             if (byTag.isEmpty) return const Text('No tag data available.');
             
             return Wrap(
               spacing: 8,
               runSpacing: 8,
               children: byTag.entries.map((e) => Chip(
                 label: Text('${e.key}: ${e.value}'),
                 backgroundColor: Colors.deepPurple.shade50,
                 avatar: CircleAvatar(
                   backgroundColor: Colors.deepPurple, 
                   child: Text('${e.value}', style: const TextStyle(fontSize: 10, color: Colors.white))
                 ),
               )).toList(),
             );
          }
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
