import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/export_service.dart';
import '../data/moderation_model.dart';
import '../viewmodels/moderation_viewmodel.dart';
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

  // One search controller per tab
  final _submittedSearchCtrl = TextEditingController();
  final _inReviewSearchCtrl = TextEditingController();
  final _acceptedSearchCtrl = TextEditingController();
  final _rejectedSearchCtrl = TextEditingController();
  final _skippedSearchCtrl = TextEditingController();

  static const _bgColor = Color(0xFFF8FAFC);
  static const _sidebarBg = Color(0xFFFFFFFF);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);
  static const _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _submittedSearchCtrl.dispose();
    _inReviewSearchCtrl.dispose();
    _acceptedSearchCtrl.dispose();
    _rejectedSearchCtrl.dispose();
    _skippedSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ModerationViewModel>();

    return Scaffold(
      backgroundColor: _bgColor,
      body: vm.isLoading && vm.submittedTranslations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                _buildSidebar(vm),
                Expanded(child: _buildMainContent(context, vm)),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------
  Widget _buildSidebar(ModerationViewModel vm) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: _sidebarBg,
        border: Border(right: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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

          // Stats cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildStatCard(
                    title: 'Submitted',
                    value: vm.stats.submitted.toString(),
                    icon: Icons.send_outlined,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    title: 'In Review',
                    value: vm.stats.inReview.toString(),
                    icon: Icons.rate_review_outlined,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    title: 'Accepted',
                    value: vm.stats.approved.toString(),
                    icon: Icons.check_circle_outline,
                    color: AppColors.softMint,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    title: 'Rejected',
                    value: vm.stats.rejected.toString(),
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    title: 'Skipped',
                    value: vm.stats.skipped.toString(),
                    icon: Icons.skip_next,
                    color: AppColors.slateGray,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Refresh button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: vm.isLoading ? null : vm.loadData,
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(vm.isLoading ? 'Loadingâ€¦' : 'Refresh'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
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

  // ---------------------------------------------------------------------------
  // Main content
  // ---------------------------------------------------------------------------
  Widget _buildMainContent(BuildContext context, ModerationViewModel vm) {
    return Container(
      color: _bgColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(vm),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAttemptTab(
                    context: context,
                    vm: vm,
                    rawList: vm.submittedTranslations,
                    filteredList: vm.filteredSubmittedTranslations,
                    searchCtrl: _submittedSearchCtrl,
                    searchValue: vm.submittedSearch,
                    onSearch: vm.setSubmittedSearch,
                    showActions: true,
                    emptyTitle: 'No submitted translations',
                    emptySubtitle: 'All caught up â€” no new submissions.',
                    tableTitle: 'Submitted Translations',
                    tableIcon: Icons.send_outlined,
                    iconColor: Colors.blue,
                    exportFileName: 'submitted_translations',
                  ),
                  _buildAttemptTab(
                    context: context,
                    vm: vm,
                    rawList: vm.inReviewTranslations,
                    filteredList: vm.filteredInReviewTranslations,
                    searchCtrl: _inReviewSearchCtrl,
                    searchValue: vm.inReviewSearch,
                    onSearch: vm.setInReviewSearch,
                    showActions: true,
                    emptyTitle: 'No translations in review',
                    emptySubtitle: 'Nothing currently assigned to reviewers.',
                    tableTitle: 'In Review',
                    tableIcon: Icons.rate_review_outlined,
                    iconColor: Colors.orangeAccent,
                    exportFileName: 'in_review_translations',
                  ),
                  _buildAttemptTab(
                    context: context,
                    vm: vm,
                    rawList: vm.acceptedTranslations,
                    filteredList: vm.filteredAcceptedTranslations,
                    searchCtrl: _acceptedSearchCtrl,
                    searchValue: vm.acceptedSearch,
                    onSearch: vm.setAcceptedSearch,
                    showActions: false,
                    emptyTitle: 'No accepted translations yet',
                    emptySubtitle: 'Approved translations will appear here.',
                    tableTitle: 'Accepted Translations',
                    tableIcon: Icons.check_circle_outline,
                    iconColor: AppColors.softMint,
                    exportFileName: 'accepted_translations',
                  ),
                  _buildAttemptTab(
                    context: context,
                    vm: vm,
                    rawList: vm.rejectedTranslations,
                    filteredList: vm.filteredRejectedTranslations,
                    searchCtrl: _rejectedSearchCtrl,
                    searchValue: vm.rejectedSearch,
                    onSearch: vm.setRejectedSearch,
                    showActions: false,
                    emptyTitle: 'No rejected translations',
                    emptySubtitle: 'Rejected translations will appear here.',
                    tableTitle: 'Rejected Translations',
                    tableIcon: Icons.cancel_outlined,
                    iconColor: AppColors.error,
                    exportFileName: 'rejected_translations',
                  ),
                  _buildSkippedTab(context, vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ModerationViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
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
            SizedBox(height: 4),
            Text(
              'Review and manage translation submissions',
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
          ],
        ),
        if (vm.error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 16),
                SizedBox(width: 6),
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
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Submitted'),
          Tab(text: 'In Review'),
          Tab(text: 'Accepted'),
          Tab(text: 'Rejected'),
          Tab(text: 'Skipped'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Generic attempt tab (Submitted / In Review / Accepted / Rejected)
  // ---------------------------------------------------------------------------
  Widget _buildAttemptTab({
    required BuildContext context,
    required ModerationViewModel vm,
    required List<TranslationAttempt> rawList,
    required List<TranslationAttempt> filteredList,
    required TextEditingController searchCtrl,
    required String searchValue,
    required void Function(String) onSearch,
    required bool showActions,
    required String emptyTitle,
    required String emptySubtitle,
    required String tableTitle,
    required IconData tableIcon,
    required Color iconColor,
    required String exportFileName,
  }) {
    if (rawList.isEmpty && searchValue.isEmpty) {
      return _buildEmptyState(
        emptyTitle,
        emptySubtitle,
        tableIcon,
        iconColor,
      );
    }

    final dataSource = TranslationDataSource(
      filteredList,
      context,
      vm,
      showActions: showActions,
    );

    return Column(
      children: [
        // Search + export row
        _buildSearchExportRow(
          searchCtrl: searchCtrl,
          hint: 'Search by user, sentence or IDâ€¦',
          searchValue: searchValue,
          onSearch: onSearch,
          onExport: () => _exportAttempts(context, filteredList, exportFileName),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                'Showing ${filteredList.length} of ${rawList.length} records',
                style: const TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildTableCard(
            context: context,
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
                    Icon(tableIcon, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      tableTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                sortColumnIndex: vm.translationSortColumnIndex,
                sortAscending: vm.sortAscending,
                columns: [
                  DataColumn(
                    label: const Text('ID',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onSort: vm.sortTranslationByColumnIndex,
                  ),
                  DataColumn(
                    label: const Text('USER',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onSort: vm.sortTranslationByColumnIndex,
                  ),
                  const DataColumn(
                    label: Text('SENTENCE',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  DataColumn(
                    label: const Text('STATUS',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onSort: vm.sortTranslationByColumnIndex,
                  ),
                  const DataColumn(
                    label: Text('REVIEW',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  DataColumn(
                    label: const Text('SUBMITTED',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onSort: vm.sortTranslationByColumnIndex,
                  ),
                  const DataColumn(
                    label: Text('ACTIONS',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Skipped tab
  // ---------------------------------------------------------------------------
  Widget _buildSkippedTab(BuildContext context, ModerationViewModel vm) {
    if (vm.skippedTranslations.isEmpty) {
      return _buildEmptyState(
        'No skipped translations',
        'There are no skipped translation records.',
        Icons.skip_next_outlined,
        _textSecondary,
      );
    }

    final dataSource = SkippedDataSource(
      vm.filteredSkippedTranslations,
      context,
      vm,
    );

    return Column(
      children: [
        _buildSearchExportRow(
          searchCtrl: _skippedSearchCtrl,
          hint: 'Search by user, sentence or reasonâ€¦',
          searchValue: vm.skippedSearchQuery,
          onSearch: vm.setSkippedSearchQuery,
          onExport: () => _exportSkipped(context, vm.filteredSkippedTranslations),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                'Showing ${vm.filteredSkippedTranslations.length} of ${vm.skippedTranslations.length} records',
                style: const TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildTableCard(
            context: context,
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
                header: const Row(
                  children: [
                    Icon(Icons.skip_next, color: _textSecondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Skipped List',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
                sortColumnIndex: vm.skippedSortColumnIndex,
                sortAscending: vm.skippedSortAscending,
                columns: [
                  DataColumn(
                    label: const Text('USER',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onSort: vm.sortSkippedByColumnIndex,
                  ),
                  DataColumn(
                    label: const Text('SENTENCE',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onSort: vm.sortSkippedByColumnIndex,
                  ),
                  const DataColumn(
                    label: Text('REASON',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  DataColumn(
                    label: const Text('SKIPPED AT',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    onSort: vm.sortSkippedByColumnIndex,
                  ),
                  const DataColumn(
                    label: Text('ACTIONS',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared UI helpers
  // ---------------------------------------------------------------------------
  Widget _buildSearchExportRow({
    required TextEditingController searchCtrl,
    required String hint,
    required String searchValue,
    required void Function(String) onSearch,
    required VoidCallback onExport,
  }) {
    // Keep controller in sync with VM state
    if (searchCtrl.text != searchValue) {
      searchCtrl.text = searchValue;
      searchCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: searchValue.length));
    }

    return Row(
      children: [
        Expanded(
          child: Container(
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
              controller: searchCtrl,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: _textSecondary),
                suffixIcon: searchValue.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: _textSecondary, size: 20),
                        onPressed: () {
                          searchCtrl.clear();
                          onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _textPrimary,
            side: const BorderSide(color: _borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard({
    required BuildContext context,
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
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(child: SizedBox(width: double.infinity, child: child)),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export helpers
  // ---------------------------------------------------------------------------
  void _exportAttempts(
    BuildContext context,
    List<TranslationAttempt> data,
    String fileName,
  ) {
    ExportService.exportToExcel(
      context: context,
      fileName: fileName,
      headers: const [
        'ID',
        'User',
        'Sentence (Khuwar)',
        'Urdu Translation',
        'Roman Translation',
        'Status',
        'Review Rating',
        'Submitted At',
      ],
      rows: data
          .map(
            (t) => [
              t.id,
              t.userName,
              t.sentence,
              t.urduTranslation,
              t.romanTranslation,
              t.status,
              t.reviewRating?.toString() ?? '',
              t.submittedAt.toIso8601String(),
            ],
          )
          .toList(),
    );
  }

  void _exportSkipped(
    BuildContext context,
    List<SkippedSentence> data,
  ) {
    ExportService.exportToExcel(
      context: context,
      fileName: 'skipped_translations',
      headers: const [
        'ID',
        'User',
        'Sentence (Khuwar)',
        'Reason',
        'Skipped At',
      ],
      rows: data
          .map(
            (s) => [
              s.id,
              s.userName,
              s.sentenceText,
              s.reason ?? '',
              s.skippedAt.toIso8601String(),
            ],
          )
          .toList(),
    );
  }
}
