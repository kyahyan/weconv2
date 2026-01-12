import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service.g.dart';

@JsonSerializable()
class Service extends Equatable {
  const Service({
    required this.id,
    required this.date,
    required this.title,
    this.worshipLeaderId,
  });

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  final String id;
  final DateTime date;
  final String title;
  
  @JsonKey(name: 'worship_leader_id')
  final String? worshipLeaderId;

  Map<String, dynamic> toJson() => _$ServiceToJson(this);

  @override
  List<Object?> get props => [id, date, title, worshipLeaderId];
}
