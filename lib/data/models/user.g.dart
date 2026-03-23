// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  photoUrl: json['photo_url'] as String?,
  level: (json['level'] as num?)?.toInt() ?? 1,
  totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  isEmailVerified: json['is_email_verified'] as bool? ?? false,
  authProvider: json['auth_provider'] as String? ?? 'email',
  createdAt: DateTime.parse(json['created_at'] as String),
  lastActiveDate: json['last_active_date'] == null
      ? null
      : DateTime.parse(json['last_active_date'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'full_name': instance.fullName,
  'photo_url': instance.photoUrl,
  'level': instance.level,
  'total_xp': instance.totalXp,
  'current_streak': instance.currentStreak,
  'longest_streak': instance.longestStreak,
  'is_email_verified': instance.isEmailVerified,
  'auth_provider': instance.authProvider,
  'created_at': instance.createdAt.toIso8601String(),
  'last_active_date': instance.lastActiveDate?.toIso8601String(),
};
