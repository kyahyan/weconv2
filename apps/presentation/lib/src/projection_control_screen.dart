import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/screens/models/screen_model.dart';
import 'features/screens/repositories/screen_repository.dart';
import 'features/screens/services/projection_window_manager.dart';
import 'features/workspace/workspace_explorer.dart';
import 'features/media/media_bin.dart';
import 'features/editor/main_editor_area.dart';
import 'features/editor/presentation_slide_list.dart';
import 'features/editor/presentation_editor_controls.dart';
import 'features/online/online_service_panel.dart';
import 'features/screens/ui/screen_configuration_dialog.dart';
import 'features/bible/bible_panel.dart';

class ProjectionControlScreen extends ConsumerStatefulWidget {
  const ProjectionControlScreen({super.key});

  @override
  ConsumerState<ProjectionControlScreen> createState() => _ProjectionControlScreenState();
}

class _ProjectionControlScreenState extends ConsumerState<ProjectionControlScreen> {
  int _selectedTabIndex = 0; 
  double _bottomPanelHeight = 400.0;
  double _workspaceWidth = 300.0;
  double _notesHeight = 200.0;
  int _selectedSlideIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Menu Bar
          Container(
            height: 30,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _buildMenuText('File'),
                const SizedBox(width: 16),
                _buildMenuText('Edit'),
                const SizedBox(width: 16),
                _buildMenuText('Start'),
                const SizedBox(width: 16),
                PopupMenuButton<String>(
                  child: Row(
                    children: [
                      const Text('Screens', style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal)),
                      const Icon(Icons.arrow_drop_down, color: Colors.black, size: 16),
                    ],
                  ),
                  onSelected: (value) {
                    if (value == 'configure') {
                      showDialog(
                        context: context,
                        builder: (context) => const ScreenConfigurationDialog(),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'configure',
                      child: Text('Configure Screens...'),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                _buildMenuText('View'),
                const SizedBox(width: 16),
                _buildMenuText('Window'),
                const Spacer(),
                // const Text('Live', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E), // Dark background
              padding: const EdgeInsets.all(4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content Area (Left + Middle merged sort of)
                  Expanded(
                    flex: 8, 
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalHeight = constraints.maxHeight;
                        // Clamp value
                        _bottomPanelHeight = _bottomPanelHeight.clamp(100.0, totalHeight - 100.0);
                        
                        // Calculated top height
                        final topHeight = totalHeight - _bottomPanelHeight - 8; // 8 for divider/spacing

                        return Column(
                          children: [
                            // Top Row: Workspace & Online
                            SizedBox(
                              height: topHeight > 0 ? topHeight : 0,
                              /* Top Row: Workspace & Online */
                              child: _selectedTabIndex == 1 // Editor Mode
                                ? Row(
                                    children: [
                                      // Workspace/Library
                                      SizedBox(
                                        width: _workspaceWidth, 
                                        child: WorkspaceExplorer(),
                                      ),
                                      
                                      // Resize Handle
                                      MouseRegion(
                                        cursor: SystemMouseCursors.resizeLeftRight,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onHorizontalDragUpdate: (details) {
                                            setState(() {
                                              _workspaceWidth += details.delta.dx;
                                              _workspaceWidth = _workspaceWidth.clamp(100.0, constraints.maxWidth - 100.0);
                                            });
                                          },
                                          child: Container(
                                            width: 8,
                                            color: const Color(0xFF1E1E1E), 
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: 2,
                                              height: 40,
                                              color: Colors.grey.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Editor Content
                                      Expanded(
                                        child: PresentationSlideList(
                                          onSlideSelected: (index) {
                                            setState(() {
                                              _selectedSlideIndex = index;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      // Workspace/Library
                                      SizedBox(
                                        width: _workspaceWidth, 
                                        child: WorkspaceExplorer(),
                                      ),
                                      
                                      // Resize Handle
                                      MouseRegion(
                                        cursor: SystemMouseCursors.resizeLeftRight,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onHorizontalDragUpdate: (details) {
                                            setState(() {
                                              _workspaceWidth += details.delta.dx;
                                              _workspaceWidth = _workspaceWidth.clamp(100.0, constraints.maxWidth - 100.0);
                                            });
                                          },
                                          child: Container(
                                            width: 8,
                                            color: const Color(0xFF1E1E1E), 
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: 2,
                                              height: 40,
                                              color: Colors.grey.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Online/Service
                                      Expanded(
                                        child: Container(color: const Color(0xFF2D2D2D)), // Empty Placeholder
                                      ),
                                    ],
                                  ),
                            ),
                            
                            // Resizable Divider
                            MouseRegion(
                              cursor: SystemMouseCursors.resizeUpDown,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onVerticalDragUpdate: (details) {
                                  setState(() {
                                    _bottomPanelHeight -= details.delta.dy;
                                  });
                                },
                                child: Container(
                                  height: 8,
                                  color: const Color(0xFF1E1E1E), 
                                  alignment: Alignment.center,
                                  child: Container(
                                    height: 2,
                                    width: 40,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),

                            // Bottom Unified Panel (Slides + Editor + Bible + Media)
                            SizedBox(
                              height: _bottomPanelHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF424242),
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    // Header (Tabs)
                                    Row(
                                      children: [
                                        _buildTabItem('Main', 0),
                                        const SizedBox(width: 16),
                                        _buildTabItem('Editor', 1),
                                        // Removed bible tab here
                                        const SizedBox(width: 16),
                                        _buildTabItem('Media', 3), // Keep index but it might be confusing if we don't reorder. Let's keep logic simple.
                                        const SizedBox(width: 16),
                                        _buildTabItem('Online', 4),
                                        const Spacer(),
                                        // Toggles
                                        _buildTypeToggle(ref, 'Audience', ScreenType.audience),
                                        const SizedBox(width: 16),
                                        _buildTypeToggle(ref, 'Stage', ScreenType.stage),
                                        const SizedBox(width: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: _buildBottomPanelContent(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 4),
                  
                  // Right Sidebar
                  Expanded(
                    flex: 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                         final totalHeight = constraints.maxHeight;
                         // Clamp notes height to safe limits
                         _notesHeight = _notesHeight.clamp(50.0, totalHeight - 100.0);
                         
                         return Column(
                           children: [
                             // Bible Panel (Top Right)
                             Expanded(
                               child: const BiblePanel(),
                             ),
                             
                             // Resizable Divider for Notes
                             MouseRegion(
                               cursor: SystemMouseCursors.resizeUpDown,
                               child: GestureDetector(
                                 behavior: HitTestBehavior.translucent,
                                 onVerticalDragUpdate: (details) {
                                   setState(() {
                                     // Dragging down decreases notes height (because it's at bottom)
                                     // Wait, dragging DOWN increases Top, decreases Bottom.
                                     // So dy > 0 means move down -> notes smaller.
                                     _notesHeight -= details.delta.dy;
                                   });
                                 },
                                 child: Container(
                                   height: 8,
                                   color: const Color(0xFF1E1E1E), 
                                   alignment: Alignment.center,
                                   child: Container(
                                     height: 2,
                                     width: 40,
                                     color: Colors.grey.withOpacity(0.3),
                                   ),
                                 ),
                               ),
                             ),

                             // Notes (Bottom Right)
                             SizedBox(
                               height: _notesHeight,
                               child: _buildPanel(
                                 title: 'Notes', 
                                 child: const Center(child: Text('Notes', style: TextStyle(color: Colors.grey, fontSize: 20)))
                               ),
                             ),
                           ],
                         );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
    Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: isSelected 
          ? BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)) 
          : null,
        child: Text(
          title, 
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
      ),
    );
  }

  Widget _buildBottomPanelContent() {
    switch (_selectedTabIndex) {
      case 0: // Main (was Order of Service)
        return const MainEditorArea();
      case 1: // Editor
        return PresentationEditorControls(selectedSlideIndex: _selectedSlideIndex);
      case 2: // Bible
        // Bible is now moved to the right panel, so this index (if we kept it 2) would be Media. 
        // But in the tabs above we removed index 2 (Bible).
        // Let's re-align the indices to match UI: Main=0, Editor=1, Media=3, Online=4. 
        // Wait, the indices in the tabs were:
        // _buildTabItem('Main', 0),
        // _buildTabItem('Editor', 1),
        // _buildTabItem('Media', 3), 
        // _buildTabItem('Online', 4),
        // So we strictly follow those.
        // What about index 2? It's gone.
        return MediaBin(); // Fallback or Error? 
      case 3: // Media
        return MediaBin();
      case 4: // Online
        return OnlinePanel();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMenuText(String text) {
    return Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal));
  }
  
  Widget _buildPanel({required String title, String? trailing, Widget? child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF424242), // Dark grey panel
        border: Border.all(color: Colors.white24, width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               if (title.isNotEmpty) Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
               if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.white, fontSize: 13)),
             ],
          ),
          if (title.isNotEmpty) const SizedBox(height: 8),
          if (child != null) Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(WidgetRef ref, String label, ScreenType type) {
     final activeWindows = ref.watch(projectionWindowManagerProvider);
     final screens = ref.watch(screenRepositoryProvider);
     
     // Find relevant screen for this type
     final screen = screens.where((s) => s.type == type).firstOrNull;
     
     final isConnected = screen != null;
     final isOpen = isConnected && activeWindows.containsKey(screen!.id);
     
     return InkWell(
        onTap: () {
           if (!isConnected) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No $label screen configured.')));
              return;
           }
           
           if (isOpen) {
              ref.read(projectionWindowManagerProvider.notifier).closeDisplay(screen!.id);
           } else {
              ref.read(projectionWindowManagerProvider.notifier).openDisplay(screen!);
           }
        },
        child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: Colors.transparent,
                   border: Border.all(color: Colors.redAccent, width: 2),
                ),
                child: isOpen ? Center(
                   child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                         shape: BoxShape.circle,
                         color: Colors.redAccent,
                      ),
                   ),
                ) : null,
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
           ],
        ),
     );
  }
}

