
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/screen_model.dart';

part 'screen_repository.g.dart';

@Riverpod(keepAlive: true)
class ScreenRepository extends _$ScreenRepository {
  @override
  List<ScreenModel> build() {
    // Start with empty or load async. Since build is synchronous, we start empty 
    // and load immediately.
    _loadScreens();
    return []; 
  }

  Future<void> _loadScreens() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/screens.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final screens = jsonList.map((e) => ScreenModel.fromJson(e)).toList();
        state = screens;
      } else {
        // Initial defaults if no config exists
        state = [
          const ScreenModel(
            id: '1',
            name: 'Projector - Front',
            type: ScreenType.audience,
            width: 1920,
            height: 1080,
          ),
          const ScreenModel(
            id: '2',
            name: 'Stage Display',
            type: ScreenType.stage,
            width: 1920,
            height: 1080,
          ),
        ];
        _saveScreens();
      }
    } catch (e) {
      print('Error loading screens: $e');
    }
  }

  Future<void> _saveScreens() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/screens.json');
      final jsonList = state.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving screens: $e');
    }
  }

  void addScreen(ScreenType type) {
    String name;
    if (type == ScreenType.audience) {
      name = 'Audience Screen ${state.where((s) => s.type == ScreenType.audience).length + 1}';
    } else {
      name = 'Stage Screen ${state.where((s) => s.type == ScreenType.stage).length + 1}';
    }

    final newScreen = ScreenModel(
      id: const Uuid().v4(),
      name: name,
      type: type,
    );
    state = [...state, newScreen];
    _saveScreens();
  }

  void removeScreen(String id) {
    state = state.where((s) => s.id != id).toList();
    _saveScreens();
  }

  void updateScreen(ScreenModel updatedScreen) {
    state = state.map((s) => s.id == updatedScreen.id ? updatedScreen : s).toList();
    _saveScreens();
  }
}
