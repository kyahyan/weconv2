import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart' as dmw;

class ProjectorScreen extends StatefulWidget {
  final int windowId;

  const ProjectorScreen({
    super.key,
    required this.windowId,
  });

  @override
  State<ProjectorScreen> createState() => _ProjectorScreenState();
}

class _ProjectorScreenState extends State<ProjectorScreen> {
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    dmw.DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'updateSlide') {
        final data = call.arguments as String;
        setState(() {
          _currentText = data;
        });
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Text(
              _currentText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64, // Large font for projection
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
