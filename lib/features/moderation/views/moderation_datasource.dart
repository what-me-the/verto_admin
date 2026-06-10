import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/moderation_model.dart';
import '../viewmodels/moderation_viewmodel.dart';
import '../widgets/translation_details_modal.dart';
import '../widgets/edit_translation_modal.dart';

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.label, this.color, this.onTap);
}

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

  /// Show Revert-to-Submitted button (Accepted tab only).
  final bool showRevert;

  TranslationDataSource(
    this.translations,
    this.context,
    this.viewModel, {
    this.showActions = true,
    this.showEdit = false,
    this.showReview = false,
    this.showRevert = false,
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
        DataCell(_buildActionsMenu(item)),
      ],
    );
  }

  Widget _buildActionsMenu(TranslationAttempt item) {
    final actions = <_ActionItem>[
      if (showEdit)
        _ActionItem(Icons.edit_outlined, 'Edit', Colors.amber.shade700, () => _openEdit(item)),
      if (showReview)
        _ActionItem(Icons.rate_review_outlined, 'Send to Review', Colors.blueAccent, () => viewModel.sendToReview(item.id)),
      if (showActions) ...[
        _ActionItem(Icons.check_circle_outline, 'Approve', AppColors.softMint, () => _showApproveConfirmDialog(item)),
        _ActionItem(Icons.cancel_outlined, 'Reject', AppColors.error, () => viewModel.rejectTranslation(item.id)),
      ],
      if (showRevert)
        _ActionItem(Icons.undo_outlined, 'Revert to Submitted', Colors.deepPurple, () => viewModel.revertToSubmitted(item.id)),
      _ActionItem(Icons.visibility_outlined, 'View Details', AppColors.slateGray, () => _openDetails(item)),
    ];

    if (actions.length <= 2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in actions) ...[
            _buildIconAction(icon: a.icon, tooltip: a.label, color: a.color, onPressed: a.onTap),
            const SizedBox(width: 4),
          ],
        ],
      );
    }

    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.slateGray),
      tooltip: 'Actions',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (idx) => actions[idx].onTap(),
      itemBuilder: (_) => List.generate(
        actions.length,
        (i) => PopupMenuItem<int>(
          value: i,
          child: Row(
            children: [
              Icon(actions[i].icon, size: 16, color: actions[i].color),
              const SizedBox(width: 10),
              Text(
                actions[i].label,
                style: TextStyle(fontSize: 13, color: actions[i].color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApproveConfirmDialog(TranslationAttempt item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.softMint, size: 22),
            SizedBox(width: 8),
            Text('Review Before Approving', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewField('Original Sentence', item.sentence),
                const SizedBox(height: 12),
                _reviewField('Urdu Translation', item.editedUrdu ?? item.urduTranslation, isUrdu: true),
                const SizedBox(height: 12),
                _reviewField('Roman Translation', item.editedRoman ?? item.romanTranslation),
                if (item.reviewNotes != null && item.reviewNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _reviewField('Review Notes', item.reviewNotes!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.approveTranslation(item.id);
            },
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softMint,
              foregroundColor: AppColors.darkCharcoal,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewField(String label, String value, {bool isUrdu = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slateGray),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkCharcoal,
              fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
            ),
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
