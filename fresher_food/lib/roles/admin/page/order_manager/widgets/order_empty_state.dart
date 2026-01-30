import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class OrderEmptyState extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color textLightColor;

  const OrderEmptyState({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.textLightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.shopping_bag,
                size: 50,
                color: textLightColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có đơn hàng nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy thử thay đổi bộ lọc hoặc tìm kiếm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

