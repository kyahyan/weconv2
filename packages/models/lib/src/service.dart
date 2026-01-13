import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service.g.dart';

@JsonSerializable()
class Service extends Equatable {
  const Service({
    required this.id,
    required this.date, // This acts as Start Time
    required this.title,
    this.worshipLeaderId,
    this.endTime,
    this.organizationId,
    this.branchId,
  });

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  final String id;
  final DateTime date;
  final String title;
  
  @JsonKey(name: 'worship_leader_id')
  final String? worshipLeaderId;

  @JsonKey(name: 'end_time')
  final DateTime? endTime;

  @JsonKey(name: 'organization_id')
  final String? organizationId;

  @JsonKey(name: 'branch_id')
  final String? branchId;

  Map<String, dynamic> toJson() => _$ServiceToJson(this);

  @override
  List<Object?> get props => [id, date, title, worshipLeaderId, endTime, organizationId, branchId];
}
