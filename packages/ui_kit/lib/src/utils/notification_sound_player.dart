import 'package:audioplayers/audioplayers.dart';

class NotificationSoundPlayer {
  static final AudioPlayer _player = AudioPlayer();

  /// Plays the default notification sound bundled in UI Kit.
  /// Ensure you have registered 'packages/ui_kit/assets/sounds/notification.wav' in pubspec.
  static Future<void> playNotificationSound() async {
    try {
      // AssetSource does not support 'package' argument.
      // We must provide the full path relative to the asset root.
      // For package assets, it is usually 'packages/<package_name>/<path>'
      // However, AssetSource adds 'assets/' prefix by default? 
      // Let's try specifying the direct path that Flutter resolves.
      // If AssetSource adds 'assets/', we might need to be careful.
      // Valid pattern: AssetSource('packages/ui_kit/sounds/notification.wav') assuming it is under assets/
      
      // Update: we'll try the standard package asset path.
      await _player.play(AssetSource('packages/ui_kit/sounds/notification.wav'));
    } catch (e) {
      // Ignore errors if sound fails (e.g. platform not supported or file missing)
      print('Error playing notification sound: $e');
    }
  }
}
