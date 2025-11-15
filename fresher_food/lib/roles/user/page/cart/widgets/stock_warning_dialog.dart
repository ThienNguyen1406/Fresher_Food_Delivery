import 'package:flutter/material.dart';
import 'package:fresher_food/models/Cart.dart';

class StockWarningDialog extends StatelessWidget {
  final CartItem item;

  const StockWarningDialog({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade400,
              size: 50,
            ),
            const SizedBox(height: 16),
            const Text(
              'Số lượng không đủ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sản phẩm "${item.tenSanPham}" chỉ còn ${item.soLuongTon} sản phẩm. Vui lòng điều chỉnh số lượng.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ĐÃ HIỂU'),
            ),
          ],
        ),
      ),
    );
  }
}

