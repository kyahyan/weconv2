import 'package:json_annotation/json_annotation.dart';

part 'attendance.g.dart';

@JsonSerializable()
class Attendance {
  final String id;
  @JsonKey(name: 'branch_id')
  final String branchId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'service_date')
  final DateTime serviceDate;
  @JsonKey(name: 'service_type')
  final String serviceType;
  final String category; // 'new_attender', 'attender', 'worker'
  @JsonKey(name: 'recorded_by')
  final String? recordedBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // Optional: Include full user profile if joined
  // @JsonKey(includeFromJson: false, includeToJson: false)
  // final UserProfile? profile;

  Attendance({
    required this.id,
    required this.branchId,
    required this.userId,
    required this.serviceDate,
    required this.serviceType,
    required this.category,
    this.recordedBy,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => _$AttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceToJson(this);
}
