import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/analytics_viewmodel.dart';

// Widgets
import '../widgets/engagement_line_chart.dart';
import '../widgets/heat_map_widget.dart';
import '../widgets/edge_case_monitor.dart';
import '../widgets/university_leaderboard.dart';
import '../widgets/quality_pie_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AnalyticsViewModel();
    _viewModel.loadData();
    _viewModel.startAutoRefresh();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const AnalyticsContent(),
    );
  }
}

class AnalyticsContent extends StatelessWidget {
  const AnalyticsContent({super.key});

  // Light theme colors
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _sidebarBg = Color(0xFFFFFFFF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalyticsViewModel>();

    return Scaffold(
      backgroundColor: _bgColor,
      body: viewModel.isLoading
          ? _buildLoadingState()
          : viewModel.error != null
          ? _buildErrorState(context, viewModel)
          : viewModel.data != null
          ? _buildDashboard(context, viewModel)
          : const SizedBox(),
    );
  }

  Widget _buildDashboard(BuildContext context, AnalyticsViewModel viewModel) {
    final data = viewModel.data!;
    final kpi = data.kpiData;

    return Row(
      children: [
        // Left Sidebar - Quick Stats
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: _sidebarBg,
            border: Border(right: BorderSide(color: _borderColor, width: 1)),
          ),
          child: Column(
            children: [
              // Logo/Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6),
                            const Color(0xFF2563EB),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analytics Hub',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          'v2.4.0',
                          style: TextStyle(fontSize: 11, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(color: _borderColor, height: 1),

              // Section Label
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'KEY METRICS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Stats Cards
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildQuickStat(
                        title: 'Total Submissions',
                        value: kpi.totalTranslations.toString(),
                        icon: Icons.translate_rounded,
                        color: const Color(0xFF6366F1),
                        trend: kpi.translationsTrend,
                      ),
                      const SizedBox(height: 10),
                      _buildQuickStat(
                        title: 'Approved',
                        value: kpi.approvedTranslations.toString(),
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        trend: kpi.approvedTrend,
                      ),
                      const SizedBox(height: 10),
                      _buildQuickStat(
                        title: 'Team Members',
                        value: kpi.totalUsers.toString(),
                        icon: Icons.people_rounded,
                        color: const Color(0xFF8B5CF6),
                        trend: kpi.usersTrend,
                      ),
                      const SizedBox(height: 10),
                      _buildQuickStat(
                        title: 'Pending Review',
                        value: kpi.pendingTranslations.toString(),
                        icon: Icons.pending_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 10),
                      _buildQuickStat(
                        title: 'Rejections',
                        value: kpi.rejectedTranslations.toString(),
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFEF4444),
                        trend: kpi.rejectedTrend,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Auto-refresh indicator & Refresh button at bottom
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Auto-refresh toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: viewModel.autoRefreshEnabled
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : _bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: viewModel.autoRefreshEnabled
                              ? const Color(0xFF10B981).withOpacity(0.3)
                              : _borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: viewModel.autoRefreshEnabled
                                  ? const Color(0xFF10B981)
                                  : _textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            viewModel.autoRefreshEnabled ? 'Live' : 'Paused',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: viewModel.autoRefreshEnabled
                                  ? const Color(0xFF10B981)
                                  : _textSecondary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => viewModel.toggleAutoRefresh(),
                            child: Icon(
                              viewModel.autoRefreshEnabled
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: viewModel.autoRefreshEnabled
                                  ? const Color(0xFF10B981)
                                  : _textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Last refresh time
                    if (viewModel.lastRefresh != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Updated ${_formatLastRefresh(viewModel.lastRefresh!)}',
                          style: TextStyle(fontSize: 11, color: _textSecondary),
                        ),
                      ),
                    // Manual refresh button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => viewModel.loadData(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Refresh Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Content Area - Bento Grid
        Expanded(
          child: Container(
            color: _bgColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Overview',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time metrics and community engagement',
                            style: TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Approval Rate Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_calculateRate(kpi.approvedTranslations, kpi.totalTranslations)}% Approval',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Date filter
                          _buildDateFilter(context, viewModel),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // BENTO GRID LAYOUT
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final gap = 20.0;

                      return Column(
                        children: [
                          // Row 1: Engagement Chart (2/3) + Quality Pie (1/3)
                          SizedBox(
                            height: 600,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildBentoCard(
                                    title: 'Engagement Trends',
                                    subtitle: 'Daily translation activity',
                                    child: EngagementLineChart(
                                      dataPoints: data.activityData,
                                    ),
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  flex: 1,
                                  child: _buildBentoCard(
                                    title: 'Quality Distribution',
                                    subtitle: 'By rating score',
                                    child: QualityPieChart(
                                      distribution: data.qualityDistribution,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),

                          // Row 2: Heat Map (1/2) + University Leaderboard (1/2)
                          SizedBox(
                            height: 600,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildBentoCard(
                                    title: 'Geographic Distribution',
                                    subtitle: 'Contributions by region',
                                    child: HeatMapWidget(
                                      regionData: data.regionData,
                                    ),
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: _buildBentoCard(
                                    title: 'University Rankings',
                                    subtitle: 'Top contributing institutions',
                                    child: UniversityLeaderboard(
                                      universities: data.universityData,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),

                          // Row 3: Recent Activity (Full Width)
                          SizedBox(
                            height: 700,
                            child: _buildBentoCard(
                              title: 'Recent Activity',
                              subtitle: "What's happening in the system",
                              child: EdgeCaseMonitor(
                                rejectionReasons: data.rejectionReasons,
                                logs: data.recentLogs,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (trend != null) _buildTrendBadge(trend),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(double trend) {
    final isPositive = trend >= 0;
    final color = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${trend.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: _textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, AnalyticsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: viewModel.selectedRange,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textSecondary,
            size: 18,
          ),
          dropdownColor: _cardBg,
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: ['Last 7 Days', 'Last 30 Days', 'This Month']
              .map(
                (range) => DropdownMenuItem(
                  value: range,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: _textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(range),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) viewModel.updateDateRange(value);
          },
        ),
      ),
    );
  }

  String _calculateRate(int part, int total) {
    if (total == 0) return '0.0';
    return ((part / total) * 100).toStringAsFixed(1);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading analytics...',
            style: TextStyle(fontSize: 16, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AnalyticsViewModel viewModel) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error!,
              style: TextStyle(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => viewModel.loadData(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastRefresh(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
