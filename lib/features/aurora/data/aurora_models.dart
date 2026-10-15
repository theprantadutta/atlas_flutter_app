import 'dart:convert';

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

/// A next step Aurora proposes in chat, shown as a card with one-tap Add
/// (habit / task) or Remind me (idea).
class AuroraSuggestion {
  const AuroraSuggestion({
    required this.title,
    required this.kind,
    this.category,
    this.time,
    this.xp,
    this.recommended = false,
  });

  final String title;

  /// 'habit' | 'task' | 'idea'
  final String kind;
  final String? category;

  /// "HH:mm" (24h), optional.
  final String? time;
  final int? xp;
  final bool recommended;

  bool get trackable => kind == 'habit' || kind == 'task';

  AuroraSuggestion copyWith({bool? recommended}) => AuroraSuggestion(
        title: title,
        kind: kind,
        category: category,
        time: time,
        xp: xp,
        recommended: recommended ?? this.recommended,
      );

  static AuroraSuggestion? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = (raw['title'] as Object?)?.toString().trim() ?? '';
    if (title.isEmpty || title.length > 80) return null;
    var kind = (raw['kind'] as Object?)?.toString().toLowerCase() ?? 'idea';
    if (!const {'habit', 'task', 'idea'}.contains(kind)) kind = 'idea';
    final time = (raw['time'] as Object?)?.toString();
    final xp = raw['xp'];
    return AuroraSuggestion(
      title: stripLongDashes(title),
      kind: kind,
      category: (raw['category'] as Object?)?.toString().toLowerCase(),
      time: time != null && RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(time) ? time : null,
      xp: kind == 'idea' || xp is! num ? null : xp.round().clamp(5, 100),
      recommended: raw['recommended'] == true,
    );
  }
}

/// Structured suggestions parsed from a reply, with the reply cleaned.
class ParsedSuggestions {
  const ParsedSuggestions(this.reply, this.items, this.followUps);
  final String reply;
  final List<AuroraSuggestion> items;
  final List<String> followUps;

  static final _fence = RegExp(r'```suggestions\s*([\s\S]*?)```');
  static final _bullet = RegExp(r'^\s*(?:[-*•]|\d+[.)])\s+(.+)$', multiLine: true);

  /// Client-side fallback for servers that don't parse the block: pull a
  /// ```suggestions block out of [reply]; failing that, turn a bullet list
  /// that follows a question into idea cards.
  static ParsedSuggestions fromReply(String reply) {
    final m = _fence.firstMatch(reply);
    if (m != null) {
      final clean = reply.replaceRange(m.start, m.end, '').trim();
      try {
        final decoded = jsonDecode(m.group(1)!.trim());
        final list = decoded is List ? decoded : (decoded is Map ? decoded['items'] : null);
        final items = [
          for (final e in (list is List ? list : const []))
            ?AuroraSuggestion.fromJson(e),
        ].take(3).toList();
        final follow = decoded is Map && decoded['followUps'] is List
            ? [
                for (final f in decoded['followUps'] as List)
                  if (f is String && f.trim().isNotEmpty) f.trim()
              ].take(2).toList()
            : <String>[];
        return ParsedSuggestions(clean, normalise(items), follow);
      } catch (_) {
        return ParsedSuggestions(clean, const [], const []);
      }
    }
    // Bullets after a question become gentle idea cards.
    final q = reply.indexOf('?');
    if (q >= 0) {
      final tail = reply.substring(q + 1);
      final bullets = _bullet.allMatches(tail).map((b) => b.group(1)!.trim()).toList();
      if (bullets.length >= 2 && bullets.length <= 5 && bullets.every((b) => b.length <= 60)) {
        final firstBullet = _bullet.firstMatch(tail)!;
        final clean = (reply.substring(0, q + 1) + tail.substring(0, firstBullet.start)).trim();
        final items = [
          for (final b in bullets.take(3))
            AuroraSuggestion(title: b.replaceAll(RegExp(r'[*_]'), ''), kind: 'idea'),
        ];
        return ParsedSuggestions(clean, normalise(items), const []);
      }
    }
    return ParsedSuggestions(reply, const [], const []);
  }

  /// Exactly one recommended item: the first flagged, else the first.
  static List<AuroraSuggestion> normalise(List<AuroraSuggestion> items) {
    if (items.isEmpty) return items;
    var first = items.indexWhere((i) => i.recommended);
    if (first < 0) first = 0;
    return [for (var i = 0; i < items.length; i++) items[i].copyWith(recommended: i == first)];
  }
}

/// The result of a chat turn.
class AuroraChatResult {
  const AuroraChatResult({
    required this.reply,
    required this.created,
    required this.isPremium,
    this.suggestions = const [],
    this.followUps = const [],
  });

  final String reply;
  final List<AuroraCreatedEntity> created;
  final bool isPremium;
  final List<AuroraSuggestion> suggestions;
  final List<String> followUps;

  factory AuroraChatResult.fromJson(Map<String, dynamic> json) {
    final created = (json['created'] as List<dynamic>? ?? [])
        .map((e) => AuroraCreatedEntity.fromJson(e as Map<String, dynamic>))
        .toList();
    var reply = stripLongDashes(json['reply'] as String? ?? '');
    var suggestions = [
      for (final e in (json['suggestions'] as List<dynamic>? ?? const []))
        ?AuroraSuggestion.fromJson(e),
    ];
    var followUps = [
      for (final f in (json['follow_ups'] as List<dynamic>? ?? const []))
        if (f is String && f.trim().isNotEmpty) stripLongDashes(f.trim()),
    ];
    if (suggestions.isEmpty) {
      final parsed = ParsedSuggestions.fromReply(reply);
      reply = parsed.reply;
      suggestions = parsed.items;
      if (followUps.isEmpty) followUps = parsed.followUps;
    }
    return AuroraChatResult(
      reply: reply,
      created: created,
      isPremium: json['is_premium'] == true,
      suggestions: ParsedSuggestions.normalise(suggestions),
      followUps: followUps.take(2).toList(),
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
