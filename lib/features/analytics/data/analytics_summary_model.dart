import 'package:latlong2/latlong.dart';

class AnalyticsSummaryModel {
  final KPIData kpiData;
  final List<ActivityDataPoint> activityData;
  final List<RegionDataPoint> regionData;
  final List<EngagementDataPoint> engagementData;
  final List<RejectionReason> rejectionReasons; // New
  final List<LogEntry> recentLogs; // New
  final List<UniversityDataPoint> universityData; // New
  final Map<String, int> qualityDistribution; // New (e.g., "5 Star": 40)

  AnalyticsSummaryModel({
    required this.kpiData,
    required this.activityData,
    required this.regionData,
    required this.engagementData,
    this.rejectionReasons = const [],
    this.recentLogs = const [],
    this.universityData = const [],
    this.qualityDistribution = const {},
  });

  factory AnalyticsSummaryModel.empty() {
    return AnalyticsSummaryModel(
      kpiData: KPIData.empty(),
      activityData: [],
      regionData: [],
      engagementData: [],
      rejectionReasons: [],
      recentLogs: [],
      universityData: [],
      qualityDistribution: {},
    );
  }
}

// ... existing classes ...

class UniversityDataPoint {
  final String name;
  final int activeUsers;
  final int translationCount;
  final int score; // Gamification score

  UniversityDataPoint({
    required this.name,
    required this.activeUsers,
    required this.translationCount,
    required this.score,
  });
}

// Ensure other existing classes remain (ActivityDataPoint, etc are below)

class KPIData {
  final int totalTranslations;
  final int approvedTranslations;
  final int pendingTranslations;
  final int rejectedTranslations;
  final int totalUsers;

  // New Trend Fields (Mocked for now)
  final double translationsTrend;
  final double approvedTrend;
  final double usersTrend;
  final double rejectedTrend;

  KPIData({
    required this.totalTranslations,
    required this.approvedTranslations,
    required this.pendingTranslations,
    required this.rejectedTranslations,
    required this.totalUsers,
    this.translationsTrend = 0.0,
    this.approvedTrend = 0.0,
    this.usersTrend = 0.0,
    this.rejectedTrend = 0.0,
  });

  factory KPIData.empty() {
    return KPIData(
      totalTranslations: 0,
      approvedTranslations: 0,
      pendingTranslations: 0,
      rejectedTranslations: 0,
      totalUsers: 0,
    );
  }
}

class ActivityDataPoint {
  final DateTime date;
  final int count;

  ActivityDataPoint({required this.date, required this.count});
}

class RegionDataPoint {
  final String city;
  final LatLng coordinates;
  final int userCount;
  final int translationCount;
  final double intensity; // 0.0 to 1.0 for HeatMap

  RegionDataPoint({
    required this.city,
    required this.coordinates,
    required this.userCount,
    required this.translationCount,
    this.intensity = 0.5,
  });
}

class EngagementDataPoint {
  final DateTime date;
  final int activeUsers;

  EngagementDataPoint({required this.date, required this.activeUsers});
}

class RejectionReason {
  final String reason;
  final int count;

  RejectionReason({required this.reason, required this.count});
}

class LogEntry {
  final String message;
  final DateTime timestamp;
  final String type; // 'error', 'info', 'warning'

  LogEntry({
    required this.message,
    required this.timestamp,
    required this.type,
  });
}
