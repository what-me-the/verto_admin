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
  /// True when this attempt has at least one review_task assigned to a reviewer.
  final bool hasReviewTask;

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
    this.hasReviewTask = false,
  });

  factory TranslationAttempt.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final sentenceData = json['sentences'] as Map<String, dynamic>?;

    final reviewTasks = json['review_tasks'] as List? ?? [];
    final hasTask = reviewTasks.isNotEmpty;

    Map<String, dynamic>? reviewData;
    if (hasTask) {
      final task = reviewTasks.first as Map<String, dynamic>;
      final reviews = task['reviews'] as List? ?? [];
      if (reviews.isNotEmpty) {
        reviewData = reviews.first as Map<String, dynamic>;
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
      reviewerName: null,
      reviewRating: reviewData?['rating'],
      reviewNotes: reviewData?['notes'],
      editedUrdu: null,
      editedRoman: null,
      hasReviewTask: hasTask,
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
  /// Translations with status = 'pending' (submitted, not yet assigned to a reviewer)
  final int submitted;

  /// Translations with status = 'assigned' (currently under review)
  final int inReview;

  final int approved;
  final int rejected;
  final int skipped;

  /// Legacy getter — combined submitted + inReview
  int get totalPending => submitted + inReview;

  ModerationStats({
    required this.submitted,
    required this.inReview,
    required this.approved,
    required this.rejected,
    required this.skipped,
  });

  factory ModerationStats.empty() {
    return ModerationStats(
      submitted: 0,
      inReview: 0,
      approved: 0,
      rejected: 0,
      skipped: 0,
    );
  }
}
