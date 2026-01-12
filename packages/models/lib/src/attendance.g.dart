// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attendance _$AttendanceFromJson(Map<String, dynamic> json) => Attendance(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      userId: json['user_id'] as String,
      serviceDate: DateTime.parse(json['service_date'] as String),
      serviceType: json['service_type'] as String,
      category: json['category'] as String,
      recordedBy: json['recorded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AttendanceToJson(Attendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'branch_id': instance.branchId,
      'user_id': instance.userId,
      'service_date': instance.serviceDate.toIso8601String(),
      'service_type': instance.serviceType,
      'category': instance.category,
      'recorded_by': instance.recordedBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
