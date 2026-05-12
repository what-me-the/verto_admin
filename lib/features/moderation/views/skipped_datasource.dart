import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/moderation_model.dart';
import '../viewmodels/moderation_viewmodel.dart';

class SkippedDataSource extends DataTableSource {
  final List<SkippedSentence> skipped;
  final BuildContext context;
  final ModerationViewModel viewModel;

  SkippedDataSource(this.skipped, this.context, this.viewModel);

  @override
  DataRow? getRow(int index) {
    if (index >= skipped.length) return null;
    final item = skipped[index];

    return DataRow(
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
              color: AppColors.slateGray.withOpacity(0.1),
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
          TextButton.icon(
            onPressed: () =>
                viewModel.unassignSkipped(item.id, item.sentenceId),
            icon: const Icon(Icons.undo, size: 16),
            label: const Text('Unassign'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  @override
  int get selectedRowCount => 0;
}
