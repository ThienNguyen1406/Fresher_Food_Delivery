import 'package:flutter/material.dart';
import 'package:fresher_food/models/Cart.dart';

class StockErrorDialog extends StatelessWidget {
  final CartItem item;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;

  const StockErrorDialog({
    super.key,
    required this.item,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.orange.shade400,
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              'Số lượng không đủ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sản phẩm "${item.tenSanPham}" chỉ còn ${item.soLuongTon} sản phẩm trong kho. Bạn đã chọn ${item.soLuong} sản phẩm.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Quay lại giỏ hàng
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('QUAY LẠI GIỎ HÀNG'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

