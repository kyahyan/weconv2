import 'dart:convert';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import 'src/projection_control_screen.dart';

import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'src/projector_screen.dart';

import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  print('MAIN LAUNCHED WITH ARGS: $args');
  
  if (args.firstOrNull == 'multi_window') {
    print('Starting Secondary Window...');
    final windowId = int.parse(args[1]);
    final argument = args[2].isEmpty ? const <String, dynamic>{} : jsonDecode(args[2]) as Map<String, dynamic>;
    
    // window_manager is handled natively in C++ for secondary windows now
    
    runApp(ProjectorScreen(
      windowId: windowId, 
      args: argument,
    ));
  } else {
    await SupabaseConfig.init();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(1024, 768),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
    });

    runApp(const ProviderScope(child: MyApp()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      theme: ShadcnAppTheme.lightTheme,
      darkTheme: ShadcnAppTheme.darkTheme,
      home: MaterialApp(
        title: 'Presentation',
        theme: AppTheme.darkTheme, // Default to dark for presentation
        home: const ProjectionControlScreen(),
      ),
    );
  }
}
