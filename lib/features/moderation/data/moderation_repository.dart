import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/supabase_service.dart';
import 'moderation_model.dart';

class ModerationRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

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
          .order('timestamp', ascending: true);

      return (response as List)
          .map((e) => TranslationAttempt.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending translations: $e');
      rethrow;
    }
  }

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

  Future<ModerationStats> fetchModerationStats() async {
    try {
      // Parallel requests for efficiency
      final pendingCount = await _client
          .from('translation_attempts')
          .count(CountOption.exact)
          .inFilter('status', ['pending', 'assigned']);

      final approvedCount = await _client
          .from('translation_attempts')
          .count(CountOption.exact)
          .eq('status', 'approved');

      final rejectedCount = await _client
          .from('translation_attempts')
          .count(CountOption.exact)
          .eq('status', 'rejected');

      final skippedCount = await _client
          .from('skipped_sentences')
          .count(CountOption.exact);

      return ModerationStats(
        totalPending: pendingCount,
        approved: approvedCount,
        rejected: rejectedCount,
        skipped: skippedCount,
        reassigned: 0, // Not easily trackable yet
      );
    } catch (e) {
      debugPrint('Error fetching moderation stats: $e');
      return ModerationStats.empty();
    }
  }

  Future<void> approveTranslation(String attemptId) async {
    try {
      // We update the status.
      // Note: In a real app, we might also want to trigger point allocation via RPC if not handled by triggers.
      // Assuming database triggers handle the leaderboard updates on status change for now,
      // or we call 'approve_translation' RPC if it exists.
      // Based on analysis, 'approve_translation' RPC likely exists and handles points.

      // Let's try calling the RPC first, if it fails, fallback to update (or check if RPC expects specific params)
      // Usually RPC 'approve_translation' takes task_id and rating.
      // If we are admin approving directly without a task, we might need to create a dummy review or just update status.
      // For 'Content Moderation', the admin IS the reviewer effectively.

      // Strategy: Just update status to 'approved' for now.
      // Validating triggers: 'translation_attempts' update usually fires triggers.

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
      // Transaction-like operation:
      // 1. Add to skipped_sentences
      // 2. Update translation_attempt to 'rejected' or delete it?
      //    Usually 'skip' means the user didn't translate it.
      //    But here we are skipping a "Submitted Translation" (which implies it was bad or inappropriate?)
      //    OR does "Skip" mean "Moderator skips reviewing this"?
      //    Reference `admincontent.md`: "Skip: Skip the translation and prevent reassigning it to the same user."
      //    "The sentence is marked as skipped and logged in the skipped_sentences table."
      //    "The sentence is unassigned from the user"

      await _client.from('skipped_sentences').insert({
        'user_id': userId,
        'sentence_id': sentenceId,
        'reason': reason,
      });

      // Update attempt to rejected or a special status?
      // Since it's in skipped_sentences, we probably should fail the attempt.
      await _client
          .from('translation_attempts')
          .update({'status': 'rejected'}) // Or 'skipped' if status allows
          .eq('attempt_id', attemptId);

      // Also need to set sentence.is_translated = false and assigned_to = null?
      // This might be handled by triggers or we implicitly allow reassignment.
      // We should clear assignment to allow others to pick it up.
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
