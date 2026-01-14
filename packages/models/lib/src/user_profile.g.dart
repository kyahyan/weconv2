// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      fullName: json['full_name'] as String?,
      address: json['address'] as String?,
      contactNumber: json['contact_number'] as String?,
      songContributorStatus: json['song_contributor_status'] as String?,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
      'full_name': instance.fullName,
      'address': instance.address,
      'contact_number': instance.contactNumber,
      'song_contributor_status': instance.songContributorStatus,
    };
