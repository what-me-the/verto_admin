import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/supabase_service.dart';
import 'moderation_model.dart';

/// Moderation data repository.
/// DB CHECK constraint on translation_attempts.status allows:
///   pending | reviewed | approved | rejected
class ModerationRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  // ---------------------------------------------------------------------------
  // Diagnostic — call once on startup to verify data visibility
  // ---------------------------------------------------------------------------
  Future<void> logDistinctStatuses() async {
    try {
      // Log who is currently authenticated
      final user = _client.auth.currentUser;
      debugPrint('ModerationRepository: current user = ${user?.id ?? "UNAUTHENTICATED"}');

      // Total row count (no filter) — if 0 and you know data exists,
      // RLS is blocking reads. Run this in Supabase SQL Editor:
      //
      //   CREATE POLICY "admins_read_all_attempts"
      //     ON translation_attempts FOR SELECT
      //     USING (EXISTS (
      //       SELECT 1 FROM admin_users
      //       WHERE user_id = auth.uid() AND is_active = true
      //     ));
      //
      //   -- Also enable realtime if not already done:
      //   ALTER PUBLICATION supabase_realtime ADD TABLE translation_attempts;
      //   ALTER PUBLICATION supabase_realtime ADD TABLE skipped_sentences;
      //   ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

      final countResp = await _client
          .from('translation_attempts')
          .count(CountOption.exact);
      debugPrint('ModerationRepository: total visible rows = $countResp');

      final response = await _client
          .from('translation_attempts')
          .select('status')
          .limit(500);
      final statuses = (response as List)
          .map((e) => e['status']?.toString() ?? 'null')
          .toSet()
          .toList()
        ..sort();
      debugPrint(
        'ModerationRepository: distinct statuses → ${statuses.isEmpty ? "(no rows visible — check RLS policies)" : statuses.join(", ")}',
      );
    } catch (e) {
      debugPrint('ModerationRepository: diagnostic error — $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  static const String _joinSelect = '''
    *,
    profiles(full_name),
    sentences(sentence_id, khuwar_text),
    review_tasks(
      reviews(rating, notes)
    )
  ''';

  Future<List<TranslationAttempt>> _fetchByStatus(String status) async {
    try {
      final response = await _client
          .from('translation_attempts')
          .select(_joinSelect)
          .eq('status', status)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((e) => TranslationAttempt.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching translations [status=$status]: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Per-status fetch methods
  // ---------------------------------------------------------------------------

  /// Fetches all `pending` and `reviewed` rows in one query.
  /// The caller splits them into Submitted vs In-Review using [hasReviewTask].
  ///
  /// • Submitted  = status == 'pending'  && hasReviewTask == false
  /// • In Review  = status == 'pending'  && hasReviewTask == true
  ///              OR status == 'reviewed' (review completed, awaiting admin)
  Future<List<TranslationAttempt>> fetchPendingAndReviewedTranslations() async {
    try {
      final response = await _client
          .from('translation_attempts')
          .select(_joinSelect)
          .inFilter('status', ['pending', 'reviewed'])
          .order('timestamp', ascending: false);

      final list = (response as List)
          .map((e) => TranslationAttempt.fromJson(e))
          .toList();
      debugPrint(
        'ModerationRepository: fetchPendingAndReviewed → ${list.length} rows '
        '(pending=${list.where((t) => t.status == "pending" && !t.hasReviewTask).length} submitted, '
        '${list.where((t) => t.status == "pending" && t.hasReviewTask).length}+${list.where((t) => t.status == "reviewed").length} in-review)',
      );
      return list;
    } catch (e) {
      debugPrint('Error fetching pending+reviewed translations: $e');
      rethrow;
    }
  }

  // Kept for backward compat — delegates to fetchPendingAndReviewedTranslations
  Future<List<TranslationAttempt>> fetchSubmittedTranslations() async {
    final all = await fetchPendingAndReviewedTranslations();
    return all.where((t) => t.status == 'pending' && !t.hasReviewTask).toList();
  }

  Future<List<TranslationAttempt>> fetchInReviewTranslations() async {
    final all = await fetchPendingAndReviewedTranslations();
    return all
        .where((t) =>
            t.status == 'reviewed' ||
            (t.status == 'pending' && t.hasReviewTask))
        .toList();
  }

  /// Approved translations (status = 'approved')
  Future<List<TranslationAttempt>> fetchAcceptedTranslations() =>
      _fetchByStatus('approved');

  /// Rejected translations (status = 'rejected')
  Future<List<TranslationAttempt>> fetchRejectedTranslations() =>
      _fetchByStatus('rejected');

  /// Legacy — fetches both pending + assigned together
  Future<List<TranslationAttempt>> fetchPendingTranslations() async {
    try {
      final response = await _client
          .from('translation_attempts')
          .select(_joinSelect)
          .inFilter('status', ['pending', 'reviewed'])
          .order('timestamp', ascending: false);

      return (response as List)
          .map((e) => TranslationAttempt.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending translations: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Skipped sentences
  // ---------------------------------------------------------------------------
  Future<List<SkippedSentence>> fetchSkippedTranslations() async {
    try {
      final response = await _client
          .from('skipped_sentences')
          .select('''
            *,
            profiles(full_name),
            sentences(khuwar_text)
          ''')
          .order('skipped_at', ascending: false);

      return (response as List)
          .map((e) => SkippedSentence.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching skipped translations: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Stats — parallel count queries for every status
  // ---------------------------------------------------------------------------
  Future<ModerationStats> fetchModerationStats() async {
    try {
      final counts = await Future.wait([
        _client
            .from('translation_attempts')
            .count(CountOption.exact)
            .eq('status', 'pending'),
        _client
            .from('translation_attempts')
            .count(CountOption.exact)
            .eq('status', 'reviewed'),
        _client
            .from('translation_attempts')
            .count(CountOption.exact)
            .eq('status', 'approved'),
        _client
            .from('translation_attempts')
            .count(CountOption.exact)
            .eq('status', 'rejected'),
        _client.from('skipped_sentences').count(CountOption.exact),
      ]);

      return ModerationStats(
        submitted: counts[0],
        inReview: counts[1],
        approved: counts[2],
        rejected: counts[3],
        skipped: counts[4],
      );
    } catch (e) {
      debugPrint('Error fetching moderation stats: \$e');
      return ModerationStats.empty();
    }
  }

  /// Lightweight stat fetch — only counts for the terminal statuses
  /// (approved / rejected / skipped). submitted + inReview are derived
  /// from the already-fetched in-memory lists so no extra DB round-trips.
  Future<({int approved, int rejected, int skipped})> fetchTerminalStats() async {
    try {
      final counts = await Future.wait([
        _client
            .from('translation_attempts')
            .count(CountOption.exact)
            .eq('status', 'approved'),
        _client
            .from('translation_attempts')
            .count(CountOption.exact)
            .eq('status', 'rejected'),
        _client.from('skipped_sentences').count(CountOption.exact),
      ]);
      return (approved: counts[0], rejected: counts[1], skipped: counts[2]);
    } catch (e) {
      debugPrint('Error fetching terminal stats: $e');
      return (approved: 0, rejected: 0, skipped: 0);
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> approveTranslation(String attemptId) async {
    try {
      await _client
          .from('translation_attempts')
          .update({'status': 'approved'})
          .eq('attempt_id', attemptId);
    } catch (e) {
      debugPrint('Error approving translation: $e');
      rethrow;
    }
  }

  Future<void> rejectTranslation(String attemptId) async {
    try {
      await _client
          .from('translation_attempts')
          .update({'status': 'rejected'})
          .eq('attempt_id', attemptId);
    } catch (e) {
      debugPrint('Error rejecting translation: $e');
      rethrow;
    }
  }

  Future<void> skipTranslation(
    String attemptId,
    String userId,
    String sentenceId,
    String reason,
  ) async {
    try {
      await _client.from('skipped_sentences').insert({
        'user_id': userId,
        'sentence_id': sentenceId,
        'reason': reason,
      });

      await _client
          .from('translation_attempts')
          .update({'status': 'rejected'})
          .eq('attempt_id', attemptId);

      await _client
          .from('sentences')
          .update({'assigned_to': null, 'is_translated': false})
          .eq('sentence_id', sentenceId);
    } catch (e) {
      debugPrint('Error skipping translation: $e');
      rethrow;
    }
  }

  Future<void> unassignSkipped(String skipId, String sentenceId) async {
    try {
      await _client.from('skipped_sentences').delete().eq('id', skipId);
      // Make sentence available again
      await _client
          .from('sentences')
          .update({'assigned_to': null})
          .eq('sentence_id', sentenceId);
    } catch (e) {
      debugPrint('Error unassigning skipped: $e');
      rethrow;
    }
  }
}
