/// The full entitlement snapshot the backend reports at
/// `GET /api/v1/entitlements`. Mirrors that contract field-for-field
/// (snake_case on the wire). Hand-written (no codegen) so it can carry the
/// local expiry re-check and be cached to secure storage as JSON.
class Entitlements {
  const Entitlements({
    required this.isPremium,
    required this.isLifetime,
    this.premiumUntil,
    required this.auroraUnlimited,
    required this.auroraQuickAdd,
    required this.cloudSync,
    required this.deepInsights,
    required this.export,
    required this.aurora,
  });

  final bool isPremium;
  final bool isLifetime;
  final DateTime? premiumUntil;

  // ─── Per-feature flags ───
  final bool auroraUnlimited;
  final bool auroraQuickAdd;
  final bool cloudSync;
  final bool deepInsights;
  final bool export;

  final AuroraUsage aurora;

  /// Premium access, re-checked locally against [premiumUntil] so a stale cache
  /// can't keep premium on forever offline. Lifetime never expires; a
  /// subscription lapses once [premiumUntil] is in the past.
  bool get effectiveIsPremium {
    if (isLifetime) return true;
    if (!isPremium) return false;
    final until = premiumUntil;
    if (until != null && !until.isAfter(DateTime.now())) return false;
    return true;
  }

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    final features =
        (json['features'] as Map?)?.cast<String, dynamic>() ?? const {};
    final aurora =
        (json['aurora'] as Map?)?.cast<String, dynamic>() ?? const {};
    final until = json['premium_until'] as String?;
    return Entitlements(
      isPremium: json['is_premium'] == true,
      isLifetime: json['is_lifetime'] == true,
      premiumUntil: until == null ? null : DateTime.tryParse(until),
      auroraUnlimited: features['aurora_unlimited'] == true,
      auroraQuickAdd: features['aurora_quick_add'] == true,
      cloudSync: features['cloud_sync'] == true,
      deepInsights: features['deep_insights'] == true,
      export: features['export'] == true,
      aurora: AuroraUsage.fromJson(aurora),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_premium': isPremium,
        'is_lifetime': isLifetime,
        'premium_until': premiumUntil?.toIso8601String(),
        'features': {
          'aurora_unlimited': auroraUnlimited,
          'aurora_quick_add': auroraQuickAdd,
          'cloud_sync': cloudSync,
          'deep_insights': deepInsights,
          'export': export,
        },
        'aurora': aurora.toJson(),
      };
}

/// Aurora weekly usage snapshot. A `null` limit means unlimited (premium).
class AuroraUsage {
  const AuroraUsage({
    required this.chatUsed,
    this.chatLimit,
    required this.reflectionUsed,
    this.reflectionLimit,
    this.weekResetsAt,
  });

  final int chatUsed;
  final int? chatLimit;
  final int reflectionUsed;
  final int? reflectionLimit;
  final DateTime? weekResetsAt;

  /// Chats left this week, or `null` when unlimited.
  int? get chatRemaining {
    final limit = chatLimit;
    if (limit == null) return null;
    final left = limit - chatUsed;
    return left < 0 ? 0 : left;
  }

  /// Reflections left this week, or `null` when unlimited.
  int? get reflectionRemaining {
    final limit = reflectionLimit;
    if (limit == null) return null;
    final left = limit - reflectionUsed;
    return left < 0 ? 0 : left;
  }

  factory AuroraUsage.fromJson(Map<String, dynamic> json) {
    return AuroraUsage(
      chatUsed: (json['chat_used'] as num?)?.toInt() ?? 0,
      chatLimit: (json['chat_limit'] as num?)?.toInt(),
      reflectionUsed: (json['reflection_used'] as num?)?.toInt() ?? 0,
      reflectionLimit: (json['reflection_limit'] as num?)?.toInt(),
      weekResetsAt: json['week_resets_at'] == null
          ? null
          : DateTime.tryParse(json['week_resets_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'chat_used': chatUsed,
        'chat_limit': chatLimit,
        'reflection_used': reflectionUsed,
        'reflection_limit': reflectionLimit,
        'week_resets_at': weekResetsAt?.toIso8601String(),
      };
}
