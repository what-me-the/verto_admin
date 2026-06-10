import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/moderation_model.dart';
import '../viewmodels/moderation_viewmodel.dart';

class SkippedDataSource extends DataTableSource {
  final List<SkippedSentence> skipped;
  final BuildContext context;
  final ModerationViewModel viewModel;
  final Set<String> selectedIds;
  final void Function(String id, String sentenceId, bool selected) onSelectionChanged;
  final void Function(bool selectAll) onSelectAll;

  SkippedDataSource(
    this.skipped,
    this.context,
    this.viewModel, {
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onSelectAll,
  });

  @override
  int get selectedRowCount => selectedIds.length;

  @override
  DataRow? getRow(int index) {
    if (index >= skipped.length) return null;
    final item = skipped[index];

    return DataRow(
      selected: selectedIds.contains(item.id),
      onSelectChanged: (v) {
        onSelectionChanged(item.id, item.sentenceId, v ?? false);
        notifyListeners();
      },
      cells: [
        DataCell(
          Text(
            item.userName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.earthyCoral,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 300,
            child: Text(
              item.sentenceText,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.darkCharcoal),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.slateGray.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.reason ?? 'No reason',
              style: TextStyle(fontSize: 12, color: AppColors.slateGray),
            ),
          ),
        ),
        DataCell(
          Text(
            DateFormat('MMM d, HH:mm').format(item.skippedAt),
            style: const TextStyle(color: AppColors.slateGray),
          ),
        ),
        DataCell(
          Tooltip(
            message: 'Unassign',
            child: Material(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => viewModel.unassignSkipped(item.id, item.sentenceId),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.undo, size: 17, color: AppColors.error),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => skipped.length;
}
