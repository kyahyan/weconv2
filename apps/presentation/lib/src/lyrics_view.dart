import 'package:flutter/material.dart';

class LyricsView extends StatelessWidget {
  const LyricsView({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48, // Huge text for projection
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
