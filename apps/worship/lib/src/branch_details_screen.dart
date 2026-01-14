import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import 'package:core/core.dart'; // Import core for ServiceRepository
import 'service_details_screen.dart';


class BranchDetailsScreen extends StatefulWidget {
  final Branch branch;
  final Organization organization;

  const BranchDetailsScreen({
    super.key,
    required this.branch,
    required this.organization,
  });

  @override
  State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
}

class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
  final _serviceRepo = ServiceRepository();
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      // Fetch services for the next 30 days, or past ones too? 
      // User said "show all services", usually implies upcoming or recent. 
      // Let's fetch a wide range for now, e.g., from today onwards or recent past.
      // Let's go with from Today for upcoming.
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 1)); // Include today completely
      final end = now.add(const Duration(days: 90)); // Next 3 months

      final services = await _serviceRepo.getServices(
        start, 
        end, 
        branchId: widget.branch.id
      );

      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching services: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Avatar
             Center(
               child: widget.branch.avatarUrl != null
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(widget.branch.avatarUrl!),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        widget.branch.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 36, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
             ),
             const SizedBox(height: 16),
             
             // Branch Name & Acronym
             Text(
               widget.branch.name,
               textAlign: TextAlign.center,
               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
             ),
             if (widget.branch.acronym != null && widget.branch.acronym!.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(top: 4.0),
                 child: Text(
                   '(${widget.branch.acronym})', 
                   style: const TextStyle(fontSize: 16, color: Colors.grey),
                   textAlign: TextAlign.center,
                 ),
               ),
             
             const SizedBox(height: 32),
             const Text('Upcoming Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             const Divider(),
             const SizedBox(height: 8),

             // Services List
             if (_isLoading)
               const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
             else if (_services.isEmpty)
               const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No upcoming services found.')))
             else
               ListView.builder(
                 shrinkWrap: true,
                 physics: const NeverScrollableScrollPhysics(),
                 itemCount: _services.length,
                 itemBuilder: (context, index) {
                   final service = _services[index];
                   return Card(
                     margin: const EdgeInsets.only(bottom: 12),
                     child: ListTile(
                       leading: Container(
                         width: 50, // Fixed width to prevent overflow
                         padding: const EdgeInsets.symmetric(vertical: 4),
                         decoration: BoxDecoration(
                           color: Colors.deepPurple.shade50,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Text(
                               DateFormat('MMM').format(service.date).toUpperCase(), 
                               style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                             ),
                             Text(
                               DateFormat('dd').format(service.date), 
                               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple)
                             ),
                           ],
                         ),
                       ),
                       title: Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                       subtitle: Text(DateFormat('EEEE, h:mm a').format(service.date)),
                       trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => ServiceDetailsScreen(service: service),
                           ),
                         );
                       },
                     ),
                   );
                 },
               ),

          ],
        ),
      ),
    );
  }
}
