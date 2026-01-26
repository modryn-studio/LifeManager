import 'package:flutter/material.dart';

/// Spacing constants for consistent layout
/// 
/// Design Philosophy:
/// - Generous whitespace (24-32px between elements)
/// - Never cramped or cluttered
/// - Each element has breathing room
class AppSpacing {
  // Base spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Screen margins - generous padding
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  
  // Horizontal screen padding only
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: 24.0);
  
  // Card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  
  // Between cards
  static const double cardSpacing = 12.0;
  
  // Between sections
  static const double sectionSpacing = 32.0;
  
  // Form field spacing
  static const double fieldSpacing = 16.0;
}

/// Border radius constants for consistent rounded corners
/// 
/// Design Philosophy:
/// - Soft, rounded corners everywhere
/// - No sharp edges
class AppRadius {
  // Base radius values
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  
  // Component-specific radii
  static BorderRadius card = BorderRadius.circular(16);
  static BorderRadius button = BorderRadius.circular(12);
  static BorderRadius input = BorderRadius.circular(12);
  static BorderRadius chip = BorderRadius.circular(8);
  static BorderRadius toast = BorderRadius.circular(12);
}

/// Animation timing constants
/// 
/// Design Philosophy:
/// - Gentle, organic animations
/// - Use ease-in-out for natural feel
/// - Never jarring or aggressive
class AppDurations {
  /// Tap feedback
  static const Duration tapFeedback = Duration(milliseconds: 200);
  
  /// Card transitions, checkmark fade-in
  static const Duration cardTransition = Duration(milliseconds: 400);
  
  /// Page transitions
  static const Duration pageTransition = Duration(milliseconds: 600);
  
  /// Toast display duration
  static const Duration toastDuration = Duration(seconds: 3);
  
  /// Pulsing animation loop
  static const Duration pulseLoop = Duration(milliseconds: 1000);
}

/// Category icons and colors
class CategoryConfig {
  static const Map<String, IconData> icons = {
    'household': Icons.home_rounded,
    'pet': Icons.pets_rounded,
    'health': Icons.favorite_rounded,
    'personal': Icons.person_rounded,
    'sentimental': Icons.auto_awesome_rounded,
  };
  
  static const Map<String, String> emojis = {
    'household': '🏠',
    'pet': '🐾',
    'health': '❤️',
    'personal': '👤',
    'sentimental': '✨',
  };
  
  static const Map<String, String> labels = {
    'household': 'Household',
    'pet': 'Pet',
    'health': 'Health',
    'personal': 'Personal',
    'sentimental': 'Sentimental',
  };
  
  static IconData getIcon(String? category) {
    return icons[category] ?? Icons.check_circle_outline_rounded;
  }
  
  static String getEmoji(String? category) {
    return emojis[category] ?? '✓';
  }
  
  static String getLabel(String? category) {
    return labels[category] ?? 'General';
  }
}

/// Recurrence pattern options
class RecurrenceConfig {
  static const List<String> patterns = ['daily', 'weekly', 'monthly', 'custom'];
  
  static const Map<String, String> labels = {
    'daily': 'Daily',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
    'custom': 'Custom Interval',
  };
  
  static String getLabel(String? pattern) {
    return labels[pattern] ?? 'One-time';
  }
}
