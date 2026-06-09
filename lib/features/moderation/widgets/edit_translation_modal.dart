import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/moderation_model.dart';
import '../viewmodels/moderation_viewmodel.dart';
import 'urdu_keyboard.dart';

class EditTranslationModal extends StatefulWidget {
  final TranslationAttempt translation;

  const EditTranslationModal({super.key, required this.translation});

  @override
  State<EditTranslationModal> createState() => _EditTranslationModalState();
}

class _EditTranslationModalState extends State<EditTranslationModal> {
  late final TextEditingController _urduCtrl;
  late final TextEditingController _romanCtrl;
  final FocusNode _urduFocus = FocusNode();
  bool _showUrduKeyboard = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urduCtrl = TextEditingController(text: widget.translation.urduTranslation);
    _romanCtrl = TextEditingController(text: widget.translation.romanTranslation);
    _urduFocus.addListener(() {
      if (_urduFocus.hasFocus && !_showUrduKeyboard) {
        setState(() => _showUrduKeyboard = true);
      }
    });
  }

  @override
  void dispose() {
    _urduCtrl.dispose();
    _romanCtrl.dispose();
    _urduFocus.dispose();
    super.dispose();
  }

  Future<void> _save(ModerationViewModel vm) async {
    final urdu = _urduCtrl.text.trim();
    final roman = _romanCtrl.text.trim();
    if (urdu.isEmpty && roman.isEmpty) return;

    setState(() => _isSaving = true);
    await vm.editTranslation(widget.translation.id, urdu, roman);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Translation updated successfully'),
            ],
          ),
          backgroundColor: AppColors.softMint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ModerationViewModel>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: isDesktop ? 760 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildOriginalSentence(),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUrduField(),
                    const SizedBox(height: 12),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: _showUrduKeyboard
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: UrduKeyboard(
                                controller: _urduCtrl,
                                focusNode: _urduFocus,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    _buildRomanField(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionRow(vm),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.edit_outlined, color: Colors.amber, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Translation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              Text(
                'Correct errors in the Urdu or Roman translation',
                style: TextStyle(fontSize: 13, color: AppColors.slateGray),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.paleGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORIGINAL (KHUWAR)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.slateGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.translation.sentence,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrduField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'URDU TRANSLATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.slateGray,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showUrduKeyboard = !_showUrduKeyboard),
              icon: Icon(
                _showUrduKeyboard ? Icons.keyboard_hide : Icons.keyboard,
                size: 16,
                color: _showUrduKeyboard
                    ? AppColors.earthyCoral
                    : AppColors.slateGray,
              ),
              label: Text(
                _showUrduKeyboard ? 'Hide Keyboard' : 'Show Keyboard',
                style: TextStyle(
                  fontSize: 12,
                  color: _showUrduKeyboard
                      ? AppColors.earthyCoral
                      : AppColors.slateGray,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _urduCtrl,
          focusNode: _urduFocus,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'serif',
            color: AppColors.darkCharcoal,
          ),
          decoration: InputDecoration(
            hintText: 'اردو ترجمہ یہاں لکھیں...',
            hintTextDirection: TextDirection.rtl,
            hintStyle: const TextStyle(
              color: AppColors.slateGray,
              fontSize: 16,
            ),
            filled: true,
            fillColor: const Color(0xFFFFFBF0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.paleGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.amber, width: 2),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildRomanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROMAN TRANSLATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.slateGray,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _romanCtrl,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.darkCharcoal,
          ),
          decoration: InputDecoration(
            hintText: 'Roman Chitrali translation...',
            hintStyle: const TextStyle(color: AppColors.slateGray),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.paleGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.earthyCoral, width: 2),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(ModerationViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.slateGray)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : () => _save(vm),
          icon: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: Text(_isSaving ? 'Saving…' : 'Save Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
