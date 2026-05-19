import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../data/user_model.dart';
import '../data/users_repository.dart';

class UsersViewModel extends ChangeNotifier {
  final UsersRepository _repository;

  UsersViewModel({UsersRepository? repository})
      : _repository = repository ?? UsersRepository() {
    _setupRealtime();
  }

  // ---------------------------------------------------------------------------
  // Realtime
  // ---------------------------------------------------------------------------
  RealtimeChannel? _realtimeChannel;
  Timer? _debounce;

  void _setupRealtime() {
    _realtimeChannel = SupabaseService.instance.client
        .channel('users_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (_) => _debouncedReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'translation_attempts',
          callback: (_) => _debouncedAnalyticsReload(),
        )
        .subscribe();
  }

  void _debouncedReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      loadUsers();
    });
  }

  Timer? _analyticsDebounce;
  void _debouncedAnalyticsReload() {
    _analyticsDebounce?.cancel();
    _analyticsDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_analyticsLoaded) loadAnalytics(force: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _analyticsDebounce?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Users state
  // ---------------------------------------------------------------------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<UserProfile> _users = [];
  List<UserProfile> get users => _users;

  List<String> _cities = [];
  List<String> get cities => _cities;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedCity;
  String? get selectedCity => _selectedCity;

  bool? _isStudentFilter;
  bool? get isStudentFilter => _isStudentFilter;

  int get totalUsers => _users.length;
  int get studentCount => _users.where((u) => u.isStudent).length;
  int get nonStudentCount => _users.where((u) => !u.isStudent).length;

  // ---------------------------------------------------------------------------
  // Analytics state
  // ---------------------------------------------------------------------------
  bool _analyticsLoading = false;
  bool get analyticsLoading => _analyticsLoading;

  String? _analyticsError;
  String? get analyticsError => _analyticsError;

  /// Daily sign-up counts: [{'date': 'yyyy-MM-dd', 'count': int}, ...]
  List<Map<String, dynamic>> _signupTrend = [];
  List<Map<String, dynamic>> get signupTrend => _signupTrend;

  /// Daily unique-active-user counts: [{'date': 'yyyy-MM-dd', 'count': int}, ...]
  List<Map<String, dynamic>> _activeUsersTrend = [];
  List<Map<String, dynamic>> get activeUsersTrend => _activeUsersTrend;

  /// Top-10 cities: [{'city': String, 'count': int}, ...]
  List<Map<String, dynamic>> _cityDistribution = [];
  List<Map<String, dynamic>> get cityDistribution => _cityDistribution;

  /// Aggregated translation status totals: {'pending':int,'approved':int,'rejected':int,'assigned':int}
  Map<String, int> _translationStatusStats = {
    'pending': 0,
    'approved': 0,
    'rejected': 0,
    'assigned': 0,
  };
  Map<String, int> get translationStatusStats => _translationStatusStats;

  /// Daily student vs general signups: [{'date':String,'students':int,'general':int}, ...]
  List<Map<String, dynamic>> _studentVsGeneralTrend = [];
  List<Map<String, dynamic>> get studentVsGeneralTrend => _studentVsGeneralTrend;

  bool _analyticsLoaded = false;

  // ---------------------------------------------------------------------------
  // Load users
  // ---------------------------------------------------------------------------
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchAllUsers(
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          cityFilter: _selectedCity,
          isStudentFilter: _isStudentFilter,
        ),
        _repository.fetchDistinctCities(),
      ]);

      _users = results[0] as List<UserProfile>;
      _cities = results[1] as List<String>;
    } catch (e) {
      _error = 'Failed to load users: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Load analytics (lazy â€” only called when Analytics tab is opened)
  // ---------------------------------------------------------------------------
  Future<void> loadAnalytics({bool force = false}) async {
    if (_analyticsLoaded && !force) return;

    _analyticsLoading = true;
    _analyticsError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchSignupTrend(),
        _repository.fetchActiveUsersTrend(),
        _repository.fetchCityDistribution(),
        _repository.fetchTranslationStatusStats(),
        _repository.fetchStudentVsGeneralTrend(),
      ]);

      _signupTrend = results[0] as List<Map<String, dynamic>>;
      _activeUsersTrend = results[1] as List<Map<String, dynamic>>;
      _cityDistribution = results[2] as List<Map<String, dynamic>>;
      _translationStatusStats = results[3] as Map<String, int>;
      _studentVsGeneralTrend = results[4] as List<Map<String, dynamic>>;
      _analyticsLoaded = true;
    } catch (e) {
      _analyticsError = 'Failed to load analytics: $e';
      debugPrint(_analyticsError);
    } finally {
      _analyticsLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Filter setters
  // ---------------------------------------------------------------------------
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadUsers();
  }

  void setCityFilter(String? city) {
    _selectedCity = city;
    loadUsers();
  }

  void setStudentFilter(bool? isStudent) {
    _isStudentFilter = isStudent;
    loadUsers();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCity = null;
    _isStudentFilter = null;
    loadUsers();
  }
}


