// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      userId: json['user_id'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['access_token_expires_at'] as String,
      ),
      refreshTokenExpiresAt: DateTime.parse(
        json['refresh_token_expires_at'] as String,
      ),
    );

Map<String, dynamic> _$TokenResponseToJson(
  TokenResponse instance,
) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'token_type': instance.tokenType,
  'user_id': instance.userId,
  'access_token_expires_at': instance.accessTokenExpiresAt.toIso8601String(),
  'refresh_token_expires_at': instance.refreshTokenExpiresAt.toIso8601String(),
};
