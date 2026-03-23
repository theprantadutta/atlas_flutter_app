import 'package:json_annotation/json_annotation.dart';

part 'token_response.g.dart';

@JsonSerializable()
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String userId;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.userId,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);
}
