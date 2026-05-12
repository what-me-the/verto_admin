import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/supabase_service.dart';
import 'moderation_model.dart';

class ModerationRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  // ---------------------------------------------------------------------------
  // Private helper — fetch translation_attempts by a single status value
  // ---------------------------------------------------------------------------
  Future<List<TranslationAttempt>> _fetchByStatus(String status) async {
    try {
      final response = await _client
          .from('translation_attempts')
          .select('''
            *,
            profiles(full_name),
            sentences(sentence_id, khuwar_text),
            review_tasks(
              reviews(rating, notes)
            )
          ''')
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

  /// Newly submitted translations not yet assigned to a reviewer (status = 'pending')
  Future<List<TranslationAttempt>> fetchSubmittedTranslations() =>
      _fetchByStatus('pending');

  /// Translations currently being reviewed (status = 'assigned')
  Future<List<TranslationAttempt>> fetchInReviewTranslations() =>
      _fetchByStatus('assigned');

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
          .select('''
            *,
            profiles(full_name),
            sentences(sentence_id, khuwar_text),
            review_tasks(
              reviews(rating, notes)
            )
          ''')
          .inFilter('status', ['pending', 'assigned'])
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
      final results = await Future.wait([
        _client
            .from('translation_attempts')
            .count(CountOption.exact)
            .eq('status', 'pending'),
        _client
            .from('translation_attempts')
            .count(CountOption.exact)
            .eq('status', 'assigned'),
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
        submitted: results[0],
        inReview: results[1],
        approved: results[2],
        rejected: results[3],
        skipped: results[4],
      );
    } catch (e) {
      debugPrint('Error fetching moderation stats: $e');
      return ModerationStats.empty();
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
