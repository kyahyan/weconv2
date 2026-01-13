import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'form_config.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ActivityFormConfig extends Equatable {
  final List<ActivityFormField> fields;

  const ActivityFormConfig({required this.fields});

  factory ActivityFormConfig.fromJson(Map<String, dynamic> json) => _$ActivityFormConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityFormConfigToJson(this);

  @override
  List<Object?> get props => [fields];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ActivityFormField extends Equatable {
  final String id;
  final String label;
  final String type; // 'text', 'number', 'dropdown', 'date', 'boolean'
  final bool isRequired;
  final List<String>? options; // For dropdowns

  ActivityFormField({
     String? id,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.options,
  }) : id = id ?? const Uuid().v4();

  factory ActivityFormField.fromJson(Map<String, dynamic> json) => _$ActivityFormFieldFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityFormFieldToJson(this);

  ActivityFormField copyWith({
    String? id,
    String? label,
    String? type,
    bool? isRequired,
    List<String>? options,
  }) {
    return ActivityFormField(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
    );
  }

  @override
  List<Object?> get props => [id, label, type, isRequired, options];
}
