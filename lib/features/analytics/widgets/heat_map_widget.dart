import 'package:flutter/material.dart';
import '../data/analytics_summary_model.dart';

class HeatMapWidget extends StatefulWidget {
  final List<RegionDataPoint> regionData;

  const HeatMapWidget({super.key, required this.regionData});

  @override
  State<HeatMapWidget> createState() => _HeatMapWidgetState();
}

class _HeatMapWidgetState extends State<HeatMapWidget> {
  // Light theme colors
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalUsers = widget.regionData.fold(0, (sum, r) => sum + r.userCount);
    final avgIntensity = widget.regionData.isEmpty
        ? 0.0
        : widget.regionData.map((r) => r.intensity).reduce((a, b) => a + b) /
              widget.regionData.length;

    // Sort by user count descending
    final sortedData = List<RegionDataPoint>.from(widget.regionData)
      ..sort((a, b) => b.userCount.compareTo(a.userCount));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: _borderColor)),
            ),
            child: Row(
              children: [
                _buildStat(
                  'Regions',
                  '${widget.regionData.length}',
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 24),
                _buildStat(
                  'Total Users',
                  '$totalUsers',
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 24),
                _buildStat(
                  'Avg Intensity',
                  '${(avgIntensity * 100).toStringAsFixed(0)}%',
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          // City bars
          Expanded(
            child: widget.regionData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 48,
                          color: _textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No geographic data',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: sortedData.length > 6 ? 6 : sortedData.length,
                    itemBuilder: (context, index) {
                      final point = sortedData[index];
                      return _buildCityBar(point, totalUsers);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: _textSecondary)),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCityBar(RegionDataPoint point, int totalUsers) {
    final percentage = totalUsers > 0 ? point.userCount / totalUsers : 0.0;
    final color = Color.lerp(
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      point.intensity,
    )!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    point.city,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${point.userCount} users',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: _borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
