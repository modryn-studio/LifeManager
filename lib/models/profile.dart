/// Profile model representing a user in the LifeManager system
/// 
/// Each profile belongs to exactly one couple
/// Partners can see each other's tasks in real-time
class Profile {
  final String id;
  final String coupleId;
  final String? displayName;
  final String timezone;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.coupleId,
    this.displayName,
    this.timezone = 'America/Chicago',
    required this.createdAt,
  });

  /// Create Profile from database row
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      displayName: json['display_name'] as String?,
      timezone: json['timezone'] as String? ?? 'America/Chicago',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to database-compatible map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'display_name': displayName,
      'timezone': timezone,
    };
  }

  /// Create a copy with updated fields
  Profile copyWith({
    String? id,
    String? coupleId,
    String? displayName,
    String? timezone,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get display name or fallback to "Partner"
  String get nameOrFallback => displayName ?? 'Partner';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
