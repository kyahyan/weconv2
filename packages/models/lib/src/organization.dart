import 'package:json_annotation/json_annotation.dart';

part 'organization.g.dart';

@JsonSerializable()
class Organization {
  final String id;
  final String name;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String status; // pending, approved, rejected

  Organization({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.status = 'pending',
  });

  factory Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);
}

@JsonSerializable()
class Branch {
  final String id;
  @JsonKey(name: 'organization_id')
  final String organizationId;
  final String name;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Branch({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => _$BranchFromJson(json);
  Map<String, dynamic> toJson() => _$BranchToJson(this);
}
