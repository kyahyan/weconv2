import 'package:flutter/material.dart';
import 'features/workspace/workspace_explorer.dart';
import 'features/media/media_bin.dart';
import 'features/editor/main_editor_area.dart';
import 'features/online/online_service_panel.dart';

class ProjectionControlScreen extends StatefulWidget {
  const ProjectionControlScreen({super.key});

  @override
  State<ProjectionControlScreen> createState() => _ProjectionControlScreenState();
}

class _ProjectionControlScreenState extends State<ProjectionControlScreen> {
  int _selectedTabIndex = 0; 
  double _bottomPanelHeight = 400.0;

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
                _buildMenuText('Screens'),
                const SizedBox(width: 16),
                _buildMenuText('View'),
                const SizedBox(width: 16),
                _buildMenuText('Window'),
                const Spacer(),
                const Text('Live', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                              child: Row(
                                children: [
                                  // Workspace/Library
                                  Expanded(
                                    flex: 3, 
                                    child: WorkspaceExplorer(),
                                  ),
                                  const SizedBox(width: 4),
                                  // Online/Service
                                  Expanded(
                                    flex: 5,
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
                                        _buildTabItem('Order of Service', 0),
                                        const SizedBox(width: 16),
                                        _buildTabItem('Bible', 1),
                                        const SizedBox(width: 16),
                                        _buildTabItem('Media', 2),
                                        const SizedBox(width: 16),
                                        _buildTabItem('Online', 3),
                                        const Spacer(),
                                        const Text('Live', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                    child: Column(
                      children: [
                        // Preview
                        Expanded(
                          flex: 3, 
                          child: _buildPanel(
                            title: '', 
                            child: const Center(child: Text('Preview', style: TextStyle(color: Colors.grey, fontSize: 20)))
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Notes
                        Expanded(
                          flex: 2,
                          child: _buildPanel(
                            title: '', 
                            child: const Center(child: Text('Notes', style: TextStyle(color: Colors.grey, fontSize: 20)))
                          ),
                        ),
                      ],
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
      case 0: // Order of Service
        return const MainEditorArea();
      case 1: // Bible
        return const Center(child: Text('Bible View', style: TextStyle(color: Colors.white54)));
      case 2: // Media
        return MediaBin();
      case 3: // Online
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
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
              if (trailing != null)
                Text(trailing, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          if (child != null) Expanded(child: child),
        ],
      ),
    );
  }
}
