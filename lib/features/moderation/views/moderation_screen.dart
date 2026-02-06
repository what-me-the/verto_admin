import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/moderation_viewmodel.dart';
import '../widgets/moderation_stats_widget.dart';
import 'moderation_datasource.dart';
import 'skipped_datasource.dart';

class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ModerationViewModel()..loadData(),
      child: const ModerationContent(),
    );
  }
}

class ModerationContent extends StatefulWidget {
  const ModerationContent({super.key});

  @override
  State<ModerationContent> createState() => _ModerationContentState();
}

class _ModerationContentState extends State<ModerationContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pendingSearchController =
      TextEditingController();
  final TextEditingController _skippedSearchController =
      TextEditingController();

  // Colors matching analytics screen
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _sidebarBg = Color(0xFFFFFFFF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingSearchController.dispose();
    _skippedSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ModerationViewModel>();

    return Scaffold(
      backgroundColor: _bgColor,
      body: viewModel.isLoading && viewModel.pendingTranslations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left Sidebar - Stats
                _buildSidebar(viewModel),
                // Main Content Area
                Expanded(child: _buildMainContent(context, viewModel)),
              ],
            ),
    );
  }

  Widget _buildSidebar(ModerationViewModel viewModel) {
    return Container(
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
                      colors: [AppColors.earthyCoral, AppColors.coralDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.content_paste_search,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Moderation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Content Review',
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
                  'OVERVIEW',
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
                    title: 'Pending',
                    value: viewModel.stats.totalPending.toString(),
                    icon: Icons.hourglass_empty,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 10),
                  _buildQuickStat(
                    title: 'Approved',
                    value: viewModel.stats.approved.toString(),
                    icon: Icons.check_circle_outline,
                    color: AppColors.softMint,
                  ),
                  const SizedBox(height: 10),
                  _buildQuickStat(
                    title: 'Rejected',
                    value: viewModel.stats.rejected.toString(),
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 10),
                  _buildQuickStat(
                    title: 'Skipped',
                    value: viewModel.stats.skipped.toString(),
                    icon: Icons.skip_next,
                    color: AppColors.slateGray,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Refresh button at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => viewModel.loadData(),
                    icon: viewModel.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(viewModel.isLoading ? 'Loading...' : 'Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.earthyCoral,
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
    );
  }

  Widget _buildQuickStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
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
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    ModerationViewModel viewModel,
  ) {
    return Container(
      color: _bgColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, viewModel),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTab(context, viewModel),
                  _buildSkippedTab(context, viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ModerationViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Moderation',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review and manage translation submissions',
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
          ],
        ),
        if (viewModel.error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Error loading data',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.earthyCoral,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Pending Translations'),
          Tab(text: 'Skipped List'),
        ],
      ),
    );
  }

  Widget _buildPendingTab(BuildContext context, ModerationViewModel viewModel) {
    if (viewModel.pendingTranslations.isEmpty &&
        viewModel.searchQuery.isEmpty) {
      return _buildEmptyState(
        'No pending translations',
        'Good job! All translations have been reviewed.',
        Icons.check_circle_outline,
        AppColors.softMint,
      );
    }

    final dataSource = TranslationDataSource(
      viewModel.filteredPendingTranslations,
      context,
      viewModel,
    );

    return Column(
      children: [
        // Search and Filter Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildSearchBar(
                controller: _pendingSearchController,
                hint: 'Search by User, Sentence, or ID...',
                onChanged: viewModel.setSearchQuery,
                value: viewModel.searchQuery,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildStatusFilter(viewModel)),
          ],
        ),
        const SizedBox(height: 16),
        // Results count
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                'Showing ${viewModel.filteredPendingTranslations.length} of ${viewModel.pendingTranslations.length} submissions',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      cardTheme: const CardThemeData(
                        elevation: 0,
                        color: Colors.white,
                        margin: EdgeInsets.zero,
                      ),
                    ),
                    child: PaginatedDataTable(
                      source: dataSource,
                      header: Row(
                        children: [
                          const Icon(
                            Icons.pending_actions,
                            color: AppColors.earthyCoral,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pending Submissions',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      sortColumnIndex: viewModel.pendingSortColumnIndex,
                      sortAscending: viewModel.pendingSortAscending,
                      columns: [
                        DataColumn(
                          label: const Text(
                            'ID',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onSort: (i, asc) =>
                              viewModel.sortPendingByColumnIndex(i, asc),
                        ),
                        DataColumn(
                          label: const Text(
                            'USER',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onSort: (i, asc) =>
                              viewModel.sortPendingByColumnIndex(i, asc),
                        ),
                        const DataColumn(
                          label: Text(
                            'SENTENCE',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: const Text(
                            'STATUS',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onSort: (i, asc) =>
                              viewModel.sortPendingByColumnIndex(i, asc),
                        ),
                        const DataColumn(
                          label: Text(
                            'REVIEW',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: const Text(
                            'SUBMITTED',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onSort: (i, asc) =>
                              viewModel.sortPendingByColumnIndex(i, asc),
                        ),
                        const DataColumn(
                          label: Text(
                            'ACTIONS',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      columnSpacing: 20,
                      horizontalMargin: 24,
                      rowsPerPage: 10,
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF9FAFB),
                      ),
                      headingRowHeight: 56,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 72,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkippedTab(BuildContext context, ModerationViewModel viewModel) {
    if (viewModel.skippedTranslations.isEmpty) {
      return _buildEmptyState(
        'No skipped translations',
        'There are no skipped translation records.',
        Icons.skip_next_outlined,
        _textSecondary,
      );
    }

    final dataSource = SkippedDataSource(
      viewModel.filteredSkippedTranslations,
      context,
      viewModel,
    );

    return Column(
      children: [
        _buildSearchBar(
          controller: _skippedSearchController,
          hint: 'Search by User, Sentence, or Reason...',
          onChanged: viewModel.setSkippedSearchQuery,
          value: viewModel.skippedSearchQuery,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                'Showing ${viewModel.filteredSkippedTranslations.length} of ${viewModel.skippedTranslations.length} skipped items',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      cardTheme: const CardThemeData(
                        elevation: 0,
                        color: Colors.white,
                        margin: EdgeInsets.zero,
                      ),
                    ),
                    child: PaginatedDataTable(
                      source: dataSource,
                      header: Row(
                        children: [
                          Icon(
                            Icons.skip_next,
                            color: _textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Skipped List',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      sortColumnIndex: viewModel.skippedSortColumnIndex,
                      sortAscending: viewModel.skippedSortAscending,
                      columns: [
                        DataColumn(
                          label: const Text(
                            'USER',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onSort: (i, asc) =>
                              viewModel.sortSkippedByColumnIndex(i, asc),
                        ),
                        DataColumn(
                          label: const Text(
                            'SENTENCE',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onSort: (i, asc) =>
                              viewModel.sortSkippedByColumnIndex(i, asc),
                        ),
                        const DataColumn(
                          label: Text(
                            'REASON',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataColumn(
                          label: const Text(
                            'SKIPPED AT',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onSort: (i, asc) =>
                              viewModel.sortSkippedByColumnIndex(i, asc),
                        ),
                        const DataColumn(
                          label: Text(
                            'ACTIONS',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      columnSpacing: 24,
                      horizontalMargin: 24,
                      rowsPerPage: 10,
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF9FAFB),
                      ),
                      headingRowHeight: 56,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 72,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    required String value,
  }) {
    if (controller.text != value) {
      controller.text = value;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: _textSecondary),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: _textSecondary, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStatusFilter(ModerationViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StatusFilter>(
          value: viewModel.statusFilter,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: _textSecondary),
          items: const [
            DropdownMenuItem(
              value: StatusFilter.all,
              child: Row(
                children: [
                  Icon(Icons.all_inclusive, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text('All Status'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: StatusFilter.pending,
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Pending'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: StatusFilter.assigned,
              child: Row(
                children: [
                  Icon(Icons.assignment, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Assigned'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              viewModel.setStatusFilter(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: _textSecondary)),
        ],
      ),
    );
  }
}
