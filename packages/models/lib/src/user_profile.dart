import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String? username;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? address;
  @JsonKey(name: 'contact_number')
  final String? contactNumber;

  UserProfile({
    required this.id,
    this.username,
    this.avatarUrl,
    this.fullName,
    this.address,
    this.contactNumber,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
