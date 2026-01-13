import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_item.g.dart';

enum ServiceItemType {
  @JsonValue('generic')
  generic,
  @JsonValue('song')
  song,
  @JsonValue('sermon')
  sermon,
  @JsonValue('reading')
  reading,
  @JsonValue('prayer')
  prayer,
}

@JsonSerializable()
class ServiceItem extends Equatable {
  const ServiceItem({
    required this.id,
    required this.serviceId,
    required this.title,
    this.type = 'generic',
    this.description,
    this.durationSeconds,
    this.orderIndex = 0,
    this.songId, // Optional link to a song for 'song' type
    this.assignedTo,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) =>
      _$ServiceItemFromJson(json);

  final String id;
  
  @JsonKey(name: 'service_id')
  final String serviceId;
  
  final String title;
  
  final String type;
  
  final String? description;
  
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  
  @JsonKey(name: 'order_index')
  final int orderIndex;
  
  @JsonKey(name: 'song_id')
  final String? songId;

  @JsonKey(name: 'assigned_to')
  final String? assignedTo;

  Map<String, dynamic> toJson() => _$ServiceItemToJson(this);

  ServiceItem copyWith({
    String? id,
    String? serviceId,
    String? title,
    String? type,
    String? description,
    int? durationSeconds,
    int? orderIndex,
    String? songId,
    String? assignedTo,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
      songId: songId ?? this.songId,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  @override
  List<Object?> get props => [id, serviceId, title, type, description, durationSeconds, orderIndex, songId, assignedTo];
}
