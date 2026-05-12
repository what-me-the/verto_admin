class UserProfile {
  final String userId;
  final String fullName;
  final String? email;
  final String? city;
  final bool isStudent;
  final String? universityName;
  final int translationCount;
  final int approvedCount;
  final int pendingCount;
  final int rejectedCount;
  final int skippedCount;
  final DateTime createdAt;

  /// Last sign-in. Populated from `last_sign_in_at` or `last_sign_in` column
  /// on the `profiles` table. Null when the column is absent/unpopulated.
  final DateTime? lastSignInAt;

  UserProfile({
    required this.userId,
    required this.fullName,
    this.email,
    this.city,
    required this.isStudent,
    this.universityName,
    required this.translationCount,
    required this.approvedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.skippedCount,
    required this.createdAt,
    this.lastSignInAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final uniData = json['universities'] as Map<String, dynamic>?;

    // translation_attempts comes as a nested list of {status} objects
    final attempts = json['translation_attempts'] as List? ?? [];
    final totalCount = attempts.length;
    final approvedCount =
        attempts.where((a) => a['status'] == 'approved').length;
    final pendingCount =
        attempts.where((a) => a['status'] == 'pending').length;
    final rejectedCount =
        attempts.where((a) => a['status'] == 'rejected').length;
    final skippedCount =
        (json['skipped_sentences'] as List? ?? []).length;

    // Try last_sign_in_at first (standard Supabase column name),
    // then fall back to last_sign_in, then null.
    DateTime? lastSignIn;
    try {
      final raw = json['last_sign_in_at'] ?? json['last_sign_in'];
      if (raw != null && raw is String && raw.isNotEmpty) {
        lastSignIn = DateTime.parse(raw).toLocal();
      }
    } catch (_) {
      lastSignIn = null;
    }

    return UserProfile(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      city: json['city'] as String?,
      isStudent: json['is_student'] as bool? ?? false,
      universityName: uniData?['name'] as String?,
      translationCount: totalCount,
      approvedCount: approvedCount,
      pendingCount: pendingCount,
      rejectedCount: rejectedCount,
      skippedCount: skippedCount,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      lastSignInAt: lastSignIn,
    );
  }
}
