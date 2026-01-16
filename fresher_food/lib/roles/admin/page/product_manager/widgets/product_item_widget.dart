import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/models/Category.dart';
import 'package:iconsax/iconsax.dart';

class ProductItemWidget extends StatelessWidget {
  final Product product;
  final Category category;
  final Function(Product)? onEdit;
  final Function(Product)? onDelete;
  final String Function(double) formatPrice;

  const ProductItemWidget({
    super.key,
    required this.product,
    required this.category,
    this.onEdit,
    this.onDelete,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: const Color(0xFFE8F5E8),
                child: product.anh.isNotEmpty
                    ? Image.network(
                        product.anh,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFFE8F5E8),
                            child: const Icon(
                              Iconsax.box,
                              color: Color(0xFF2E7D32),
                              size: 24,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          );
                        },
                      )
                    : const Icon(Iconsax.box, color: Color(0xFF2E7D32), size: 24),
              ),
            ),
            const SizedBox(width: 16),

            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.tenSanPham,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatPrice(product.giaBan),
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${product.soLuongTon} ${product.donViTinh}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.soLuongTon > 0
                              ? const Color(0xFFE8F5E8)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.soLuongTon > 0 ? 'Còn hàng' : 'Hết hàng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: product.soLuongTon > 0
                                ? const Color(0xFF2E7D32)
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Danh mục: ${category.tenDanhMuc}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (product.moTa.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      product.moTa,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Nút hành động
            if (onEdit != null || onDelete != null)
              Column(
                children: [
                  if (onEdit != null)
                    _buildActionButton(
                      onPressed: () => onEdit!(product),
                      icon: Iconsax.edit,
                      color: const Color(0xFF2196F3),
                    ),
                  if (onEdit != null && onDelete != null) const SizedBox(height: 8),
                  if (onDelete != null)
                    _buildActionButton(
                      onPressed: () => onDelete!(product),
                      icon: Iconsax.trash,
                      color: Colors.red,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ),
    );
  }
}

