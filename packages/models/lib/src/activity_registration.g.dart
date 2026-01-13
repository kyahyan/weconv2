// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_registration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityRegistration _$ActivityRegistrationFromJson(
        Map<String, dynamic> json) =>
    ActivityRegistration(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      formData: json['form_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ActivityRegistrationToJson(
        ActivityRegistration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'activity_id': instance.activityId,
      'user_id': instance.userId,
      'status': instance.status,
      'form_data': instance.formData,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
