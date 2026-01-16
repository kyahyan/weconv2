
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'projection_style.dart';

part 'screen_model.freezed.dart';
part 'screen_model.g.dart';

enum ScreenType {
  audience,
  stage,
}

enum ScreenMode {
  single,
  group, // For edge blending or multi-projector setups later
}

@freezed
class ScreenModel with _$ScreenModel {
  const factory ScreenModel({
    required String id,
    required String name,
    required ScreenType type,
    @Default(ScreenMode.single) ScreenMode mode,
    @Default(1920) int width,
    @Default(1080) int height,
    String? outputId, // ID of the physical display or window
    @Default(false) bool isEnabled,
    ProjectionStyle? style,
  }) = _ScreenModel;

  factory ScreenModel.fromJson(Map<String, dynamic> json) => _$ScreenModelFromJson(json);
}
