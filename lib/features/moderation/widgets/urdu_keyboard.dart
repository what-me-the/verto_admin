import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class UrduKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const UrduKeyboard({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  static const _rows = [
    ['ق', 'و', 'ع', 'ر', 'ص', 'ط', 'ی', 'ا', 'ہ', 'ھ'],
    ['پ', 'ل', 'آ', 'ش', 'س', 'ن', 'م', 'ک', 'گ', 'ئ'],
    ['ز', 'خ', 'چ', 'ج', 'ث', 'ب', 'ت', 'ٹ', 'ظ', 'ض'],
    ['ے', 'ذ', 'ف', 'غ', 'ح', 'د', 'ڈ', 'ڑ', 'ژ', 'ء'],
    ['ں', 'ؤ', 'ۃ', '۔', '،', 'ُ', 'ِ', 'َ', 'ّ', 'ْ'],
  ];

  void _insert(String char) {
    final text = controller.text;
    final sel = controller.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, char);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + char.length),
    );
  }

  void _backspace() {
    final text = controller.text;
    if (text.isEmpty) return;
    final sel = controller.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    if (start != end) {
      // Delete selection
      final newText = text.replaceRange(start, end, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.keyboard, size: 14, color: AppColors.slateGray),
                const SizedBox(width: 6),
                const Text(
                  'Urdu Keyboard',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateGray,
                  ),
                ),
              ],
            ),
          ),
          // Character rows
          ..._rows.map((row) => _buildRow(row)),
          const SizedBox(height: 4),
          // Bottom row: space + backspace
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildSpecialKey(
                  label: 'Space',
                  icon: Icons.space_bar,
                  onTap: () => _insert(' '),
                  color: AppColors.slateGray,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: _buildSpecialKey(
                  label: '⌫ Delete',
                  onTap: _backspace,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> chars) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: chars
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildKey(c),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildKey(String char) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _insert(char),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            char,
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'serif',
              color: Color(0xFF1E293B),
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required String label,
    required VoidCallback onTap,
    required Color color,
    IconData? icon,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: icon != null
              ? Icon(icon, size: 16, color: color)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
        ),
      ),
    );
  }
}
