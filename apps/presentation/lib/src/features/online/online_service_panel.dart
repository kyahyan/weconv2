import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../auth/auth_provider.dart';
import '../auth/login_dialog.dart';
import 'online_providers.dart';

class OnlinePanel extends ConsumerWidget {
  const OnlinePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(onlineServicesProvider);
    final importService = ref.watch(onlineImportProvider);
    final authState = ref.watch(authProvider);

    // Safely determine state
    final user = authState.valueOrNull; // Safe access
    final isLoggedIn = user != null;
    final hasError = authState.hasError;
    final errorMsg = authState.error?.toString() ?? 'Unknown Error';

    return Container(
      color: const Color(0xFF2D2D2D), // Dark panel background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Online Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (isLoggedIn)
                  Row(
                    children: [
                      Text(user.fullName ?? 'User', style: const TextStyle(color: Colors.green, fontSize: 12)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => ref.read(authProvider.notifier).logout(),
                        child: const Icon(LucideIcons.logOut, size: 14, color: Colors.white54),
                      )
                    ],
                  )
                else
                  InkWell(
                    onTap: () => showDialog(context: context, builder: (_) => const LoginDialog()),
                    child: const Text('Login', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: hasError 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning, size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          errorMsg.replaceAll('Exception:', '').trim(), 
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                             // Reset state or just allow login retry
                             showDialog(context: context, builder: (_) => const LoginDialog());
                          },
                          child: const Text('Try Login Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : (!isLoggedIn 
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.lock, size: 48, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text('Login Required', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => showDialog(context: context, builder: (_) => const LoginDialog()),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  )
                : servicesAsync.when(
                  data: (services) {
                    if (services.isEmpty) {
                      return const Center(child: Text('No services found.', style: TextStyle(color: Colors.white54)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final item = services[index];
                        return Card(
                          color: const Color(0xFF383838),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item.title, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('${item.author} • ${_formatDate(item.date)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(LucideIcons.download, color: Colors.blue),
                              onPressed: () async {
                                  await importService.importService(item);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Imported ${item.title}')),
                                    );
                                  }
                              },
                              tooltip: 'Import to Workspace',
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                )
              ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
