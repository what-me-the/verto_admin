import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/moderation_model.dart';
import '../viewmodels/moderation_viewmodel.dart';
import '../widgets/translation_details_modal.dart';
import '../widgets/edit_translation_modal.dart';

class TranslationDataSource extends DataTableSource {
  final List<TranslationAttempt> translations;
  final BuildContext context;
  final ModerationViewModel viewModel;

  /// Show Approve + Reject buttons (Submitted / In Review tabs).
  final bool showActions;

  /// Show Edit button (Submitted / In Review / Accepted / Rejected tabs).
  final bool showEdit;

  /// Show Send-to-Review button (Submitted tab only).
  final bool showReview;

  TranslationDataSource(
    this.translations,
    this.context,
    this.viewModel, {
    this.showActions = true,
    this.showEdit = false,
    this.showReview = false,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= translations.length) return null;
    final item = translations[index];

    return DataRow(
      cells: [
        // ID
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
        // User
        DataCell(
          Text(
            item.userName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.earthyCoral,
            ),
          ),
        ),
        // Sentence
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
        // Status
        DataCell(_buildStatusBadge(item.status)),
        // Review rating
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.reviewRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
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
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.slateGray.withValues(alpha: 0.1),
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
        // Submitted
        DataCell(
          Text(
            DateFormat('MMM d, HH:mm').format(item.submittedAt),
            style: const TextStyle(color: AppColors.slateGray, fontSize: 13),
          ),
        ),
        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit
              if (showEdit) ...[
                _buildIconAction(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit Translation',
                  color: Colors.amber.shade700,
                  onPressed: () => _openEdit(item),
                ),
                const SizedBox(width: 4),
              ],
              // Send to Review
              if (showReview) ...[
                _buildIconAction(
                  icon: Icons.rate_review_outlined,
                  tooltip: 'Send to Review',
                  color: Colors.blueAccent,
                  onPressed: () => viewModel.sendToReview(item.id),
                ),
                const SizedBox(width: 4),
              ],
              // Approve
              if (showActions) ...[
                _buildIconAction(
                  icon: Icons.check_circle_outline,
                  tooltip: 'Approve',
                  color: AppColors.softMint,
                  onPressed: () => viewModel.approveTranslation(item.id),
                ),
                const SizedBox(width: 4),
                _buildIconAction(
                  icon: Icons.cancel_outlined,
                  tooltip: 'Reject',
                  color: AppColors.error,
                  onPressed: () => viewModel.rejectTranslation(item.id),
                ),
                const SizedBox(width: 4),
              ],
              // View details
              _buildIconAction(
                icon: Icons.visibility_outlined,
                tooltip: 'View Details',
                color: AppColors.slateGray,
                onPressed: () => _openDetails(item),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openEdit(TranslationAttempt item) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: EditTranslationModal(translation: item),
      ),
    );
  }

  void _openDetails(TranslationAttempt item) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: TranslationDetailsModal(translation: item),
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }

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
      case 'reviewed':
        color = Colors.blueAccent;
        icon = Icons.rate_review;
        break;
      case 'pending':
        color = Colors.orangeAccent;
        icon = Icons.hourglass_empty;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => translations.length;

  @override
  int get selectedRowCount => 0;
}
