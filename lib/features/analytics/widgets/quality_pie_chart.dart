import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class QualityPieChart extends StatefulWidget {
  final Map<String, int> distribution;

  const QualityPieChart({super.key, required this.distribution});

  @override
  State<QualityPieChart> createState() => _QualityPieChartState();
}

class _QualityPieChartState extends State<QualityPieChart> {
  int _touchedIndex = -1;

  // Light theme colors
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  bool get _hasData {
    if (widget.distribution.isEmpty) return false;
    final total = widget.distribution.values.fold(0, (a, b) => a + b);
    return total > 0;
  }

  @override
  Widget build(BuildContext context) {
    // Show empty state if no data
    if (!_hasData) {
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
                Icons.star_outline_rounded,
                size: 56,
                color: const Color(0xFFF59E0B).withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No rating data yet',
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Quality metrics will appear here\nonce submissions are reviewed',
                style: TextStyle(color: _textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final total = widget.distribution.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 45,
                sections: _generateSections(total),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Expanded(
            flex: 2,
            child: ListView(children: _buildLegendItems(total)),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(int total) {
    final colors = [
      const Color(0xFF10B981), // 5 Star - Emerald
      const Color(0xFF3B82F6), // 4 Star - Blue
      const Color(0xFFF59E0B), // 3 Star - Amber
      const Color(0xFFF97316), // 2 Star - Orange
      const Color(0xFFEF4444), // 1 Star - Red
    ];

    final keys = ['5 Star', '4 Star', '3 Star', '2 Star', '1 Star'];

    List<PieChartSectionData> sections = [];
    int sectionIndex = 0;

    for (int i = 0; i < keys.length; i++) {
      final count = widget.distribution[keys[i]] ?? 0;
      if (count > 0) {
        final isTouched = sectionIndex == _touchedIndex;
        final percentage = total > 0
            ? ((count / total) * 100).toStringAsFixed(0)
            : '0';

        sections.add(
          PieChartSectionData(
            color: colors[i],
            value: count.toDouble(),
            title: isTouched ? '$percentage%' : '',
            radius: isTouched ? 60 : 50,
            titleStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        sectionIndex++;
      }
    }

    return sections;
  }

  List<Widget> _buildLegendItems(int total) {
    final keys = ['5 Star', '4 Star', '3 Star', '2 Star', '1 Star'];
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFF97316),
      const Color(0xFFEF4444),
    ];

    List<Widget> legends = [];
    for (int i = 0; i < keys.length; i++) {
      final count = widget.distribution[keys[i]] ?? 0;
      if (count > 0) {
        final percentage = total > 0
            ? ((count / total) * 100).toStringAsFixed(1)
            : '0.0';
        legends.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors[i].withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors[i].withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: colors[i], size: 16),
                const SizedBox(width: 8),
                Text(
                  keys[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors[i].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors[i],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return legends;
  }
}
