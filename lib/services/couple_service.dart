import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/models.dart';

/// Service for couple pairing operations
/// 
/// Handles:
/// - Creating new couples
/// - Email-based partner lookup
/// - Linking partners together
class CoupleService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Create a new couple and profile for the current user
  /// 
  /// [partnerEmail] - Optional email to invite partner (will be linked when they join)
  /// [displayName] - User's display name
  /// 
  /// Returns the created profile
  static Future<Profile> createCoupleAndProfile({
    String? partnerEmail,
    String? displayName,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    
    // Create the couple first
    final coupleResponse = await _client
        .from('couples')
        .insert({
          if (partnerEmail != null && partnerEmail.isNotEmpty) 
            'partner_email': partnerEmail.toLowerCase().trim(),
        })
        .select()
        .single();
    
    final couple = Couple.fromJson(coupleResponse);
    
    // Create the profile linked to this couple
    final profileResponse = await _client
        .from('profiles')
        .insert({
          'id': user.id,
          'couple_id': couple.id,
          'display_name': displayName,
          'timezone': 'America/Chicago',
        })
        .select()
        .single();
    
    return Profile.fromJson(profileResponse);
  }

  /// Try to join an existing couple via email lookup
  /// 
  /// Looks for a couple where partner_email matches current user's email
  /// If found, creates a profile and clears the partner_email
  /// 
  /// Returns the profile if joined, null if no matching couple
  static Future<Profile?> tryJoinExistingCouple({
    String? displayName,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    
    final userEmail = user.email?.toLowerCase().trim();
    if (userEmail == null) return null;
    
    // Look for a couple waiting for this email
    final coupleResponse = await _client
        .from('couples')
        .select()
        .eq('partner_email', userEmail)
        .maybeSingle();
    
    if (coupleResponse == null) return null;
    
    final couple = Couple.fromJson(coupleResponse);
    
    // Create profile for this couple
    final profileResponse = await _client
        .from('profiles')
        .insert({
          'id': user.id,
          'couple_id': couple.id,
          'display_name': displayName,
          'timezone': 'America/Chicago',
        })
        .select()
        .single();
    
    // Clear the partner_email (they've joined!)
    // Note: This is also handled by the link_pending_partner trigger
    await _client
        .from('couples')
        .update({'partner_email': null})
        .eq('id', couple.id);
    
    return Profile.fromJson(profileResponse);
  }

  /// Get the current user's couple
  static Future<Couple?> getCurrentCouple() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    
    try {
      final response = await _client
          .from('profiles')
          .select('couple_id, couples(*)')
          .eq('id', user.id)
          .single();
      
      if (response['couples'] == null) return null;
      return Couple.fromJson(response['couples'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Check if partner email is valid format (client-side validation)
  static bool isValidEmailFormat(String email) {
    // Basic email regex for format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Get pending partner email (if any)
  static Future<String?> getPendingPartnerEmail() async {
    final couple = await getCurrentCouple();
    return couple?.partnerEmail;
  }

  /// Check if couple is fully linked (has 2 members)
  static Future<bool> isCoupleFullyLinked() async {
    final profile = await _getProfile();
    if (profile == null) return false;
    
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('couple_id', profile.coupleId);
    
    return (response as List).length >= 2;
  }

  static Future<Profile?> _getProfile() async {
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
}
