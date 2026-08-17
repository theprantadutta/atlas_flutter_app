// API models for the Aurora endpoints. These mirror the backend Aurora DTOs
// (snake_case on the wire).
//
// Every field the language model authored is passed through [stripLongDashes]
// here, at the boundary, so no em or en dash reaches the UI or Drift no matter
// what the model decides to write.

import 'package:atlas_flutter_app/core/utils/prose.dart';

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
      content: stripLongDashes(json['content'] as String),
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      modelTier: json['model_tier'] as String? ?? 'free',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// A structured entity spec Aurora parsed from natural language. The backend
/// only parses; the client creates the entity in the local Drift database
/// (offline-first source of truth), so these carry the full spec.
class AuroraCreatedEntity {
  const AuroraCreatedEntity({
    required this.type,
    required this.title,
    this.description,
    this.category,
    this.frequency,
    this.priority,
    this.taskType,
    this.difficulty,
  });

  final String type; // 'habit' | 'task' | 'goal'
  final String title;
  final String? description;
  final String? category;
  final String? frequency;
  final String? priority;
  final String? taskType;
  final int? difficulty;

  factory AuroraCreatedEntity.fromJson(Map<String, dynamic> json) {
    return AuroraCreatedEntity(
      type: json['type'] as String? ?? '',
      title: stripLongDashes(json['title'] as String? ?? ''),
      description: switch (json['description'] as String?) {
        final d? => stripLongDashes(d),
        null => null,
      },
      category: json['category'] as String?,
      frequency: json['frequency'] as String?,
      priority: json['priority'] as String?,
      taskType: json['task_type'] as String?,
      difficulty: json['difficulty'] as int?,
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
      reply: stripLongDashes(json['reply'] as String? ?? ''),
      created: created,
      isPremium: json['is_premium'] == true,
    );
  }
}

/// The result of a natural-language quick-add: a short note + parsed specs.
class AuroraQuickAddResult {
  const AuroraQuickAddResult({required this.note, required this.created});

  final String note;
  final List<AuroraCreatedEntity> created;

  factory AuroraQuickAddResult.fromJson(Map<String, dynamic> json) {
    final created = (json['created'] as List<dynamic>? ?? [])
        .map((e) => AuroraCreatedEntity.fromJson(e as Map<String, dynamic>))
        .toList();
    return AuroraQuickAddResult(
      note: stripLongDashes(json['note'] as String? ?? 'Done. Added for you.'),
      created: created,
    );
  }
}
