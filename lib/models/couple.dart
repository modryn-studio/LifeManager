/// Couple model representing a linked pair of users
/// 
/// Couples share:
/// - All tasks (visible to both partners)
/// - AI agent insights
/// - Completion history
class Couple {
  final String id;
  final String? partnerEmail;
  final DateTime createdAt;

  const Couple({
    required this.id,
    this.partnerEmail,
    required this.createdAt,
  });

  /// Create Couple from database row
  factory Couple.fromJson(Map<String, dynamic> json) {
    return Couple(
      id: json['id'] as String,
      partnerEmail: json['partner_email'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Check if waiting for partner to join
  bool get isWaitingForPartner => partnerEmail != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Couple &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
