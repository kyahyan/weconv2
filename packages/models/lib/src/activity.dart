import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'form_config.dart';

part 'activity.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Activity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? imageUrl;
  final bool isRegistrationRequired;
  final ActivityFormConfig? formConfig;
  final DateTime? createdAt;
  final String? organizationId;
  final String? branchId;

  const Activity({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.imageUrl,
    this.isRegistrationRequired = false,
    this.formConfig,
    this.createdAt,
    this.organizationId,
    this.branchId,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? imageUrl,
    bool? isRegistrationRequired,
    ActivityFormConfig? formConfig,
    DateTime? createdAt,
    String? organizationId,
    String? branchId,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      isRegistrationRequired: isRegistrationRequired ?? this.isRegistrationRequired,
      formConfig: formConfig ?? this.formConfig,
      createdAt: createdAt ?? this.createdAt,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        location,
        imageUrl,
        isRegistrationRequired,
        formConfig,
        createdAt,
        organizationId,
        branchId,
      ];
}
