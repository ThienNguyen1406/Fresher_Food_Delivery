import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ProductManagerHeader extends StatelessWidget {
  final int productCount;
  final VoidCallback onAddProduct;
  final VoidCallback? onExportExcel;

  const ProductManagerHeader({
    super.key,
    required this.productCount,
    required this.onAddProduct,
    this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.box, color: Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Quản lý sản phẩm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
            ),
          ),
          const Spacer(),
          // Export Excel button
          if (onExportExcel != null)
            IconButton(
              icon: const Icon(Iconsax.document_download, color: Color(0xFF2E7D32)),
              tooltip: 'Xuất Excel',
              onPressed: onExportExcel,
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$productCount sản phẩm',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

