// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAssignment _$ServiceAssignmentFromJson(Map<String, dynamic> json) =>
    ServiceAssignment(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      memberId: json['member_id'] as String,
      roleName: json['role_name'] as String,
      confirmed: json['confirmed'] as bool? ?? false,
      teamName: json['team_name'] as String? ?? 'General',
    );

Map<String, dynamic> _$ServiceAssignmentToJson(ServiceAssignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service_id': instance.serviceId,
      'member_id': instance.memberId,
      'role_name': instance.roleName,
      'confirmed': instance.confirmed,
      'team_name': instance.teamName,
    };
