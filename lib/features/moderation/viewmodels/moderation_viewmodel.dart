import 'package:flutter/foundation.dart';
import '../data/moderation_model.dart';
import '../data/moderation_repository.dart';

/// Enum for sort direction
enum SortDirection { ascending, descending }

/// Sort column options for pending translations
enum PendingSortColumn { id, user, status, submitted }

/// Sort column options for skipped translations
enum SkippedSortColumn { user, sentence, skippedAt }

/// Status filter options
enum StatusFilter { all, pending, assigned }

class ModerationViewModel extends ChangeNotifier {
  final ModerationRepository _repository;

  ModerationViewModel({ModerationRepository? repository})
    : _repository = repository ?? ModerationRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Raw data
  List<TranslationAttempt> _pendingTranslations = [];
  List<TranslationAttempt> get pendingTranslations => _pendingTranslations;

  List<SkippedSentence> _skippedTranslations = [];
  List<SkippedSentence> get skippedTranslations => _skippedTranslations;

  // Search queries
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _skippedSearchQuery = '';
  String get skippedSearchQuery => _skippedSearchQuery;

  // Sorting state for pending tab
  PendingSortColumn _pendingSortColumn = PendingSortColumn.submitted;
  PendingSortColumn get pendingSortColumn => _pendingSortColumn;

  SortDirection _pendingSortDirection = SortDirection.descending;
  SortDirection get pendingSortDirection => _pendingSortDirection;

  // Sorting state for skipped tab
  SkippedSortColumn _skippedSortColumn = SkippedSortColumn.skippedAt;
  SkippedSortColumn get skippedSortColumn => _skippedSortColumn;

  SortDirection _skippedSortDirection = SortDirection.descending;
  SortDirection get skippedSortDirection => _skippedSortDirection;

  // Status filter for pending tab
  StatusFilter _statusFilter = StatusFilter.all;
  StatusFilter get statusFilter => _statusFilter;

  // Get column index for DataTable sorting (pending)
  int get pendingSortColumnIndex {
    switch (_pendingSortColumn) {
      case PendingSortColumn.id:
        return 0;
      case PendingSortColumn.user:
        return 1;
      case PendingSortColumn.status:
        return 3;
      case PendingSortColumn.submitted:
        return 5;
    }
  }

  // Get column index for DataTable sorting (skipped)
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

  bool get pendingSortAscending =>
      _pendingSortDirection == SortDirection.ascending;
  bool get skippedSortAscending =>
      _skippedSortDirection == SortDirection.ascending;

  // Filtered and sorted pending translations
  List<TranslationAttempt> get filteredPendingTranslations {
    var result = _pendingTranslations.toList();

    // Apply status filter
    if (_statusFilter != StatusFilter.all) {
      final filterStatus = _statusFilter == StatusFilter.pending
          ? 'pending'
          : 'assigned';
      result = result
          .where((t) => t.status.toLowerCase() == filterStatus)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        return t.userName.toLowerCase().contains(query) ||
            t.sentence.toLowerCase().contains(query) ||
            t.id.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    result.sort((a, b) {
      int comparison;
      switch (_pendingSortColumn) {
        case PendingSortColumn.id:
          comparison = a.id.compareTo(b.id);
          break;
        case PendingSortColumn.user:
          comparison = a.userName.toLowerCase().compareTo(
            b.userName.toLowerCase(),
          );
          break;
        case PendingSortColumn.status:
          comparison = a.status.compareTo(b.status);
          break;
        case PendingSortColumn.submitted:
          comparison = a.submittedAt.compareTo(b.submittedAt);
          break;
      }
      return _pendingSortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });

    return result;
  }

  // Filtered and sorted skipped translations
  List<SkippedSentence> get filteredSkippedTranslations {
    var result = _skippedTranslations.toList();

    // Apply search filter
    if (_skippedSearchQuery.isNotEmpty) {
      final query = _skippedSearchQuery.toLowerCase();
      result = result.where((s) {
        return s.userName.toLowerCase().contains(query) ||
            s.sentenceText.toLowerCase().contains(query) ||
            (s.reason?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sorting
    result.sort((a, b) {
      int comparison;
      switch (_skippedSortColumn) {
        case SkippedSortColumn.user:
          comparison = a.userName.toLowerCase().compareTo(
            b.userName.toLowerCase(),
          );
          break;
        case SkippedSortColumn.sentence:
          comparison = a.sentenceText.toLowerCase().compareTo(
            b.sentenceText.toLowerCase(),
          );
          break;
        case SkippedSortColumn.skippedAt:
          comparison = a.skippedAt.compareTo(b.skippedAt);
          break;
      }
      return _skippedSortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });

    return result;
  }

  // Set pending tab search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set skipped tab search query
  void setSkippedSearchQuery(String query) {
    _skippedSearchQuery = query;
    notifyListeners();
  }

  // Set status filter
  void setStatusFilter(StatusFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  // Set pending sort column
  void setPendingSortColumn(PendingSortColumn column) {
    if (_pendingSortColumn == column) {
      // Toggle direction if same column
      _pendingSortDirection = _pendingSortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    } else {
      _pendingSortColumn = column;
      _pendingSortDirection = SortDirection.ascending;
    }
    notifyListeners();
  }

  // Set skipped sort column
  void setSkippedSortColumn(SkippedSortColumn column) {
    if (_skippedSortColumn == column) {
      // Toggle direction if same column
      _skippedSortDirection = _skippedSortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    } else {
      _skippedSortColumn = column;
      _skippedSortDirection = SortDirection.ascending;
    }
    notifyListeners();
  }

  // Sort by column index (for DataTable onSort callback) - Pending
  void sortPendingByColumnIndex(int columnIndex, bool ascending) {
    PendingSortColumn column;
    switch (columnIndex) {
      case 0:
        column = PendingSortColumn.id;
        break;
      case 1:
        column = PendingSortColumn.user;
        break;
      case 3:
        column = PendingSortColumn.status;
        break;
      case 5:
        column = PendingSortColumn.submitted;
        break;
      default:
        return; // Non-sortable column
    }
    _pendingSortColumn = column;
    _pendingSortDirection = ascending
        ? SortDirection.ascending
        : SortDirection.descending;
    notifyListeners();
  }

  // Sort by column index (for DataTable onSort callback) - Skipped
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
        return; // Non-sortable column
    }
    _skippedSortColumn = column;
    _skippedSortDirection = ascending
        ? SortDirection.ascending
        : SortDirection.descending;
    notifyListeners();
  }

  ModerationStats _stats = ModerationStats.empty();
  ModerationStats get stats => _stats;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_fetchPending(), _fetchSkipped(), _fetchStats()]);
    } catch (e) {
      _error = 'Failed to load moderation data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPending() async {
    _pendingTranslations = await _repository.fetchPendingTranslations();
  }

  Future<void> _fetchSkipped() async {
    _skippedTranslations = await _repository.fetchSkippedTranslations();
  }

  Future<void> _fetchStats() async {
    _stats = await _repository.fetchModerationStats();
  }

  Future<void> approveTranslation(String id) async {
    try {
      await _repository.approveTranslation(id);
      _pendingTranslations.removeWhere((t) => t.id == id);
      await _fetchStats(); // update stats
      notifyListeners();
    } catch (e) {
      _error = 'Failed to approve: $e';
      notifyListeners();
    }
  }

  Future<void> rejectTranslation(String id) async {
    try {
      await _repository.rejectTranslation(id);
      _pendingTranslations.removeWhere((t) => t.id == id);
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

      _pendingTranslations.removeWhere((t) => t.id == attempt.id);
      await _fetchStats();
      await _fetchSkipped();
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
