import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ProductManagerHeader extends StatelessWidget {
  final int productCount;
  final VoidCallback onAddProduct;
  final VoidCallback? onExportExcel;
  final bool isGridView;
  final VoidCallback? onToggleView;

  const ProductManagerHeader({
    super.key,
    required this.productCount,
    required this.onAddProduct,
    this.onExportExcel,
    this.isGridView = false,
    this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const Expanded(
            child: Text(
              'Quản lý sản phẩm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Toggle view button
          if (onToggleView != null)
            IconButton(
              icon: Icon(
                isGridView ? Iconsax.menu_1 : Iconsax.grid_1,
                color: const Color(0xFF2E7D32),
              ),
              tooltip: isGridView ? 'Xem dạng danh sách' : 'Xem dạng lưới',
              onPressed: onToggleView,
            ),
          // Export Excel button
          if (onExportExcel != null)
            IconButton(
              icon: const Icon(Iconsax.document_download, color: Color(0xFF2E7D32)),
              tooltip: 'Xuất Excel',
              onPressed: onExportExcel,
            ),
        ],
      ),
    );
  }
}

