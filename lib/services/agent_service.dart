import '../core/supabase_client.dart';
import '../core/notification_service.dart';
import '../models/models.dart';

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
      final profile = await _getProfile();
      if (profile == null) return;
      
      // Get unacknowledged reminders from last 24 hours
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      
      final response = await SupabaseService.client
          .from('reminders_log')
          .select()
          .eq('couple_id', profile.coupleId)
          .is_('acknowledged_at', null)
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
      // Silently fail - not critical
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
      // Silently fail
    }
  }

  /// Acknowledge all reminders for the current couple
  static Future<void> acknowledgeAllReminders() async {
    try {
      final profile = await _getProfile();
      if (profile == null) return;
      
      await SupabaseService.client
          .from('reminders_log')
          .update({'acknowledged_at': DateTime.now().toIso8601String()})
          .eq('couple_id', profile.coupleId)
          .is_('acknowledged_at', null);
    } catch (e) {
      // Silently fail
    }
  }

  /// Get latest morning digest message (if any)
  static Future<String?> getLatestMorningDigest() async {
    try {
      final profile = await _getProfile();
      if (profile == null) return null;
      
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
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
      // Pattern analysis can fail silently
    }
  }

  static Future<Profile?> _getProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
