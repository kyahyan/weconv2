import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'qr_scanner_screen.dart';

class ActivityCheckInScreen extends StatefulWidget {
  final Activity activity;
  const ActivityCheckInScreen({super.key, required this.activity});

  @override
  State<ActivityCheckInScreen> createState() => _ActivityCheckInScreenState();
}

class _ActivityCheckInScreenState extends State<ActivityCheckInScreen> {
  final _activityRepo = ActivityRepository();
  List<ActivityRegistration> _registrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() => _isLoading = true);
    try {
      final regs = await _activityRepo.getRegistrations(widget.activity.id);
      if (mounted) {
        setState(() {
          _registrations = regs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCheckIn(ActivityRegistration reg) async {
    final newStatus = reg.status == 'checked_in' ? 'registered' : 'checked_in';
    try {
      await _activityRepo.updateRegistrationStatus(reg.id, newStatus);
      // Optimistic update or reload
      setState(() {
         final index = _registrations.indexWhere((r) => r.id == reg.id);
         if (index != -1) {
           _registrations[index] = reg.copyWith(status: newStatus);
         }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleScan(String code) async {
    // Code should be the registration ID
    // Find registration in local list first for speed
    try {
      final index = _registrations.indexWhere((r) => r.id == code);
      if (index != -1) {
        final reg = _registrations[index];
        if (reg.status == 'checked_in') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Already checked in: ID ${reg.id.substring(0,8)}...'), backgroundColor: Colors.orange));
        } else {
           await _toggleCheckIn(reg);
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in Successful!'), backgroundColor: Colors.green));
        }
      } else {
        // Not in list? Maybe reload or invalid ID.
        // Try fetching it? or just fail if we assume list is full.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration not found for this activity.'), backgroundColor: Colors.red));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scan Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkedInCount = _registrations.where((r) => r.status == 'checked_in').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "$checkedInCount / ${_registrations.length} Checked In",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Scanner Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => QRScannerScreen(onScan: _handleScan)));
                 },
                 icon: const Icon(Icons.qr_code_scanner),
                 label: const Text("Scan QR Code"),
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.all(16),
                   backgroundColor: Colors.purple,
                   foregroundColor: Colors.white
                 ),
               ),

            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _registrations.isEmpty
                    ? const Center(child: Text("No registrations found."))
                    : ListView.separated(
                        itemCount: _registrations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final reg = _registrations[index];
                          final isCheckedIn = reg.status == 'checked_in';
                          
                          // In a real app we would join Profile to get name, but for now we might just show ID or fetch it.
                          // Let's assume we can tolerate just user ID or a placeholder for now until we do the join properly.
                          // Actually, we should probably fetch profiles. But let's stick to the ID for the first pass.
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCheckedIn ? Colors.green : Colors.grey,
                              child: Icon(isCheckedIn ? Icons.check : Icons.person, color: Colors.white),
                            ),
                            title: Text("User ID: ${reg.userId.substring(0, 8)}..."),
                            subtitle: Text("Status: ${reg.status.toUpperCase()}"),
                            trailing: Checkbox(
                              value: isCheckedIn,
                              activeColor: Colors.green,
                              onChanged: (val) => _toggleCheckIn(reg),
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
