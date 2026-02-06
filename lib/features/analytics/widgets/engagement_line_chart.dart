import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/analytics_summary_model.dart';

class EngagementLineChart extends StatefulWidget {
  final List<ActivityDataPoint> dataPoints;

  const EngagementLineChart({super.key, required this.dataPoints});

  @override
  State<EngagementLineChart> createState() => _EngagementLineChartState();
}

class _EngagementLineChartState extends State<EngagementLineChart> {
  String _viewRange = '7d';

  // Light theme colors
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  List<ActivityDataPoint> get _filteredData {
    var data = List<ActivityDataPoint>.from(widget.dataPoints)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (_viewRange == '7d' && data.length > 7) {
      return data.sublist(data.length - 7);
    } else if (_viewRange == '14d' && data.length > 14) {
      return data.sublist(data.length - 14);
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: _textSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No activity data yet',
                style: TextStyle(color: _textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Data will appear once submissions are made',
                style: TextStyle(
                  color: _textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedPoints = _filteredData;
    double maxY = 0;
    double totalCount = 0;
    for (var point in sortedPoints) {
      if (point.count.toDouble() > maxY) maxY = point.count.toDouble();
      totalCount += point.count;
    }
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _buildMiniStat(
                'TOTAL',
                totalCount.toInt().toString(),
                const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                'AVERAGE',
                (totalCount / sortedPoints.length).toStringAsFixed(0),
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                'PEAK',
                maxY.toInt().toString(),
                const Color(0xFFF59E0B),
              ),
              const Spacer(),
              // Range selector
              _buildRangeSelector(),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: _borderColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (sortedPoints.length / 5).ceilToDouble().clamp(
                        1,
                        double.infinity,
                      ),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedPoints.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat(
                                'MMM d',
                              ).format(sortedPoints[index].date),
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: _textSecondary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedPoints.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedPoints.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFF3B82F6),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.2),
                          const Color(0xFF3B82F6).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    tooltipMargin: 12,
                    tooltipBgColor: _textPrimary,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        if (barSpot.x < 0 || barSpot.x >= sortedPoints.length) {
                          return null;
                        }
                        final date = sortedPoints[barSpot.x.toInt()].date;
                        return LineTooltipItem(
                          '${DateFormat('EEE, MMM d').format(date)}\n',
                          TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: barSpot.y.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: ' translations',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildRangeButton('7D', '7d'),
          _buildRangeButton('14D', '14d'),
          _buildRangeButton('All', 'all'),
        ],
      ),
    );
  }

  Widget _buildRangeButton(String label, String value) {
    final isSelected = _viewRange == value;
    return GestureDetector(
      onTap: () => setState(() => _viewRange = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? _textPrimary : _textSecondary,
          ),
        ),
      ),
    );
  }
}
