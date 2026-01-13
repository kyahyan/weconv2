import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';

class TicketScreen extends StatelessWidget {
  final Activity activity;
  final ActivityRegistration registration;
  final Map<String, dynamic>? profile; // To show user name

  const TicketScreen({
    super.key,
    required this.activity,
    required this.registration,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // We can encode just the registration ID, or a JSON with more info.
    // For now, just the registration ID is enough for the scanner to look it up.
    final qrData = registration.id;

    return Scaffold(
      appBar: AppBar(title: const Text("My Ticket")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                   Text(
                     activity.title,
                     style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 8),
                   Text(
                     DateFormat.yMMMMEEEEd().add_Hm().format(activity.startTime.toLocal()),
                     style: TextStyle(color: Colors.grey[600]),
                   ),
                   const SizedBox(height: 24),
                   QrImageView(
                     data: qrData,
                     version: QrVersions.auto,
                     size: 200.0,
                   ),
                   const SizedBox(height: 24),
                   Text(
                     "Scan this at the entrance",
                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
                   ),
                   const SizedBox(height: 8),
                   SelectableText(
                     "${registration.id}",
                     style: TextStyle(color: Colors.grey[400], fontSize: 10),
                   ),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: registration.status == 'checked_in' ? Colors.green[100] : Colors.blue[100],
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text(
                       registration.status == 'checked_in' ? 'CHECKED IN' : 'VALID TICKET',
                       style: TextStyle(
                         color: registration.status == 'checked_in' ? Colors.green[800] : Colors.blue[800],
                         fontWeight: FontWeight.bold,
                         fontSize: 12,
                       ),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (activity.location != null) ...[
               const Icon(Icons.location_on, color: Colors.red),
               const SizedBox(height: 8),
               Text(activity.location!, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
