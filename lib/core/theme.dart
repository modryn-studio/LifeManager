import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LifeManager Theme
/// 
/// "Invisible magic for life together"
/// 
/// Design Philosophy:
/// - Warm, intimate, respectful
/// - Sunday morning coffee vibe
/// - Feels like a caring friend, not a task manager
class AppTheme {
  // =====================================================
  // COLORS - Soft & Grounded
  // =====================================================
  
  /// Warm Cream - Background, calm uncluttered space
  static const Color warmCream = Color(0xFFFAF7F2);
  
  /// Soft Sage - Primary actions, growth, harmony
  static const Color softSage = Color(0xFFA8B5A0);
  
  /// Muted Coral - Warmth, connection, love highlights
  static const Color mutedCoral = Color(0xFFE8B4A0);
  
  /// Gentle Green - Success, completion (never harsh)
  static const Color gentleGreen = Color(0xFFC8D5B9);
  
  /// Warm Peach - Gentle alerts and suggestions (never alarming)
  static const Color warmPeach = Color(0xFFF4C6A6);
  
  /// Charcoal - Dark text
  static const Color charcoal = Color(0xFF3D3D3D);
  
  /// Warm Gray - Light text, captions
  static const Color warmGray = Color(0xFF8A8A8A);
  
  /// Card border color
  static const Color cardBorder = Color(0xFFE8E8E8);
  
  /// Toast success background
  static const Color toastSuccess = Color(0xFFF0F7EB);
  
  /// Suggestion card background (warm peach tint)
  static const Color suggestionBackground = Color(0xFFFFF9F5);

  // =====================================================
  // TYPOGRAPHY
  // =====================================================
  
  /// Handwritten font for special moments, headers
  /// Feels like: Personal note from your partner
  static TextStyle handwritten({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = charcoal,
  }) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
  
  /// Sans-serif for functional UI, body text
  /// Feels: Efficient but warm
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = charcoal,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // =====================================================
  // THEME DATA
  // =====================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: warmCream,
      primaryColor: softSage,
      
      colorScheme: const ColorScheme.light(
        primary: softSage,
        secondary: mutedCoral,
        surface: Colors.white,
        error: warmPeach, // Never harsh red!
        onPrimary: Colors.white,
        onSecondary: charcoal,
        onSurface: charcoal,
        onError: charcoal,
      ),
      
      // Card Theme - Soft and breathing
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      
      // Elevated Button Theme - Primary actions
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softSage,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Text Button Theme - Secondary actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: warmGray, width: 1),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: warmGray, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softSage, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: warmPeach, width: 1),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: warmGray,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: charcoal,
        ),
      ),
      
      // App Bar Theme - Minimal, warm
      appBarTheme: AppBarTheme(
        backgroundColor: warmCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.caveat(
          fontSize: 28,
          fontWeight: FontWeight.normal,
          color: charcoal,
        ),
        iconTheme: const IconThemeData(color: charcoal),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: softSage,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return gentleGreen;
          }
          return Colors.white;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: warmGray, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: toastSuccess,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: charcoal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.caveat(
          fontSize: 24,
          color: charcoal,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: charcoal,
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 24,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: softSage,
      ),
    );
  }
}
