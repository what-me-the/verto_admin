import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../data/moderation_model.dart';
import '../data/moderation_repository.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------
enum SortDirection { ascending, descending }

/// Column options shared across all TranslationAttempt-based tabs
enum TranslationSortColumn { id, user, status, submitted }

enum SkippedSortColumn { user, sentence, skippedAt }

/// Kept for backward compatibility â€” no longer used in the new 5-tab UI
enum StatusFilter { all, pending, assigned }

// Backward-compat alias
typedef PendingSortColumn = TranslationSortColumn;

class ModerationViewModel extends ChangeNotifier {
  final ModerationRepository _repository;

  ModerationViewModel({ModerationRepository? repository})
      : _repository = repository ?? ModerationRepository() {
    _setupRealtime();
  }

  // ---------------------------------------------------------------------------
  // Realtime
  // ---------------------------------------------------------------------------
  RealtimeChannel? _realtimeChannel;
  Timer? _debounce;

  void _setupRealtime() {
    _realtimeChannel = SupabaseService.instance.client
        .channel('moderation_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'translation_attempts',
          callback: (_) => _debouncedReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'skipped_sentences',
          callback: (_) => _debouncedReload(),
        )
        .subscribe();
  }

  void _debouncedReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      loadData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Loading / error state
  // ---------------------------------------------------------------------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Translation attempt lists (one per DB status)
  // ---------------------------------------------------------------------------
  List<TranslationAttempt> _submittedTranslations = [];
  List<TranslationAttempt> _inReviewTranslations = [];
  List<TranslationAttempt> _acceptedTranslations = [];
  List<TranslationAttempt> _rejectedTranslations = [];

  List<TranslationAttempt> get submittedTranslations => _submittedTranslations;
  List<TranslationAttempt> get inReviewTranslations => _inReviewTranslations;
  List<TranslationAttempt> get acceptedTranslations => _acceptedTranslations;
  List<TranslationAttempt> get rejectedTranslations => _rejectedTranslations;

  /// Legacy getter â€” combined submitted + inReview
  List<TranslationAttempt> get pendingTranslations =>
      [..._submittedTranslations, ..._inReviewTranslations];

  // ---------------------------------------------------------------------------
  // Skipped list
  // ---------------------------------------------------------------------------
  List<SkippedSentence> _skippedTranslations = [];
  List<SkippedSentence> get skippedTranslations => _skippedTranslations;

  // ---------------------------------------------------------------------------
  // Per-tab search queries
  // ---------------------------------------------------------------------------
  String _submittedSearch = '';
  String _inReviewSearch = '';
  String _acceptedSearch = '';
  String _rejectedSearch = '';
  String _skippedSearch = '';

  String get submittedSearch => _submittedSearch;
  String get inReviewSearch => _inReviewSearch;
  String get acceptedSearch => _acceptedSearch;
  String get rejectedSearch => _rejectedSearch;
  String get skippedSearchQuery => _skippedSearch;

  /// Backward compat
  String get searchQuery => _submittedSearch;

  // ---------------------------------------------------------------------------
  // Sorting â€” shared across all 4 attempt tabs
  // ---------------------------------------------------------------------------
  TranslationSortColumn _sortColumn = TranslationSortColumn.submitted;
  SortDirection _sortDirection = SortDirection.descending;

  TranslationSortColumn get sortColumn => _sortColumn;
  bool get sortAscending => _sortDirection == SortDirection.ascending;

  /// Column index used by PaginatedDataTable (7-column layout)
  /// 0=ID, 1=USER, 2=SENTENCE, 3=STATUS, 4=REVIEW, 5=SUBMITTED, 6=ACTIONS
  int get translationSortColumnIndex {
    switch (_sortColumn) {
      case TranslationSortColumn.id:
        return 0;
      case TranslationSortColumn.user:
        return 1;
      case TranslationSortColumn.status:
        return 3;
      case TranslationSortColumn.submitted:
        return 5;
    }
  }

  /// Backward compat
  int get pendingSortColumnIndex => translationSortColumnIndex;
  bool get pendingSortAscending => sortAscending;

  // ---------------------------------------------------------------------------
  // Sorting â€” skipped tab
  // ---------------------------------------------------------------------------
  SkippedSortColumn _skippedSortColumn = SkippedSortColumn.skippedAt;
  SortDirection _skippedSortDirection = SortDirection.descending;

  SkippedSortColumn get skippedSortColumn => _skippedSortColumn;
  bool get skippedSortAscending =>
      _skippedSortDirection == SortDirection.ascending;

  int get skippedSortColumnIndex {
    switch (_skippedSortColumn) {
      case SkippedSortColumn.user:
        return 0;
      case SkippedSortColumn.sentence:
        return 1;
      case SkippedSortColumn.skippedAt:
        return 3;
    }
  }

  // ---------------------------------------------------------------------------
  // Stats
  // ---------------------------------------------------------------------------
  ModerationStats _stats = ModerationStats.empty();
  ModerationStats get stats => _stats;

  // ---------------------------------------------------------------------------
  // Status filter (backward compat â€” kept but no longer needed per tab)
  // ---------------------------------------------------------------------------
  StatusFilter _statusFilter = StatusFilter.all;
  StatusFilter get statusFilter => _statusFilter;

  void setStatusFilter(StatusFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Filtering helper â€” applies search + sort to any TranslationAttempt list
  // ---------------------------------------------------------------------------
  List<TranslationAttempt> _applyFilter(
    List<TranslationAttempt> list,
    String search,
  ) {
    var result = list.toList();

    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((t) {
        return t.userName.toLowerCase().contains(q) ||
            t.sentence.toLowerCase().contains(q) ||
            t.id.toLowerCase().contains(q) ||
            t.urduTranslation.toLowerCase().contains(q) ||
            t.romanTranslation.toLowerCase().contains(q);
      }).toList();
    }

    result.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case TranslationSortColumn.id:
          cmp = a.id.compareTo(b.id);
          break;
        case TranslationSortColumn.user:
          cmp =
              a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
          break;
        case TranslationSortColumn.status:
          cmp = a.status.compareTo(b.status);
          break;
        case TranslationSortColumn.submitted:
          cmp = a.submittedAt.compareTo(b.submittedAt);
          break;
      }
      return _sortDirection == SortDirection.ascending ? cmp : -cmp;
    });

    return result;
  }

  // ---------------------------------------------------------------------------
  // Filtered getters
  // ---------------------------------------------------------------------------
  List<TranslationAttempt> get filteredSubmittedTranslations =>
      _applyFilter(_submittedTranslations, _submittedSearch);

  List<TranslationAttempt> get filteredInReviewTranslations =>
      _applyFilter(_inReviewTranslations, _inReviewSearch);

  List<TranslationAttempt> get filteredAcceptedTranslations =>
      _applyFilter(_acceptedTranslations, _acceptedSearch);

  List<TranslationAttempt> get filteredRejectedTranslations =>
      _applyFilter(_rejectedTranslations, _rejectedSearch);

  /// Backward compat
  List<TranslationAttempt> get filteredPendingTranslations =>
      _applyFilter(pendingTranslations, _submittedSearch);

  List<SkippedSentence> get filteredSkippedTranslations {
    var result = _skippedTranslations.toList();

    if (_skippedSearch.isNotEmpty) {
      final q = _skippedSearch.toLowerCase();
      result = result.where((s) {
        return s.userName.toLowerCase().contains(q) ||
            s.sentenceText.toLowerCase().contains(q) ||
            (s.reason?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    result.sort((a, b) {
      int cmp;
      switch (_skippedSortColumn) {
        case SkippedSortColumn.user:
          cmp =
              a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
          break;
        case SkippedSortColumn.sentence:
          cmp = a.sentenceText
              .toLowerCase()
              .compareTo(b.sentenceText.toLowerCase());
          break;
        case SkippedSortColumn.skippedAt:
          cmp = a.skippedAt.compareTo(b.skippedAt);
          break;
      }
      return _skippedSortDirection == SortDirection.ascending ? cmp : -cmp;
    });

    return result;
  }

  // ---------------------------------------------------------------------------
  // Search setters
  // ---------------------------------------------------------------------------
  void setSubmittedSearch(String q) {
    _submittedSearch = q;
    notifyListeners();
  }

  void setInReviewSearch(String q) {
    _inReviewSearch = q;
    notifyListeners();
  }

  void setAcceptedSearch(String q) {
    _acceptedSearch = q;
    notifyListeners();
  }

  void setRejectedSearch(String q) {
    _rejectedSearch = q;
    notifyListeners();
  }

  void setSkippedSearchQuery(String q) {
    _skippedSearch = q;
    notifyListeners();
  }

  /// Backward compat
  void setSearchQuery(String q) => setSubmittedSearch(q);

  // ---------------------------------------------------------------------------
  // Sort setters
  // ---------------------------------------------------------------------------
  void sortTranslationByColumnIndex(int columnIndex, bool ascending) {
    TranslationSortColumn column;
    switch (columnIndex) {
      case 0:
        column = TranslationSortColumn.id;
        break;
      case 1:
        column = TranslationSortColumn.user;
        break;
      case 3:
        column = TranslationSortColumn.status;
        break;
      case 5:
        column = TranslationSortColumn.submitted;
        break;
      default:
        return;
    }
    _sortColumn = column;
    _sortDirection =
        ascending ? SortDirection.ascending : SortDirection.descending;
    notifyListeners();
  }

  /// Backward compat
  void sortPendingByColumnIndex(int i, bool asc) =>
      sortTranslationByColumnIndex(i, asc);

  void sortSkippedByColumnIndex(int columnIndex, bool ascending) {
    SkippedSortColumn column;
    switch (columnIndex) {
      case 0:
        column = SkippedSortColumn.user;
        break;
      case 1:
        column = SkippedSortColumn.sentence;
        break;
      case 3:
        column = SkippedSortColumn.skippedAt;
        break;
      default:
        return;
    }
    _skippedSortColumn = column;
    _skippedSortDirection =
        ascending ? SortDirection.ascending : SortDirection.descending;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Log distinct statuses once so we can diagnose data mismatches
      await _repository.logDistinctStatuses();

      // Fetch pending+reviewed as one query; accepted/rejected/skipped in parallel
      await Future.wait([
        _fetchPendingAndReviewed(),
        _fetchAccepted(),
        _fetchRejected(),
        _fetchSkipped(),
      ]);

      // Compute stats AFTER lists are populated so submitted/inReview counts
      // reflect the same task-based split as the tabs.
      await _fetchStats();
    } catch (e) {
      _error = 'Failed to load moderation data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches pending+reviewed in a single query and splits into the two lists:
  /// • Submitted = pending rows with no review task assigned yet
  /// • In Review = pending rows WITH a review task  OR  status == 'reviewed'
  Future<void> _fetchPendingAndReviewed() async {
    final all = await _repository.fetchPendingAndReviewedTranslations();
    _submittedTranslations =
        all.where((t) => t.status == 'pending' && !t.hasReviewTask).toList();
    _inReviewTranslations = all
        .where((t) =>
            t.status == 'reviewed' ||
            (t.status == 'pending' && t.hasReviewTask))
        .toList();
  }

  Future<void> _fetchSubmitted() async {
    _submittedTranslations = await _repository.fetchSubmittedTranslations();
  }

  Future<void> _fetchInReview() async {
    _inReviewTranslations = await _repository.fetchInReviewTranslations();
  }

  Future<void> _fetchAccepted() async {
    _acceptedTranslations = await _repository.fetchAcceptedTranslations();
  }

  Future<void> _fetchRejected() async {
    _rejectedTranslations = await _repository.fetchRejectedTranslations();
  }

  Future<void> _fetchSkipped() async {
    _skippedTranslations = await _repository.fetchSkippedTranslations();
  }

  Future<void> _fetchStats() async {
    // submitted / inReview are derived from the in-memory lists so the counts
    // in the sidebar match exactly what the tabs show (task-based split).
    final terminal = await _repository.fetchTerminalStats();
    _stats = ModerationStats(
      submitted: _submittedTranslations.length,
      inReview: _inReviewTranslations.length,
      approved: terminal.approved,
      rejected: terminal.rejected,
      skipped: _skippedTranslations.length,
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> approveTranslation(String id) async {
    try {
      await _repository.approveTranslation(id);

      // Move item locally from submitted/inReview â†’ accepted
      final item = _submittedTranslations.where((t) => t.id == id).firstOrNull
          ?? _inReviewTranslations.where((t) => t.id == id).firstOrNull;

      _submittedTranslations.removeWhere((t) => t.id == id);
      _inReviewTranslations.removeWhere((t) => t.id == id);

      if (item != null) {
        _acceptedTranslations.insert(
          0,
          TranslationAttempt(
            id: item.id,
            userId: item.userId,
            userName: item.userName,
            sentenceId: item.sentenceId,
            sentence: item.sentence,
            urduTranslation: item.urduTranslation,
            romanTranslation: item.romanTranslation,
            status: 'approved',
            submittedAt: item.submittedAt,
            reviewerName: item.reviewerName,
            reviewRating: item.reviewRating,
            reviewNotes: item.reviewNotes,
            editedUrdu: item.editedUrdu,
            editedRoman: item.editedRoman,
          ),
        );
      }

      await _fetchStats();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to approve: $e';
      notifyListeners();
    }
  }

  Future<void> rejectTranslation(String id) async {
    try {
      await _repository.rejectTranslation(id);

      final item = _submittedTranslations.where((t) => t.id == id).firstOrNull
          ?? _inReviewTranslations.where((t) => t.id == id).firstOrNull;

      _submittedTranslations.removeWhere((t) => t.id == id);
      _inReviewTranslations.removeWhere((t) => t.id == id);

      if (item != null) {
        _rejectedTranslations.insert(
          0,
          TranslationAttempt(
            id: item.id,
            userId: item.userId,
            userName: item.userName,
            sentenceId: item.sentenceId,
            sentence: item.sentence,
            urduTranslation: item.urduTranslation,
            romanTranslation: item.romanTranslation,
            status: 'rejected',
            submittedAt: item.submittedAt,
            reviewerName: item.reviewerName,
            reviewRating: item.reviewRating,
            reviewNotes: item.reviewNotes,
            editedUrdu: item.editedUrdu,
            editedRoman: item.editedRoman,
          ),
        );
      }

      await _fetchStats();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reject: $e';
      notifyListeners();
    }
  }

  Future<void> skipTranslation(
    TranslationAttempt attempt,
    String reason,
  ) async {
    try {
      await _repository.skipTranslation(
        attempt.id,
        attempt.userId,
        attempt.sentenceId,
        reason,
      );

      _submittedTranslations.removeWhere((t) => t.id == attempt.id);
      _inReviewTranslations.removeWhere((t) => t.id == attempt.id);

      await Future.wait([_fetchStats(), _fetchSkipped()]);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to skip: $e';
      notifyListeners();
    }
  }

  Future<void> unassignSkipped(String id, String sentenceId) async {
    try {
      await _repository.unassignSkipped(id, sentenceId);
      _skippedTranslations.removeWhere((s) => s.id == id);
      await _fetchStats();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to unassign: $e';
      notifyListeners();
    }
  }
}
