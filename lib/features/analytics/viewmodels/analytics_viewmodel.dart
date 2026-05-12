import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/analytics_repository.dart';
import '../data/analytics_summary_model.dart';

class AnalyticsViewModel extends ChangeNotifier {
  final AnalyticsRepository _repository;
  Timer? _autoRefreshTimer;

  // Auto-refresh interval (30 seconds)
  static const Duration _refreshInterval = Duration(seconds: 30);

  AnalyticsViewModel({AnalyticsRepository? repository})
    : _repository = repository ?? AnalyticsRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AnalyticsSummaryModel? _data;
  AnalyticsSummaryModel? get data => _data;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime get startDate => _startDate;

  DateTime _endDate = DateTime.now();
  DateTime get endDate => _endDate;

  String _selectedRange = 'Last 30 Days';
  String get selectedRange => _selectedRange;

  DateTime? _lastRefresh;
  DateTime? get lastRefresh => _lastRefresh;

  bool _autoRefreshEnabled = true;
  bool get autoRefreshEnabled => _autoRefreshEnabled;

  Future<void> loadData({bool silent = false}) async {
    // Don't show loading indicator for silent (auto) refreshes
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    try {
      _data = await _repository.fetchAnalyticsSummary(
        startDate: _startDate,
        endDate: _endDate,
      );
      _lastRefresh = DateTime.now();
    } catch (e) {
      _error = 'Failed to load analytics data: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    if (_autoRefreshEnabled) {
      _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
        // Silent refresh - don't show loading indicator
        loadData(silent: true);
      });
    }
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void toggleAutoRefresh() {
    _autoRefreshEnabled = !_autoRefreshEnabled;
    if (_autoRefreshEnabled) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
    notifyListeners();
  }

  void updateDateRange(String range) {
    _selectedRange = range;
    final now = DateTime.now();

    switch (range) {
      case 'Last 7 Days':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'Last 30 Days':
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      default:
        // Keep existing custom range or default
        break;
    }

    loadData();
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _selectedRange = 'Custom';
    loadData();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
