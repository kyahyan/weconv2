// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Organization _$OrganizationFromJson(Map<String, dynamic> json) => Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'pending',
      acronym: json['acronym'] as String?,
      contactMobile: json['contact_mobile'] as String?,
      contactLandline: json['contact_landline'] as String?,
      location: json['location'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      website: json['website'] as String?,
      socialMediaLinks: json['social_media_links'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'owner_id': instance.ownerId,
      'created_at': instance.createdAt.toIso8601String(),
      'status': instance.status,
      'acronym': instance.acronym,
      'contact_mobile': instance.contactMobile,
      'contact_landline': instance.contactLandline,
      'location': instance.location,
      'avatar_url': instance.avatarUrl,
      'website': instance.website,
      'social_media_links': instance.socialMediaLinks,
    };

Branch _$BranchFromJson(Map<String, dynamic> json) => Branch(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      acronym: json['acronym'] as String?,
      contactMobile: json['contact_mobile'] as String?,
      contactLandline: json['contact_landline'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      socialMediaLinks: json['social_media_links'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BranchToJson(Branch instance) => <String, dynamic>{
      'id': instance.id,
      'organization_id': instance.organizationId,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
      'acronym': instance.acronym,
      'contact_mobile': instance.contactMobile,
      'contact_landline': instance.contactLandline,
      'address': instance.address,
      'avatar_url': instance.avatarUrl,
      'social_media_links': instance.socialMediaLinks,
    };
