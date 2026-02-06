import 'package:flutter/material.dart';
import '../data/analytics_summary_model.dart';

class UniversityLeaderboard extends StatefulWidget {
  final List<UniversityDataPoint> universities;

  const UniversityLeaderboard({super.key, required this.universities});

  @override
  State<UniversityLeaderboard> createState() => _UniversityLeaderboardState();
}

class _UniversityLeaderboardState extends State<UniversityLeaderboard> {
  String _sortBy = 'activeUsers';
  bool _sortAscending = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 5;
  String _searchQuery = '';

  // Light theme colors
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _bgColor = Color(0xFFF8FAFC);

  List<UniversityDataPoint> get _filteredAndSortedData {
    var data = List<UniversityDataPoint>.from(widget.universities);

    // Filter
    if (_searchQuery.isNotEmpty) {
      data = data
          .where(
            (u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Sort
    data.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'activeUsers':
        default:
          comparison = a.activeUsers.compareTo(b.activeUsers);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return data;
  }

  List<UniversityDataPoint> get _paginatedData {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredAndSortedData.length);
    if (start >= _filteredAndSortedData.length) return [];
    return _filteredAndSortedData.sublist(start, end);
  }

  int get _totalPages => (_filteredAndSortedData.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Sort Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    }),
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search university...',
                      hintStyle: TextStyle(color: _textSecondary, fontSize: 13),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _textSecondary,
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Sort dropdown
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: Colors.white,
                    iconEnabledColor: _textSecondary,
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                    items: const [
                      DropdownMenuItem(
                        value: 'activeUsers',
                        child: Text('By Students'),
                      ),
                      DropdownMenuItem(value: 'name', child: Text('By Name')),
                    ],
                    onChanged: (value) => setState(() {
                      _sortBy = value!;
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor),
                ),
                child: IconButton(
                  onPressed: () =>
                      setState(() => _sortAscending = !_sortAscending),
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: _textSecondary,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(width: 50, child: Text('RANK', style: _headerStyle)),
                Expanded(child: Text('UNIVERSITY', style: _headerStyle)),
                SizedBox(
                  width: 70,
                  child: Text(
                    'STUDENTS',
                    style: _headerStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Data Rows
          Expanded(
            child: _paginatedData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 40,
                          color: _textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No university data',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _paginatedData.length,
                    itemBuilder: (context, index) {
                      final uni = _paginatedData[index];
                      final globalIndex = _currentPage * _itemsPerPage + index;
                      return _buildRow(uni, globalIndex);
                    },
                  ),
          ),

          // Pagination
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_currentPage * _itemsPerPage + 1}-${((_currentPage + 1) * _itemsPerPage).clamp(0, _filteredAndSortedData.length)} of ${_filteredAndSortedData.length}',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
              Row(
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_currentPage + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
            ],
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: _textSecondary,
    letterSpacing: 0.5,
  );

  Widget _buildRow(UniversityDataPoint uni, int index) {
    final isTop3 = index < 3;
    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isTop3 ? rankColors[index].withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop3 ? rankColors[index].withOpacity(0.2) : _borderColor,
        ),
      ),
      child: Row(
        children: [
          // Rank with trophy
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isTop3 ? rankColors[index].withOpacity(0.15) : _bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isTop3
                  ? Icon(
                      Icons.emoji_events_rounded,
                      size: 18,
                      color: rankColors[index],
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // University name
          Expanded(
            child: Text(
              uni.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Student count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${uni.activeUsers}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
