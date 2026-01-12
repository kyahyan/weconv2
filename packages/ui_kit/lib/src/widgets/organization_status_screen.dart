import 'package:core/core.dart';
import 'package:flutter/material.dart';

class OrganizationStatusScreen extends StatelessWidget {
  final String status; // 'pending' or 'rejected'
  final VoidCallback onRefresh;

  const OrganizationStatusScreen({
    super.key,
    required this.status,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRejected ? Icons.error_outline : Icons.pending_actions,
                size: 80,
                color: isRejected ? Colors.red : Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                isRejected ? 'Application Rejected' : 'Verification in Progress',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isRejected 
                  ? 'Your organization application has been declined by the administrator.'
                  : 'Your organization is currently under review. access is restricted until approval.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => AuthService().signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
