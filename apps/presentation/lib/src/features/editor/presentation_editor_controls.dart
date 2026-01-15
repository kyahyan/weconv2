import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_provider.dart';
import '../service/service_model.dart';


class PresentationEditorControls extends ConsumerStatefulWidget {
  final int selectedSlideIndex;

  const PresentationEditorControls({
    super.key,
    required this.selectedSlideIndex,
  });

  @override
  ConsumerState<PresentationEditorControls> createState() => _PresentationEditorControlsState();
}

class _PresentationEditorControlsState extends ConsumerState<PresentationEditorControls> {
  late TextEditingController _textController;
  ServiceItem? _activeItem;
  int? _lastSlideIndex;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PresentationEditorControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If index changed, we must update text, BUT we should also check if the active item changed in build
  }

  void _syncToProject(ServiceItem updatedItem) {
     // Update the item provider
     ref.read(activeEditorItemProvider.notifier).state = updatedItem;
     
     // Update the project provider
     final currentProject = ref.read(activeProjectProvider);
     if (currentProject != null) {
        final newItems = currentProject.items.map((item) {
           return item.id == updatedItem.id ? updatedItem : item;
        }).toList();
        
        final updatedProject = ServiceProject(title: currentProject.title, items: newItems);
        ref.read(activeProjectProvider.notifier).state = updatedProject;
     }
  }

  void _onTextChanged(String value) {
     if (_activeItem == null) return;
     if (widget.selectedSlideIndex < 0 || widget.selectedSlideIndex >= _activeItem!.slides.length) return;

     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final currentSlide = slides[widget.selectedSlideIndex];
     
     if (currentSlide.content == value) return; // No change

     slides[widget.selectedSlideIndex] = PresentationSlide(
        id: currentSlide.id,
        content: value,
        label: currentSlide.label,
        color: currentSlide.color,
     );

     final updatedItem = _activeItem!.copyWith(slides: slides);
     
     // Optimistically update local reference to avoid jitter ? 
     // Actually ref.read will trigger rebuild, so we should be careful with text cursor.
     // For now, let's just sync.
     _syncToProject(updatedItem);
  }

  void _splitSlide() {
     if (_activeItem == null || widget.selectedSlideIndex < 0) return;
     
     final text = _textController.text;
     final selection = _textController.selection;
     
     if (selection.baseOffset < 0 || selection.baseOffset >= text.length) {
        // No selection/cursor? Just assume split at end? Or do nothing?
        // Let's do nothing if no cursor.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place cursor where you want to split.')));
        return;
     }

     final splitIndex = selection.baseOffset;
     final textBefore = text.substring(0, splitIndex).trim();
     final textAfter = text.substring(splitIndex).trim();
     
     if (textAfter.isEmpty) return; // Nothing to move to new slide

     final slides = List<PresentationSlide>.from(_activeItem!.slides);
     final currentSlide = slides[widget.selectedSlideIndex];
     
     // Update current slide
     slides[widget.selectedSlideIndex] = PresentationSlide(
        id: currentSlide.id,
        content: textBefore,
        label: currentSlide.label,
        color: currentSlide.color,
     );
     
     // Create new slide
     // For ID, we need uuid. Importing Uuid package or just using random if not available.
     // Assuming Uuid is available since used elsewhere, but need import.
     // If import missing, I'll use simple datetime fallback or need to add import.
     // Let's rely on standard import or duplicate Uuid logic.
     // Actually, let's use a simpler unique generator or assume Uuid is imported.
     // I'll check imports first.
     // Adding import locally in replacement if needed? 
     // I'll use standard DateTime for now to avoid import mess in this tool call, 
     // OR better, I will include the import in this same multi_replace.
     
     final newSlide = PresentationSlide(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID
        content: textAfter,
        label: currentSlide.label, // Inherit label
        color: currentSlide.color, // Inherit color
     );
     
     slides.insert(widget.selectedSlideIndex + 1, newSlide);
     
     final updatedItem = _activeItem!.copyWith(slides: slides);
     _syncToProject(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = ref.watch(activeEditorItemProvider);
    
    // Check if we need to update the text controller
    if (activeItem != _activeItem || widget.selectedSlideIndex != _lastSlideIndex) {
        _activeItem = activeItem;
        _lastSlideIndex = widget.selectedSlideIndex;
        
        String newText = '';
        if (activeItem != null && widget.selectedSlideIndex >= 0 && widget.selectedSlideIndex < activeItem.slides.length) {
           newText = activeItem.slides[widget.selectedSlideIndex].content;
        }
        
        // Only update if text is different to avoid cursor reset if we were just typing
        if (_textController.text != newText) {
             _textController.text = newText;
             // We might lose cursor position here if external update happens. 
             // Since we are the only editor, it should be fine mostly.
        }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editor Area
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing Slide ${widget.selectedSlideIndex + 1}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Mock Toolbar
                Row(
                  children: [
                    _buildToolbarButton(Icons.format_bold),
                    const SizedBox(width: 8),
                    _buildToolbarButton(Icons.format_italic),
                    const SizedBox(width: 8),
                    _buildToolbarButton(Icons.format_underlined),
                    const SizedBox(width: 16),
                    _buildToolbarButton(Icons.format_align_left),
                    const SizedBox(width: 8),
                    _buildToolbarButton(Icons.format_align_center),
                    const SizedBox(width: 8),
                    _buildToolbarButton(Icons.format_align_right),
                    const SizedBox(width: 16),
                    // Split Slide Button
                    TextButton.icon(
                      onPressed: _splitSlide,
                      icon: const Icon(Icons.call_split, size: 16, color: Colors.white70),
                      label: const Text('Split', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Text Field
                 Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _textController,
                      onChanged: _onTextChanged,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type your content here...',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Settings/Tools Sidebar
        Container(
          width: 200,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Colors.white10)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Slide Settings',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSettingItem('Transition', 'Fade'),
              const SizedBox(height: 12),
              _buildSettingItem('Duration', '5s'),
              const SizedBox(height: 12),
              _buildSettingItem('Background', 'Color'),
               const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton(IconData icon) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white70, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
