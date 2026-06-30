// API models for the Aurora endpoints. These mirror the backend Aurora DTOs
// (snake_case on the wire).

/// A generated weekly reflection.
class AuroraReflectionData {
  const AuroraReflectionData({
    required this.id,
    required this.content,
    required this.periodStart,
    required this.periodEnd,
    required this.modelTier,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String modelTier;
  final DateTime createdAt;

  factory AuroraReflectionData.fromJson(Map<String, dynamic> json) {
    return AuroraReflectionData(
      id: json['id'] as String,
      content: json['content'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      modelTier: json['model_tier'] as String? ?? 'free',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// An entity Aurora created from a natural-language chat message.
class AuroraCreatedEntity {
  const AuroraCreatedEntity({
    required this.type,
    required this.title,
    required this.id,
  });

  final String type; // 'habit' | 'task' | 'goal'
  final String title;
  final String id;

  factory AuroraCreatedEntity.fromJson(Map<String, dynamic> json) {
    return AuroraCreatedEntity(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      id: json['id'] as String? ?? '',
    );
  }
}

/// The result of a chat turn.
class AuroraChatResult {
  const AuroraChatResult({
    required this.reply,
    required this.created,
    required this.isPremium,
  });

  final String reply;
  final List<AuroraCreatedEntity> created;
  final bool isPremium;

  factory AuroraChatResult.fromJson(Map<String, dynamic> json) {
    final created = (json['created'] as List<dynamic>? ?? [])
        .map((e) => AuroraCreatedEntity.fromJson(e as Map<String, dynamic>))
        .toList();
    return AuroraChatResult(
      reply: json['reply'] as String? ?? '',
      created: created,
      isPremium: json['is_premium'] == true,
    );
  }
}
