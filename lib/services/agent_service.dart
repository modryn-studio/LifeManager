import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';
import '../core/notification_service.dart';
import '../core/profile_helper.dart';
import '../core/date_utils.dart' as app_date;

/// Service for checking and displaying agent messages
/// 
/// Since MVP uses local notifications (no FCM), this service
/// polls for pending reminders on app open
class AgentService {
  /// Check for pending reminders and show notifications
  /// 
  /// Called when app opens or resumes
  /// Shows local notifications for any unacknowledged reminders
  static Future<void> checkForPendingReminders() async {
    try {
      final profile = await ProfileHelper.getCurrentProfile();
      if (profile == null) return;
      
      // Get unacknowledged reminders from last 24 hours
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      
      final response = await SupabaseService.client
          .from('reminders_log')
          .select()
          .eq('sent_to', profile.id)
          .filter('acknowledged_at', 'is', null)
          .gte('sent_at', yesterday.toIso8601String())
          .order('sent_at', ascending: false);
      
      final reminders = response as List;
      
      // Show notification for most recent unacknowledged reminder
      if (reminders.isNotEmpty) {
        final latest = reminders.first as Map<String, dynamic>;
        final reminderType = latest['reminder_type'] as String?;
        final message = latest['message'] as String?;
        
        if (message != null && reminderType != null) {
          if (reminderType == 'morning_digest') {
            await NotificationService.showMorningDigest(message: message);
          } else if (reminderType == 'followup') {
            await NotificationService.showFollowUpReminder(message: message);
          }
        }
      }
    } catch (e) {
      debugPrint('AgentService.checkForPendingReminders error: $e');
    }
  }

  /// Acknowledge a reminder (mark as seen)
  static Future<void> acknowledgeReminder(String reminderId) async {
    try {
      await SupabaseService.client
          .from('reminders_log')
          .update({'acknowledged_at': DateTime.now().toIso8601String()})
          .eq('id', reminderId);
    } catch (e) {
      debugPrint('AgentService.acknowledgeReminder error: $e');
    }
  }

  /// Acknowledge all reminders for the current user
  static Future<void> acknowledgeAllReminders() async {
    try {
      final profile = await ProfileHelper.getCurrentProfile();
      if (profile == null) return;
      
      await SupabaseService.client
          .from('reminders_log')
          .update({'acknowledged_at': DateTime.now().toIso8601String()})
          .eq('sent_to', profile.id)
          .filter('acknowledged_at', 'is', null);
    } catch (e) {
      debugPrint('AgentService.acknowledgeAllReminders error: $e');
    }
  }

  /// Get latest morning digest message (if any)
  static Future<String?> getLatestMorningDigest() async {
    try {
      final profile = await ProfileHelper.getCurrentProfile();
      if (profile == null) return null;
      
      final todayStr = app_date.DateUtils.todayForDb;
      
      final response = await SupabaseService.client
          .from('reminders_log')
          .select()
          .eq('couple_id', profile.coupleId)
          .eq('reminder_type', 'morning_digest')
          .gte('sent_at', todayStr)
          .order('sent_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return null;
      return response['message'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Manually trigger pattern analysis (for testing)
  /// 
  /// In production, this runs weekly via Edge Function scheduler
  static Future<void> triggerPatternAnalysis() async {
    try {
      await SupabaseService.client.functions.invoke('pattern-analyzer');
    } catch (e) {
      debugPrint('AgentService.triggerPatternAnalysis error: $e');
    }
  }
}
