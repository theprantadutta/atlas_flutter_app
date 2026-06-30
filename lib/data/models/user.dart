import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final int level;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final bool isEmailVerified;
  final String authProvider;
  final DateTime createdAt;
  final DateTime? lastActiveDate;

  // Premium entitlement (from /auth/me)
  final bool isPremium;
  final DateTime? premiumUntil;
  final bool isLifetime;
  final List<String> ownedCosmetics;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.level = 1,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isEmailVerified = false,
    this.authProvider = 'email',
    required this.createdAt,
    this.lastActiveDate,
    this.isPremium = false,
    this.premiumUntil,
    this.isLifetime = false,
    this.ownedCosmetics = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? photoUrl,
    int? level,
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    bool? isEmailVerified,
    String? authProvider,
    DateTime? createdAt,
    DateTime? lastActiveDate,
    bool? isPremium,
    DateTime? premiumUntil,
    bool? isLifetime,
    List<String>? ownedCosmetics,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      isLifetime: isLifetime ?? this.isLifetime,
      ownedCosmetics: ownedCosmetics ?? this.ownedCosmetics,
    );
  }
}
