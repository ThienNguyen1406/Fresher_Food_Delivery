import 'package:flutter/material.dart';
import 'package:fresher_food/models/Cart.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final CartItem cartItem;

  const DeleteConfirmationDialog({
    super.key,
    required this.cartItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Dialog(
      backgroundColor: theme.dialogBackgroundColor ?? theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: isDark ? Colors.red.shade300 : Colors.red.shade400,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Xác nhận xóa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn có chắc muốn xóa "${cartItem.tenSanPham}" khỏi giỏ hàng?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textTheme.bodyMedium?.color,
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.red.shade400
                          : Colors.red.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: isDark ? 6 : 2,
                      shadowColor: isDark
                          ? Colors.red.shade400.withOpacity(0.5)
                          : null,
                    ),
                    child: const Text('Xóa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

