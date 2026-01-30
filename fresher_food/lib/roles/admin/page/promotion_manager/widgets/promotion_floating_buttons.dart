import 'package:flutter/material.dart';

class PromotionFloatingButtons extends StatelessWidget {
  final VoidCallback onGlobalSalePressed;
  final VoidCallback onProductSalePressed;
  final Color primaryColor;

  const PromotionFloatingButtons({
    super.key,
    required this.onGlobalSalePressed,
    required this.onProductSalePressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Floating action button cho khuyến mãi toàn bộ sản phẩm
        FloatingActionButton(
          heroTag: "global_sale",
          onPressed: onGlobalSalePressed,
          backgroundColor: Colors.orange,
          elevation: 4,
          mini: true,
          child: const Icon(Icons.public, color: Colors.white, size: 20),
          tooltip: 'Khuyến mãi toàn bộ sản phẩm',
        ),
        const SizedBox(height: 12),
        // Floating action button cho khuyến mãi sản phẩm cụ thể
        FloatingActionButton(
          heroTag: "product_sale",
          onPressed: onProductSalePressed,
          backgroundColor: primaryColor,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          tooltip: 'Khuyến mãi sản phẩm',
        ),
      ],
    );
  }
}

