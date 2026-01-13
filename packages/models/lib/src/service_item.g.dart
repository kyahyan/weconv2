// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceItem _$ServiceItemFromJson(Map<String, dynamic> json) => ServiceItem(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String? ?? 'generic',
      description: json['description'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      songId: json['song_id'] as String?,
      assignedTo: json['assigned_to'] as String?,
    );

Map<String, dynamic> _$ServiceItemToJson(ServiceItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service_id': instance.serviceId,
      'title': instance.title,
      'type': instance.type,
      'description': instance.description,
      'duration_seconds': instance.durationSeconds,
      'order_index': instance.orderIndex,
      'song_id': instance.songId,
      'assigned_to': instance.assignedTo,
    };
