import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/profile_helper.dart';
import '../core/date_utils.dart' as app_date;
import '../models/models.dart';

/// Service for task management operations
/// 
/// Handles:
/// - CRUD operations for tasks
/// - Real-time sync between partners
/// - Task completion tracking
class TaskService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Get all tasks for the current couple
  /// 
  /// Returns incomplete tasks first, then by due date
  static Future<List<Task>> getAllTasks() async {
    try {
      final profile = await ProfileHelper.getCurrentProfile();
      if (profile == null) return [];
      
      final response = await _client
          .from('tasks')
          .select()
          .eq('couple_id', profile.coupleId)
          .order('is_completed', ascending: true)
          .order('due_date', ascending: true, nullsFirst: false)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('TaskService.getAllTasks error: $e');
      return [];
    }
  }

  /// Get incomplete tasks for the current couple
  static Future<List<Task>> getIncompleteTasks() async {
    final profile = await ProfileHelper.getCurrentProfile();
    if (profile == null) return [];
    
    final response = await _client
        .from('tasks')
        .select()
        .eq('couple_id', profile.coupleId)
        .eq('is_completed', false)
        .order('due_date', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get overdue tasks
  static Future<List<Task>> getOverdueTasks() async {
    final profile = await ProfileHelper.getCurrentProfile();
    if (profile == null) return [];
    
    final todayStr = app_date.DateUtils.todayForDb;
    
    final response = await _client
        .from('tasks')
        .select()
        .eq('couple_id', profile.coupleId)
        .eq('is_completed', false)
        .lt('due_date', todayStr)
        .order('due_date', ascending: true);
    
    return (response as List)
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get tasks due today
  static Future<List<Task>> getTasksDueToday() async {
    final profile = await ProfileHelper.getCurrentProfile();
    if (profile == null) return [];
    
    final todayStr = app_date.DateUtils.todayForDb;
    
    final response = await _client
        .from('tasks')
        .select()
        .eq('couple_id', profile.coupleId)
        .eq('is_completed', false)
        .eq('due_date', todayStr)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get tasks with no due date ("when you get to it")
  static Future<List<Task>> getTasksNoDueDate() async {
    final profile = await ProfileHelper.getCurrentProfile();
    if (profile == null) return [];
    
    final response = await _client
        .from('tasks')
        .select()
        .eq('couple_id', profile.coupleId)
        .eq('is_completed', false)
        .isFilter('due_date', null)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get recently completed tasks (last 7 days)
  static Future<List<Task>> getRecentlyCompletedTasks() async {
    final profile = await ProfileHelper.getCurrentProfile();
    if (profile == null) return [];
    
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    final response = await _client
        .from('tasks')
        .select()
        .eq('couple_id', profile.coupleId)
        .eq('is_completed', true)
        .gte('completed_at', weekAgo.toIso8601String())
        .order('completed_at', ascending: false);
    
    return (response as List)
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new task
  /// 
  /// Returns the created task
  static Future<Task> createTask({
    required String title,
    String? description,
    String? category,
    DateTime? dueDate,
    String? recurrencePattern,
    int? recurrenceIntervalDays,
    String? assignedTo,
  }) async {
    final user = SupabaseService.currentUser;
    final profile = await ProfileHelper.getCurrentProfile();
    
    if (user == null || profile == null) {
      throw Exception('Not authenticated');
    }
    
    final response = await _client
        .from('tasks')
        .insert({
          'couple_id': profile.coupleId,
          'created_by': user.id,
          'title': title,
          if (description != null && description.isNotEmpty) 'description': description,
          if (category != null) 'category': category,
          if (dueDate != null) 'due_date': app_date.DateUtils.formatDateForDb(dueDate),
          if (recurrencePattern != null) 'recurrence_pattern': recurrencePattern,
          if (recurrenceIntervalDays != null) 'recurrence_interval_days': recurrenceIntervalDays,
          if (assignedTo != null) 'assigned_to': assignedTo,
        })
        .select()
        .single();
    
    return Task.fromJson(response);
  }

  /// Update an existing task
  static Future<Task> updateTask(Task task) async {
    final response = await _client
        .from('tasks')
        .update(task.toUpdateJson())
        .eq('id', task.id)
        .select()
        .single();
    
    return Task.fromJson(response);
  }

  /// Mark a task as completed
  /// 
  /// Also creates a task_completions record for pattern analysis
  /// Triggers auto-creation of next recurring task (via database trigger)
  static Future<Task> completeTask(String taskId) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    
    final profile = await ProfileHelper.getCurrentProfile();
    if (profile == null) {
      throw Exception('Profile not found. Please sign in again.');
    }
    
    // Mark task as completed
    final response = await _client
        .from('tasks')
        .update({
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
          'completed_by': user.id,
        })
        .eq('id', taskId)
        .select()
        .single();
    
    // Also record in task_completions for pattern analysis
    await _client.from('task_completions').insert({
      'task_id': taskId,
      'couple_id': profile.coupleId,
      'completed_by': user.id,
    });
    
    return Task.fromJson(response);
  }

  /// Mark a task as incomplete (undo completion)
  static Future<Task> uncompleteTask(String taskId) async {
    // First, delete any task_completions records for this task
    await _client
        .from('task_completions')
        .delete()
        .eq('task_id', taskId);
    
    // Then update the task to mark as incomplete
    final response = await _client
        .from('tasks')
        .update({
          'is_completed': false,
          'completed_at': null,
          'completed_by': null,
        })
        .eq('id', taskId)
        .select()
        .single();
    
    return Task.fromJson(response);
  }

  /// Delete a task
  static Future<void> deleteTask(String taskId) async {
    await _client
        .from('tasks')
        .delete()
        .eq('id', taskId);
  }

  /// Subscribe to real-time task updates for the couple
  /// 
  /// Returns a stream of all tasks whenever any change occurs
  static Stream<List<Task>> watchTasks() {
    final controller = StreamController<List<Task>>.broadcast();
    RealtimeChannel? channel;
    bool isCancelled = false;
    
    Future<void> initialize() async {
      try {
        final profile = await ProfileHelper.getCurrentProfile();
        if (profile == null || isCancelled) {
          if (!isCancelled) controller.add([]);
          return;
        }
        
        // Initial load
        final tasks = await getAllTasks();
        if (isCancelled) return;
        controller.add(tasks);
        
        // Subscribe to changes
        channel = _client
            .channel('tasks:${profile.coupleId}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'tasks',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'couple_id',
                value: profile.coupleId,
              ),
              callback: (payload) async {
                if (isCancelled) return;
                try {
                  debugPrint('Real-time event received: ${payload.eventType}');
                  // Refresh the full list on any change
                  final updatedTasks = await getAllTasks();
                  if (!isCancelled) {
                    controller.add(updatedTasks);
                  }
                } catch (e) {
                  debugPrint('TaskService.watchTasks callback error: $e');
                }
              },
            )
            .subscribe((status, error) {
              if (error != null) {
                debugPrint('Real-time subscription error: $error');
              } else {
                debugPrint('Real-time subscription status: $status');
              }
            });
      } catch (e) {
        debugPrint('TaskService.watchTasks initialize error: $e');
        if (!isCancelled) {
          controller.addError(e);
        }
      }
    }
    
    initialize();
    
    controller.onCancel = () {
      isCancelled = true;
      channel?.unsubscribe();
      controller.close();
    };
    
    return controller.stream;
  }

  /// Get task by ID
  static Future<Task?> getTaskById(String taskId) async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('id', taskId)
          .maybeSingle();
      
      if (response == null) return null;
      return Task.fromJson(response);
    } catch (e) {
      debugPrint('TaskService.getTaskById error: $e');
      return null;
    }
  }
}
