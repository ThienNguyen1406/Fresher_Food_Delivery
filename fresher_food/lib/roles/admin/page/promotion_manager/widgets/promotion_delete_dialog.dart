import 'package:flutter/material.dart';

class PromotionDeleteDialog extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final Color errorColor;

  const PromotionDeleteDialog({
    super.key,
    required this.textPrimary,
    required this.textSecondary,
    required this.errorColor,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Color textPrimary,
    required Color textSecondary,
    required Color errorColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => PromotionDeleteDialog(
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        errorColor: errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Xác nhận xóa',
        style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
      ),
      content: const Text('Bạn có chắc muốn xóa khuyến mãi này?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Hủy', style: TextStyle(color: textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: errorColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

