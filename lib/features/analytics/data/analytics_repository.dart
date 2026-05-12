import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/supabase_service.dart';
import 'analytics_summary_model.dart';
import 'package:intl/intl.dart';

class AnalyticsRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<AnalyticsSummaryModel> fetchAnalyticsSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final kpiData = await _fetchKPIData(startDate, endDate);
      final activityData = await _fetchActivityData(startDate, endDate);
      final regionData = await _fetchRegionData();
      final engagementData = await _fetchEngagementData(startDate, endDate);
      final rejectionReasons = await _fetchRejectionReasons();
      final recentLogs = await _fetchRecentLogs();
      final universityData = await _fetchUniversityData();
      final qualityDistribution = await _fetchQualityDistribution();

      return AnalyticsSummaryModel(
        kpiData: kpiData,
        activityData: activityData,
        regionData: regionData,
        engagementData: engagementData,
        rejectionReasons: rejectionReasons,
        recentLogs: recentLogs,
        universityData: universityData,
        qualityDistribution: qualityDistribution,
      );
    } catch (e) {
      debugPrint('Error fetching analytics summary: $e');
      rethrow;
    }
  }

  Future<KPIData> _fetchKPIData(DateTime start, DateTime end) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // Total Translations
    final totalTranslationsResponse = await _client
        .from('translation_attempts')
        .select('attempt_id')
        .gte('timestamp', startStr)
        .lte('timestamp', endStr)
        .count();

    // Approved
    final approvedResponse = await _client
        .from('translation_attempts')
        .select('attempt_id')
        .eq('status', 'approved')
        .gte('timestamp', startStr)
        .lte('timestamp', endStr)
        .count();

    // Pending (includes assigned and reviewed)
    final pendingResponse = await _client
        .from('translation_attempts')
        .select('attempt_id')
        .inFilter('status', [
          'pending',
          'assigned',
          'reviewed',
        ]) // Include all non-final states
        .gte('timestamp', startStr)
        .lte('timestamp', endStr)
        .count();

    // Rejected
    final rejectedResponse = await _client
        .from('translation_attempts')
        .select('attempt_id')
        .eq('status', 'rejected')
        .gte('timestamp', startStr)
        .lte('timestamp', endStr)
        .count();

    // Total Users (Overall, not just in range, usually)
    // If range needed, filter by created_at
    final totalUsersResponse = await _client
        .from('profiles')
        .select('user_id')
        .count();

    // Calculate Previous Period for Trends
    final duration = end.difference(start);
    final prevStart = start.subtract(duration);
    final prevEnd = start;

    final prevStartStr = prevStart.toIso8601String();
    final prevEndStr = prevEnd.toIso8601String();

    // Previous Total Translations
    final prevTotalResponse = await _client
        .from('translation_attempts')
        .select('attempt_id')
        .gte('timestamp', prevStartStr)
        .lte('timestamp', prevEndStr)
        .count();

    // Previous Approved
    final prevApprovedResponse = await _client
        .from('translation_attempts')
        .select('attempt_id')
        .eq('status', 'approved')
        .gte('timestamp', prevStartStr)
        .lte('timestamp', prevEndStr)
        .count();

    // Previous Rejected
    final prevRejectedResponse = await _client
        .from('translation_attempts')
        .select('attempt_id')
        .eq('status', 'rejected')
        .gte('timestamp', prevStartStr)
        .lte('timestamp', prevEndStr)
        .count();

    // Trends calculation
    double calculateTrend(int current, int previous) {
      if (previous == 0) return current > 0 ? 100.0 : 0.0;
      return ((current - previous) / previous) * 100;
    }

    return KPIData(
      totalTranslations: totalTranslationsResponse.count,
      approvedTranslations: approvedResponse.count,
      pendingTranslations: pendingResponse.count,
      rejectedTranslations: rejectedResponse.count,
      totalUsers: totalUsersResponse.count,
      translationsTrend: calculateTrend(
        totalTranslationsResponse.count,
        prevTotalResponse.count,
      ),
      approvedTrend: calculateTrend(
        approvedResponse.count,
        prevApprovedResponse.count,
      ),
      usersTrend:
          0.0, // User trend requires historical user count snapshot which is complex without logs
      rejectedTrend: calculateTrend(
        rejectedResponse.count,
        prevRejectedResponse.count,
      ),
    );
  }

  Future<List<ActivityDataPoint>> _fetchActivityData(
    DateTime start,
    DateTime end,
  ) async {
    // Note: Doing aggregation on client side for MVP as Supabase
    // doesn't support easy time-bucket grouping without RPCs.
    // Fetching minimal data for counting.
    final response = await _client
        .from('translation_attempts')
        .select('timestamp')
        .gte('timestamp', start.toIso8601String())
        .lte('timestamp', end.toIso8601String());

    final Map<String, int> dailyCounts = {};

    for (var record in response) {
      final date = DateTime.parse(record['timestamp']).toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
    }

    // Fill in missing days with 0
    List<ActivityDataPoint> dataPoints = [];
    int days = end.difference(start).inDays;
    for (int i = 0; i <= days; i++) {
      final d = start.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      dataPoints.add(ActivityDataPoint(date: d, count: dailyCounts[key] ?? 0));
    }

    return dataPoints;
  }

  Future<List<RegionDataPoint>> _fetchRegionData() async {
    // Get profiles with coordinates
    // Ideally this should be an RPC to aggregate by city
    final response = await _client
        .from('profiles')
        .select('city, gps_coordinates')
        .not('city', 'is', null);

    // Simple aggregation
    final Map<String, int> cityCounts = {};
    final Map<String, LatLng> cityCoords = {};

    for (var record in response) {
      final city = record['city'] as String;
      cityCounts[city] = (cityCounts[city] ?? 0) + 1;

      // Use first found coords for city center approx if available
      // Warning: Parsing PostGIS geography string is complex without specific format knowledge
      // For MVP, we might mock coords or try basic parsing if format is standard WKT
      // Assuming we might not get simple lat/lng back easily from raw JSON select without conversion
      // So for this MVP step, we'll assign some default coords for known major cities
      // or try to parse if standard point.
      if (!cityCoords.containsKey(city)) {
        cityCoords[city] = _getMockCoordsForCity(city);
      }
    }

    return cityCounts.entries
        .map(
          (e) => RegionDataPoint(
            city: e.key,
            coordinates:
                cityCoords[e.key] ??
                const LatLng(30.3753, 69.3451), // Default Pakistan center
            userCount: e.value,
            translationCount: 0,
            intensity: (e.value / 10).clamp(
              0.0,
              1.0,
            ), // Simple intensity normalization
          ),
        )
        .toList();
  }

  LatLng _getMockCoordsForCity(String city) {
    final lowerCity = city.toLowerCase();
    if (lowerCity.contains('chitral')) return const LatLng(35.8510, 71.7864);
    if (lowerCity.contains('peshawar')) return const LatLng(34.0151, 71.5249);
    if (lowerCity.contains('islamabad')) return const LatLng(33.6844, 73.0479);
    if (lowerCity.contains('karachi')) return const LatLng(24.8607, 67.0011);
    if (lowerCity.contains('lahore')) return const LatLng(31.5204, 74.3587);
    return const LatLng(30.3753, 69.3451);
  }

  Future<List<EngagementDataPoint>> _fetchEngagementData(
    DateTime start,
    DateTime end,
  ) async {
    // Real aggregation of active users based on translation activity
    // Note: This only counts users who submitted translations.
    // Passive users are not tracked without a proper analytics event log.
    final response = await _client
        .from('translation_attempts')
        .select('timestamp, user_id')
        .gte('timestamp', start.toIso8601String())
        .lte('timestamp', end.toIso8601String());

    final Map<String, Set<String>> dailyActiveUsers = {};

    for (var record in response) {
      final date = DateTime.parse(record['timestamp']).toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      dailyActiveUsers
          .putIfAbsent(dateKey, () => <String>{})
          .add(record['user_id']);
    }

    List<EngagementDataPoint> points = [];
    int days = end.difference(start).inDays;

    for (int i = 0; i <= days; i++) {
      final d = start.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      final count = dailyActiveUsers[key]?.length ?? 0;

      points.add(EngagementDataPoint(date: d, activeUsers: count));
    }

    return points;
  }

  Future<List<RejectionReason>> _fetchRejectionReasons() async {
    try {
      // Fetch reviews with low ratings (1 or 2 stars) which indicate rejection/issues
      final response = await _client
          .from('reviews')
          .select('notes')
          .lt('rating', 3)
          .not('notes', 'is', null)
          .limit(100);

      final Map<String, int> reasonCounts = {};

      for (var record in response) {
        final note = record['notes'] as String;
        // Simple normalization: take first 30 chars or first sentence
        final reason = note.split('\n').first.split('.').first.trim();
        if (reason.isNotEmpty) {
          reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
        }
      }

      final sortedReasons = reasonCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedReasons
          .take(5)
          .map((e) => RejectionReason(reason: e.key, count: e.value))
          .toList();
    } catch (e) {
      debugPrint('Error fetching rejection reasons: $e');
      return [];
    }
  }

  Future<List<LogEntry>> _fetchRecentLogs() async {
    try {
      // Fetch recent 5 users
      final usersResponse = await _client
          .from('profiles')
          .select('full_name, created_at')
          .order('created_at', ascending: false)
          .limit(5);

      // Fetch recent 5 translations
      final translationsResponse = await _client
          .from('translation_attempts')
          .select('timestamp, status')
          .order('timestamp', ascending: false)
          .limit(5);

      List<LogEntry> logs = [];

      for (var u in usersResponse) {
        logs.add(
          LogEntry(
            message: 'New user joined: ${u['full_name']}',
            timestamp: DateTime.parse(u['created_at']).toLocal(),
            type: 'info',
          ),
        );
      }

      for (var t in translationsResponse) {
        logs.add(
          LogEntry(
            message: 'Translation submitted (${t['status']})',
            timestamp: DateTime.parse(t['timestamp']).toLocal(),
            type: t['status'] == 'rejected' ? 'warning' : 'info',
          ),
        );
      }

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs.take(10).toList();
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      return [];
    }
  }

  Future<List<UniversityDataPoint>> _fetchUniversityData() async {
    try {
      // Fetch profiles that are students, linked with universities
      // User requested "how many students from which universities"
      final response = await _client
          .from('profiles')
          .select('university_id, universities(name)')
          .eq('is_student', true)
          .not('university_id', 'is', null);

      final Map<String, int> uniCounts = {};

      for (var record in response) {
        final uniData = record['universities'];
        if (uniData == null) continue;

        final name = uniData['name'] as String;
        uniCounts[name] = (uniCounts[name] ?? 0) + 1;
      }

      final sorted = uniCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(10)
          .map(
            (e) => UniversityDataPoint(
              name: e.key,
              activeUsers: e.value, // Represents Total Students
              translationCount: 0,
              score: 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching university data: $e');
      return [];
    }
  }

  Future<Map<String, int>> _fetchQualityDistribution() async {
    try {
      final response = await _client.from('reviews').select('rating');

      final Map<String, int> distribution = {
        '5 Star': 0,
        '4 Star': 0,
        '3 Star': 0,
        '2 Star': 0,
        '1 Star': 0,
      };

      for (var record in response) {
        final rating = record['rating'] as int?;
        if (rating != null) {
          final key = '$rating Star';
          if (distribution.containsKey(key)) {
            distribution[key] = distribution[key]! + 1;
          }
        }
      }
      return distribution;
    } catch (e) {
      debugPrint('Error fetching quality distribution: $e');
      return {};
    }
  }
}
