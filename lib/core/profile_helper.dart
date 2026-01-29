import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'supabase_client.dart';

/// Shared helper for profile operations
/// 
/// Centralizes profile fetching to avoid code duplication
/// across services
class ProfileHelper {
  /// Get the current user's profile
  /// 
  /// Returns null if user is not authenticated or profile doesn't exist
  static Future<Profile?> getCurrentProfile() async {
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
      debugPrint('ProfileHelper.getCurrentProfile error: $e');
      return null;
    }
  }
}
