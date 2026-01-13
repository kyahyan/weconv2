import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_registration.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ActivityRegistration extends Equatable {
  final String id;
  final String activityId;
  final String userId;
  final String status; // 'registered', 'checked_in', 'cancelled'
  final Map<String, dynamic>? formData;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional: Include Profile if joined? 
  // For now let's keep it simple and join in repo if needed, or handle separately.

  const ActivityRegistration({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    this.formData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityRegistration.fromJson(Map<String, dynamic> json) => _$ActivityRegistrationFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityRegistrationToJson(this);

  ActivityRegistration copyWith({
    String? id,
    String? activityId,
    String? userId,
    String? status,
    Map<String, dynamic>? formData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityRegistration(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      formData: formData ?? this.formData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, activityId, userId, status, formData, createdAt, updatedAt];
}
