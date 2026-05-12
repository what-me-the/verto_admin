import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/supabase_service.dart';
import 'user_model.dart';

class UsersRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  // profiles select — no last_sign_in_at here; auth.users is queried separately
  static const _selectBase = '''
    user_id, full_name, email, city, is_student, created_at,
    universities(name), translation_attempts(status), skipped_sentences(id)
  ''';

  Future<List<UserProfile>> fetchAllUsers({
    String? searchQuery,
    String? cityFilter,
    bool? isStudentFilter,
  }) async {
    try {
      var q = _client.from('profiles').select(_selectBase);
      if (cityFilter != null && cityFilter.isNotEmpty) {
        q = q.eq('city', cityFilter);
      }
      if (isStudentFilter != null) {
        q = q.eq('is_student', isStudentFilter);
      }
      final response = await q.order('created_at', ascending: false);

      // Fetch last_sign_in_at from auth.users via the RPC helper.
      // Falls back gracefully if the function hasn't been created yet.
      Map<String, DateTime?> signInMap = {};
      try {
        final rpcResult = await _client
            .rpc('get_users_with_last_sign_in')
            .select();
        for (final row in (rpcResult as List)) {
          final uid = row['user_id'] as String?;
          final raw = row['last_sign_in_at'];
          if (uid != null && raw != null && raw is String && raw.isNotEmpty) {
            signInMap[uid] = DateTime.parse(raw).toLocal();
          }
        }
      } catch (e) {
        debugPrint('UsersRepository: get_users_with_last_sign_in RPC unavailable — $e');
        // Continue without sign-in data; each user will show "—"
      }

      List<UserProfile> users = (response as List).map((e) {
        final uid = e['user_id'] as String? ?? '';
        // Inject last_sign_in_at from auth.users into the json map
        final enriched = Map<String, dynamic>.from(e as Map)
          ..['last_sign_in_at'] = signInMap[uid]?.toIso8601String();
        return UserProfile.fromJson(enriched);
      }).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lq = searchQuery.toLowerCase();
        users = users
            .where((u) =>
                u.fullName.toLowerCase().contains(lq) ||
                (u.email?.toLowerCase().contains(lq) ?? false) ||
                (u.city?.toLowerCase().contains(lq) ?? false) ||
                (u.universityName?.toLowerCase().contains(lq) ?? false))
            .toList();
      }
      return users;
    } catch (e) {
      debugPrint('Error fetching users: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchDistinctCities() async {
    try {
      final response = await _client
          .from('profiles')
          .select('city')
          .not('city', 'is', null);

      final cities = (response as List)
          .map((e) => e['city'] as String)
          .toSet()
          .toList()
        ..sort();

      return cities;
    } catch (e) {
      debugPrint('Error fetching cities: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Analytics queries
  // ---------------------------------------------------------------------------

  /// Daily new user sign-ups over the last [days] days, grouped by date.
  Future<List<Map<String, dynamic>>> fetchSignupTrend({int days = 30}) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('profiles')
          .select('created_at')
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: true);

      final fmt = DateFormat('yyyy-MM-dd');
      final Map<String, int> counts = {};
      for (final row in response as List) {
        final date = DateTime.parse(row['created_at'] as String).toLocal();
        final key = fmt.format(date);
        counts[key] = (counts[key] ?? 0) + 1;
      }

      final result = counts.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList()
        ..sort(
            (a, b) => (a['date'] as String).compareTo(b['date'] as String));
      return result;
    } catch (e) {
      debugPrint('Error fetching signup trend: $e');
      return [];
    }
  }

  /// Daily unique active users (those who submitted at least one translation)
  /// over the last [days] days.
  Future<List<Map<String, dynamic>>> fetchActiveUsersTrend(
      {int days = 30}) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('translation_attempts')
          .select('user_id, timestamp')
          .gte('timestamp', since.toIso8601String())
          .order('timestamp', ascending: true);

      final fmt = DateFormat('yyyy-MM-dd');
      final Map<String, Set<String>> uniquePerDay = {};
      for (final row in response as List) {
        final date = DateTime.parse(row['timestamp'] as String).toLocal();
        final key = fmt.format(date);
        uniquePerDay.putIfAbsent(key, () => {}).add(row['user_id'] as String);
      }

      final result = uniquePerDay.entries
          .map((e) => {'date': e.key, 'count': e.value.length})
          .toList()
        ..sort(
            (a, b) => (a['date'] as String).compareTo(b['date'] as String));
      return result;
    } catch (e) {
      debugPrint('Error fetching active users trend: $e');
      return [];
    }
  }

  /// Distribution of users per city, sorted by count descending (top 10).
  Future<List<Map<String, dynamic>>> fetchCityDistribution() async {
    try {
      final response = await _client
          .from('profiles')
          .select('city')
          .not('city', 'is', null);

      final Map<String, int> counts = {};
      for (final row in response as List) {
        final city = row['city'] as String;
        counts[city] = (counts[city] ?? 0) + 1;
      }

      final result = counts.entries
          .map((e) => {'city': e.key, 'count': e.value})
          .toList()
        ..sort((b, a) => (a['count'] as int).compareTo(b['count'] as int));

      // Return top 10 cities
      return result.take(10).toList();
    } catch (e) {
      debugPrint('Error fetching city distribution: $e');
      return [];
    }
  }

  /// Aggregated translation status totals across all time.
  /// Returns a map like: {'pending': int, 'approved': int, 'rejected': int, 'assigned': int}
  Future<Map<String, int>> fetchTranslationStatusStats() async {
    try {
      final response = await _client
          .from('translation_attempts')
          .select('status');

      final Map<String, int> counts = {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'assigned': 0,
      };
      for (final row in response as List) {
        final status = row['status'] as String? ?? '';
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('Error fetching translation status stats: $e');
      return {'pending': 0, 'approved': 0, 'rejected': 0, 'assigned': 0};
    }
  }

  /// Daily new student vs general signups over the last [days] days.
  /// Returns: [{'date': 'yyyy-MM-dd', 'students': int, 'general': int}, ...]
  Future<List<Map<String, dynamic>>> fetchStudentVsGeneralTrend(
      {int days = 30}) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('profiles')
          .select('created_at, is_student')
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: true);

      final fmt = DateFormat('yyyy-MM-dd');
      final Map<String, Map<String, int>> perDay = {};
      for (final row in response as List) {
        final date = DateTime.parse(row['created_at'] as String).toLocal();
        final key = fmt.format(date);
        final isStudent = row['is_student'] as bool? ?? false;
        perDay.putIfAbsent(key, () => {'students': 0, 'general': 0});
        if (isStudent) {
          perDay[key]!['students'] = (perDay[key]!['students'] ?? 0) + 1;
        } else {
          perDay[key]!['general'] = (perDay[key]!['general'] ?? 0) + 1;
        }
      }

      final result = perDay.entries
          .map((e) => {
                'date': e.key,
                'students': e.value['students']!,
                'general': e.value['general']!,
              })
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      return result;
    } catch (e) {
      debugPrint('Error fetching student vs general trend: $e');
      return [];
    }
  }
}


