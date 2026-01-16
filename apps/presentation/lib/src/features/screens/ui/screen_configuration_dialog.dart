
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../repositories/screen_repository.dart';
import '../repositories/hardware_display_repository.dart';
import '../services/projection_window_manager.dart';
import '../services/projection_window_manager.dart';
import '../models/screen_model.dart';
import '../models/projection_style.dart';
import 'package:screen_retriever/screen_retriever.dart';

class ScreenConfigurationDialog extends ConsumerStatefulWidget {
  const ScreenConfigurationDialog({super.key});

  @override
  ConsumerState<ScreenConfigurationDialog> createState() => _ScreenConfigurationDialogState();
}

class _ScreenConfigurationDialogState extends ConsumerState<ScreenConfigurationDialog> {
  String? _selectedScreenId;

  @override
  Widget build(BuildContext context) {
    final screens = ref.watch(screenRepositoryProvider);

    // Auto-select first screen if nothing selected
    if (_selectedScreenId == null && screens.isNotEmpty) {
      _selectedScreenId = screens.first.id;
    }

    final selectedScreen = screens.where((s) => s.id == _selectedScreenId).firstOrNull;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 1000,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Screen Configuration', style: TextStyle(color: Colors.white, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  Container(
                    width: 250,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white24)),
                    ),
                    child: Column(
                      children: [
                        _buildSidebarSection(
                          title: 'Audience',
                          screens: screens.where((s) => s.type == ScreenType.audience).toList(),
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _buildSidebarSection(
                          title: 'Stage',
                          screens: screens.where((s) => s.type == ScreenType.stage).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Details
                  Expanded(
                    child: selectedScreen != null 
                        ? ScreenDetailView(screen: selectedScreen)
                        : const Center(child: Text('Select a screen to configure', style: TextStyle(color: Colors.grey))),
                  ),
                ],
              ),
            ),
            
            // Footer
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarSection({required String title, required List<ScreenModel> screens}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                   const Icon(Icons.circle_outlined, size: 14, color: Colors.white),
                   const SizedBox(width: 8),
                   Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 ],
               ),
               IconButton(
                 icon: const Icon(Icons.add, size: 16, color: Colors.white),
                 onPressed: () {
                   ref.read(screenRepositoryProvider.notifier).addScreen(
                     title == 'Audience' ? ScreenType.audience : ScreenType.stage
                   );
                 },
               )
            ],
          ),
        ),
        
                  ...screens.map((screen) {
          final isSelected = _selectedScreenId == screen.id;
          return InkWell(
            onTap: () => setState(() => _selectedScreenId = screen.id),
            child: Container(
              color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(screen.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        Text('${screen.width} x ${screen.height}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white54),
                    onPressed: () {
                       // Confirm delete
                       showDialog(
                         context: context, 
                         builder: (ctx) => AlertDialog(
                           backgroundColor: const Color(0xFF2D2D2D),
                           title: const Text('Remove Display?', style: TextStyle(color: Colors.white)),
                           content: Text('Are you sure you want to remove "${screen.name}"?', style: const TextStyle(color: Colors.white70)),
                           actions: [
                             TextButton(
                               child: const Text('Cancel'),
                               onPressed: () => Navigator.of(ctx).pop(),
                             ),
                             TextButton(
                               child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                               onPressed: () {
                                 ref.read(screenRepositoryProvider.notifier).removeScreen(screen.id);
                                 Navigator.of(ctx).pop();
                                 if (_selectedScreenId == screen.id) {
                                   setState(() => _selectedScreenId = null);
                                 }
                               },
                             ),
                           ],
                         )
                       );
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class ScreenDetailView extends ConsumerWidget {
  final ScreenModel screen;

  const ScreenDetailView({super.key, required this.screen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Top Preview Area
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.black, // Simulating preview area
            alignment: Alignment.center,
            child: Container(
              width: 300,
              height: 300 * (1080/1920),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
              ),
              alignment: Alignment.center,
              child: Text(screen.name, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
        
        // Bottom Configuration Panel
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2D2D2D),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(screen.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Tabs (Hardware, Color, etc.)
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabAlignment: TabAlignment.start,
                          isScrollable: true,
                          dividerColor: Colors.transparent,
                          indicatorColor: Colors.blueAccent,
                          labelColor: Colors.blueAccent,
                          unselectedLabelColor: Colors.white60,
                          tabs: [
                            Tab(text: 'Hardware'),
                            Tab(text: 'Text Style'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Hardware Tab
                              SingleChildScrollView(child: _buildHardwareSettings(ref, screen)),
                              SingleChildScrollView(child: _buildTextStyleSettings(ref, screen)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareSettings(WidgetRef ref, ScreenModel screen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text('Enabled (Auto-Open)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             Switch(
               value: screen.isEnabled,
               onChanged: (val) {
                  ref.read(screenRepositoryProvider.notifier).updateScreen(
                    screen.copyWith(isEnabled: val)
                  );
                  // If we enabled it, maybe we want to open it right away?
                  // Relying on manual "Test" or app restart for now as per plan logic.
                  // But user might expect it to open.
               },
               activeColor: Colors.green,
             ),
          ],
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text('Output Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
             Consumer(builder: (context, ref, child) {
               // We need a way to check status, currently checking by ID via a hypothetical provider method 
               // or just simple toggle for now.
               // Since ProjectionWindowManager isn't exposing a stream of open windows yet in the interface I built,
               // I'll just add a "Open/Test" button. Ideally this should be reactive.
               return OutlinedButton(
                 onPressed: () {
                   ref.read(projectionWindowManagerProvider.notifier).openDisplay(screen);
                 },
                 child: const Text('Open / Test Output'),
               );
             }),
          ],
        ),
        
        const SizedBox(height: 16),
        
        const Text('Name', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
         ShadInput(
           initialValue: screen.name,
           onChanged: (value) {
             // In a real app we'd debounce this or have a save button, 
             // but for now let's just update the state
             ref.read(screenRepositoryProvider.notifier).updateScreen(
               screen.copyWith(name: value)
             );
           },
         ),
      ],
    );
  }

  Widget _buildTextStyleSettings(WidgetRef ref, ScreenModel screen) {
    // Default style if none exists
    final style = screen.style ?? const ProjectionStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: style.fontFamily,
                dropdownColor: const Color(0xFF424242),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                   filled: true,
                   fillColor: Colors.black12,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ['Roboto', 'Arial', 'Times New Roman', 'Courier New', 'Verdana', 'Georgia', 'Segoe UI']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (val) {
                   if (val != null) {
                      _updateStyle(ref, screen, style.copyWith(fontFamily: val));
                   }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Bold Toggle
            IconButton(
              icon: Icon(Icons.format_bold, color: style.isBold ? Colors.blueAccent : Colors.white24),
              onPressed: () => _updateStyle(ref, screen, style.copyWith(isBold: !style.isBold)),
            ),
            // Italic Toggle
            IconButton(
              icon: Icon(Icons.format_italic, color: style.isItalic ? Colors.blueAccent : Colors.white24),
              onPressed: () => _updateStyle(ref, screen, style.copyWith(isItalic: !style.isItalic)),
            ),
          ],
        ),

        const SizedBox(height: 16),
        
        Row(
          children: [
            const Text('Size', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            Text('${style.fontSize.round()}px', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
        Slider(
          value: style.fontSize,
          min: 20,
          max: 300,
          activeColor: Colors.blueAccent,
          inactiveColor: Colors.white10,
          onChanged: (val) => _updateStyle(ref, screen, style.copyWith(fontSize: val)),
        ),

        const SizedBox(height: 16),

        const Text('Alignment', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
                _buildAlignToggle(ref, screen, style, TextAlign.left, Icons.format_align_left),
                _buildAlignToggle(ref, screen, style, TextAlign.center, Icons.format_align_center),
                _buildAlignToggle(ref, screen, style, TextAlign.right, Icons.format_align_right),
                _buildAlignToggle(ref, screen, style, TextAlign.justify, Icons.format_align_justify),
             ],
          ),
        ),

        const SizedBox(height: 16),
        
        const Text('Scaling', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ScaleMode>(
          value: style.scaleMode,
          dropdownColor: const Color(0xFF424242),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
             DropdownMenuItem(value: ScaleMode.fixed, child: Text("Fixed Size")),
             DropdownMenuItem(value: ScaleMode.textDown, child: Text("Scale Down Only")),
             DropdownMenuItem(value: ScaleMode.fitToScreen, child: Text("Fit to Screen")),
          ],
          onChanged: (val) {
             if (val != null) {
                _updateStyle(ref, screen, style.copyWith(scaleMode: val));
             }
          },
        ),
      ],
    );
  }

  Widget _buildAlignToggle(WidgetRef ref, ScreenModel screen, ProjectionStyle style, TextAlign align, IconData icon) {
     final isSelected = style.align == align;
     return IconButton(
       icon: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70),
       onPressed: () => _updateStyle(ref, screen, style.copyWith(align: align)),
     );
  }

  void _updateStyle(WidgetRef ref, ScreenModel screen, ProjectionStyle newStyle) {
     ref.read(screenRepositoryProvider.notifier).updateScreen(
       screen.copyWith(style: newStyle)
     );
  }
}
