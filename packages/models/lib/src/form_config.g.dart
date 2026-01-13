// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityFormConfig _$ActivityFormConfigFromJson(Map<String, dynamic> json) =>
    ActivityFormConfig(
      fields: (json['fields'] as List<dynamic>)
          .map((e) => ActivityFormField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ActivityFormConfigToJson(ActivityFormConfig instance) =>
    <String, dynamic>{
      'fields': instance.fields,
    };

ActivityFormField _$ActivityFormFieldFromJson(Map<String, dynamic> json) =>
    ActivityFormField(
      id: json['id'] as String?,
      label: json['label'] as String,
      type: json['type'] as String,
      isRequired: json['is_required'] as bool? ?? false,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ActivityFormFieldToJson(ActivityFormField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'type': instance.type,
      'is_required': instance.isRequired,
      'options': instance.options,
    };
