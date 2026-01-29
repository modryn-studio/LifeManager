import 'package:flutter/foundation.dart';

/// Task model representing a household/life task
/// 
/// Tasks can be:
/// - One-time (no recurrence)
/// - Recurring (daily, weekly, monthly, or custom interval)
/// - With or without due dates (null = "when you get to it")
/// 
/// Categories: household, pet, health, personal, sentimental
@immutable
class Task {
  final String id;
  final String coupleId;
  final String createdBy;
  final String? assignedTo;
  final String title;
  final String? description;
  final String? category;
  final DateTime? dueDate;
  final String? recurrencePattern;
  final int? recurrenceIntervalDays;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.coupleId,
    required this.createdBy,
    this.assignedTo,
    required this.title,
    this.description,
    this.category,
    this.dueDate,
    this.recurrencePattern,
    this.recurrenceIntervalDays,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    required this.createdAt,
  });

  /// Create Task from database row
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String) 
          : null,
      recurrencePattern: json['recurrence_pattern'] as String?,
      recurrenceIntervalDays: json['recurrence_interval_days'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      completedBy: json['completed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to database-compatible map for insert
  /// 
  /// Excludes id (auto-generated), is_completed, completed_at, completed_by, created_at
  Map<String, dynamic> toInsertJson() {
    return {
      'couple_id': coupleId,
      'created_by': createdBy,
      if (assignedTo != null) 'assigned_to': assignedTo,
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
      if (recurrencePattern != null) 'recurrence_pattern': recurrencePattern,
      if (recurrenceIntervalDays != null) 'recurrence_interval_days': recurrenceIntervalDays,
    };
  }

  /// Convert to database-compatible map for update
  Map<String, dynamic> toUpdateJson() {
    return {
      if (assignedTo != null) 'assigned_to': assignedTo,
      'title': title,
      'description': description,
      'category': category,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'recurrence_pattern': recurrencePattern,
      'recurrence_interval_days': recurrenceIntervalDays,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'completed_by': completedBy,
    };
  }

  /// Create a copy with updated fields
  Task copyWith({
    String? id,
    String? coupleId,
    String? createdBy,
    String? assignedTo,
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? recurrencePattern,
    bool clearRecurrencePattern = false,
    int? recurrenceIntervalDays,
    bool clearRecurrenceIntervalDays = false,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      recurrencePattern: clearRecurrencePattern ? null : (recurrencePattern ?? this.recurrencePattern),
      recurrenceIntervalDays: clearRecurrenceIntervalDays ? null : (recurrenceIntervalDays ?? this.recurrenceIntervalDays),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  /// Check if task is due today
  bool get isDueToday {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isAtSameMomentAs(today);
  }

  /// Check if task is recurring
  bool get isRecurring => recurrencePattern != null;

  /// Check if task has no due date ("when you get to it")
  bool get hasNoDueDate => dueDate == null;

  /// Get a human-readable recurrence description
  String get recurrenceDescription {
    if (recurrencePattern == null) return 'One-time';
    switch (recurrencePattern) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'custom':
        return 'Every ${recurrenceIntervalDays ?? 1} days';
      default:
        return 'One-time';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
