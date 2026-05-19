import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/export_service.dart';
import '../viewmodels/users_viewmodel.dart';
import '../data/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette constants (module-level so all widgets share them)
// ─────────────────────────────────────────────────────────────────────────────
const _bgColor = Color(0xFFF8FAFC);
const _cardBg = Color(0xFFFFFFFF);
const _borderColor = Color(0xFFE2E8F0);
const _textPrimary = Color(0xFF1E293B);
const _textSecondary = Color(0xFF64748B);
const _headerBg = Color(0xFFF1F5F9);

// ─────────────────────────────────────────────────────────────────────────────
// Clipboard helper
// ─────────────────────────────────────────────────────────────────────────────
void _showCopied(BuildContext ctx, String message) {
  ScaffoldMessenger.of(ctx)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        width: 280,
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────────────────────────────────────
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late final UsersViewModel _vm;
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = UsersViewModel();
    _vm.loadUsers();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.index == 1 && !_tabController.indexIsChanging) {
          _vm.loadAnalytics();
        }
      });
  }

  @override
  void dispose() {
    _vm.dispose();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: _UsersShell(searchCtrl: _searchCtrl, tabCtrl: _tabController),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shell — centers + caps max width at 1400px
// ─────────────────────────────────────────────────────────────────────────────
class _UsersShell extends StatelessWidget {
  final TextEditingController searchCtrl;
  final TabController tabCtrl;

  const _UsersShell({required this.searchCtrl, required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UsersViewModel>();
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(vm: vm),
              _TabBarRow(tabCtrl: tabCtrl),
              Expanded(
                child: TabBarView(
                  controller: tabCtrl,
                  children: [
                    _UsersTab(vm: vm, searchCtrl: searchCtrl),
                    _AnalyticsTab(vm: vm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header with stat chips
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final UsersViewModel vm;
  const _Header({required this.vm});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.height < 800;
    return Container(
      padding: EdgeInsets.fromLTRB(24, compact ? 12 : 24, 24, compact ? 8 : 16),
      color: _cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Management', style: AppTypography.h3),
                    const SizedBox(height: 4),
                    Text(
                      'View and manage all registered users',
                      style: AppTypography.bodyMedium
                          .copyWith(color: _textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: vm.loadUsers,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                color: AppColors.slateGray,
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _StatChip(
                icon: Icons.people_rounded,
                label: 'Total Users',
                value: vm.totalUsers,
                color: AppColors.earthyCoral,
              ),
              _StatChip(
                icon: Icons.school_rounded,
                label: 'Students',
                value: vm.studentCount,
                color: AppColors.softMint,
              ),
              _StatChip(
                icon: Icons.person_rounded,
                label: 'Non-Students',
                value: vm.nonStudentCount,
                color: AppColors.warmBeige,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: AppTypography.bodyMedium.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar row
// ─────────────────────────────────────────────────────────────────────────────
class _TabBarRow extends StatelessWidget {
  final TabController tabCtrl;
  const _TabBarRow({required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cardBg,
      child: Column(
        children: [
          TabBar(
            controller: tabCtrl,
            labelColor: AppColors.earthyCoral,
            unselectedLabelColor: _textSecondary,
            indicatorColor: AppColors.earthyCoral,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
            tabs: const [Tab(text: 'Users'), Tab(text: 'Analytics')],
          ),
          const Divider(color: _borderColor, height: 1),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users tab
// ─────────────────────────────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  final UsersViewModel vm;
  final TextEditingController searchCtrl;

  const _UsersTab({required this.vm, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(vm: vm, searchCtrl: searchCtrl),
        Expanded(
          child: vm.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.earthyCoral))
              : vm.error != null
                  ? _ErrorView(vm: vm)
                  : _UsersContent(vm: vm),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final UsersViewModel vm;
  final TextEditingController searchCtrl;

  const _FilterBar({required this.vm, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.height < 800;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: compact ? 8 : 12),
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Filters (search + dropdowns) ─────────────────────────────
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search
                SizedBox(
                  width: 260,
                  height: 38,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: vm.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search name, email or city…',
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AppColors.slateGray),
                      suffixIcon: vm.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                searchCtrl.clear();
                                vm.setSearchQuery('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.earthyCoral)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      filled: true,
                      fillColor: _bgColor,
                    ),
                    style:
                        AppTypography.bodyMedium.copyWith(fontSize: 14),
                  ),
                ),
                // City
                if (vm.cities.isNotEmpty)
                  _DropdownBox<String?>(
                    value: vm.selectedCity,
                    hint: 'All Cities',
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All Cities')),
                      ...vm.cities.map((c) => DropdownMenuItem<String?>(
                          value: c, child: Text(c))),
                    ],
                    onChanged: vm.setCityFilter,
                  ),
                // Student filter
                _DropdownBox<String>(
                  value: vm.isStudentFilter == null
                      ? 'all'
                      : vm.isStudentFilter!
                          ? 'student'
                          : 'non_student',
                  items: const [
                    DropdownMenuItem(
                        value: 'all', child: Text('All Users')),
                    DropdownMenuItem(
                        value: 'student', child: Text('Students')),
                    DropdownMenuItem(
                        value: 'non_student',
                        child: Text('Non-Students')),
                  ],
                  onChanged: (val) {
                    if (val == 'all') {
                      vm.setStudentFilter(null);
                    } else if (val == 'student') {
                      vm.setStudentFilter(true);
                    } else {
                      vm.setStudentFilter(false);
                    }
                  },
                ),
                // Clear
                if (vm.selectedCity != null ||
                    vm.isStudentFilter != null ||
                    vm.searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      searchCtrl.clear();
                      vm.clearFilters();
                    },
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Clear filters'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.slateGray),
                  ),
              ],
            ),
          ),
          // ── Count + action icons (only when data ready) ───────────────
          if (!vm.isLoading && vm.error == null && vm.users.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              '${vm.users.length} users',
              style: AppTypography.bodyMedium.copyWith(
                  fontSize: 12, color: _textSecondary),
            ),
            Tooltip(
              message: 'Copy all emails to clipboard',
              child: IconButton(
                onPressed: () => _copyBulkEmails(context, vm.users),
                icon: const Icon(Icons.content_copy_outlined, size: 18),
                color: _textSecondary,
                constraints:
                    const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: const EdgeInsets.all(6),
              ),
            ),
            Tooltip(
              message: 'Export to Excel',
              child: IconButton(
                onPressed: () => _exportUsers(context, vm.users),
                icon: const Icon(Icons.download_outlined, size: 18),
                color: _textSecondary,
                constraints:
                    const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: const EdgeInsets.all(6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _copyBulkEmails(BuildContext context, List<UserProfile> users) {
    final emails = users
        .map((u) => u.email ?? '')
        .where((e) => e.isNotEmpty)
        .join('\n');
    if (emails.isEmpty) {
      _showCopied(context, 'No emails to copy');
      return;
    }
    Clipboard.setData(ClipboardData(text: emails)).then((_) {
      final count =
          users.where((u) => (u.email ?? '').isNotEmpty).length;
      _showCopied(context,
          '$count email${count == 1 ? '' : 's'} copied to clipboard');
    });
  }

  void _exportUsers(BuildContext context, List<UserProfile> users) {
    final fmt = DateFormat('MMM d, yyyy');
    ExportService.exportToExcel(
      context: context,
      fileName: 'users',
      headers: const [
        'Full Name',
        'Email',
        'City',
        'University',
        'Type',
        'Pending Trans',
        'Accepted Trans',
        'Rejected Trans',
        'Skipped Trans',
        'Total Trans',
        'Joined',
        'Last Sign In',
      ],
      rows: users
          .map((u) => [
                u.fullName,
                u.email ?? '',
                u.city ?? '',
                u.universityName ?? '',
                u.isStudent ? 'Student' : 'General',
                u.pendingCount,
                u.approvedCount,
                u.rejectedCount,
                u.skippedCount,
                u.translationCount,
                fmt.format(u.createdAt),
                u.lastSignInAt != null
                    ? fmt.format(u.lastSignInAt!)
                    : '—',
              ])
          .toList(),
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  final T value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownBox({
    required this.value,
    this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonHideUnderline(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(8),
            color: _bgColor,
          ),
          child: DropdownButton<T>(
            value: value,
            hint: hint != null
                ? Text(hint!,
                    style: AppTypography.bodyMedium
                        .copyWith(fontSize: 14, color: _textSecondary))
                : null,
            items: items,
            onChanged: onChanged,
            style: AppTypography.bodyMedium
                .copyWith(fontSize: 14, color: _textPrimary),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final UsersViewModel vm;
  const _ErrorView({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(vm.error ?? 'Unknown error', style: AppTypography.body),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: vm.loadUsers,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.earthyCoral),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users content (result count row + table)
// ─────────────────────────────────────────────────────────────────────────────
class _UsersContent extends StatelessWidget {
  final UsersViewModel vm;
  const _UsersContent({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64,
                color: AppColors.slateGray.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No users found',
                style:
                    AppTypography.body.copyWith(color: _textSecondary)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _UsersTable(users: vm.users),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users DataTable — 9 sortable columns + horizontal/vertical scroll
// ─────────────────────────────────────────────────────────────────────────────
class _UsersTable extends StatefulWidget {
  final List<UserProfile> users;
  const _UsersTable({required this.users});

  @override
  State<_UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<_UsersTable> {
  // 0=Name 1=City 2=University 3=Pending 4=Accepted 5=Rejected 6=Skipped 7=Joined 8=LastSignIn 9=Type
  int _sortCol = 7;
  bool _sortAsc = false;
  late List<UserProfile> _sorted;
  late final DateFormat _fmt;

  // Synchronized horizontal scroll controllers — header stays pinned while
  // the body scrolls vertically; both scroll horizontally in lock-step.
  late final ScrollController _headerHScroll;
  late final ScrollController _bodyHScroll;
  bool _syncing = false;

  // ── Column definitions ────────────────────────────────────────────────────
  static const _labels = [
    'NAME', 'CITY', 'UNIVERSITY',
    'PENDING', 'ACCEPTED', 'REJECTED', 'SKIPPED',
    'JOINED', 'LAST SIGN IN', 'TYPE',
  ];
  static const _widths = [
    210.0, 100.0, 160.0, 88.0, 90.0, 88.0, 88.0, 110.0, 128.0, 90.0,
  ];
  static const _numeric = [
    false, false, false, true, true, true, true, false, false, false,
  ];
  static const _sortable = [
    true, true, true, true, true, true, true, true, true, false,
  ];

  static const _hPad = 20.0;
  static const _colSpacing = 20.0;
  static const _rowHeight = 52.0;
  static const _headerHeight = 44.0;

  double get _totalWidth =>
      _hPad * 2 +
      _widths.fold(0.0, (s, w) => s + w) +
      _colSpacing * (_widths.length - 1);

  @override
  void initState() {
    super.initState();
    _fmt = DateFormat('MMM d, yyyy');
    _sorted = List.from(widget.users);
    _applySort();
    _headerHScroll = ScrollController();
    _bodyHScroll = ScrollController();
    _headerHScroll.addListener(_syncBodyFromHeader);
    _bodyHScroll.addListener(_syncHeaderFromBody);
  }

  void _syncBodyFromHeader() {
    if (_syncing || !_bodyHScroll.hasClients) return;
    _syncing = true;
    _bodyHScroll.jumpTo(_headerHScroll.offset);
    _syncing = false;
  }

  void _syncHeaderFromBody() {
    if (_syncing || !_headerHScroll.hasClients) return;
    _syncing = true;
    _headerHScroll.jumpTo(_bodyHScroll.offset);
    _syncing = false;
  }

  @override
  void dispose() {
    _headerHScroll.dispose();
    _bodyHScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_UsersTable old) {
    super.didUpdateWidget(old);
    if (old.users != widget.users) {
      _sorted = List.from(widget.users);
      _applySort();
    }
  }

  void _applySort() {
    _sorted.sort((a, b) {
      final int cmp;
      switch (_sortCol) {
        case 0:
          cmp = a.fullName.compareTo(b.fullName);
          break;
        case 1:
          cmp = (a.city ?? '').compareTo(b.city ?? '');
          break;
        case 2:
          cmp =
              (a.universityName ?? '').compareTo(b.universityName ?? '');
          break;
        case 3:
          cmp = a.pendingCount.compareTo(b.pendingCount);
          break;
        case 4:
          cmp = a.approvedCount.compareTo(b.approvedCount);
          break;
        case 5:
          cmp = a.rejectedCount.compareTo(b.rejectedCount);
          break;
        case 6:
          cmp = a.skippedCount.compareTo(b.skippedCount);
          break;
        case 8:
          final aT = a.lastSignInAt;
          final bT = b.lastSignInAt;
          if (aT == null && bT == null) {
            cmp = 0;
          } else if (aT == null) {
            cmp = 1; // nulls always last
          } else if (bT == null) {
            cmp = -1;
          } else {
            cmp = aT.compareTo(bT);
          }
          break;
        case 7:
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAsc ? cmp : -cmp;
    });
  }

  void _onSort(int col) => setState(() {
        if (_sortCol == col) {
          _sortAsc = !_sortAsc;
        } else {
          _sortCol = col;
          _sortAsc = true;
        }
        _applySort();
      });

  // ── Header cell ───────────────────────────────────────────────────────────
  Widget _headerCell(int i, double width) {
    final isSorted = _sortCol == i && _sortable[i];
    final numeric = _numeric[i];

    final sortIcon = !_sortable[i]
        ? const SizedBox.shrink()
        : isSorted
            ? Icon(
                _sortAsc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color: _textSecondary,
              )
            : const Icon(Icons.unfold_more_rounded,
                size: 12, color: Color(0xFFCBD5E1));

    final label = Text(
      _labels[i],
      style: AppTypography.bodyMedium.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _textSecondary,
        letterSpacing: 0.3,
      ),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: numeric
          ? [sortIcon, const SizedBox(width: 4), label]
          : [
              label,
              if (_sortable[i]) ...[const SizedBox(width: 4), sortIcon],
            ],
    );

    return GestureDetector(
      onTap: _sortable[i] ? () => _onSort(i) : null,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor:
            _sortable[i] ? SystemMouseCursors.click : MouseCursor.defer,
        child: SizedBox(
          width: width,
          height: _headerHeight,
          child: Align(
            alignment:
                numeric ? Alignment.centerRight : Alignment.centerLeft,
            child: content,
          ),
        ),
      ),
    );
  }

  // ── Data cell ─────────────────────────────────────────────────────────────
  Widget _dataCell(BuildContext ctx, int col, UserProfile u, double width) {
    final numeric = _numeric[col];
    Widget cell;
    switch (col) {
      case 0:
        // Name column: avatar | text | copy-email icon
        const avatarW = 30.0;   // diameter
        const avatarSpacing = 10.0;
        const copyBtnW = 26.0;
        const copyBtnSpacing = 4.0;
        final textW = width - avatarW - avatarSpacing -
            copyBtnW - copyBtnSpacing;
        cell = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.earthyCoral.withOpacity(0.15),
              child: Text(
                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.earthyCoral,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: avatarSpacing),
            SizedBox(
              width: textW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(u.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  if (u.email != null)
                    Text(u.email!,
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: copyBtnSpacing),
            // Per-row email copy button
            if (u.email != null)
              SizedBox(
                width: copyBtnW,
                height: copyBtnW,
                child: Tooltip(
                  message: 'Copy email',
                  waitDuration: const Duration(milliseconds: 400),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      Clipboard.setData(
                              ClipboardData(text: u.email!))
                          .then((_) => _showCopied(
                              ctx, 'Email copied to clipboard'));
                    },
                    child: const Icon(
                      Icons.content_copy_rounded,
                      size: 14,
                      color: _textSecondary,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: copyBtnW),
          ],
        );
        break;
      case 1:
        cell = Text(u.city ?? '—',
            style: const TextStyle(color: _textSecondary));
        break;
      case 2:
        cell = Text(u.universityName ?? '—',
            style: const TextStyle(color: _textSecondary),
            overflow: TextOverflow.ellipsis);
        break;
      case 3:
        cell = _CountBadge(
            count: u.pendingCount,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7));
        break;
      case 4:
        cell = _CountBadge(
            count: u.approvedCount,
            color: AppColors.success,
            bgColor: const Color(0xFFDCFCE7));
        break;
      case 5:
        cell = _CountBadge(
            count: u.rejectedCount,
            color: AppColors.error,
            bgColor: const Color(0xFFFEE2E2));
        break;
      case 6:
        cell = _CountBadge(
            count: u.skippedCount,
            color: AppColors.slateGray,
            bgColor: const Color(0xFFF1F5F9));
        break;
      case 7:
        cell = Text(_fmt.format(u.createdAt),
            style: AppTypography.bodyMedium
                .copyWith(fontSize: 13, color: _textPrimary));
        break;
      case 8:
        cell = u.lastSignInAt != null
            ? Text(_fmt.format(u.lastSignInAt!),
                style: AppTypography.bodyMedium
                    .copyWith(fontSize: 13, color: _textPrimary))
            : Tooltip(
                message:
                    'No sign-in timestamp recorded in the database',
                child: const Text('—',
                    style: TextStyle(color: _textSecondary)),
              );
        break;
      case 9:
      default:
        cell = _TypeBadge(isStudent: u.isStudent);
    }

    return SizedBox(
      width: width,
      height: _rowHeight,
      child: Align(
        alignment:
            numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: cell,
      ),
    );
  }

  // ── Data row ──────────────────────────────────────────────────────────────
  // ── Responsive width computation ─────────────────────────────────────────
  List<double> _computeEffectiveWidths(double available) {
    if (available <= _totalWidth) return List.from(_widths);
    final fixedContentWidth = _widths.fold(0.0, (s, w) => s + w);
    final availContent =
        available - _hPad * 2 - _colSpacing * (_widths.length - 1);
    final scale = availContent / fixedContentWidth;
    return _widths.map((w) => w * scale).toList();
  }

  Widget _buildRow(BuildContext ctx, UserProfile u, List<double> widths) {
    return Container(
      height: _rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Row(
        children: List.generate(widths.length, (i) => Padding(
          padding: EdgeInsets.only(
              right: i < widths.length - 1 ? _colSpacing : 0),
          child: _dataCell(ctx, i, u, widths[i]),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth;
      final needsScroll = available < _totalWidth;
      final widths = _computeEffectiveWidths(available);
      final tableWidth = needsScroll ? _totalWidth : available;

      final headerRow = SizedBox(
        width: tableWidth,
        height: _headerHeight,
        child: ColoredBox(
          color: _headerBg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            child: Row(
              children: List.generate(
                widths.length,
                (i) => Padding(
                  padding: EdgeInsets.only(
                      right: i < widths.length - 1 ? _colSpacing : 0),
                  child: _headerCell(i, widths[i]),
                ),
              ),
            ),
          ),
        ),
      );

      final bodyList = SizedBox(
        width: tableWidth,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _sorted.length,
          itemExtent: _rowHeight,
          itemBuilder: (ctx, index) => _buildRow(ctx, _sorted[index], widths),
        ),
      );

      if (needsScroll) {
        return Column(
          children: [
            SingleChildScrollView(
              controller: _headerHScroll,
              scrollDirection: Axis.horizontal,
              child: headerRow,
            ),
            const Divider(height: 1, thickness: 1, color: _borderColor),
            Expanded(
              child: SingleChildScrollView(
                controller: _bodyHScroll,
                scrollDirection: Axis.horizontal,
                child: bodyList,
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          headerRow,
          const Divider(height: 1, thickness: 1, color: _borderColor),
          Expanded(child: bodyList),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable table widgets
// ─────────────────────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final Color bgColor;

  const _CountBadge({
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Text('0',
          style: TextStyle(color: _textSecondary, fontSize: 13));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isStudent;
  const _TypeBadge({required this.isStudent});

  @override
  Widget build(BuildContext context) {
    final bg = isStudent ? AppColors.softMint : AppColors.warmBeige;
    final textColor = isStudent
        ? const Color(0xFF2D6A4F)
        : const Color(0xFF7B5C3A);
    final border =
        isStudent ? AppColors.softMint : AppColors.sandyTaupe;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        isStudent ? 'Student' : 'General',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics tab — 5 charts in a responsive grid
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final UsersViewModel vm;
  const _AnalyticsTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.analyticsLoading) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.earthyCoral));
    }

    if (vm.analyticsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(vm.analyticsError!,
                style:
                    AppTypography.body.copyWith(color: _textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.loadAnalytics(force: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earthyCoral),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Analytics', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text(
            'Insights for the last 30 days',
            style: AppTypography.bodyMedium.copyWith(color: _textSecondary),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (ctx, box) {
            final narrow = box.maxWidth < 900;
            if (narrow) {
              return Column(
                children: _allCharts(vm).expand((w) sync* {
                  yield w;
                  yield const SizedBox(height: 16);
                }).toList()
                  ..removeLast(),
              );
            }
            // Wide: 2-col row 1, 3-col row 2
            return Column(
              children: [
                _row2(
                  _SignupTrendChart(data: vm.signupTrend),
                  _ActiveUsersChart(data: vm.activeUsersTrend),
                ),
                const SizedBox(height: 16),
                _row3(
                  _CityDistributionChart(data: vm.cityDistribution),
                  _StudentDistributionChart(
                    total: vm.totalUsers,
                    students: vm.studentCount,
                    general: vm.nonStudentCount,
                  ),
                  _TranslationStatusChart(stats: vm.translationStatusStats),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _allCharts(UsersViewModel vm) => [
        _SignupTrendChart(data: vm.signupTrend),
        _ActiveUsersChart(data: vm.activeUsersTrend),
        _CityDistributionChart(data: vm.cityDistribution),
        _StudentDistributionChart(
          total: vm.totalUsers,
          students: vm.studentCount,
          general: vm.nonStudentCount,
        ),
        _TranslationStatusChart(stats: vm.translationStatusStats),
      ];

  Widget _row2(Widget a, Widget b) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: a),
            const SizedBox(width: 16),
            Expanded(child: b),
          ],
        ),
      );

  Widget _row3(Widget a, Widget b, Widget c) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: a),
            const SizedBox(width: 16),
            Expanded(child: b),
            const SizedBox(width: 16),
            Expanded(child: c),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared chart card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;
  final double chartHeight;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.chart,
    this.chartHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: _textSecondary)),
          const SizedBox(height: 20),
          SizedBox(height: chartHeight, child: chart),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart 1 — Sign-up trend (LineChart, coral)
// ─────────────────────────────────────────────────────────────────────────────
class _SignupTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _SignupTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _ChartCard(
        title: 'New Sign-Ups',
        subtitle: 'Daily registrations (last 30 days)',
        chart: const _EmptyChart(message: 'No sign-up data yet'),
      );
    }
    final spots = _spots(data);
    final maxY = _maxY(spots);
    return _ChartCard(
      title: 'New Sign-Ups',
      subtitle: 'Daily registrations (last 30 days)',
      chart: LineChart(_lineChartData(
        spots: spots,
        maxY: maxY,
        color: AppColors.earthyCoral,
        data: data,
        tooltip: 'sign-ups',
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart 2 — Active users trend (LineChart, indigo)
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveUsersChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ActiveUsersChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _ChartCard(
        title: 'Active Users',
        subtitle: 'Unique daily contributors (last 30 days)',
        chart: const _EmptyChart(message: 'No activity data yet'),
      );
    }
    final spots = _spots(data);
    final maxY = _maxY(spots);
    return _ChartCard(
      title: 'Active Users',
      subtitle: 'Unique daily contributors (last 30 days)',
      chart: LineChart(_lineChartData(
        spots: spots,
        maxY: maxY,
        color: const Color(0xFF6366F1),
        data: data,
        tooltip: 'active users',
      )),
    );
  }
}

// Helpers shared by both line charts
List<FlSpot> _spots(List<Map<String, dynamic>> data) => data
    .asMap()
    .entries
    .map((e) =>
        FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble()))
    .toList();

double _maxY(List<FlSpot> spots) =>
    spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

LineChartData _lineChartData({
  required List<FlSpot> spots,
  required double maxY,
  required Color color,
  required List<Map<String, dynamic>> data,
  required String tooltip,
}) {
  final interval = (maxY / 4).ceilToDouble().clamp(1.0, double.infinity);
  return LineChartData(
    minX: 0,
    maxX: (data.length - 1).toDouble(),
    minY: 0,
    maxY: maxY + interval,
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
    ),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: interval,
          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
              style: const TextStyle(
                  fontSize: 10, color: _textSecondary)),
          reservedSize: 30,
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: (data.length / 5)
              .ceilToDouble()
              .clamp(1.0, double.infinity),
          getTitlesWidget: (v, _) {
            final idx = v.toInt();
            if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
            final ds = data[idx]['date'] as String;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(ds.length > 7 ? ds.substring(5) : ds,
                  style: const TextStyle(
                      fontSize: 9, color: _textSecondary)),
            );
          },
          reservedSize: 24,
        ),
      ),
      topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false)),
    ),
    borderData: FlBorderData(show: false),
    lineBarsData: [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData:
            BarAreaData(show: true, color: color.withOpacity(0.08)),
      ),
    ],
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (ts) => ts
            .map((s) => LineTooltipItem(
                  '${s.y.toInt()} $tooltip',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ))
            .toList(),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart 3 — City distribution (BarChart)
// ─────────────────────────────────────────────────────────────────────────────
class _CityDistributionChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CityDistributionChart({required this.data});

  static const _colors = [
    AppColors.earthyCoral,
    Color(0xFF6366F1),
    AppColors.softMint,
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Colors.teal,
    Colors.pink,
    Colors.amber,
    AppColors.slateGray,
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _ChartCard(
        title: 'City Distribution',
        subtitle: 'Top 10 cities by user count',
        chart: const _EmptyChart(message: 'No city data yet'),
        chartHeight: 240,
      );
    }

    final maxY = data
        .map((e) => (e['count'] as int).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final interval = (maxY / 4).ceilToDouble().clamp(1.0, double.infinity);

    return _ChartCard(
      title: 'City Distribution',
      subtitle: 'Top 10 cities by user count',
      chartHeight: 240,
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.25,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, _, rod, _) {
                final city = data[g.x]['city'] as String;
                return BarTooltipItem(
                  '$city\n${rod.toY.toInt()} users',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 10, color: _textSecondary)),
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final city = data[idx]['city'] as String;
                  final lbl =
                      city.length > 6 ? city.substring(0, 6) : city;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(lbl,
                        style: const TextStyle(
                            fontSize: 9, color: _textSecondary)),
                  );
                },
                reservedSize: 24,
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (e.value['count'] as int).toDouble(),
                  color: _colors[e.key % _colors.length],
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart 4 — Student vs General (PieChart)
// ─────────────────────────────────────────────────────────────────────────────
class _StudentDistributionChart extends StatefulWidget {
  final int total;
  final int students;
  final int general;

  const _StudentDistributionChart({
    required this.total,
    required this.students,
    required this.general,
  });

  @override
  State<_StudentDistributionChart> createState() =>
      _StudentDistributionChartState();
}

class _StudentDistributionChartState
    extends State<_StudentDistributionChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    if (widget.total == 0) {
      return _ChartCard(
        title: 'User Types',
        subtitle: 'Student vs general breakdown',
        chart: const _EmptyChart(message: 'No user data yet'),
      );
    }

    String pct(v) =>
        '${((v / widget.total) * 100).toStringAsFixed(1)}%';

    final sections = [
      PieChartSectionData(
        value: widget.students.toDouble(),
        title: _touched == 0
            ? '${widget.students}\nStudents'
            : pct(widget.students),
        color: AppColors.softMint,
        radius: _touched == 0 ? 80 : 70,
        titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D6A4F)),
      ),
      PieChartSectionData(
        value: widget.general.toDouble(),
        title: _touched == 1
            ? '${widget.general}\nGeneral'
            : pct(widget.general),
        color: AppColors.warmBeige,
        radius: _touched == 1 ? 80 : 70,
        titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7B5C3A)),
      ),
    ];

    return _ChartCard(
      title: 'User Types',
      subtitle: 'Student vs general breakdown',
      chartHeight: 220,
      chart: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 36,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (ev, res) => setState(() {
                    if (!ev.isInterestedForInteractions ||
                        res == null ||
                        res.touchedSection == null) {
                      _touched = null;
                    } else {
                      _touched =
                          res.touchedSection!.touchedSectionIndex;
                    }
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(
                  color: AppColors.softMint,
                  label: 'Students (${widget.students})'),
              const SizedBox(width: 16),
              _Legend(
                  color: AppColors.warmBeige,
                  label: 'General (${widget.general})'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart 5 — Translation status breakdown (BarChart)
// ─────────────────────────────────────────────────────────────────────────────
class _TranslationStatusChart extends StatelessWidget {
  final Map<String, int> stats;
  const _TranslationStatusChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pending = stats['pending'] ?? 0;
    final inReview = stats['assigned'] ?? 0;
    final accepted = stats['approved'] ?? 0;
    final rejected = stats['rejected'] ?? 0;
    final total = pending + inReview + accepted + rejected;

    if (total == 0) {
      return _ChartCard(
        title: 'Translation Status',
        subtitle: 'All-time status breakdown',
        chart: const _EmptyChart(message: 'No translations yet'),
        chartHeight: 240,
      );
    }

    final data = [
      {
        'label': 'Pending',
        'count': pending,
        'color': const Color(0xFFF59E0B)
      },
      {
        'label': 'In Review',
        'count': inReview,
        'color': const Color(0xFF6366F1)
      },
      {
        'label': 'Accepted',
        'count': accepted,
        'color': AppColors.success
      },
      {
        'label': 'Rejected',
        'count': rejected,
        'color': AppColors.error
      },
    ];

    final maxY = data
        .map((e) => (e['count'] as int).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final interval = (maxY / 4).ceilToDouble().clamp(1.0, double.infinity);

    return _ChartCard(
      title: 'Translation Status',
      subtitle: 'All-time status breakdown',
      chartHeight: 240,
      chart: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, _, rod, _) {
                      final item = data[g.x];
                      return BarTooltipItem(
                        '${item['label']}\n${rod.toY.toInt()}',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE2E8F0), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 10, color: _textSecondary)),
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final lbl = data[idx]['label'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            lbl.length > 8 ? lbl.substring(0, 7) : lbl,
                            style: const TextStyle(
                                fontSize: 9, color: _textSecondary),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['count'] as int).toDouble(),
                        color: e.value['color'] as Color,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: data
                .map((d) => _Legend(
                      color: d['color'] as Color,
                      label: '${d['label']} (${d['count']})',
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_rounded,
              size: 36, color: _textSecondary),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  fontSize: 13, color: _textSecondary)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: _textSecondary)),
      ],
    );
  }
}
