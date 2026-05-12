import 'package:flutter/material.dart';
import '../data/analytics_summary_model.dart';

class EdgeCaseMonitor extends StatefulWidget {
  final List<RejectionReason> rejectionReasons;
  final List<LogEntry> logs;

  const EdgeCaseMonitor({
    super.key,
    required this.rejectionReasons,
    required this.logs,
  });

  @override
  State<EdgeCaseMonitor> createState() => _EdgeCaseMonitorState();
}

class _EdgeCaseMonitorState extends State<EdgeCaseMonitor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _logFilter = 'all';
  int _currentPage = 0;
  static const int _logsPerPage = 6;

  // Light theme colors
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _bgColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<LogEntry> get _filteredLogs {
    if (_logFilter == 'all') return widget.logs;
    return widget.logs.where((log) => log.type == _logFilter).toList();
  }

  List<LogEntry> get _paginatedLogs {
    final start = _currentPage * _logsPerPage;
    final end = (start + _logsPerPage).clamp(0, _filteredLogs.length);
    if (start >= _filteredLogs.length) return [];
    return _filteredLogs.sublist(start, end);
  }

  int get _totalPages => (_filteredLogs.length / _logsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: _borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3B82F6),
              indicatorWeight: 3,
              labelColor: _textPrimary,
              unselectedLabelColor: _textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Rejection Reasons'),
                Tab(text: 'System Logs'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildRejectionReasonsTab(), _buildLogsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReasonsTab() {
    if (widget.rejectionReasons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: const Color(0xFF10B981).withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No rejection data',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All submissions are on track!',
              style: TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final maxCount = widget.rejectionReasons
        .map((r) => r.count)
        .reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.rejectionReasons.length,
      itemBuilder: (context, index) {
        final reason = widget.rejectionReasons[index];
        final progress = reason.count / maxCount;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reason.reason,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${reason.count}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: _borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                      const Color(0xFFF59E0B),
                      const Color(0xFFEF4444),
                      progress,
                    )!,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Filter buttons
          Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Errors', 'error'),
              const SizedBox(width: 8),
              _buildFilterChip('Warnings', 'warning'),
              const SizedBox(width: 8),
              _buildFilterChip('Info', 'info'),
              const Spacer(),
              Text(
                '${_filteredLogs.length} logs',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logs list
          Expanded(
            child: _paginatedLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 40,
                          color: _textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No logs found',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _paginatedLogs.length,
                    itemBuilder: (context, index) =>
                        _buildLogRow(_paginatedLogs[index]),
                  ),
          ),

          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                    ),
                    child: const Text('Prev'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _logFilter == value;
    return GestureDetector(
      onTap: () => setState(() {
        _logFilter = value;
        _currentPage = 0;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.1)
              : _bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : _borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF3B82F6) : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLogRow(LogEntry log) {
    Color iconColor;
    IconData icon;
    Color bgColor;

    switch (log.type) {
      case 'error':
        iconColor = const Color(0xFFEF4444);
        icon = Icons.error_rounded;
        bgColor = const Color(0xFFEF4444).withOpacity(0.1);
        break;
      case 'warning':
        iconColor = const Color(0xFFF59E0B);
        icon = Icons.warning_rounded;
        bgColor = const Color(0xFFF59E0B).withOpacity(0.1);
        break;
      default:
        iconColor = const Color(0xFF3B82F6);
        icon = Icons.info_rounded;
        bgColor = const Color(0xFF3B82F6).withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(log.timestamp),
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
