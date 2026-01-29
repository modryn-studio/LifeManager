import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/profile_helper.dart';
import '../models/models.dart';

/// Service for AI-detected task patterns
/// 
/// Handles:
/// - Fetching pattern suggestions
/// - Accepting patterns (creating recurring tasks)
/// - Dismissing patterns
class PatternService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Get pending pattern suggestions for the couple
  /// 
  /// Returns patterns that haven't been accepted or dismissed
  static Future<List<TaskPattern>> getPendingPatterns() async {
    final profile = await ProfileHelper.getCurrentProfile();
    if (profile == null) return [];
    
    final response = await _client
        .from('task_patterns')
        .select()
        .eq('couple_id', profile.coupleId)
        .isFilter('accepted', null) // NULL = pending (not accepted or dismissed)
        .gte('confidence', 0.80) // Only show high-confidence patterns
        .order('confidence', ascending: false)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => TaskPattern.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Accept a pattern and create a recurring task
  /// 
  /// Returns the created task
  static Future<Task> acceptPattern(TaskPattern pattern) async {
    final user = SupabaseService.currentUser;
    final profile = await ProfileHelper.getCurrentProfile();
    
    if (user == null || profile == null) {
      throw Exception('Not authenticated');
    }
    
    // Mark pattern as accepted
    await _client
        .from('task_patterns')
        .update({'accepted': true})
        .eq('id', pattern.id);
    
    // Create the recurring task
    final taskResponse = await _client
        .from('tasks')
        .insert({
          'couple_id': profile.coupleId,
          'created_by': user.id,
          'title': pattern.patternTitle,
          'recurrence_pattern': pattern.suggestedRecurrence,
          'recurrence_interval_days': pattern.suggestedIntervalDays,
          // No due date initially - will be set based on pattern
        })
        .select()
        .single();
    
    return Task.fromJson(taskResponse);
  }

  /// Dismiss a pattern suggestion
  static Future<void> dismissPattern(String patternId) async {
    await _client
        .from('task_patterns')
        .update({'accepted': false}) // false = rejected/dismissed
        .eq('id', patternId);
  }

  /// Get all patterns for the couple (including accepted/dismissed)
  static Future<List<TaskPattern>> getAllPatterns() async {
    final profile = await ProfileHelper.getCurrentProfile();
    if (profile == null) return [];
    
    final response = await _client
        .from('task_patterns')
        .select()
        .eq('couple_id', profile.coupleId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => TaskPattern.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get count of pending pattern suggestions
  /// 
  /// Note: Returns 0 until pattern analyzer is fully implemented.
  /// The pattern analyzer Edge Function needs to be deployed and 
  /// task_patterns table populated before this will return non-zero.
  static Future<int> getPendingPatternCount() async {
    try {
      final profile = await ProfileHelper.getCurrentProfile();
      if (profile == null) return 0;
      
      final response = await _client
          .from('task_patterns')
          .select('id')
          .eq('couple_id', profile.coupleId)
          .isFilter('accepted', null)
          .gte('confidence', 0.80);
      
      return (response as List).length;
    } catch (e) {
      debugPrint('PatternService.getPendingPatternCount error: $e');
      return 0;
    }
  }
}
