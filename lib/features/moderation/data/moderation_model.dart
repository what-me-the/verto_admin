class TranslationAttempt {
  final String id;
  final String userId;
  final String userName;
  final String sentenceId;
  final String sentence;
  final String urduTranslation;
  final String romanTranslation;
  final String status;
  final DateTime submittedAt;
  final String? reviewerName;
  final int? reviewRating;
  final String? reviewNotes;
  final String? editedUrdu;
  final String? editedRoman;

  TranslationAttempt({
    required this.id,
    required this.userId,
    required this.userName,
    required this.sentenceId,
    required this.sentence,
    required this.urduTranslation,
    required this.romanTranslation,
    required this.status,
    required this.submittedAt,
    this.reviewerName,
    this.reviewRating,
    this.reviewNotes,
    this.editedUrdu,
    this.editedRoman,
  });

  factory TranslationAttempt.fromJson(Map<String, dynamic> json) {
    // Handle nested joins from Supabase
    // Expecting:
    // *, profiles(full_name), sentences(khuwar_text),
    // reviews(rating, notes, urdu_edited, roman_chitrali_edited) -- accessed via review_tasks usually,
    // but for pending list we might fetch directly or via task.

    // For simplicity in joining, we'll assume the repository flattens or we parse the nested structure.

    final profile = json['profiles'] as Map<String, dynamic>?;
    final sentenceData = json['sentences'] as Map<String, dynamic>?;

    // Attempt to find review data. It might be direct join or nested array.
    // Ideally we join review_tasks -> reviews.
    // For 'pending', review might not exist yet or be in progress.

    Map<String, dynamic>? reviewData;
    // Check if review_tasks is present and has reviews
    if (json['review_tasks'] != null &&
        (json['review_tasks'] as List).isNotEmpty) {
      final tasks = json['review_tasks'] as List;
      if (tasks.isNotEmpty) {
        final task = tasks.first;
        if (task['reviews'] != null && (task['reviews'] as List).isNotEmpty) {
          reviewData = (task['reviews'] as List).first;
        }
      }
    }

    return TranslationAttempt(
      id: json['attempt_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: profile?['full_name'] ?? 'Unknown User',
      sentenceId: sentenceData?['sentence_id'] ?? '',
      sentence: sentenceData?['khuwar_text'] ?? 'Unknown Sentence',
      urduTranslation: json['urdu_translation'] ?? '',
      romanTranslation: json['roman_chitrali_translation'] ?? '',
      status: json['status'] ?? 'pending',
      submittedAt: DateTime.parse(json['timestamp']).toLocal(),
      reviewerName:
          null, // Would need another join on review_tasks -> reviewer_id -> profile
      reviewRating: reviewData?['rating'],
      reviewNotes: reviewData?['notes'],
      editedUrdu: reviewData?['urdu_edited'],
      editedRoman: reviewData?['roman_chitrali_edited'],
    );
  }
}

class SkippedSentence {
  final String id;
  final String userId;
  final String userName;
  final String sentenceId;
  final String sentenceText;
  final String? reason;
  final DateTime skippedAt;

  SkippedSentence({
    required this.id,
    required this.userId,
    required this.userName,
    required this.sentenceId,
    required this.sentenceText,
    this.reason,
    required this.skippedAt,
  });

  factory SkippedSentence.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final sentence = json['sentences'] as Map<String, dynamic>?;

    return SkippedSentence(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: profile?['full_name'] ?? 'Unknown User',
      sentenceId: json['sentence_id'] ?? '',
      sentenceText: sentence?['khuwar_text'] ?? 'Unknown Sentence',
      reason: json['reason'],
      skippedAt: DateTime.parse(json['skipped_at']).toLocal(),
    );
  }
}

class ModerationStats {
  final int totalPending;
  final int approved;
  final int rejected;
  final int skipped;
  final int
  reassigned; // This might be hard to track without logs, maybe fallback to 0

  ModerationStats({
    required this.totalPending,
    required this.approved,
    required this.rejected,
    required this.skipped,
    this.reassigned = 0,
  });

  factory ModerationStats.empty() {
    return ModerationStats(
      totalPending: 0,
      approved: 0,
      rejected: 0,
      skipped: 0,
    );
  }
}
