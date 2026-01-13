// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      isRegistrationRequired:
          json['is_registration_required'] as bool? ?? false,
      formConfig: json['form_config'] == null
          ? null
          : ActivityFormConfig.fromJson(
              json['form_config'] as Map<String, dynamic>),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      organizationId: json['organization_id'] as String?,
      branchId: json['branch_id'] as String?,
    );

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
      'location': instance.location,
      'image_url': instance.imageUrl,
      'is_registration_required': instance.isRegistrationRequired,
      'form_config': instance.formConfig,
      'created_at': instance.createdAt?.toIso8601String(),
      'organization_id': instance.organizationId,
      'branch_id': instance.branchId,
    };
