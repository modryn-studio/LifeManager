import 'package:flutter/foundation.dart';

/// TaskCompletion model for tracking completion history
/// 
/// Used by the pattern analyzer to detect recurring behaviors
/// Stores 90 days of history for pattern detection
@immutable
class TaskCompletion {
  final String id;
  final String taskId;
  final String coupleId;
  final String completedBy;
  final DateTime completedAt;

  const TaskCompletion({
    required this.id,
    required this.taskId,
    required this.coupleId,
    required this.completedBy,
    required this.completedAt,
  });

  /// Create TaskCompletion from database row
  factory TaskCompletion.fromJson(Map<String, dynamic> json) {
    return TaskCompletion(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      coupleId: json['couple_id'] as String,
      completedBy: json['completed_by'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  /// Convert to database-compatible map for insert
  Map<String, dynamic> toInsertJson() {
    return {
      'task_id': taskId,
      'couple_id': coupleId,
      'completed_by': completedBy,
      // completed_at defaults to now() in database
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCompletion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
