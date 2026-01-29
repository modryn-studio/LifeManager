import 'package:flutter/foundation.dart';

/// TaskPattern model for AI-detected recurring patterns
/// 
/// When the pattern analyzer detects that you do a task repeatedly
/// (e.g., "clean cat box" every 3 days), it creates a suggestion
/// 
/// Confidence threshold: 0.80 (hardcoded)
@immutable
class TaskPattern {
  final String id;
  final String coupleId;
  final String patternTitle;
  final String suggestedRecurrence;
  final int suggestedIntervalDays;
  final double confidence;
  final String? embedding;
  final bool? accepted; // NULL = pending, true = accepted, false = rejected/dismissed
  final DateTime createdAt;

  const TaskPattern({
    required this.id,
    required this.coupleId,
    required this.patternTitle,
    required this.suggestedRecurrence,
    required this.suggestedIntervalDays,
    required this.confidence,
    this.embedding,
    this.accepted,
    required this.createdAt,
  });

  /// Create TaskPattern from database row
  factory TaskPattern.fromJson(Map<String, dynamic> json) {
    return TaskPattern(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      patternTitle: json['pattern_title'] as String,
      suggestedRecurrence: json['suggested_recurrence'] as String,
      suggestedIntervalDays: json['suggested_interval_days'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      embedding: json['embedding'] as String?,
      accepted: json['accepted'] as bool?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Check if this pattern is pending user action
  bool get isPending => accepted == null;

  /// Get confidence as percentage string (e.g., "85%")
  String get confidencePercentage => '${(confidence * 100).round()}%';

  /// Get a human-readable recurrence description
  String get recurrenceDescription {
    switch (suggestedRecurrence) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'custom':
        return 'Every $suggestedIntervalDays days';
      default:
        return 'Every $suggestedIntervalDays days';
    }
  }

  /// Create a copy with updated fields
  TaskPattern copyWith({
    String? id,
    String? coupleId,
    String? patternTitle,
    String? suggestedRecurrence,
    int? suggestedIntervalDays,
    double? confidence,
    String? embedding,
    bool? accepted,
    DateTime? createdAt,
  }) {
    return TaskPattern(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      patternTitle: patternTitle ?? this.patternTitle,
      suggestedRecurrence: suggestedRecurrence ?? this.suggestedRecurrence,
      suggestedIntervalDays: suggestedIntervalDays ?? this.suggestedIntervalDays,
      confidence: confidence ?? this.confidence,
      embedding: embedding ?? this.embedding,
      accepted: accepted ?? this.accepted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPattern &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
