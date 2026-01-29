/// Couple model representing a linked pair of users
/// 
/// Couples share:
/// - All tasks (visible to both partners)
/// - AI agent insights
/// - Completion history
class Couple {
  final String id;
  final String householdName;
  final String timezone;
  final DateTime createdAt;

  const Couple({
    required this.id,
    required this.householdName,
    this.timezone = 'America/Chicago',
    required this.createdAt,
  });

  /// Create Couple from database row
  factory Couple.fromJson(Map<String, dynamic> json) {
    return Couple(
      id: json['id'] as String,
      householdName: json['household_name'] as String,
      timezone: json['timezone'] as String? ?? 'America/Chicago',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Couple &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
