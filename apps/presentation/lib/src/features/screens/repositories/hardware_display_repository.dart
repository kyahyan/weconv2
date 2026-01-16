
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_retriever/screen_retriever.dart';

part 'hardware_display_repository.g.dart';

@Riverpod(keepAlive: true)
class HardwareDisplayRepository extends _$HardwareDisplayRepository {
  @override
  Future<List<Display>> build() async {
    // Fetch initial displays
    return await _fetchDisplays();
  }

  Future<List<Display>> _fetchDisplays() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      return displays;
    } catch (e) {
      // Handle error or return empty if platform not supported
      print('Error fetching displays: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDisplays());
  }
}
