import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/moderation_model.dart';
import '../viewmodels/moderation_viewmodel.dart';
import '../widgets/translation_details_modal.dart';

class TranslationDataSource extends DataTableSource {
  final List<TranslationAttempt> translations;
  final BuildContext context;
  final ModerationViewModel viewModel;

  /// When true, Approve and Reject action buttons are shown (Submitted / In Review tabs).
  /// When false, only the View Details button is shown (Accepted / Rejected tabs).
  final bool showActions;

  TranslationDataSource(
    this.translations,
    this.context,
    this.viewModel, {
    this.showActions = true,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= translations.length) return null;
    final item = translations[index];

    return DataRow(
      cells: [
        // ID Column
        DataCell(
          Text(
            item.id.length > 8 ? item.id.substring(0, 8) : item.id,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.slateGray,
            ),
          ),
        ),
        // User Column
        DataCell(
          Text(
            item.userName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.earthyCoral,
            ),
          ),
        ),
        // Sentence Column
        DataCell(
          Tooltip(
            message: item.sentence,
            child: SizedBox(
              width: 200,
              child: Text(
                item.sentence,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.darkCharcoal),
              ),
            ),
          ),
        ),
        // Status Column
        DataCell(_buildStatusBadge(item.status)),
        // Review Column
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.reviewRating != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${item.reviewRating}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (item.reviewRating == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slateGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '-',
                    style: TextStyle(color: AppColors.slateGray),
                  ),
                ),
            ],
          ),
        ),
        // Submitted Column
        DataCell(
          Text(
            DateFormat('MMM d, HH:mm').format(item.submittedAt),
            style: const TextStyle(color: AppColors.slateGray, fontSize: 13),
          ),
        ),
        // Actions Column
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showActions) ...[
                _buildActionButton(
                  label: 'Approve',
                  icon: Icons.check,
                  color: AppColors.softMint,
                  onPressed: () => viewModel.approveTranslation(item.id),
                ),
                const SizedBox(width: 6),
                _buildActionButton(
                  label: 'Reject',
                  icon: Icons.close,
                  color: AppColors.error,
                  isOutlined: true,
                  onPressed: () => viewModel.rejectTranslation(item.id),
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: viewModel,
                      child: TranslationDetailsModal(translation: item),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined),
                iconSize: 18,
                tooltip: 'View Details',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.slateGray,
                  backgroundColor: AppColors.slateGray.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => translations.length;

  @override
  int get selectedRowCount => 0;

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'approved':
        color = AppColors.softMint;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppColors.error;
        icon = Icons.cancel;
        break;
      case 'pending':
        color = Colors.orangeAccent;
        icon = Icons.hourglass_empty;
        break;
      case 'assigned':
        color = Colors.blueAccent;
        icon = Icons.assignment;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
