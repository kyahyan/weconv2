// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Service _$ServiceFromJson(Map<String, dynamic> json) => Service(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      worshipLeaderId: json['worship_leader_id'] as String?,
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
    );

Map<String, dynamic> _$ServiceToJson(Service instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'title': instance.title,
      'worship_leader_id': instance.worshipLeaderId,
      'end_time': instance.endTime?.toIso8601String(),
    };
