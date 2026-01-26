import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/models.dart';

/// Service for authentication operations
/// 
/// Handles:
/// - Email/password signup and login
/// - Session management
/// - Logout
class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Sign up with email and password
  /// 
  /// Returns the new user if successful
  /// Throws on error (e.g., email already exists)
  static Future<User> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (displayName != null) 'display_name': displayName,
      },
    );
    
    if (response.user == null) {
      throw Exception('Failed to create account');
    }
    
    return response.user!;
  }

  /// Sign in with email and password
  /// 
  /// Returns the authenticated user if successful
  /// Throws on error (e.g., invalid credentials)
  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw Exception('Invalid email or password');
    }
    
    return response.user!;
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get the current user's profile
  /// 
  /// Returns null if user is not authenticated or profile doesn't exist
  static Future<Profile?> getCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    
    try {
      final response = await _client
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

  /// Update the current user's profile
  static Future<Profile> updateProfile({
    String? displayName,
    String? timezone,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (timezone != null) updates['timezone'] = timezone;
    
    final response = await _client
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .single();
    
    return Profile.fromJson(response);
  }

  /// Check if a user has a profile (has completed setup)
  static Future<bool> hasProfile() async {
    final profile = await getCurrentProfile();
    return profile != null;
  }

  /// Check if user's couple has a partner linked
  static Future<bool> hasPartner() async {
    final profile = await getCurrentProfile();
    if (profile == null) return false;
    
    // Count profiles in the same couple
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('couple_id', profile.coupleId);
    
    return (response as List).length >= 2;
  }

  /// Get the partner's profile
  /// 
  /// Returns null if no partner is linked yet
  static Future<Profile?> getPartnerProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    
    final myProfile = await getCurrentProfile();
    if (myProfile == null) return null;
    
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('couple_id', myProfile.coupleId)
          .neq('id', user.id)
          .maybeSingle();
      
      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange => 
      SupabaseService.onAuthStateChange;

  /// Get current authenticated user
  static User? get currentUser => SupabaseService.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => SupabaseService.isAuthenticated;
}
