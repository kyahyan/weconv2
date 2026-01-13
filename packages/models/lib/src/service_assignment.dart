import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_assignment.g.dart';

@JsonSerializable()
class ServiceAssignment extends Equatable {
  const ServiceAssignment({
    required this.id,
    required this.serviceId,
    required this.memberId,
    required this.roleName,
    this.confirmed = false,
    this.teamName = 'General',
  });

  factory ServiceAssignment.fromJson(Map<String, dynamic> json) =>
      _$ServiceAssignmentFromJson(json);

  final String id;
  @JsonKey(name: 'service_id')
  final String serviceId;
  @JsonKey(name: 'member_id')
  final String memberId;
  @JsonKey(name: 'role_name')
  final String roleName;
  final bool confirmed;
  @JsonKey(name: 'team_name')
  final String teamName;

  Map<String, dynamic> toJson() => _$ServiceAssignmentToJson(this);

  ServiceAssignment copyWith({
    String? id,
    String? serviceId,
    String? memberId,
    String? roleName,
    bool? confirmed,
    String? teamName,
  }) {
    return ServiceAssignment(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      memberId: memberId ?? this.memberId,
      roleName: roleName ?? this.roleName,
      confirmed: confirmed ?? this.confirmed,
      teamName: teamName ?? this.teamName,
    );
  }

  @override
  List<Object?> get props => [id, serviceId, memberId, roleName, confirmed, teamName];
}
