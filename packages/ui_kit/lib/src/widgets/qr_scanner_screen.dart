import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final void Function(String code) onScan;
  const QRScannerScreen({super.key, required this.onScan});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false; // Prevent multiple scans

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _buildMockScanner();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto: 
                     return const Icon(Icons.flash_auto, color: Colors.white);
                  case TorchState.unavailable:
                     return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (_isScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _isScanned = true;
              widget.onScan(barcode.rawValue!);
              Navigator.pop(context); // Close scanner on first detection
              break;
            }
          }
        },
      ),
    );
  }

  Widget _buildMockScanner() {
    final TextEditingController _mockController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text("Mock Scanner (Windows)")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.computer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Camera not available on Desktop.\nPaste the Registration ID (Ticket) below:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _mockController,
              decoration: const InputDecoration(
                labelText: "Registration ID",
                border: OutlineInputBorder(),
                hintText: "Enter UUID...",
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_mockController.text.isNotEmpty) {
                   widget.onScan(_mockController.text);
                   Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text("Simulate Scan"),
            ),
          ],
        ),
      ),
    );
  }
}
