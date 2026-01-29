/// Date utility functions for consistent date formatting
/// 
/// Centralizes date formatting to avoid code duplication
class DateUtils {
  /// Format a DateTime to YYYY-MM-DD string for database queries
  /// 
  /// Example: DateTime(2026, 1, 29) -> '2026-01-29'
  static String formatDateForDb(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Get today's date formatted for database queries
  static String get todayForDb => formatDateForDb(DateTime.now());
  
  /// Get a DateTime representing the start of today (midnight)
  static DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
