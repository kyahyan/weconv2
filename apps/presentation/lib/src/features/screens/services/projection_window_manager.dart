import 'dart:convert';
import 'package:flutter/widgets.dart'; // For Size, Rect
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'dart:ui' as ui;
import '../models/screen_model.dart';
import '../models/projection_style.dart';
import '../repositories/screen_repository.dart';
import '../../editor/editor_provider.dart';

part 'projection_window_manager.g.dart';

@Riverpod(keepAlive: true)
class ProjectionWindowManager extends _$ProjectionWindowManager {
  bool _initialized = false;

  @override
  Map<String, int> build() {
    // 1. Listen to Content Updates
    ref.listen(liveSlideContentProvider, (previous, next) {
      _broadcastContent(next);
    });

    // Listens to Screen Repository Changes
    ref.listen(screenRepositoryProvider, (previous, next) {
       _syncWindows(next);
    });

    // Initial Restore
    if (!_initialized) {
       final screens = ref.read(screenRepositoryProvider);
       if (screens.isNotEmpty) {
          _restoreWindows(screens);
       }
       _initialized = true;
    }

    // Listen for window close requests from secondary windows
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'requestClose') {
        final windowId = call.arguments as int;
        debugPrint('Window $windowId requested close. Closing...');
        
        try {
          await WindowController.fromWindowId(windowId).close();
        } catch (e) {
          debugPrint('Error closing window $windowId: $e');
        }
        
        final newState = Map<String, int>.from(state);
        newState.removeWhere((key, value) => value == windowId);
        state = newState;
      } else if (call.method == 'requestInitialState') {
        // Find which screen this window belongs to
        final screenId = state.entries.firstWhereOrNull((e) => e.value == fromWindowId)?.key;
        if (screenId != null) {
           final screens = ref.read(screenRepositoryProvider);
           final screen = screens.firstWhereOrNull((s) => s.id == screenId);
           final content = ref.read(liveSlideContentProvider);
           
           return jsonEncode({
             'content': content.content, // Fallback string for simple readers
             'slideData': content.toJson(), // Full data
             'name': screen?.name,
             'style': screen?.style?.toJson() ?? const ProjectionStyle().toJson(),
           });
        }
      }
      return null;
    });
    
    return {};
  }

  Future<void> _syncWindows(List<ScreenModel> screens) async {
    // 1. Close windows for disabled screens or deleted screens
    final activeScreenIds = screens.map((s) => s.id).toSet();
    final windowsToClose = <String>[];
    
    for (final screenId in state.keys) {
      final screen = screens.firstWhereOrNull((s) => s.id == screenId);
      if (screen == null || !screen.isEnabled) {
         windowsToClose.add(screenId);
      }
    }
    
    for (final id in windowsToClose) {
      await closeDisplay(id);
    }

    // 2. Open windows for enabled screens (if not already open)
    for (final screen in screens) {
      if (screen.isEnabled) {
        if (!state.containsKey(screen.id)) {
           await openDisplay(screen);
        } else {
           // Window is open, check if we need to update style
           // For simplicity, we just push the style every time the repo updates
           if (screen.style != null) {
              await _broadcastStyle(screen);
           }
        }
      }
    }
  }

  Future<void> _broadcastStyle(ScreenModel screen) async {
     if (!state.containsKey(screen.id)) return;
     
     final windowId = state[screen.id]!;
     try {
       await DesktopMultiWindow.invokeMethod(
          windowId, 
          'updateStyle', 
          jsonEncode(screen.style?.toJson() ?? const ProjectionStyle().toJson())
       );
     } catch (e) {
       print('Error updating style for window $windowId: $e');
     }
  }

  Future<void> _restoreWindows(List<ScreenModel> screens) async {
    for (final screen in screens) {
      if (screen.isEnabled && !state.containsKey(screen.id)) {
        await Future.delayed(const Duration(milliseconds: 500));
        await openDisplay(screen);
      }
    }
  }

  Future<void> _broadcastContent(LiveSlideData content) async {
    final jsonString = jsonEncode(content.toJson());
    for (final windowId in state.values) {
      try {
        await DesktopMultiWindow.invokeMethod(windowId, 'updateSlide', jsonString);
      } catch (e) {
        print('Error updating window $windowId: $e');
      }
    }
  }

  Future<void> openDisplay(ScreenModel screen) async {
    if (state.containsKey(screen.id)) {
      final windowId = state[screen.id]!;
      try {
        await DesktopMultiWindow.invokeMethod(windowId, 'focus');
      } catch (e) {
        // Window might be dead
        final newState = Map<String, int>.from(state);
        newState.remove(screen.id);
        state = newState;
        await _entryPoint(screen);
      }
      return;
    }
    await _entryPoint(screen);
  }

  Future<void> _entryPoint(ScreenModel screen) async {
    try {
      // Calculate Bounds First
      Rect? bounds;
      
      if (screen.outputId != null) {
        final displays = await ScreenRetriever.instance.getAllDisplays();
        final display = displays.where((d) => d.id.toString() == screen.outputId).firstOrNull;
        if (display != null) {
           bounds = Offset(display.visiblePosition!.dx, display.visiblePosition!.dy) & display.size;
        }
      }

      final window = await DesktopMultiWindow.createWindow(jsonEncode({
        'type': screen.type == ScreenType.audience ? 'audience' : 'stage',
        'screenId': screen.id,
        'name': screen.name,
      }));
      
      final newState = Map<String, int>.from(state);
      newState[screen.id] = window.windowId;
      state = newState;

      if (bounds != null) {
        await window.setFrame(bounds);
      }

      await window.setTitle(screen.name);
      await window.show();
      
      // Send initial content
      final currentContent = ref.read(liveSlideContentProvider);
      if (currentContent.content.isNotEmpty) {
         await DesktopMultiWindow.invokeMethod(window.windowId, 'updateSlide', jsonEncode(currentContent.toJson()));
      }

    } catch (e) {
      print('Error spawning window for ${screen.name}: $e');
    }
  }

  Future<void> closeDisplay(String screenId) async {
    if (state.containsKey(screenId)) {
      final windowId = state[screenId]!;
      try {
        final controller = WindowController.fromWindowId(windowId);
        await controller.close();
      } catch (e) {
        print('Error closing window $windowId: $e');
      }
      final newState = Map<String, int>.from(state);
      newState.remove(screenId);
      state = newState;
    }
  }
  
  bool isWindowOpen(String screenId) {
    return state.containsKey(screenId);
  }
}
