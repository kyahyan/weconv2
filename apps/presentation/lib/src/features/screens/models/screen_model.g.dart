// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScreenModelImpl _$$ScreenModelImplFromJson(Map<String, dynamic> json) =>
    _$ScreenModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$ScreenTypeEnumMap, json['type']),
      mode: $enumDecodeNullable(_$ScreenModeEnumMap, json['mode']) ??
          ScreenMode.single,
      width: (json['width'] as num?)?.toInt() ?? 1920,
      height: (json['height'] as num?)?.toInt() ?? 1080,
      outputId: json['outputId'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? false,
      style: json['style'] == null
          ? null
          : ProjectionStyle.fromJson(json['style'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ScreenModelImplToJson(_$ScreenModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ScreenTypeEnumMap[instance.type]!,
      'mode': _$ScreenModeEnumMap[instance.mode]!,
      'width': instance.width,
      'height': instance.height,
      'outputId': instance.outputId,
      'isEnabled': instance.isEnabled,
      'style': instance.style,
    };

const _$ScreenTypeEnumMap = {
  ScreenType.audience: 'audience',
  ScreenType.stage: 'stage',
};

const _$ScreenModeEnumMap = {
  ScreenMode.single: 'single',
  ScreenMode.group: 'group',
};
