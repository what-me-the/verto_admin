import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/moderation_model.dart';
import '../viewmodels/moderation_viewmodel.dart';
import 'package:provider/provider.dart';

class TranslationDetailsModal extends StatefulWidget {
  final TranslationAttempt translation;

  const TranslationDetailsModal({super.key, required this.translation});

  @override
  State<TranslationDetailsModal> createState() =>
      _TranslationDetailsModalState();
}

class _TranslationDetailsModalState extends State<TranslationDetailsModal> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _skipReasonController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _skipReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ModerationViewModel>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: isDesktop ? 800 : double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOriginalSentence(),
                    const SizedBox(height: 20),
                    _buildTranslations(),
                    const SizedBox(height: 20),
                    if (widget.translation.reviewRating != null)
                      _buildReviewFeedback(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Translation Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            Text(
              'Submitted by ${widget.translation.userName}',
              style: const TextStyle(fontSize: 14, color: AppColors.slateGray),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.slateGray),
        ),
      ],
    );
  }

  Widget _buildOriginalSentence() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.paleGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORIGINAL SENTENCE (KHUWAR)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.slateGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.translation.sentence,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.darkCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslations() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTranslationBox(
            'URDU TRANSLATION',
            widget.translation.urduTranslation,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTranslationBox(
            'ROMAN TRANSLATION',
            widget.translation.romanTranslation,
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationBox(String label, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.paleGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.slateGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16, color: AppColors.darkCharcoal),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFeedback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softMint.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softMint.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rate_review,
                size: 16,
                color: AppColors.slateGray,
              ),
              const SizedBox(width: 8),
              const Text(
                'REVIEWER FEEDBACK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slateGray,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < (widget.translation.reviewRating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          if (widget.translation.reviewNotes != null) ...[
            const SizedBox(height: 8),
            Text(
              '"${widget.translation.reviewNotes}"',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.darkCharcoal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ModerationViewModel viewModel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _showSkipDialog(context, viewModel),
          child: const Text('Skip', style: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _showRejectDialog(context, viewModel),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: const Text('Reject'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            await viewModel.approveTranslation(widget.translation.id);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.softMint,
            foregroundColor: AppColors.darkCharcoal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 0,
          ),
          child: const Text('Approve'),
        ),
      ],
    );
  }

  void _showRejectDialog(BuildContext context, ModerationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Translation'),
          content: TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // In real app, pass reason to rejectTranslation
                await viewModel.rejectTranslation(widget.translation.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close confirm
                  Navigator.pop(context); // Close detail modal
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSkipDialog(BuildContext context, ModerationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Skip Translation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Skipping will remove this translation from the queue and unassign it from the user. Are you sure?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _skipReasonController,
                decoration: const InputDecoration(
                  hintText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await viewModel.skipTranslation(
                  widget.translation,
                  _skipReasonController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context); // Close confirm
                  Navigator.pop(context); // Close detail modal
                }
              },
              child: const Text('Skip'),
            ),
          ],
        );
      },
    );
  }
}
