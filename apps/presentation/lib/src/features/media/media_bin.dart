import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'media_manager_service.dart';
import 'package:path/path.dart' as p;

class MediaBin extends ConsumerWidget {
  const MediaBin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAssets = ref.watch(mediaManagerProvider);

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Header
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF2D2D2D),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Media', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                // Import Button
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                  tooltip: 'Import Media',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ref.read(mediaManagerProvider.notifier).importMedia();
                  },
                ),
              ],
            ),
          ),
          
          // Grid
          Expanded(
            child: mediaAssets.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return const Center(child: Text('No Media', style: TextStyle(color: Colors.grey, fontSize: 12)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final file = assets[index];
                    final ext = p.extension(file.path).toLowerCase();
                    final isImage = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'}.contains(ext);
                    
                    return GestureDetector(
                      onDoubleTap: () {
                        debugPrint('Presenting: ${file.path}');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ClipRect(
                          child: isImage
                            ? Image.file(
                                File(file.path),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(LucideIcons.imageOff, color: Colors.white38),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.video, color: Colors.white70),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.basename(file.path), 
                                    style: const TextStyle(color: Colors.white, fontSize: 8),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red, fontSize: 10))),
            ),
          ),
        ],
      ),
    );
  }
}
